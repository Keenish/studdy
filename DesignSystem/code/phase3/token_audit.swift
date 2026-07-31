// Phase 3 검증 — 토큰 3계층을 타입으로 강제하고, 팔레트 값으로 대비비를 감사한다.
// 실행: swift -swift-version 6 DesignSystem/code/phase3/token_audit.swift
//
// 색 값은 이 실습을 위해 직접 정한 예제 팔레트다.
import Foundation

// ═══════════════════════════════════════════════════════════
// 1. 3계층을 타입으로 나눈다
//    규칙: "Alias 토큰 우선 — Primitive 직접 참조 금지"
//    → 규칙을 문서가 아니라 접근 제어로 강제한다.
// ═══════════════════════════════════════════════════════════

struct RGB: Equatable {
    let r, g, b: Double

    init(hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }
}

/// 계층 1 — Primitive. 팔레트 원본. 모듈 밖으로 노출하지 않는다(여기서는 fileprivate).
///
/// **Primitive는 스킴에 따라 바뀌지 않는다.** "brand-200은 이 색"이라는 사실은
/// 라이트든 다크든 같다. 바뀌는 것은 어느 역할에 어느 원색을 쓰느냐(= Semantic)다.
fileprivate enum Primitive {
    static let brand200 = RGB(hex: 0xB9A7F5)
    static let brand600 = RGB(hex: 0x4B3A8C)
    static let neutral50 = RGB(hex: 0xF7F7F5)
    static let neutral100 = RGB(hex: 0xEDEDE9)
    static let neutral200 = RGB(hex: 0xDCDBD5)
    static let neutral300 = RGB(hex: 0xB0AEA8)
    static let neutral400 = RGB(hex: 0x8A8880)
    static let neutral500 = RGB(hex: 0x615F58)
    static let neutral600 = RGB(hex: 0x2B2A26)
    static let neutral700 = RGB(hex: 0x1F1E1B)
    static let neutral800 = RGB(hex: 0x141310)
    static let error400 = RGB(hex: 0xF2705A)
    static let error700 = RGB(hex: 0xA33322)
    static let white = RGB(hex: 0xFFFFFF)
}

/// 계층 2 — Semantic. 역할 이름. 화면 코드가 쓰는 최소 단위.
///
/// **테마 스위칭이 사는 층이 여기다.** 같은 역할 이름이 스킴마다 다른 Primitive를
/// 가리킨다. 화면 코드는 `Semantic.textPrimary`만 알면 되고 스킴을 모른다.
struct SemanticPalette {
    let textPrimary: RGB
    let textSecondary: RGB
    let textTertiary: RGB
    let textError: RGB

    let surface: RGB
    let surfaceContainerLow: RGB
    let surfaceContainerHigh: RGB
    let surfaceToast: RGB

    static let dark = SemanticPalette(
        textPrimary: Primitive.neutral50,
        textSecondary: Primitive.neutral300,
        textTertiary: Primitive.neutral400,
        textError: Primitive.error400,
        surface: Primitive.neutral800,
        surfaceContainerLow: Primitive.neutral700,
        surfaceContainerHigh: Primitive.neutral600,
        surfaceToast: Primitive.neutral500
    )

    /// 라이트는 밝기 램프를 뒤집는다. 다만 **뒤집기만으로는 안 되는 항목**이 있다 —
    /// error는 error400을 그대로 쓰면 밝은 배경에서 대비가 무너진다([4] 참조).
    static let light = SemanticPalette(
        textPrimary: Primitive.neutral800,
        textSecondary: Primitive.neutral600,
        textTertiary: Primitive.neutral500,
        textError: Primitive.error700,
        surface: Primitive.neutral50,
        surfaceContainerLow: Primitive.neutral100,
        surfaceContainerHigh: Primitive.neutral200,
        surfaceToast: Primitive.neutral600
    )
}

/// 계층 3 — Component. 특정 컴포넌트 전용. Semantic 또는 Primitive를 가리킨다.
struct ComponentPalette {
    let buttonBgPrimary: RGB
    let buttonTextPrimary: RGB
    let chipBgDefault: RGB
    let chipTextDefault: RGB
    let chipBgActive: RGB
    let chipTextActive: RGB

    /// Component 토큰도 스킴을 따라간다. Semantic을 경유하는 것은 자동으로 따라오고,
    /// Primitive를 직결한 것(`chip-bg-active`)은 **스킴마다 따로 정해야 한다.**
    /// 계층을 건너뛴 대가가 여기서 나타난다.
    static func of(_ s: SemanticPalette, isDark: Bool) -> ComponentPalette {
        ComponentPalette(
            buttonBgPrimary: isDark ? Primitive.brand200 : Primitive.brand600,
            buttonTextPrimary: isDark ? Primitive.neutral800 : Primitive.neutral50,
            chipBgDefault: s.surfaceContainerLow,
            chipTextDefault: s.textSecondary,
            chipBgActive: isDark ? Primitive.neutral50 : Primitive.neutral800,
            chipTextActive: isDark ? Primitive.neutral800 : Primitive.neutral50
        )
    }
}

// ═══════════════════════════════════════════════════════════
// 2. WCAG 대비비 계산
// ═══════════════════════════════════════════════════════════

func relativeLuminance(_ c: RGB) -> Double {
    func channel(_ v: Double) -> Double {
        v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
}

func contrastRatio(_ a: RGB, _ b: RGB) -> Double {
    let la = relativeLuminance(a), lb = relativeLuminance(b)
    let (hi, lo) = la > lb ? (la, lb) : (lb, la)
    return (hi + 0.05) / (lo + 0.05)
}

/// WCAG 2.x 최소 기준
enum Requirement {
    /// 본문 텍스트 (18pt 미만, 또는 14pt 미만 Bold)
    case normalText
    /// 큰 텍스트 (18pt 이상, 또는 14pt 이상 Bold)
    case largeText
    /// UI 컴포넌트 경계·아이콘
    case nonText

    var minimum: Double {
        switch self {
        case .normalText: return 4.5
        case .largeText, .nonText: return 3.0
        }
    }
}

struct Pair {
    let label: String
    let foreground: RGB
    let background: RGB
    /// 이 조합이 실제로 쓰이는 폰트 크기
    let usedAtPt: Double
    let requirement: Requirement
}

/// 같은 조합 목록을 두 스킴에 각각 적용한다.
/// 조합 정의를 한 번만 쓰고 스킴을 바꿔 끼우는 것이 요점이다 — 목록이 갈라지면
/// 한쪽만 검사하는 상태가 조용히 생긴다.
func pairs(for s: SemanticPalette, _ c: ComponentPalette) -> [Pair] {
    [
        Pair(label: "text-primary on surface",         foreground: s.textPrimary,   background: s.surface,              usedAtPt: 16, requirement: .normalText),
        Pair(label: "text-secondary on surface",       foreground: s.textSecondary, background: s.surface,              usedAtPt: 14, requirement: .normalText),
        Pair(label: "text-tertiary on surface",        foreground: s.textTertiary,  background: s.surface,              usedAtPt: 13, requirement: .normalText),
        Pair(label: "text-tertiary on container-low",  foreground: s.textTertiary,  background: s.surfaceContainerLow,  usedAtPt: 13, requirement: .normalText),
        Pair(label: "text-tertiary on container-high", foreground: s.textTertiary,  background: s.surfaceContainerHigh, usedAtPt: 13, requirement: .normalText),
        Pair(label: "text-error on surface",           foreground: s.textError,     background: s.surface,              usedAtPt: 13, requirement: .normalText),
        Pair(label: "toast text on surface-toast",     foreground: Primitive.white, background: s.surfaceToast,         usedAtPt: 14, requirement: .normalText),
        Pair(label: "button solid primary",            foreground: c.buttonTextPrimary, background: c.buttonBgPrimary,  usedAtPt: 16, requirement: .normalText),
        Pair(label: "chip default",                    foreground: c.chipTextDefault,   background: c.chipBgDefault,    usedAtPt: 14, requirement: .normalText),
        Pair(label: "chip active",                     foreground: c.chipTextActive,    background: c.chipBgActive,     usedAtPt: 14, requirement: .normalText),
    ]
}

@discardableResult
func auditContrast(_ name: String, _ s: SemanticPalette, _ c: ComponentPalette) -> Int {
    print("    [\(name)]")
    var failures = 0
    for p in pairs(for: s, c) {
        let ratio = contrastRatio(p.foreground, p.background)
        let ok = ratio >= p.requirement.minimum
        if !ok { failures += 1 }
        let ratioText = String(format: "%.3f", ratio)
        let padded = p.label.padding(toLength: 31, withPad: " ", startingAt: 0)
        print("      \(padded) \(ratioText.padding(toLength: 7, withPad: " ", startingAt: 0))"
              + "\(String(format: "%.1f", p.requirement.minimum))    "
              + "\(ok ? "통과" : "미달")   \(Int(p.usedAtPt))pt")
    }
    print("      → \(pairs(for: s, c).count)개 중 \(failures)개 미달")
    return failures
}

func auditBothSchemes() {
    print("[1] WCAG 대비비 감사 — 두 스킴 전부")
    print("    조합                            비율    기준   판정   쓰이는 크기")
    let dark = SemanticPalette.dark
    let light = SemanticPalette.light
    let df = auditContrast("dark", dark, ComponentPalette.of(dark, isDark: true))
    let lf = auditContrast("light", light, ComponentPalette.of(light, isDark: false))
    print("    ⇒ dark \(df)개 미달 · light \(lf)개 미달")
    print("    ⇒ 한 스킴만 재면 나머지 절반은 검사되지 않은 채 출시된다")
}

// ═══════════════════════════════════════════════════════════
// 3. 계층 참조 무결성 — Component가 Primitive를 직접 가리키는지 센다
//    규칙은 "화면 코드"에 대한 것이고, Component 토큰이 Primitive를
//    가리키는 건 허용된다. 다만 얼마나 되는지는 알아야 한다.
// ═══════════════════════════════════════════════════════════

func auditLayering() {
    print("[2] Component 토큰의 참조 계층")

    let s = SemanticPalette.dark
    let c = ComponentPalette.of(s, isDark: true)

    let semanticValues: [RGB] = [
        s.textPrimary, s.textSecondary, s.textTertiary, s.textError,
        s.surface, s.surfaceContainerLow, s.surfaceContainerHigh, s.surfaceToast,
    ]

    let componentTokens: [(String, RGB)] = [
        ("button-bg-primary", c.buttonBgPrimary),
        ("button-text-primary", c.buttonTextPrimary),
        ("chip-bg-default", c.chipBgDefault),
        ("chip-text-default", c.chipTextDefault),
        ("chip-bg-active", c.chipBgActive),
        ("chip-text-active", c.chipTextActive),
    ]

    var viaSemantic: [String] = []
    var viaPrimitive: [String] = []
    for (name, value) in componentTokens {
        if semanticValues.contains(value) { viaSemantic.append(name) }
        else { viaPrimitive.append(name) }
    }
    print("    Semantic 경유: \(viaSemantic.count)개 \(viaSemantic)")
    print("    Primitive 직결: \(viaPrimitive.count)개 \(viaPrimitive)")
    print("    → 값이 같으면 구분이 불가능하다. 토큰 그래프는 값이 아니라 '참조'로 표현해야 검사할 수 있다")
}

// ═══════════════════════════════════════════════════════════
// 4. 스킴을 뒤집기만 하면 되는가 — 안 되는 항목을 찾는다
// ═══════════════════════════════════════════════════════════

func auditNaiveInversion() {
    print("[4] '램프만 뒤집으면 된다'가 성립하지 않는 항목")

    let light = SemanticPalette.light
    // 다크에서 쓰던 강조색을 라이트에 그대로 재사용하면?
    let cases: [(String, RGB, RGB)] = [
        ("error400 on light surface  (다크 값 재사용)", Primitive.error400, light.surface),
        ("error700 on light surface  (스킴 전용 토큰)", Primitive.error700, light.surface),
        ("brand200 배경 + neutral50 글자 (재사용)", Primitive.neutral50, Primitive.brand200),
        ("brand600 배경 + neutral50 글자 (스킴 전용)", Primitive.neutral50, Primitive.brand600),
    ]
    for (label, fg, bg) in cases {
        let r = contrastRatio(fg, bg)
        let ok = r >= 4.5
        print("    \(label.padding(toLength: 42, withPad: " ", startingAt: 0)) \(String(format: "%.3f", r))  \(ok ? "통과" : "미달")")
    }
    print("    → 중성색은 뒤집기로 되지만 **강조색(brand·error)은 스킴 전용 값이 필요하다**")
    print("      밝기 램프의 양 끝은 대칭이 아니다. 색상이 있는 토큰일수록 더 그렇다")
}

// ═══════════════════════════════════════════════════════════
// 5. 조합 폭발 — 파라미터 조합 수와 해석 지점 수는 다르다
// ═══════════════════════════════════════════════════════════

func countCombinations() {
    print("[3] Button 조합 수와 해석 지점")

    let style = 2, role = 4, size = 3, iconOnly = 2, disabled = 2, loading = 2
    let naive = style * role * size * iconOnly * disabled * loading
    print("    파라미터를 전부 축으로 세면: \(style)×\(role)×\(size)×\(iconOnly)×\(disabled)×\(loading) = \(naive)")

    // 해석을 Palette.resolve / Metrics 두 곳에 모았을 때의 분기 수
    let paletteBranches = style * role      // Palette.resolve의 switch
    let paletteDisabled = style             // enabled=false 경로
    let metricsBranches = size              // Metrics.init의 switch
    let contentBranches = 2                 // Content enum (text / iconOnly)
    let environmentAxes = 3                 // isEnabled · isLoading · isFullWidth (modifier)
    let resolved = paletteBranches + paletteDisabled + metricsBranches + contentBranches
    print("    해석 지점의 분기: \(paletteBranches)(색) + \(paletteDisabled)(비활성) + \(metricsBranches)(치수) + \(contentBranches)(콘텐츠) = \(resolved)")
    print("    환경으로 뺀 축: \(environmentAxes)개 (조합에서 제외됨)")
    print("    → \(naive)개 조합을 \(resolved)개 분기로 다룬다. 축을 없앤 게 아니라 해석을 두 곳에 모았다")
    print("    ※ 스킴(dark/light)은 여기 곱해지지 않는다. Semantic 층이 흡수하므로")
    print("      컴포넌트 분기 수는 그대로다 — 테마를 Semantic에 두는 실익이 이것이다")
}

auditBothSchemes(); print()
auditLayering(); print()
countCombinations(); print()
auditNaiveInversion()
