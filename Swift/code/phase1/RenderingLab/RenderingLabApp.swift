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
// 🔬 EQUATABLE — `.equatable()` 이 실제로 재평가를 줄이는가
//
// §9 가 오래 "미검증"으로 남겨둔 항목. 앞의 bad/good 실측에서 행 body 가 0 회였던
// 이유는 **입력이 이미 같아서 SwiftUI 가 알아서 건너뛴 것**이라, `.equatable()` 의
// 효과를 잰 게 아니었다.
//
// 자동 건너뛰기가 안 되는 조건을 만들어야 차이가 보인다. 뷰가 **클로저를 들고
// 있으면** SwiftUI 는 두 값을 비교할 수 없어 매번 다시 평가한다.
// ═══════════════════════════════════════════════════════

/// 클로저를 들고 있어 자동 비교가 안 되는 행.
struct ClosureRow: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        BodyCounter.tick("ClosureRow")
        return Text(title)
    }
}

/// 같은 행에 `Equatable` 을 직접 구현한다. 클로저는 비교에서 **뺀다** —
/// 렌더 결과에 영향이 없기 때문이다. 이게 `.equatable()` 이 사는 자리다.
struct EquatableRow: View, Equatable {
    let title: String
    let onTap: () -> Void

    // `View` 가 @MainActor 라 준수가 격리를 넘는다. §4-B 사례 4 와 같은 진단이고
    // 해법도 같다 — nonisolated. (@preconcurrency 는 런타임 오류로 미루는 우회다)
    nonisolated static func == (lhs: EquatableRow, rhs: EquatableRow) -> Bool {
        lhs.title == rhs.title
    }

    var body: some View {
        BodyCounter.tick("EquatableRow")
        return Text(title)
    }
}

/// 부모가 tick 을 읽으므로 변경마다 부모 body 가 다시 돈다(= BadList 와 같은 조건).
/// 차이는 자식이 `.equatable()` 을 붙였는지 하나뿐이다.
struct ClosureList: View {
    let model: FeedModel

    var body: some View {
        BodyCounter.tick("ClosureList")
        let t = model.tick
        let captured: () -> Void = { _ = t }   // 값을 캡처 → 렌더마다 새 컨텍스트
        return VStack(spacing: 0) {
            Text("업데이트 \(model.tick)회")
            ForEach(Array(model.items.enumerated()), id: \.offset) { _, title in
                // ⚠️ 비캡처 `{}` 를 넘기면 매번 같은 값이라 SwiftUI 가 그냥 건너뛴다.
                // 그러면 `.equatable()` 의 효과를 잴 조건 자체가 안 만들어진다(사례 17).
                ClosureRow(title: title, onTap: { captured() })
            }
        }
    }
}

struct EquatableList: View {
    let model: FeedModel

    var body: some View {
        BodyCounter.tick("EquatableList")
        let t = model.tick
        let captured: () -> Void = { _ = t }
        return VStack(spacing: 0) {
            Text("업데이트 \(model.tick)회")
            ForEach(Array(model.items.enumerated()), id: \.offset) { _, title in
                EquatableRow(title: title, onTap: { captured() }).equatable()
            }
        }
    }
}

// ═══════════════════════════════════════════════════════
// 구동
// ═══════════════════════════════════════════════════════

enum Mode: String, CaseIterable {
    case bad, good
    /// `.equatable()` 비교군 — 클로저를 들고 있어 자동 건너뛰기가 안 되는 조건
    case closure, equatable
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
    /// 모드 전환 시의 렌더. "행이 아예 안 그려진 것"과 "그려졌지만 재평가가 없는 것"을
    /// 구별하기 위한 양성 대조 — 이게 없으면 0 을 잘못 읽는다.
    private var transitionRender: [(Mode, [String: Int])] = []

    func run() async {
        for mode in Mode.allCases {
            let beforeTransition = BodyCounter.snapshot()
            self.mode = mode
            try? await Task.sleep(for: .milliseconds(400))   // 전환 렌더가 끝나길 기다린다
            transitionRender.append((mode, BodyCounter.delta(since: beforeTransition)))

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
        print("=== 모드 전환 시 렌더 (양성 대조 — 뷰가 그려지긴 했는가) ===")
        for (mode, delta) in transitionRender {
            let sum = delta.values.reduce(0, +)
            let detail = delta.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: " · ")
            print("  \(pad(mode.rawValue, 10))\(pad("총 \(sum)", 10))\(detail)")
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
                case .bad:       BadList(model: driver.model)
                case .good:      GoodList(model: driver.model)
                case .closure:   ClosureList(model: driver.model)
                case .equatable: EquatableList(model: driver.model)
                }
            }
            .frame(width: 320, height: 640)
            .task { await driver.run() }
        }
    }
}
