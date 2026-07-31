// 통과 기준 실습: Button 스펙(96조합)을 제네릭 + PAT로 재설계
// 검증: swiftc -typecheck component_api.swift
import SwiftUI

// ═══════════════════════════════════════════════════════
// ❌ Before — 설정(configuration) 일변도. 축이 곱해진다.
// ═══════════════════════════════════════════════════════
struct NaiveButton: View {
    enum Variant { case solid, outlined }
    enum ColorRole { case primary, assistive, error, white }
    enum Size { case large, medium, small }

    let title: String
    var variant: Variant = .solid
    var color: ColorRole = .primary
    var size: Size = .medium
    var iconOnly: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    // 2 × 4 × 3 × 2 × 2 = 96 조합을 이 body 하나가 전부 분기해야 한다
    var body: some View {
        Button(title, action: action)
            .disabled(disabled)
    }
}

// ═══════════════════════════════════════════════════════
// ✅ After — 축을 직교 분해하고, 축마다 확장 지점을 따로 둔다
// ═══════════════════════════════════════════════════════

// ── 축 1: 치수 = 값 타입 토큰 (enum 아님 → 추가가 곱셈이 아니다)
struct ButtonMetrics: Equatable, Sendable {
    let height: CGFloat
    let horizontalPadding: CGFloat
    let iconSize: CGFloat
    let fontSize: CGFloat

    // 흔한 디자인 시스템의 Button 사이즈 스펙을 본떠 정한 값
    static let large  = ButtonMetrics(height: 52, horizontalPadding: 24, iconSize: 20, fontSize: 16)
    static let medium = ButtonMetrics(height: 40, horizontalPadding: 20, iconSize: 18, fontSize: 14)
    static let small  = ButtonMetrics(height: 32, horizontalPadding: 12, iconSize: 16, fontSize: 12)
}

// ── 축 2: 색 = 값 타입 토큰 세트
struct ButtonPalette: Equatable, Sendable {
    let background: Color
    let foreground: Color
    let border: Color?

    // 예제 팔레트 — 실습용으로 직접 정했다
    static let primary   = ButtonPalette(background: Color(0xB9A7F5), foreground: Color(0x141310), border: nil)
    static let assistive = ButtonPalette(background: Color(0x2B2A26), foreground: Color(0xB0AEA8), border: nil)
    static let error     = ButtonPalette(background: Color(0xF2705A), foreground: Color(0x141310), border: nil)
    static let white     = ButtonPalette(background: Color(0xF7F7F5), foreground: Color(0x141310), border: nil)
}

extension Color {
    init(_ hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8)  & 0xFF) / 255,
                  blue:  Double( hex        & 0xFF) / 255,
                  opacity: 1)
    }
}

// ── 축 3: 외형 = PAT 프로토콜 (Solid/Outlined는 '값'이 아니라 '타입'이 된다)
struct DSButtonConfiguration {
    /// 타입 소거를 이 한 지점에 격리한다.
    /// SwiftUI의 `ButtonStyleConfiguration.Label`과 같은 트릭.
    struct Label: View {
        fileprivate let content: AnyView
        var body: some View { content }
    }

    let label: Label
    let metrics: ButtonMetrics
    let palette: ButtonPalette
    let isPressed: Bool
    let isEnabled: Bool
    /// 외형이 아니라 레이아웃 축이라서 남긴 유일한 Bool
    let isIconOnly: Bool
}

protocol DSButtonStyling {
    associatedtype Body: View      // ← PAT. 각 스타일이 자기 뷰 타입을 고른다
    @ViewBuilder func makeBody(_ configuration: DSButtonConfiguration) -> Body
}

struct SolidButtonStyling: DSButtonStyling {
    func makeBody(_ c: DSButtonConfiguration) -> some View {
        c.label
            .font(.system(size: c.metrics.fontSize, weight: .medium))
            .foregroundStyle(c.palette.foreground)
            .frame(width: c.isIconOnly ? c.metrics.height : nil, height: c.metrics.height)
            .padding(.horizontal, c.isIconOnly ? 0 : c.metrics.horizontalPadding)
            .background(c.palette.background)
            .overlay(Color.black.opacity(c.isPressed ? 0.12 : 0))
            .clipShape(Capsule())
            .opacity(c.isEnabled ? 1 : 0.4)
    }
}

struct OutlinedButtonStyling: DSButtonStyling {
    func makeBody(_ c: DSButtonConfiguration) -> some View {
        c.label
            .font(.system(size: c.metrics.fontSize, weight: .medium))
            .foregroundStyle(c.palette.background)   // Outlined는 테두리색 = 텍스트색
            .frame(width: c.isIconOnly ? c.metrics.height : nil, height: c.metrics.height)
            .padding(.horizontal, c.isIconOnly ? 0 : c.metrics.horizontalPadding)
            .overlay(Capsule().strokeBorder(c.palette.background, lineWidth: 1))
            .overlay(Color.black.opacity(c.isPressed ? 0.12 : 0).clipShape(Capsule()))
            .opacity(c.isEnabled ? 1 : 0.4)
    }
}

/// PAT의 대가: 환경에 담으려면 타입 소거 어댑터가 필요하다.
/// 비용을 여기 한 군데로 몰아넣는다.
struct AnyButtonStyling: DSButtonStyling {
    private let _makeBody: (DSButtonConfiguration) -> AnyView
    init(_ styling: some DSButtonStyling) {
        _makeBody = { AnyView(styling.makeBody($0)) }
    }
    func makeBody(_ configuration: DSButtonConfiguration) -> AnyView {
        _makeBody(configuration)
    }
}

// ── 축 4: disabled = 컴포넌트 prop이 아니라 환경값 (표준 .disabled()를 그대로 쓴다)
extension EnvironmentValues {
    @Entry var dsButtonStyling: AnyButtonStyling = AnyButtonStyling(SolidButtonStyling())
    @Entry var dsButtonMetrics: ButtonMetrics = .medium
    @Entry var dsButtonPalette: ButtonPalette = .primary
}

extension View {
    func dsButtonStyling(_ styling: some DSButtonStyling) -> some View {
        environment(\.dsButtonStyling, AnyButtonStyling(styling))
    }
    func dsButtonSize(_ metrics: ButtonMetrics) -> some View {
        environment(\.dsButtonMetrics, metrics)
    }
    func dsButtonColor(_ palette: ButtonPalette) -> some View {
        environment(\.dsButtonPalette, palette)
    }
}

// ── 축 5: 콘텐츠 = 슬롯(@ViewBuilder 제네릭). iconOnly가 enum 값이 아니라 구조가 된다
struct DSButton<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dsButtonStyling) private var styling
    @Environment(\.dsButtonMetrics) private var metrics
    @Environment(\.dsButtonPalette) private var palette

    private let label: Label
    private let isIconOnly: Bool
    private let action: () -> Void

    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
        self.isIconOnly = false
    }

    fileprivate init(iconOnly label: Label, action: @escaping () -> Void) {
        self.action = action
        self.label = label
        self.isIconOnly = true
    }

    var body: some View {
        Button(action: action) { label }
            .buttonStyle(
                StyleBridge(styling: styling, metrics: metrics, palette: palette,
                            isEnabled: isEnabled, isIconOnly: isIconOnly)
            )
    }

    /// SwiftUI의 isPressed를 얻기 위한 최소 브리지
    private struct StyleBridge: ButtonStyle {
        let styling: AnyButtonStyling
        let metrics: ButtonMetrics
        let palette: ButtonPalette
        let isEnabled: Bool
        let isIconOnly: Bool

        func makeBody(configuration: Configuration) -> some View {
            styling.makeBody(
                DSButtonConfiguration(
                    label: .init(content: AnyView(configuration.label)),
                    metrics: metrics,
                    palette: palette,
                    isPressed: configuration.isPressed,
                    isEnabled: isEnabled,
                    isIconOnly: isIconOnly
                )
            )
        }
    }
}

// 조건부 확장 — Label이 Image일 때만 존재하는 이니셜라이저
extension DSButton where Label == Image {
    init(icon: Image, action: @escaping () -> Void) {
        self.init(iconOnly: icon, action: action)
    }
}

// 편의 확장 — Label이 Text일 때만
extension DSButton where Label == Text {
    init(_ title: String, action: @escaping () -> Void) {
        self.init(action: action) { Text(title) }
    }
}

// ═══════════════════════════════════════════════════════
// 사용부 — 축이 독립적으로 조합된다
// ═══════════════════════════════════════════════════════
struct UsageSample: View {
    var body: some View {
        VStack(spacing: 12) {
            // Solid Primary Large
            DSButton("다음") {}
                .dsButtonSize(.large)

            // Outlined Assistive Medium
            DSButton("취소") {}
                .dsButtonStyling(OutlinedButtonStyling())
                .dsButtonColor(.assistive)

            // Icon Only Medium Assistive
            DSButton(icon: Image(systemName: "xmark")) {}
                .dsButtonColor(.assistive)

            // Disabled — 표준 modifier 그대로
            DSButton("비활성") {}
                .disabled(true)

            // 슬롯 — 텍스트+아이콘 조합에 새 prop이 필요없다
            DSButton {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("AI 추천")
                }
            }
            .dsButtonSize(.small)

            // 트리 전체에 한 번 적용 — 자식 버튼이 모두 상속
            VStack {
                DSButton("확인") {}
                DSButton("삭제") {}
                    .dsButtonColor(.error)
            }
            .dsButtonSize(.large)
        }
    }
}
