// Phase 3 §4 — Dynamic Type 을 실제로 통과시킨다.
//
// 감사 결과: 실제 디자인 시스템은 `UIFontMetrics|ScaledMetric|relativeTo|dynamicTypeSize`
// 검색 결과가 0건이었다. 문서는 고치는 방향만 적고 **컴파일하지 못했다** —
// 제안한 코드가 `UIFontMetrics`(UIKit)라 macOS 에서 타입체크가 안 됐기 때문이다.
//
// 여기서는 SwiftUI 의 `@ScaledMetric` 을 쓴다. 크로스 플랫폼이라 실제로 컴파일된다.
//
// 그리고 또 하나 — **component_api.swift 를 고치지 않는다.** 새 스타일 타입 하나를
// 더할 뿐이다. Phase 0 §7 이 주장한 확장성을 여기서 한 번 더 쓰는 셈이다.
import SwiftUI

/// 치수를 Dynamic Type 배율에 따라 같이 키우는 외형.
///
/// 감사가 지적한 함정을 피한다 —
/// "Button 높이가 52pt 고정이면 폰트만 커져도 텍스트가 잘린다."
/// 그래서 폰트만이 아니라 **높이·패딩도 같은 배율로** 곱한다.
struct DynamicTypeButtonStyling: DSButtonStyling {
    func makeBody(_ configuration: DSButtonConfiguration) -> some View {
        ScaledBody(configuration: configuration)
    }

    /// `@ScaledMetric` 은 View 안에서만 살아 있으므로 별도 뷰로 뺀다.
    private struct ScaledBody: View {
        let configuration: DSButtonConfiguration

        /// 현재 Dynamic Type 크기의 배율. 기본 크기에서 1.0.
        @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

        var body: some View {
            let m = configuration.metrics
            let p = configuration.palette

            configuration.label
                .font(.system(size: m.fontSize * scale, weight: .medium))
                .foregroundStyle(p.foreground)
                .frame(
                    width: configuration.isIconOnly ? m.height * scale : nil,
                    height: m.height * scale
                )
                .padding(.horizontal, configuration.isIconOnly ? 0 : m.horizontalPadding * scale)
                .background(p.background)
                .overlay(Color.black.opacity(configuration.isPressed ? 0.12 : 0))
                .clipShape(Capsule())
                .opacity(configuration.isEnabled ? 1 : 0.4)
        }
    }
}

// ═══════════════════════════════════════════════════════
// 대비비 — 감사를 재현 가능한 계산으로
// ═══════════════════════════════════════════════════════

/// WCAG 2.1 상대 휘도와 대비비.
///
/// Phase 3 §4 의 감사는 `DESIGN.md` 의 hex 를 손으로 계산한 **일회성 표**였다.
/// 여기서는 팔레트에 실제로 들어 있는 `Color` 값에서 성분을 꺼내 계산한다 —
/// 토큰이 바뀌면 계산도 따라 바뀌므로 회귀 가드가 된다.
enum WCAG {
    /// sRGB 성분(0~1)에서 상대 휘도.
    static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// 두 휘도 사이의 대비비. 항상 1 이상.
    static func contrastRatio(_ l1: Double, _ l2: Double) -> Double {
        let hi = max(l1, l2)
        let lo = min(l1, l2)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// WCAG 2.1 AA 기준.
    /// 큰 글씨(18pt 이상, 또는 굵은 14pt 이상)는 3.0, 나머지는 4.5.
    static func minimumAA(fontSize: CGFloat, isBold: Bool = false) -> Double {
        let isLarge = fontSize >= 18 || (isBold && fontSize >= 14)
        return isLarge ? 3.0 : 4.5
    }
}

extension ButtonPalette {
    /// 전경/배경 대비비. 계산할 수 없으면 nil.
    ///
    /// `Color` 에서 성분을 꺼내려면 플랫폼 색 타입을 거쳐야 한다.
    /// 색 공간 변환이 실패할 수 있어 옵셔널이다.
    var foregroundContrastRatio: Double? {
        guard let f = Self.components(of: foreground),
              let b = Self.components(of: background)
        else { return nil }

        return WCAG.contrastRatio(
            WCAG.relativeLuminance(red: f.0, green: f.1, blue: f.2),
            WCAG.relativeLuminance(red: b.0, green: b.1, blue: b.2)
        )
    }

    #if canImport(AppKit)
    private static func components(of color: Color) -> (Double, Double, Double)? {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        return (Double(srgb.redComponent), Double(srgb.greenComponent), Double(srgb.blueComponent))
    }
    #elseif canImport(UIKit)
    private static func components(of color: Color) -> (Double, Double, Double)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (Double(r), Double(g), Double(b))
    }
    #endif
}
