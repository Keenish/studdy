// Phase 1a — SwiftUI 렌더링 모델 코드 모음
// 검증: swiftc -typecheck -swift-version 6 Swift/code/phase1/rendering_views.swift
//
// ⚠️ 이 파일은 타입체크만 검증했다. body 호출 횟수·레이아웃 실측은 UI 호스트가 필요하므로
//    여기서 확인하지 않았다. 무효화 범위의 런타임 근거는 observation_demo.swift에 있다.
import SwiftUI

// ═══════════════════════════════════════════════════════
// 1. body 재평가를 관찰하는 도구
// ═══════════════════════════════════════════════════════
struct ObservedBodyView: View {
    let title: String

    var body: some View {
        // 어떤 의존성이 body를 다시 부르게 했는지 콘솔에 찍는다.
        // 언더스코어 API(비공개)이므로 디버깅 중에만 쓰고 커밋하지 않는다.
        let _ = Self._printChanges()
        return Text(title)
    }
}

// ═══════════════════════════════════════════════════════
// 2. 불필요한 재계산의 전형적 원인 3가지
// ═══════════════════════════════════════════════════════

@Observable
final class FeedModel {
    var query = ""
    var items: [String] = []
    var unrelatedCounter = 0
}

// ❌ (a) 모델 전체를 하위 뷰에 넘긴다 → 하위 뷰가 모델의 모든 읽기에 묶인다
struct BadRow: View {
    let model: FeedModel
    let index: Int
    var body: some View {
        Text(model.items[index])
    }
}

// ✅ 필요한 값만 넘긴다 → 그 값이 바뀔 때만 무효화된다
struct GoodRow: View {
    let text: String
    var body: some View {
        Text(text)
    }
}

// ❌ (b) body 안에서 매번 정렬·필터를 한다
struct BadList: View {
    let items: [String]
    var body: some View {
        // items가 그대로여도 부모가 재평가되면 매번 다시 정렬된다
        VStack {
            ForEach(items.sorted(), id: \.self) { Text($0) }
        }
    }
}

// ✅ 파생 값은 모델 쪽에서 계산해 캐시하거나, 최소한 뷰 밖에서 만든다
struct GoodList: View {
    let sortedItems: [String]
    var body: some View {
        VStack {
            ForEach(sortedItems, id: \.self) { Text($0) }
        }
    }
}

// ❌ (c) 클로저를 프로퍼티로 받으면 Equatable을 만들 수 없다
struct BadButtonRow: View {
    let title: String
    let onTap: () -> Void          // 클로저는 == 비교 대상이 아니다
    var body: some View { Button(title, action: onTap) }
}

// ✅ 비교 대상 값과 동작을 분리한다
struct GoodButtonRow: View, Equatable {
    let title: String
    let isEnabled: Bool

    // View는 @MainActor라서 nonisolated를 붙이지 않으면
    // Equatable 요구사항(nonisolated)을 만족하지 못한다 — Swift 6 모드 컴파일 에러
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title && lhs.isEnabled == rhs.isEnabled
    }

    // 동작은 환경/액션으로 주입해 비교 대상에서 뺀다
    @Environment(\.rowAction) private var action

    var body: some View {
        Button(title) { action() }
            .disabled(!isEnabled)
    }
}

extension EnvironmentValues {
    @Entry var rowAction: () -> Void = {}
}

// ═══════════════════════════════════════════════════════
// 3. Equatable View로 재평가를 끊는다
// ═══════════════════════════════════════════════════════
struct ExpensiveRow: View, Equatable {
    let id: Int
    let label: String

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.label == rhs.label
    }

    var body: some View {
        let _ = Self._printChanges()
        return Text(label)
    }
}

struct EquatableUsage: View {
    let rows: [(id: Int, label: String)]
    var body: some View {
        VStack {
            ForEach(rows, id: \.id) { row in
                // .equatable() = EquatableView 래핑.
                // 값이 같으면 SwiftUI가 body 재평가를 건너뛸 수 있다
                ExpensiveRow(id: row.id, label: row.label)
                    .equatable()
            }
        }
    }
}

// ═══════════════════════════════════════════════════════
// 4. 상태 프로퍼티 래퍼별 무효화 범위
// ═══════════════════════════════════════════════════════
struct StateScopeSample: View {
    // 이 뷰가 소유. 값이 바뀌면 이 뷰의 body만 다시 평가된다
    @State private var localCount = 0

    // 소유하지 않고 참조만. 원본 소유자 기준으로 무효화된다
    @Binding var sharedText: String

    // 읽은 프로퍼티 단위로 추적된다 (observation_demo.swift [1]에서 확인)
    @State private var model = FeedModel()

    // 이 키를 쓰는 뷰만 무효화된다
    @Environment(\.rowAction) private var action

    var body: some View {
        VStack {
            Text("\(localCount)")
            TextField("", text: $sharedText)
            // model.query만 읽는다 → model.unrelatedCounter 변경에는 반응하지 않는다
            Text(model.query)
        }
    }
}

// ═══════════════════════════════════════════════════════
// 5. 레이아웃 협상 — Layout 프로토콜로 3단계를 직접 구현
// ═══════════════════════════════════════════════════════
/// 부모가 제안(proposal) → 자식이 자기 크기 응답 → 부모가 배치(place)
struct EqualWidthHStack: Layout {
    var spacing: CGFloat = 8

    // 1~2단계: 자식에게 물어보고, 내가 필요한 크기를 부모에게 답한다
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let widest = sizes.map(\.width).max() ?? 0
        let tallest = sizes.map(\.height).max() ?? 0
        let totalWidth = widest * CGFloat(subviews.count)
            + spacing * CGFloat(subviews.count - 1)
        return CGSize(width: totalWidth, height: tallest)
    }

    // 3단계: 확정된 bounds 안에 자식을 놓는다
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        var x = bounds.minX
        for subview in subviews {
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(width: widest, height: bounds.height)
            )
            x += widest + spacing
        }
    }
}

// ═══════════════════════════════════════════════════════
// 6. 리스트 — id 안정성이 재사용을 결정한다
// ═══════════════════════════════════════════════════════
struct Item: Identifiable, Equatable {
    let id: UUID          // ❌ 매번 새로 만들면 SwiftUI가 전부 새 뷰로 본다
    let text: String
}

struct StableList: View {
    let items: [Item]
    var body: some View {
        ScrollView {
            // Lazy 계열은 화면에 보이는 것만 body를 평가한다
            LazyVStack {
                ForEach(items) { item in
                    Text(item.text)
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════
// 7. NavigationStack — path 기반 라우팅
// ═══════════════════════════════════════════════════════
enum Route: Hashable {
    case detail(id: Int)
    case settings
}

struct RootView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Button("상세 42") { path.append(.detail(id: 42)) }
                Button("설정") { path.append(.settings) }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .detail(let id): Text("상세 \(id)")
                case .settings: Text("설정")
                }
            }
        }
    }

    /// 딥링크 복원 = path 배열을 한 번에 갈아끼우는 것
    func restore(from deepLink: [Route]) {
        path = deepLink
    }
}
