// Phase 3 §5 — "스냅샷 테스트는 0개" 를 닫는다.
//
// 감사가 지적한 것: Preview 15개가 스냅샷을 대신하고 있는데 셋을 못 한다.
//   1. 회귀 검출     — 토큰 하나 바꿔 45개 중 3개가 깨져도 눈으로 봐야 안다
//   2. 조합 커버리지 — CaseIterable 이 있는데 전 조합 결과를 고정해 비교하지 않는다
//   3. 접근성 상태   — Dynamic Type·reduce motion 렌더를 매번 스위치로 보기 어렵다
//
// 여기서는 1·2를 닫는다. 3은 macOS 가 Dynamic Type 을 무시해서 못 닫는다
// (AccessibilityTests.macOS는_DynamicType을_무시한다 참조).
//
// 참조 이미지는 __Snapshots__/ 에 커밋한다. 처음 실행하면 기록하며 실패하고,
// 두 번째부터 비교한다.
import SnapshotTesting
import SwiftUI
import Testing

@testable import ComponentAPI

@MainActor
struct SnapshotTests {
    // MARK: - 허용 오차
    //
    // 참조 이미지는 기록한 기계의 폰트 래스터라이저에 묶인다. CI runner 는
    // OS·Xcode 가 달라 픽셀이 미세하게 어긋나고, 완전 일치를 요구하면 6건 전부
    // 실패한다(실측). 그렇다고 오차를 크게 잡으면 회귀를 놓치므로,
    // **토큰 변경은 여전히 잡히는 선**을 찾아야 한다.
    static let precision: Float = 0.99
    static let perceptualPrecision: Float = 0.97

    // MARK: - 렌더 헬퍼

    private func host(_ view: some View, width: CGFloat, height: CGFloat,
                      background: Color = Color(0x141310)) -> NSView {
        let host = NSHostingView(rootView: view.padding(16).background(background))
        host.frame = CGRect(x: 0, y: 0, width: width, height: height)
        host.layoutSubtreeIfNeeded()
        return host
    }

    private static let palettes: [(String, ButtonPalette)] = [
        ("primary", .primary), ("assistive", .assistive), ("error", .error),
        ("white", .white), ("warning", .warning),
    ]
    private static let sizes: [(String, ButtonMetrics)] = [
        ("small", .small), ("medium", .medium), ("large", .large), ("xlarge", .xlarge),
    ]

    /// 팔레트 × 치수 전 조합을 한 장에 렌더한다.
    /// 조합마다 파일을 만들면 20장이 되고, 리뷰에서 아무도 안 본다.
    private func grid(styling: some DSButtonStyling) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Self.sizes, id: \.0) { sizeName, metrics in
                HStack(spacing: 10) {
                    ForEach(Self.palettes, id: \.0) { _, palette in
                        DSButton(sizeName, action: {})
                            .dsButtonColor(palette)
                            .dsButtonSize(metrics)
                    }
                }
            }
        }
        .dsButtonStyling(styling)
    }

    // MARK: - 조합 커버리지

    @Test
    func solid_전조합() {
        assertSnapshot(
            of: host(grid(styling: SolidButtonStyling()), width: 720, height: 320),
            as: .image(precision: Self.precision, perceptualPrecision: Self.perceptualPrecision),
            named: "solid"
        )
    }

    @Test
    func outlined_전조합() {
        assertSnapshot(
            of: host(grid(styling: OutlinedButtonStyling()), width: 720, height: 320),
            as: .image(precision: Self.precision, perceptualPrecision: Self.perceptualPrecision),
            named: "outlined"
        )
    }

    /// Phase 0 에서 원본을 고치지 않고 추가한 외형. 스냅샷도 추가만으로 붙는다.
    @Test
    func ghost_전조합() {
        assertSnapshot(
            of: host(grid(styling: GhostButtonStyling()), width: 720, height: 320),
            as: .image(precision: Self.precision, perceptualPrecision: Self.perceptualPrecision),
            named: "ghost"
        )
    }

    // MARK: - 테마 (§6-A)

    /// 테마 한 벌의 전 역할 × 치수를 렌더한다.
    /// 역할 이름은 그대로고 값만 테마가 정한다 — 그게 Semantic 층이 하는 일이다.
    private func themeGrid(_ theme: ButtonTheme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Self.sizes, id: \.0) { sizeName, metrics in
                HStack(spacing: 10) {
                    ForEach(ButtonRole.allCases, id: \.self) { role in
                        DSButton(sizeName, action: {})
                            .dsButtonRole(role, in: theme)
                            .dsButtonSize(metrics)
                    }
                }
            }
        }
        .dsButtonStyling(SolidButtonStyling())
    }

    /// 스킴을 바꾸면 렌더가 실제로 달라지는지 두 장으로 고정한다.
    /// 한 장만 두면 "라이트에서 안 보이는 버튼"이 회귀로 잡히지 않는다.
    @Test(arguments: [ButtonTheme.dark, ButtonTheme.light])
    func 테마_전조합(theme: ButtonTheme) {
        assertSnapshot(
            of: host(themeGrid(theme), width: 720, height: 240, background: theme.surface),
            as: .image(precision: Self.precision, perceptualPrecision: Self.perceptualPrecision),
            named: "theme-\(theme.name)"
        )
    }

    // MARK: - 상태

    /// 아이콘 전용·비활성·슬롯 조합. 축이 아니라 구조가 달라지는 것들.
    @Test
    func 상태_모음() {
        let view = VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                DSButton("기본", action: {})
                DSButton("비활성", action: {}).disabled(true)
                DSButton(icon: Image(systemName: "xmark"), action: {})
            }
            DSButton(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("슬롯 — 아이콘 + 텍스트")
                }
            }
        }
        .dsButtonSize(.medium)

        assertSnapshot(of: host(view, width: 420, height: 160), as: .image(precision: Self.precision, perceptualPrecision: Self.perceptualPrecision), named: "states")
    }

    // MARK: - 회귀 검출이 실제로 되는가

    /// 스냅샷의 존재 이유는 "토큰을 바꾸면 알아챈다"다.
    /// 그게 실제로 되는지 확인한다 — 같은 뷰를 팔레트만 바꿔 렌더하면 **다른 이미지**여야 한다.
    ///
    /// 이 테스트는 참조 이미지를 쓰지 않는다. 렌더 결과를 직접 비교한다.
    @Test
    func 토큰이_바뀌면_렌더가_달라진다() throws {
        func png(_ palette: ButtonPalette) throws -> Data {
            let view = DSButton("확인", action: {}).dsButtonColor(palette)
            let nsView = host(view, width: 200, height: 80)
            let rep = try #require(nsView.bitmapImageRepForCachingDisplay(in: nsView.bounds))
            nsView.cacheDisplay(in: nsView.bounds, to: rep)
            return try #require(rep.representation(using: .png, properties: [:]))
        }

        let a = try png(.primary)
        let b = try png(.error)
        let aAgain = try png(.primary)

        #expect(a != b, "팔레트를 바꿨는데 렌더가 같다 — 스냅샷이 회귀를 못 잡는다는 뜻")
        #expect(a == aAgain, "같은 입력인데 렌더가 다르다 — 스냅샷이 불안정하다는 뜻")
    }
}
