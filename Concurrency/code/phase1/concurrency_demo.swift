// Phase 1b 검증 — Swift 6 strict concurrency 모드에서 컴파일·실행
// 실행: swift -swift-version 6 Concurrency/code/phase1/concurrency_demo.swift
import Foundation

func threadID() -> UInt64 {
    var tid: UInt64 = 0
    pthread_threadid_np(nil, &tid)
    return tid
}

func ms(_ d: Duration) -> Int {
    Int(Double(d.components.seconds) * 1000
        + Double(d.components.attoseconds) / 1_000_000_000_000_000)
}

// ─────────────────────────────────────────────
// 1. 스레드 ≠ Task — 재개 스레드는 보장되지 않는다
// ─────────────────────────────────────────────
func demo1() async {
    print("[1] 스레드 ≠ Task")
    var observed: Set<UInt64> = [threadID()]
    for _ in 0..<20 {
        try? await Task.sleep(for: .milliseconds(1))
        observed.insert(threadID())
    }
    print("  20회 suspend/resume 중 관측된 스레드 수: \(observed.count)")
    print("  → await는 '이 스레드를 붙잡는다'가 아니라 '여기서 놓아준다'는 뜻")
}

// ─────────────────────────────────────────────
// 2. 구조적 동시성 — async let은 실제로 겹쳐 실행된다
// ─────────────────────────────────────────────
func work(_ milliseconds: Int) async -> Int {
    try? await Task.sleep(for: .milliseconds(milliseconds))
    return milliseconds
}

func demo2() async {
    print("[2] 순차 vs async let")
    let t0 = ContinuousClock.now
    _ = await work(100)
    _ = await work(100)
    let sequential = ContinuousClock.now - t0

    let t1 = ContinuousClock.now
    async let a = work(100)
    async let b = work(100)
    _ = await (a, b)
    let parallel = ContinuousClock.now - t1

    print("  순차:    \(ms(sequential))ms")
    print("  async let: \(ms(parallel))ms")
}

// ─────────────────────────────────────────────
// 3. 취소는 협조적이다 — 확인하지 않으면 멈추지 않는다
// ─────────────────────────────────────────────
func demo3() async {
    print("[3] 취소 전파")

    // (a) 취소를 확인하지 않는 루프 — cancel()에도 끝까지 돈다
    let ignoring = Task {
        var done = 0
        for _ in 1...5 {
            // Task.sleep 대신 계산만 — suspension point가 없다
            for _ in 0..<2_000_000 { done += 1 }
        }
        return "완주(취소 무시), isCancelled=\(Task.isCancelled)"
    }
    ignoring.cancel()
    print("  \(await ignoring.value)")

    // (b) checkCancellation을 쓰는 루프
    let cooperative = Task {
        for i in 1...10 {
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(20))
            _ = i
        }
        return "완주"
    }
    try? await Task.sleep(for: .milliseconds(50))
    cooperative.cancel()
    do {
        print("  결과: \(try await cooperative.value)")
    } catch {
        print("  취소로 종료: \(type(of: error))")
    }

    // (c) TaskGroup — 자식 하나가 던지면 형제에게 취소가 전파된다
    do {
        try await withThrowingTaskGroup(of: Int.self) { group in
            for i in 1...4 {
                group.addTask {
                    if i == 2 {
                        try await Task.sleep(for: .milliseconds(10))
                        throw CancellationError()
                    }
                    try await Task.sleep(for: .milliseconds(200))
                    return i
                }
            }
            for try await _ in group {}
        }
    } catch {
        print("  그룹: 자식 실패 → 형제 취소 후 종료 (\(type(of: error)))")
    }
}

// ─────────────────────────────────────────────
// 4. actor reentrancy — await 전후로 상태 불변이 아니다
// ─────────────────────────────────────────────
actor NaiveLoader {
    private var cache: [String: String] = [:]
    private(set) var fetchCount = 0

    func value(for key: String) async -> String {
        if let cached = cache[key] { return cached }
        // ↓ 이 await에서 actor를 놓아준다. 다른 호출이 위 검사를 똑같이 통과한다
        let fetched = await fetch(key)
        cache[key] = fetched
        return fetched
    }

    private func fetch(_ key: String) async -> String {
        fetchCount += 1
        try? await Task.sleep(for: .milliseconds(50))
        return "v-\(key)"
    }
}

/// 진행 중인 Task를 공유해 중복 요청을 합친다 (single-flight)
actor SingleFlightLoader {
    private var cache: [String: String] = [:]
    private var inFlight: [String: Task<String, Never>] = [:]
    private(set) var fetchCount = 0

    func value(for key: String) async -> String {
        if let cached = cache[key] { return cached }
        if let running = inFlight[key] { return await running.value }

        let task = Task { await self.fetch(key) }
        inFlight[key] = task
        let fetched = await task.value
        cache[key] = fetched
        inFlight[key] = nil
        return fetched
    }

    private func fetch(_ key: String) async -> String {
        fetchCount += 1
        try? await Task.sleep(for: .milliseconds(50))
        return "v-\(key)"
    }
}

func demo4() async {
    print("[4] actor reentrancy 함정")

    let naive = NaiveLoader()
    await withTaskGroup(of: String.self) { group in
        for _ in 0..<5 { group.addTask { await naive.value(for: "k") } }
        for await _ in group {}
    }
    print("  캐시 검사가 있는데도 fetch 횟수: \(await naive.fetchCount)  (동시 호출 5건)")

    let single = SingleFlightLoader()
    await withTaskGroup(of: String.self) { group in
        for _ in 0..<5 { group.addTask { await single.value(for: "k") } }
        for await _ in group {}
    }
    print("  single-flight 적용 후 fetch 횟수: \(await single.fetchCount)")
}

// ─────────────────────────────────────────────
// 5. AsyncStream 버퍼링 정책 — 값은 조용히 버려질 수 있다
// ─────────────────────────────────────────────
func demo5() async {
    print("[5] AsyncStream 버퍼링")

    let (unbounded, c1) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .unbounded)
    for i in 1...5 { c1.yield(i) }
    c1.finish()
    var a: [Int] = []
    for await v in unbounded { a.append(v) }
    print("  .unbounded          → \(a)")

    let (newest, c2) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .bufferingNewest(1))
    for i in 1...5 { c2.yield(i) }
    c2.finish()
    var b: [Int] = []
    for await v in newest { b.append(v) }
    print("  .bufferingNewest(1) → \(b)   (나머지는 버려짐)")
}

// ─────────────────────────────────────────────
// 6. 콜백 API 브리징
// ─────────────────────────────────────────────
func legacyFetch(completion: @escaping @Sendable (String) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.03) {
        completion("legacy-ok")
    }
}

func modernFetch() async -> String {
    await withCheckedContinuation { continuation in
        legacyFetch { continuation.resume(returning: $0) }
    }
}

func demo6() async {
    print("[6] withCheckedContinuation")
    print("  콜백 → async 변환 결과: \(await modernFetch())")
}

await demo1(); print()
await demo2(); print()
await demo3(); print()
await demo4(); print()
await demo5(); print()
await demo6()
