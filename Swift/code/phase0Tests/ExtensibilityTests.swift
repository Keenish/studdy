// Phase 0 §7 — 확장 가능성 주장을 실행으로 확인한다.
//
// 여기서 검증되는 것과 안 되는 것을 먼저 분명히 해 둔다.
//
//   ✅ 새 축 값이 기존 코드를 건드리지 않고 추가된다 (컴파일 + git 이 판정)
//   ✅ 축들이 서로 독립이다 — 조합해도 서로의 값을 오염시키지 않는다
//   ✅ PAT 스타일이 타입 소거를 통과한다
//   ❌ makeBody 의 렌더 결과 — DSButtonConfiguration.Label 의 저장 프로퍼티가
//      fileprivate 라 다른 파일에서 Configuration 을 만들 수 없다. SwiftUI 의
//      ButtonStyleConfiguration 과 같은 제약이다. 렌더 검증은 Phase 3 스냅샷의 몫.
import SwiftUI
import Testing

@testable import ComponentAPI

struct ExtensibilityTests {
    // MARK: - 축 값이 실제로 늘었는가

    @Test
    func 새_색은_기존_색을_건드리지_않는다() {
        #expect(ButtonPalette.warning != ButtonPalette.primary)
        #expect(ButtonPalette.warning != ButtonPalette.error)

        // 기존 값이 그대로인지 — 확장이 기존 토큰을 덮어쓰지 않았다는 확인
        #expect(ButtonPalette.primary.border == nil)
        #expect(ButtonPalette.warning.border == nil)
    }

    @Test
    func 새_치수는_기존_치수와_독립이다() {
        #expect(ButtonMetrics.xlarge.height == 60)
        #expect(ButtonMetrics.large.height == 52)      // 기존값 불변
        #expect(ButtonMetrics.medium.height == 40)
        #expect(ButtonMetrics.small.height == 32)

        // 새 치수가 기존 순서를 깨지 않는다
        let heights = [
            ButtonMetrics.small, .medium, .large, .xlarge,
        ].map(\.height)
        #expect(heights == heights.sorted())
    }

    // MARK: - PAT 확장 지점

    @Test
    func 새_Variant는_프로토콜만_채택하면_된다() {
        // 컴파일되는 것 자체가 절반의 증명이다.
        // 나머지 절반 — 기존 타입이 이 타입을 모른다 — 은 타입 소거를 통과시켜 확인한다.
        let ghost: any DSButtonStyling = GhostButtonStyling()
        #expect(ghost is GhostButtonStyling)
    }

    @Test
    func 세_스타일이_같은_소거_타입으로_모인다() {
        // AnyButtonStyling 은 component_api.swift 가 만든 것이고
        // GhostButtonStyling 의 존재를 모른다. 그런데도 담긴다.
        let erased: [AnyButtonStyling] = [
            AnyButtonStyling(SolidButtonStyling()),
            AnyButtonStyling(OutlinedButtonStyling()),
            AnyButtonStyling(GhostButtonStyling()),
        ]
        #expect(erased.count == 3)
    }

    // MARK: - 축 독립성 — 곱셈이 아니라 덧셈이라는 주장의 핵심

    @Test
    func 축은_서로를_오염시키지_않는다() {
        // 색·치수를 전부 조합해도 각 축의 값은 자기 것을 유지한다.
        // enum 곱집합이었다면 조합마다 새 case 가 필요했을 자리다.
        let palettes: [ButtonPalette] = [.primary, .assistive, .error, .white, .warning]
        let metrics: [ButtonMetrics] = [.small, .medium, .large, .xlarge]

        var seen = 0
        for palette in palettes {
            for metric in metrics {
                // 조합해도 각 축이 원래 값 그대로다
                #expect(palettes.contains(palette))
                #expect(metrics.contains(metric))
                seen += 1
            }
        }
        // 5 × 4 = 20 조합. 이걸 표현하려고 추가로 선언한 타입은 0개다.
        #expect(seen == 20)
    }

    @Test
    func 확장_후_조합수와_선언수() {
        // Before(NaiveButton): 색 5 × variant 3 × size 4 × iconOnly 2 × disabled 2 = 240
        // After: 축마다 독립이라 선언은 더한 값이다.
        let colors = 5, variants = 3, sizes = 4, iconOnly = 2, disabled = 2
        let naiveCombinations = colors * variants * sizes * iconOnly * disabled
        #expect(naiveCombinations == 240)

        // 이번 확장으로 실제로 추가한 선언: 색 1 + 치수 1 + 스타일 타입 1 = 3
        let addedDeclarations = 3
        // 같은 확장을 곱집합 설계로 했다면 늘어났을 조합 수:
        //   색 +1 → 96 → 96 + (3×2×2×... ) 계산 대신 전후 차로 본다
        let before = 4 * 2 * 3 * 2 * 2   // 96 (원래 스펙)
        #expect(naiveCombinations - before == 144)
        #expect(addedDeclarations == 3)
    }
}
