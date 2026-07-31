// §2-D 실습 — 같은 화면을 세 번째 방식(Reducer + Store)으로 구현하고,
// 테스트 결정론을 A·B와 비교한다.
// 실행: swift -swift-version 6 Architecture/code/phase2/three_way.swift
//
// ⚠️ 이건 TCA 라이브러리가 아니다. Point-Free ep68~71·83~84가 라이브러리 이전에
//    손으로 만들어 보이는 형태를 최소로 재현한 것이다. 패턴 수준의 비교만 유효하고,
//    라이브러리 비용(컴파일 시간·러닝커브·lock-in)은 여기서 측정되지 않는다.
import Foundation

// ═══════════════════════════════════════════════════════════
// 공통 도메인
// ═══════════════════════════════════════════════════════════

struct Country: Equatable, Sendable {
    let code: String
    let name: String
}

enum LoadFailure: Error, Equatable { case network }

let stubbed = [
    Country(code: "KR", name: "대한민국"),
    Country(code: "JP", name: "일본"),
    Country(code: "US", name: "미국"),
    Country(code: "GB", name: "영국"),
]

/// 리듀서가 정렬한 뒤의 기대값 (KR 최상단 + 이름순).
/// 정렬 규칙을 리듀서에 넣은 순간 테스트 기대가 낡았고, TestStore가 그걸 잡았다.
let sortedStubbed = [
    Country(code: "KR", name: "대한민국"),
    Country(code: "US", name: "미국"),
    Country(code: "GB", name: "영국"),
    Country(code: "JP", name: "일본"),
]

// ═══════════════════════════════════════════════════════════
// 리듀서 코어 — ep68~71 형태
// ═══════════════════════════════════════════════════════════
// <CORE>

/// 부수효과를 **값으로** 반환한다. 실행 시점을 호출자가 정한다 = 테스트가 통제한다.
struct Effect<Action: Sendable>: Sendable {
    let run: @Sendable () async -> Action?
}

/// (inout State, Action, Environment) -> [Effect<Action>]
typealias Reducer<State, Action: Sendable, Environment> =
    (inout State, Action, Environment) -> [Effect<Action>]

@MainActor
final class Store<State, Action: Sendable, Environment> {
    private(set) var state: State
    private let reducer: Reducer<State, Action, Environment>
    private let environment: Environment

    init(initial: State, reducer: @escaping Reducer<State, Action, Environment>, environment: Environment) {
        self.state = initial
        self.reducer = reducer
        self.environment = environment
    }

    /// 실서비스 경로: 효과를 즉시 띄운다.
    func send(_ action: Action) {
        for effect in reducer(&state, action, environment) {
            Task { @MainActor in
                if let next = await effect.run() { self.send(next) }
            }
        }
    }
}

// </CORE>

// ═══════════════════════════════════════════════════════════
// 버전 C — Reducer + Store + Environment
// ═══════════════════════════════════════════════════════════
// <C>

struct CountryState: Equatable {
    var query = ""
    var countries: [Country] = []
    var isLoading = false
    var errorMessage: String?

    var visible: [Country] {
        query.isEmpty ? countries : countries.filter { $0.name.contains(query) }
    }
}

enum CountryAction: Equatable, Sendable {
    case appeared
    case queryChanged(String)
    case retryTapped
    case response(Result<[Country], LoadFailure>)
}

/// 프로토콜이 아니라 **함수를 담은 구조체**. 목을 만들려고 타입을 새로 선언하지 않는다 (ep83).
struct CountryEnvironment {
    var loadCountries: @Sendable () async -> Result<[Country], LoadFailure>
    var preferredCode: String = "KR"
}

/// 실패 메시지를 읽을 수 있게. 실제 TestStore도 같은 이유로 진단 출력에 공을 들인다.
extension CountryAction: CustomStringConvertible {
    var description: String {
        switch self {
        case .appeared: return "appeared"
        case .retryTapped: return "retryTapped"
        case let .queryChanged(text): return "queryChanged(\"\(text)\")"
        case let .response(.success(list)): return "response(.success, \(list.count)개)"
        case let .response(.failure(error)): return "response(.failure(\(error)))"
        }
    }
}

let countryReducer: Reducer<CountryState, CountryAction, CountryEnvironment> = { state, action, env in
    switch action {
    case .appeared, .retryTapped:
        state.isLoading = true
        state.errorMessage = nil
        return [Effect { .response(await env.loadCountries()) }]

    case let .queryChanged(text):
        state.query = text
        return []

    case let .response(.success(countries)):
        state.isLoading = false
        // 비즈니스 규칙(선호 국가 최상단)이 여기 산다.
        // A는 State의 계산 프로퍼티, B는 UseCase, C는 리듀서 — 세 방식의 차이가 이 줄이다.
        state.countries = countries.sorted { lhs, rhs in
            if lhs.code == env.preferredCode { return true }
            if rhs.code == env.preferredCode { return false }
            return lhs.name < rhs.name
        }
        return []

    case .response(.failure):
        state.isLoading = false
        state.errorMessage = "목록을 불러오지 못했어요."
        return []
    }
}

// </C>

// ═══════════════════════════════════════════════════════════
// TestStore — ep84의 "보낸 액션 / 받은 액션" 구분을 강제한다
// ═══════════════════════════════════════════════════════════
// <TESTSTORE>

@MainActor
final class TestStore<State: Equatable, Action: Equatable & Sendable, Environment> {
    private var state: State
    private let reducer: Reducer<State, Action, Environment>
    private let environment: Environment
    private var pending: [Effect<Action>] = []
    private(set) var failures: [String] = []

    init(initial: State, reducer: @escaping Reducer<State, Action, Environment>, environment: Environment) {
        self.state = initial
        self.reducer = reducer
        self.environment = environment
    }

    /// 사용자 행동. 기대 상태를 직접 적는다.
    func send(_ action: Action, expect mutate: (inout State) -> Void) {
        var expected = state
        mutate(&expected)
        pending += reducer(&state, action, environment)
        if state != expected { failures.append("send(\(action)) 후 상태 불일치") }
    }

    /// 효과가 돌려준 액션. 무엇이 올지도 함께 적는다.
    func receive(_ expected: Action, expect mutate: (inout State) -> Void) async {
        guard !pending.isEmpty else {
            failures.append("receive(\(expected))를 기대했지만 대기 중인 효과가 없다")
            return
        }
        let effect = pending.removeFirst()
        guard let produced = await effect.run() else {
            failures.append("효과가 액션을 돌려주지 않았다")
            return
        }
        if produced != expected {
            failures.append("받은 액션 불일치: 기대 \(expected), 실제 \(produced)")
        }
        var expectedState = state
        mutate(&expectedState)
        pending += reducer(&state, produced, environment)
        if state != expectedState { failures.append("receive(\(produced)) 후 상태 불일치") }
    }

    /// 전수성 검사: 처리하지 않은 효과가 남아 있으면 실패다.
    func finish() {
        if !pending.isEmpty {
            failures.append("처리하지 않은 효과 \(pending.count)개가 남았다")
        }
    }
}

// </TESTSTORE>

// ═══════════════════════════════════════════════════════════
// 확인 1 — 실서비스 경로에서 동작이 A·B와 같다
// ═══════════════════════════════════════════════════════════

@MainActor
func runBehaviour() async {
    print("[C-1] 실서비스 경로")
    let failFirst = Counter()
    let env = CountryEnvironment {
        let n = failFirst.increment()
        try? await Task.sleep(for: .milliseconds(10))
        return n == 1 ? .failure(.network) : .success(stubbed)
    }
    let store = Store(initial: CountryState(), reducer: countryReducer, environment: env)

    store.send(.appeared)
    print("  로딩 시작: isLoading=\(store.state.isLoading)")
    try? await Task.sleep(for: .milliseconds(60))
    print("  첫 시도 실패: error=\(store.state.errorMessage ?? "nil")")

    store.send(.retryTapped)
    try? await Task.sleep(for: .milliseconds(60))
    print("  재시도 성공: \(store.state.visible.map(\.code))")

    store.send(.queryChanged("국"))
    print("  '국' 필터: \(store.state.visible.map(\.code))")
}

final class Counter: Sendable {
    private let box = Mutex(0)
    func increment() -> Int { box.withLock { $0 += 1; return $0 } }
}

// ═══════════════════════════════════════════════════════════
// 확인 2 — 테스트에서 대기(sleep)가 필요 없다
// ═══════════════════════════════════════════════════════════

@MainActor
func runDeterministicTest() async {
    print("[C-2] TestStore — 대기 없이 전수 검증")
    let env = CountryEnvironment { .success(stubbed) }
    let store = TestStore(initial: CountryState(), reducer: countryReducer, environment: env)

    store.send(.appeared) { $0.isLoading = true }
    await store.receive(.response(.success(stubbed))) {
        $0.isLoading = false
        $0.countries = sortedStubbed        // 리듀서가 정렬한다
    }
    store.send(.queryChanged("국")) { $0.query = "국" }
    store.finish()

    print("  실패 \(store.failures.count)건 — \(store.failures.isEmpty ? "전부 기대와 일치" : store.failures.joined(separator: " / "))")
    print("  Task.sleep 호출 0회. 효과 실행 시점을 테스트가 정한다")
}

// ═══════════════════════════════════════════════════════════
// 확인 3 — 틀린 기대를 실제로 잡아내는가
// ═══════════════════════════════════════════════════════════

@MainActor
func runExhaustivityCheck() async {
    print("[C-3] 전수성 — 틀린 기대와 빠뜨린 효과를 잡는다")

    // (a) 상태 기대를 틀리게 적는다
    let s1 = TestStore(initial: CountryState(), reducer: countryReducer,
                       environment: CountryEnvironment { .success(stubbed) })
    s1.send(.appeared) { $0.isLoading = false }   // 실제로는 true
    print("  (a) 상태 기대 오류 → 검출 \(s1.failures.count)건: \(s1.failures.first ?? "-")")

    // (b) 받을 액션을 틀리게 적는다
    let s2 = TestStore(initial: CountryState(), reducer: countryReducer,
                       environment: CountryEnvironment { .failure(.network) })
    s2.send(.appeared) { $0.isLoading = true }
    await s2.receive(.response(.success(stubbed))) { _ in }   // 실제로는 failure
    print("  (b) 액션 기대 오류 → 검출 \(s2.failures.count)건: \(s2.failures.first ?? "-")")

    // (c) 효과를 처리하지 않고 끝낸다
    let s3 = TestStore(initial: CountryState(), reducer: countryReducer,
                       environment: CountryEnvironment { .success(stubbed) })
    s3.send(.appeared) { $0.isLoading = true }
    s3.finish()                                   // receive를 빠뜨렸다
    print("  (c) 효과 누락 → 검출 \(s3.failures.count)건: \(s3.failures.first ?? "-")")
}

import Synchronization

await runBehaviour(); print()
await runDeterministicTest(); print()
await runExhaustivityCheck()
