// Phase 3 §4 — 접근성 감사를 "찾기만" 에서 "닫는다" 로.
//
// 감사(§4)가 찾은 것을 상시 검사로 바꾼다.
//   1. 대비비  → 일회성 계산을 회귀 가드로. 토큰이 바뀌면 계산도 따라 바뀐다.
//   2. Dynamic Type → 내 컴포넌트에서 실제로 통과시킨다.
//   3. 테마    → **두 스킴 전부** 검사한다. 한 쪽만 재면 나머지 절반은 검사되지 않는다.
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

    /// §6-A — 테마를 추가하면 접근성 검사도 같이 늘어나야 한다.
    /// 다크만 통과시키고 라이트를 안 재면 사용자 절반이 검사 밖에 있다.
    @Test(arguments: [ButtonTheme.dark, ButtonTheme.light])
    func 두_스킴_모두_WCAG_AA를_통과한다(theme: ButtonTheme) {
        let minimum = WCAG.minimumAA(fontSize: ButtonMetrics.medium.fontSize)
        for (role, palette) in theme.all {
            guard let ratio = palette.foregroundContrastRatio else {
                Issue.record("\(theme.name)/\(role): 대비비를 계산할 수 없다")
                continue
            }
            #expect(
                ratio >= minimum,
                "\(theme.name)/\(role): 대비비 \(String(format: "%.3f", ratio)) < 기준 \(minimum)"
            )
        }
    }

    /// **§6-A 에서 드러난 구멍.** 위 테스트는 팔레트 안쪽(글자 vs 버튼 배경)만 잰다.
    /// 다크용 팔레트를 라이트 테마에 그대로 꽂아도 그 값은 통과한다 —
    /// 버튼 내부는 읽히는데 버튼이 화면 배경과 구분되지 않는 상태가 남는다.
    /// WCAG 2.1 §1.4.11 이 요구하는 것은 이쪽이고 기준은 3.0 이다.
    @Test(arguments: [ButtonTheme.dark, ButtonTheme.light])
    func 버튼이_배경과_구분된다(theme: ButtonTheme) {
        for (role, palette) in theme.all {
            guard let ratio = palette.surfaceContrastRatio(on: theme.surface) else {
                Issue.record("\(theme.name)/\(role): 대비비를 계산할 수 없다")
                continue
            }
            #expect(
                ratio >= WCAG.minimumNonText,
                "\(theme.name)/\(role): surface 대비 \(String(format: "%.3f", ratio)) < 기준 \(WCAG.minimumNonText)"
            )
        }
    }

    /// 라이트 테마가 다크 값을 그대로 재사용하지 않았는지 본다.
    /// 중성색은 뒤집기로 되지만 강조색은 스킴 전용 값이 필요하다 — 그걸 잊으면
    /// 위 테스트는 통과하는데(계산은 되니까) 실제로는 대비가 무너진 채 남는다.
    @Test
    func 라이트_테마가_다크_강조색을_재사용하지_않는다() {
        #expect(ButtonTheme.light.primary.background != ButtonTheme.dark.primary.background)
        #expect(ButtonTheme.light.error.background != ButtonTheme.dark.error.background)
        #expect(ButtonTheme.light.surface != ButtonTheme.dark.surface)
    }

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
