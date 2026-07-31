// Phase 1b §7 — 진단은 **파도로 온다**는 걸 보이는 프로브.
//
// legacy_service.swift 의 1차 진단 4건은 전부 타입체커가 낸 것이다.
// 타입 검사가 실패하면 SIL 생성이 아예 돌지 않으므로, SIL 패스가 내는
// region isolation 진단은 **가려져서 안 보인다.**
//
// 이 파일은 1차 4건만 우회 수단으로 눌러 놓은 상태다.
// 그러면 2차 진단이 드러난다 — 그리고 그건 -c 에서만 보인다.
//
// ⚠️ 여기 쓰인 nonisolated(unsafe) 는 **의도적인 우회**다. 이 파일은 이행 결과물이
//    아니라 "1차를 넘기면 무엇이 더 나오는가"를 보이기 위한 진단용 표본이다.
//    실제 이행본은 migrated_service.swift 이고 거기엔 우회가 하나도 없다.
import Foundation

nonisolated(unsafe) var currentAccessToken: String?

enum Analytics {
    nonisolated(unsafe) static var eventCount = 0
    static func track(_ name: String) { eventCount += 1; _ = name }
}

final class ImageCache {
    nonisolated(unsafe) static let shared = ImageCache()
    private(set) var storage: [String: Data] = [:]
    func insert(_ data: Data, for key: String) { storage[key] = data }
}

/// ← 2차 진단이 여기서 난다 (비Sendable 캐시를 detached task 로 보낸다)
func prefetch(urls: [String], into cache: ImageCache) {
    for url in urls {
        Task.detached { cache.insert(Data(url.utf8), for: url) }
    }
}

/// ← 그리고 여기서도 (MainActor 표시 없는 화면 상태를 백그라운드에서 쓴다)
final class FeedScreenState {
    var rows: [String] = []
    func load() {
        Task.detached { self.rows = ["행 0"] }
    }
}

protocol Summarizable {
    var summary: String { get }
}

@MainActor
final class FeedSummary: @MainActor Summarizable {
    var rowCount = 0
    var summary: String { "행 \(rowCount)개" }
}
