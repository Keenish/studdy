// Phase 1b §7 — 이행 **후**. legacy_service.swift 를 Swift 6 complete 에서 깨끗하게.
//
// 제약: **우회 수단을 하나도 쓰지 않는다.**
//   금지 — @unchecked Sendable · nonisolated(unsafe) · @preconcurrency
//   verify_migration.sh 가 grep 으로 강제한다.
//
//   swiftc -c -swift-version 6 -parse-as-library migrated_service.swift   → 진단 0
//
// ⚠️ -typecheck 이 아니라 -c 로 컴파일해야 한다. region isolation 진단은
//    타입체커가 아니라 SIL 패스에서 나오므로 -typecheck 은 그냥 통과시킨다.
//    (이 사실 자체가 이번 이행에서 얻은 것이다 — 문서 §7 참조)
import Foundation
import Synchronization

// ═══════════════════════════════════════════════════════
// ① 전역 가변 상태 → 격리된 저장소
// ═══════════════════════════════════════════════════════

/// 전역 var 를 actor 로 감쌌다. 읽기도 await 가 되는 게 대가다.
/// 그 대가가 싫으면 @MainActor 로 두는 선택지도 있다 — 접근 지점이 전부 UI 라면.
actor TokenStore {
    static let shared = TokenStore()

    private var accessToken: String?

    func update(_ token: String?) { accessToken = token }
    func current() -> String? { accessToken }
}

/// 카운터는 actor 까지 갈 필요가 없다. 잠깐 잠그고 끝나는 접근이라 Mutex 가 맞다.
/// actor 로 만들면 track 이 async 가 되어 호출부가 전부 오염된다.
enum Analytics {
    private static let eventCount = Mutex(0)

    static func track(_ name: String) {
        let n = eventCount.withLock { $0 += 1; return $0 }
        print("[analytics] \(name) (\(n))")
    }

    static var count: Int { eventCount.withLock { $0 } }
}

// ═══════════════════════════════════════════════════════
// ② 비Sendable 타입이 경계를 넘는다 → 애초에 넘기지 않는다
// ═══════════════════════════════════════════════════════

/// class → actor. 내부 상태가 격리되니 참조를 넘겨도 안전하다.
/// (actor 는 자동으로 Sendable 이다)
actor ImageCache {
    static let shared = ImageCache()

    private var storage: [String: Data] = [:]

    func insert(_ data: Data, for key: String) { storage[key] = data }
    func value(for key: String) -> Data? { storage[key] }
    var count: Int { storage.count }
}

/// 각 Task 가 캐시 액터에 말을 건다. 넘어가는 건 참조가 아니라 메시지다.
func prefetch(urls: [String], into cache: ImageCache) {
    for url in urls {
        Task.detached {
            let data = Data(url.utf8)
            await cache.insert(data, for: url)
        }
    }
}

// ═══════════════════════════════════════════════════════
// ③ 메인 액터 격리 위반 → 타입에 표시
// ═══════════════════════════════════════════════════════

/// UI 상태니까 @MainActor. 그러면 백그라운드에서 직접 쓰는 코드가 컴파일되지 않는다.
@MainActor
final class FeedScreenState {
    var title = ""
    var rows: [String] = []
    var isLoading = false

    /// Task.detached 대신 Task — 현재 격리(MainActor)를 물려받는다.
    /// 무거운 작업만 따로 떼면 되지, 상태 갱신까지 밖으로 낼 이유가 없다.
    func load() async {
        isLoading = true
        let fetched = await Self.fetch()
        rows = fetched
        title = "피드"
        isLoading = false
    }

    /// 실제 작업은 격리 밖에서. 값 타입만 돌려준다.
    private nonisolated static func fetch() async -> [String] {
        (0..<3).map { "행 \($0)" }
    }
}

// ═══════════════════════════════════════════════════════
// ④ 프로토콜 준수가 격리를 넘는다 → 준수 자체를 격리
// ═══════════════════════════════════════════════════════

protocol Summarizable {
    var summary: String { get }
}

/// `: @MainActor Summarizable` — 준수를 MainActor 로 격리한다.
/// 컴파일러가 진단에서 직접 제안하는 해법이고, 검사를 끄는 게 아니다.
/// (같은 진단의 다른 제안인 @preconcurrency 는 런타임 오류로 미루는 우회다)
@MainActor
final class FeedSummary: @MainActor Summarizable {
    var rowCount = 0

    var summary: String {
        "행 \(rowCount)개"
    }
}

// ═══════════════════════════════════════════════════════
// ⑤ 클로저의 가변 캡처
// ═══════════════════════════════════════════════════════

/// 원본 그대로 둬도 Swift 6 에서 통과한다 — region isolation 이
/// `attempts` 가 클로저 안에서만 쓰인다는 걸 증명하기 때문이다.
/// "가변 캡처는 무조건 위반"이라는 옛 규칙은 더 이상 맞지 않는다.
func retrying(times: Int, _ body: @escaping @Sendable () -> Bool) {
    var attempts = 0
    Task.detached {
        while attempts < times {
            attempts += 1
            if body() { break }
        }
        Analytics.track("retry-\(attempts)")
    }
}
