// Phase 3 §6-A — 테마(라이트/다크) 스위칭을 붙인다.
//
// 규칙은 component_api_extensions.swift 와 같다:
//   **component_api.swift 를 한 줄도 고치지 않는다.** 고쳤는지는 git 이 판정한다.
//
// 여기서 확인하려는 것은 "테마가 축을 하나 더 늘리는가"다.
// 늘리지 않는 게 정답이고, 그러려면 스킴이 **팔레트 값을 고르는 층**에서 흡수돼야 한다.
// 컴포넌트는 `ButtonPalette` 하나만 알고 스킴을 모른 채로 남는다.
import SwiftUI

// ── 스킴별 팔레트 묶음.
//    개별 팔레트가 아니라 '한 벌'이 스킴의 단위다. 하나씩 고르게 두면
//    다크 배경에 라이트 버튼이 섞이는 조합이 타입으로 표현 가능해진다.
struct ButtonTheme: Sendable {
    let name: String
    /// 이 테마가 전제하는 배경. 대비비는 항상 이 위에서 계산된다.
    let surface: Color

    let primary: ButtonPalette
    let assistive: ButtonPalette
    let error: ButtonPalette
    let white: ButtonPalette
    let warning: ButtonPalette

    var all: [(String, ButtonPalette)] {
        [("primary", primary), ("assistive", assistive), ("error", error),
         ("white", white), ("warning", warning)]
    }
}

extension ButtonTheme {
    /// 기존 팔레트가 그대로 다크 테마가 된다 — 값을 옮겨 적지 않고 참조한다.
    /// 여기서 값을 복사하면 두 사본이 어긋난다.
    static let dark = ButtonTheme(
        name: "dark",
        surface: Color(0x141310),
        primary: .primary,
        // 기본 `.assistive` 는 그대로 쓸 수 없었다 — surface 대비 1.293 으로
        // §1.4.11 기준(3.0)에 한참 못 미친다. 테마 전용 값이 필요하다.
        assistive: ButtonPalette(background: Color(0x6B6961), foreground: Color(0xF7F7F5), border: nil),
        error: .error,
        white: .white,
        warning: .warning
    )

    /// 라이트는 중성색을 뒤집고 **강조색은 따로 정한다.**
    /// 밝은 배경 위에서 brand-200·error-400 은 대비가 무너진다
    /// (DesignSystem/code/phase3/token_audit.swift 의 [4] 참조).
    static let light = ButtonTheme(
        name: "light",
        surface: Color(0xF7F7F5),
        primary:   ButtonPalette(background: Color(0x4B3A8C), foreground: Color(0xF7F7F5), border: nil),
        assistive: ButtonPalette(background: Color(0x8A8880), foreground: Color(0x141310), border: nil),
        error:     ButtonPalette(background: Color(0xA33322), foreground: Color(0xF7F7F5), border: nil),
        white:     ButtonPalette(background: Color(0x141310), foreground: Color(0xF7F7F5), border: nil),
        warning:   ButtonPalette(background: Color(0x8A5A00), foreground: Color(0xF7F7F5), border: nil)
    )

    static func resolve(_ scheme: ColorScheme) -> ButtonTheme {
        scheme == .dark ? .dark : .light
    }
}

// ── 환경에 테마를 얹는다. 컴포넌트는 여전히 `ButtonPalette` 만 읽는다.
extension EnvironmentValues {
    @Entry var dsButtonTheme: ButtonTheme = .dark
}

extension View {
    func dsButtonTheme(_ theme: ButtonTheme) -> some View {
        environment(\.dsButtonTheme, theme)
            .environment(\.dsButtonPalette, theme.primary)
    }

    /// 시스템 스킴을 따라간다. 호출부가 스킴을 모르고 쓰는 경로.
    func dsButtonThemeFollowingSystem() -> some View {
        modifier(SystemThemeModifier())
    }
}

private struct SystemThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.dsButtonTheme(.resolve(scheme))
    }
}

// ── 역할 이름으로 고르는 접근자.
//    호출부가 `.dsButtonColor(.primary)` 대신 `.dsButtonRole(.primary, in: theme)` 를 쓴다.
//    이름이 같아도 값은 테마가 정한다 — Semantic 층이 하는 일과 같다.
enum ButtonRole: String, CaseIterable, Sendable {
    case primary, assistive, error, white, warning

    func palette(in theme: ButtonTheme) -> ButtonPalette {
        switch self {
        case .primary: return theme.primary
        case .assistive: return theme.assistive
        case .error: return theme.error
        case .white: return theme.white
        case .warning: return theme.warning
        }
    }
}

extension View {
    func dsButtonRole(_ role: ButtonRole, in theme: ButtonTheme) -> some View {
        dsButtonColor(role.palette(in: theme))
    }
}

// ── §6-A 에서 드러난 구멍을 메운다.
//
// `foregroundContrastRatio` 는 팔레트 **안쪽**(글자 vs 버튼 배경)만 잰다.
// 그래서 다크용 팔레트를 라이트 테마에 그대로 꽂아도 그 값은 그대로 통과한다 —
// 버튼 내부는 읽히는데 **버튼이 화면 배경과 구분되지 않는** 상태가 남는다.
//
// WCAG 2.1 §1.4.11(Non-text Contrast)이 요구하는 것이 이쪽이고, 기준은 3.0 이다.
extension ButtonPalette {
    /// 버튼 배경과 화면 배경(surface) 사이의 대비비.
    func surfaceContrastRatio(on surface: Color) -> Double? {
        guard let b = Self.components(of: background),
              let s = Self.components(of: surface)
        else { return nil }
        return WCAG.contrastRatio(
            WCAG.relativeLuminance(red: b.0, green: b.1, blue: b.2),
            WCAG.relativeLuminance(red: s.0, green: s.1, blue: s.2)
        )
    }
}

extension WCAG {
    /// WCAG 2.1 AA — 텍스트가 아닌 UI 컴포넌트의 경계 대비.
    static let minimumNonText: Double = 3.0
}
