// Phase 1a 통과 기준 실습 — body 재계산을 실제로 세고, 고치고, 다시 센다.
//
// 문서 §7의 진단 절차는 오래 "계획"으로만 있었다. 실행하려면 UI 호스트가 필요한데
// 타입체크만 돌렸기 때문이다. 이 타겟이 그 호스트다.
//
// 설계 원칙: **사람이 클릭하지 않아도 같은 수가 나와야 한다.**
// 앱이 스스로 정해진 횟수만큼 상태를 바꾸고, 세고, 출력하고, 끝낸다.
//
//   swift run RenderingLab
//   xcrun xctrace record --template SwiftUI --launch -- <바이너리>
//
import OSLog
import SwiftUI

// ═══════════════════════════════════════════════════════
// 계측
// ═══════════════════════════════════════════════════════

/// body 는 MainActor 에서 불린다. 락 없이 셀 수 있다.
@MainActor
enum BodyCounter {
    private(set) static var counts: [String: Int] = [:]

    static func tick(_ name: String) {
        counts[name, default: 0] += 1
        signposter.emitEvent("body", "\(name, privacy: .public)")
    }

    /// 구간 측정 — 시작 시점 스냅샷을 찍고 끝에서 차를 낸다.
    /// 게이트로 막지 않고 항상 세는 이유: "초기 렌더가 실제로 일어났는가" 를
    /// 확인해야 0 이 '측정 실패'인지 '무효화 없음'인지 구별된다.
    static func snapshot() -> [String: Int] { counts }

    static func delta(since base: [String: Int]) -> [String: Int] {
        var out: [String: Int] = [:]
        for (key, value) in counts {
            let diff = value - (base[key] ?? 0)
            if diff > 0 { out[key] = diff }
        }
        return out
    }
}

/// Instruments 의 Points of Interest 트랙에 찍힌다.
let signposter = OSSignposter(subsystem: "studdy.rendering", category: .pointsOfInterest)

// ═══════════════════════════════════════════════════════
// 모델
// ═══════════════════════════════════════════════════════

@Observable
final class FeedModel {
    var items: [String]
    /// 자주 바뀌는 값. 목록 내용과는 무관하다.
    var tick = 0

    init(count: Int) {
        items = (0..<count).map { "항목 \($0)" }
    }
}

// ═══════════════════════════════════════════════════════
// ❌ BAD — 목록 body 가 자주 바뀌는 값을 직접 읽는다
// ═══════════════════════════════════════════════════════

struct BadRow: View {
    let title: String

    var body: some View {
        BodyCounter.tick("BadRow")
        return Text(title)
    }
}

struct BadList: View {
    let model: FeedModel

    var body: some View {
        BodyCounter.tick("BadList")
        // 이 한 줄이 목록 전체를 model.tick 에 묶는다.
        // tick 이 바뀔 때마다 이 body 가 다시 돌고 ForEach 가 재구성된다.
        return VStack(spacing: 0) {
            Text("업데이트 \(model.tick)회")
            ForEach(Array(model.items.enumerated()), id: \.offset) { _, title in
                BadRow(title: title)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════
// ✅ GOOD — 바뀌는 값을 읽는 부분만 잎 뷰로 격리한다
// ═══════════════════════════════════════════════════════

struct CounterBadge: View {
    let model: FeedModel

    var body: some View {
        BodyCounter.tick("CounterBadge")
        return Text("업데이트 \(model.tick)회")
    }
}

struct GoodRow: View {
    let title: String

    var body: some View {
        BodyCounter.tick("GoodRow")
        return Text(title)
    }
}

struct GoodList: View {
    let model: FeedModel

    var body: some View {
        BodyCounter.tick("GoodList")
        // 이 body 는 model.tick 을 읽지 않는다. 읽는 건 CounterBadge 뿐이다.
        return VStack(spacing: 0) {
            CounterBadge(model: model)
            ForEach(Array(model.items.enumerated()), id: \.offset) { _, title in
                GoodRow(title: title)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════
// 구동
// ═══════════════════════════════════════════════════════

enum Mode: String, CaseIterable {
    case bad, good
}

@MainActor
@Observable
final class Driver {
    var mode: Mode = .bad
    let model: FeedModel

    static let mutations = 10
    static let rowCount = 20

    init() { model = FeedModel(count: Self.rowCount) }

    private var initialRender: [String: Int] = [:]
    private var results: [(Mode, [String: Int])] = []

    func run() async {
        for mode in Mode.allCases {
            self.mode = mode
            try? await Task.sleep(for: .milliseconds(400))   // 전환 렌더가 끝나길 기다린다

            if mode == .bad { initialRender = BodyCounter.snapshot() }

            let base = BodyCounter.snapshot()
            let state = signposter.beginInterval(
                "mutations", id: signposter.makeSignpostID(),
                "\(mode.rawValue, privacy: .public)"
            )
            for _ in 0..<Self.mutations {
                model.tick += 1
                try? await Task.sleep(for: .milliseconds(50))
            }
            signposter.endInterval("mutations", state)

            results.append((mode, BodyCounter.delta(since: base)))
        }

        printReport()
        exit(0)
    }

    private func printReport() {
        func pad(_ s: String, _ n: Int) -> String {
            s + String(repeating: " ", count: max(0, n - s.count))
        }

        print("")
        print("=== 초기 렌더에서 실제로 body 가 불렸는가 ===")
        if initialRender.isEmpty {
            print("  0건 — 렌더가 일어나지 않았다. 아래 수치는 무의미하다.")
        } else {
            for (name, count) in initialRender.sorted(by: { $0.key < $1.key }) {
                print("  \(pad(name, 16)) \(count)")
            }
        }

        print("")
        print("=== body 호출 횟수 (행 \(Self.rowCount)개 · 무관한 값 \(Self.mutations)회 변경) ===")
        print("")
        print("  \(pad("모드", 8))\(pad("뷰", 16))\(pad("호출", 8))변경당")
        for (mode, delta) in results {
            if delta.isEmpty {
                print("  \(pad(mode.rawValue, 8))(없음)")
                continue
            }
            for (name, count) in delta.sorted(by: { $0.key < $1.key }) {
                let per = String(format: "%.1f", Double(count) / Double(Self.mutations))
                print("  \(pad(mode.rawValue, 8))\(pad(name, 16))\(pad("\(count)", 8))\(per)")
            }
        }
        print("")
    }
}

// ═══════════════════════════════════════════════════════

@main
struct RenderingLabApp: App {
    @State private var driver = Driver()

    var body: some Scene {
        WindowGroup {
            Group {
                switch driver.mode {
                case .bad:  BadList(model: driver.model)
                case .good: GoodList(model: driver.model)
                }
            }
            .frame(width: 320, height: 640)
            .task { await driver.run() }
        }
    }
}
