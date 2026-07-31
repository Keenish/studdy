// Phase 1b §7 후속 — 이행본을 **실행해서** 데이터 레이스가 없는지 본다.
//
// 문서가 오래 "컴파일만 확인했다. 실행해 데이터 레이스가 없음을 보인 게 아니다"로
// 남겨둔 항목이다. Swift 6 complete 가 컴파일 타임에 증명한다고 하지만,
// **그 증명이 실제로 맞는지는 다른 질문**이다.
//
// 실행:
//   swiftc -swift-version 6 -sanitize=thread -O \
//     -o /tmp/tsan_run migrated_service.swift tsan_driver.swift && /tmp/tsan_run
//
// TSan 은 "실행된 경로에서 관측된 레이스"만 잡는다. 안 돈 코드는 검사되지 않으므로
// 아래 드라이버는 이행본의 다섯 축을 **전부 동시에** 두드린다.
import Foundation

@main
struct TSanDriver {
    static func main() async {
        // ① 격리된 전역 상태 — 여러 Task 가 같은 actor 를 동시에 읽고 쓴다
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<64 {
                group.addTask {
                    await TokenStore.shared.update("token-\(i)")
                    _ = await TokenStore.shared.current()
                }
            }
        }

        // ① Mutex — actor 가 아니라 잠금으로 보호한 카운터
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<64 {
                group.addTask { Analytics.track("event-\(i)") }
            }
        }

        // ② actor 캐시에 detached Task 들이 동시에 쓴다
        let cache = ImageCache()
        prefetch(urls: (0..<64).map { "https://example.invalid/\($0).png" }, into: cache)

        // ③ MainActor 격리 상태 — 백그라운드와 섞어 돌린다
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                // `group.addTask { @MainActor in ... }` 로 쓰면 컴파일되지 않는다:
                //   error: pattern that the region-based isolation checker does not
                //          understand how to check. Please file a bug
                // 컴파일러가 스스로 버그 신고를 요청하는 진단이다. 격리를 클로저 속성이
                // 아니라 **호출 지점**에 두면 통과한다 — 의미는 같다.
                group.addTask {
                    let screen = await MainActor.run { FeedScreenState() }
                    await screen.load()
                    _ = await screen.rows.count
                }
            }
            for _ in 0..<8 {
                group.addTask {
                    _ = await TokenStore.shared.current()
                }
            }
        }

        // ④ 격리된 프로토콜 준수
        await MainActor.run {
            let s = FeedSummary()
            s.rowCount = 3
            _ = s.summary
        }

        // ⑤ 클로저의 가변 캡처 — region isolation 이 안전을 증명한 자리
        for _ in 0..<16 {
            retrying(times: 4) { Bool.random() }
        }

        // detached Task 들이 끝날 시간을 준다. TSan 은 관측한 것만 잡으므로
        // 여기서 일찍 끝내면 "레이스 없음"이 아니라 "안 봤음"이 된다.
        try? await Task.sleep(for: .milliseconds(500))

        let cached = await cache.count
        print("완료 — analytics \(Analytics.count)건 · cache \(cached)건")
    }
}
