// Phase 1b §7 — 이행 **전**. Swift 5 시절 관용구로 쓴 작은 피처 모듈.
//
// §7의 "경고 유형별 처방" 표에 있는 5가지를 전부 하나씩 담았다.
// 억지로 만든 게 아니라 실제 앱에서 흔한 모양이다 —
// 전역 토큰 · 싱글턴 캐시 · 콜백 재시도 · 화면 상태 클래스.
//
//   swiftc -typecheck -swift-version 5 legacy_service.swift   → 통과
//   swiftc -typecheck -swift-version 6 legacy_service.swift   → 진단 발생 (그게 목적)
//
// ⚠️ 이 파일은 고치지 않는다. 이행 결과는 migrated_service.swift 에 따로 있다.
//    두 파일을 나란히 둬야 "무엇이 어떻게 바뀌었나"가 보인다.
import Foundation

// ═══════════════════════════════════════════════════════
// ① 전역 가변 상태
// ═══════════════════════════════════════════════════════

/// 로그인하면 채워 넣고 아무 데서나 읽던 값.
var currentAccessToken: String?

enum Analytics {
    /// 이벤트 수를 세는 static var. 어느 스레드에서든 증가시켰다.
    static var eventCount = 0

    static func track(_ name: String) {
        eventCount += 1
        print("[analytics] \(name) (\(eventCount))")
    }
}

// ═══════════════════════════════════════════════════════
// ② 비Sendable 타입이 격리 경계를 넘는다
// ═══════════════════════════════════════════════════════

/// 평범한 참조 타입 캐시. Sendable 표시가 없다.
final class ImageCache {
    static let shared = ImageCache()
    private(set) var storage: [String: Data] = [:]

    func insert(_ data: Data, for key: String) {
        storage[key] = data
    }
}

/// 캐시 객체를 그대로 다른 격리로 넘긴다.
func prefetch(urls: [String], into cache: ImageCache) {
    for url in urls {
        Task.detached {
            let data = Data(url.utf8)
            cache.insert(data, for: url)   // 비Sendable 캡처
        }
    }
}

// ═══════════════════════════════════════════════════════
// ③ 메인 액터 격리 위반 — UI 인접 타입에 표시가 없다
// ═══════════════════════════════════════════════════════

/// 화면 상태를 들고 있는데 @MainActor 가 없다.
/// 로딩이 끝나면 백그라운드에서 바로 프로퍼티를 쓴다.
final class FeedScreenState {
    var title = ""
    var rows: [String] = []
    var isLoading = false

    func load() {
        isLoading = true
        Task.detached {
            let fetched = (0..<3).map { "행 \($0)" }
            self.rows = fetched          // 백그라운드에서 UI 상태 변경
            self.title = "피드"
            self.isLoading = false
        }
    }
}

// ═══════════════════════════════════════════════════════
// ④ 프로토콜 준수가 격리를 넘는다
// ═══════════════════════════════════════════════════════

/// 로깅용 프로토콜. 격리 표시가 없으니 요구사항은 nonisolated 다.
protocol Summarizable {
    var summary: String { get }
}

/// 화면 상태라 MainActor 인데, nonisolated 요구사항을 구현한다.
@MainActor
final class FeedSummary: Summarizable {
    var rowCount = 0

    var summary: String {
        "행 \(rowCount)개"
    }
}

// ═══════════════════════════════════════════════════════
// ⑤ 클로저가 가변 상태를 캡처한다
// ═══════════════════════════════════════════════════════

/// 실패하면 다시 시도하는 흔한 헬퍼. 시도 횟수를 클로저 밖 var 로 센다.
func retrying(times: Int, _ body: @escaping @Sendable () -> Bool) {
    var attempts = 0
    Task.detached {
        while attempts < times {
            attempts += 1               // 가변 캡처
            if body() { break }
        }
        Analytics.track("retry-\(attempts)")
    }
}
