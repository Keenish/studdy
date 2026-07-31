// Phase 3 §4 — 접근성 감사를 "찾기만" 에서 "닫는다" 로.
//
// 감사(§4)는 두 가지를 찾고 끝났다.
//   1. 대비비 10개 중 2개 미달  → 실제 디자인 시스템 쪽이라 여기서 못 고친다.
//      대신 **내 팔레트에 같은 검사를 상시로 건다** — 일회성 손계산을 회귀 가드로.
//   2. Dynamic Type 0건        → 내 컴포넌트에서 실제로 통과시킨다.
//
// 대상은 Phase 0 §7 에서 내가 설계한 ComponentAPI 다.
import SwiftUI
import Testing

@testable import ComponentAPI

@MainActor
struct AccessibilityTests {
    // MARK: - 대비비

    /// 팔레트 이름과 실제로 쓰이는 폰트 크기.
    /// 크기가 필요한 이유: WCAG AA 기준이 큰 글씨에서 4.5 → 3.0 으로 내려간다.
    static let palettes: [(String, ButtonPalette, CGFloat)] = [
        ("primary", .primary, ButtonMetrics.medium.fontSize),
        ("assistive", .assistive, ButtonMetrics.medium.fontSize),
        ("error", .error, ButtonMetrics.medium.fontSize),
        ("white", .white, ButtonMetrics.medium.fontSize),
        ("warning", .warning, ButtonMetrics.medium.fontSize),
    ]

    @Test
    func 모든_팔레트가_WCAG_AA를_통과한다() {
        for (name, palette, fontSize) in Self.palettes {
            guard let ratio = palette.foregroundContrastRatio else {
                Issue.record("\(name): 대비비를 계산할 수 없다 (색 공간 변환 실패)")
                continue
            }
            let minimum = WCAG.minimumAA(fontSize: fontSize)
            #expect(
                ratio >= minimum,
                "\(name): 대비비 \(String(format: "%.3f", ratio)) < 기준 \(minimum)"
            )
        }
    }

    /// `token_audit.swift` 의 `button solid primary` 와 같은 값이 나오는지 대조한다.
    /// 서로 다른 두 구현이 같은 수를 내야 둘 다 믿을 수 있다 — 감사 스크립트도 검증 대상이다.
    @Test
    func 감사_스크립트와_같은_값을_낸다() throws {
        let ratio = try #require(ButtonPalette.primary.foregroundContrastRatio)
        // token_audit.swift 출력: button solid primary 8.766
        #expect(abs(ratio - 8.766) < 0.001, "실제 \(String(format: "%.3f", ratio))")
    }

    @Test
    func 큰_글씨는_기준이_낮다() {
        #expect(WCAG.minimumAA(fontSize: 16) == 4.5)
        #expect(WCAG.minimumAA(fontSize: 18) == 3.0)
        #expect(WCAG.minimumAA(fontSize: 14, isBold: true) == 3.0)
        #expect(WCAG.minimumAA(fontSize: 14, isBold: false) == 4.5)
    }

    // MARK: - Dynamic Type

    /// 주어진 외형·글자 크기에서 버튼이 실제로 차지하는 높이를 잰다.
    private func measuredHeight(
        styling: some DSButtonStyling,
        dynamicTypeSize: DynamicTypeSize
    ) -> CGFloat {
        let view = DSButton("확인", action: {})
            .dsButtonStyling(styling)
            .dsButtonSize(.medium)
            .environment(\.dynamicTypeSize, dynamicTypeSize)

        let host = NSHostingView(rootView: view)
        host.layoutSubtreeIfNeeded()
        return host.fittingSize.height
    }

    /// 감사가 지적한 결함 — 고정 크기 외형은 글자 크기를 키워도 그대로다.
    /// 이 테스트는 **버그가 아직 거기 있다는 것**을 고정한다.
    @Test
    func 고정_외형은_글자_크기를_따라가지_않는다() {
        let base = measuredHeight(styling: SolidButtonStyling(), dynamicTypeSize: .large)
        let big = measuredHeight(styling: SolidButtonStyling(), dynamicTypeSize: .accessibility3)

        #expect(base == big, "고정 외형인데 높이가 달라졌다 — \(base) vs \(big)")
        #expect(base == ButtonMetrics.medium.height)
    }

    /// **macOS 는 Dynamic Type 을 무시한다.** 아래 스케일 테스트를 끈 이유가 이것이다.
    ///
    /// 측정으로 확인했다 — 평범한 `Text` 의 높이가 xSmall 부터 accessibility5 까지
    /// 전부 16.0 이고, `@ScaledMetric` 도 배율이 1.0 에서 안 움직인다.
    /// 즉 이 플랫폼에서는 고친 코드와 안 고친 코드를 구별할 방법이 없다.
    @Test
    func macOS는_DynamicType을_무시한다() {
        let sizes: [DynamicTypeSize] = [.xSmall, .large, .xxxLarge, .accessibility1, .accessibility5]
        let heights = sizes.map {
            measuredHeight(styling: DynamicTypeButtonStyling(), dynamicTypeSize: $0)
        }

        // 전부 같다 = 플랫폼이 무시한다
        #expect(Set(heights).count == 1, "높이가 갈렸다: \(heights) — 이 단정이 깨지면 좋은 소식이다")
    }

    /// 고친 외형이 기본 크기에서 원래와 같은 치수를 낸다 (회귀 방지).
    /// 스케일 동작은 검증하지 못하지만, **망가뜨리지 않았다**는 건 확인된다.
    @Test
    func DynamicType_외형은_기본_크기에서_고정_외형과_같다() {
        let fixed = measuredHeight(styling: SolidButtonStyling(), dynamicTypeSize: .large)
        let scaled = measuredHeight(styling: DynamicTypeButtonStyling(), dynamicTypeSize: .large)

        #expect(fixed == scaled)
        #expect(scaled == ButtonMetrics.medium.height)
    }

    /// 고친 쪽이 실제로 글자 크기를 따라가는지 — **이 환경에서는 검증할 수 없다.**
    ///
    /// macOS 에 Dynamic Type 이 없어서(`macOS는_DynamicType을_무시한다` 참조)
    /// 이 단정은 플랫폼 한계로 항상 실패한다. iOS 시뮬레이터에서 돌려야 의미가 있는데,
    /// 이 패키지는 `xcodebuild` iOS 목적지로 스킴이 잡히지 않았다.
    ///
    /// 끄되 **지우지는 않는다** — 열린 항목이 보이게 남긴다.
    @Test(.disabled("macOS는 Dynamic Type을 지원하지 않는다 — iOS 시뮬레이터에서 실행해야 유효"))
    func DynamicType_외형은_글자_크기를_따라간다() {
        let base = measuredHeight(styling: DynamicTypeButtonStyling(), dynamicTypeSize: .large)
        let big = measuredHeight(styling: DynamicTypeButtonStyling(), dynamicTypeSize: .accessibility3)

        #expect(big > base, "접근성 크기에서 높이가 안 커졌다 — \(base) → \(big)")
        let growth = big / base
        #expect(growth < 4.0, "배율 \(growth) 는 과하다")
    }
}
