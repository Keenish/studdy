// Phase 3 검증 — 토큰 3계층을 타입으로 강제하고, 팔레트 값으로 대비비를 감사한다.
// 실행: swift -swift-version 6 DesignSystem/code/phase3/token_audit.swift
//
// 색 값은 이 실습을 위해 직접 정한 예제 팔레트다.
import Foundation

// ═══════════════════════════════════════════════════════════
// 1. 3계층을 타입으로 나눈다
//    규칙(DESIGN.md): "Alias 토큰 우선 — Primitive 직접 참조 금지"
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
fileprivate enum Primitive {
    static let brand200 = RGB(hex: 0xB9A7F5)
    static let neutral50 = RGB(hex: 0xF7F7F5)
    static let neutral300 = RGB(hex: 0xB0AEA8)
    static let neutral400 = RGB(hex: 0x8A8880)
    static let neutral500 = RGB(hex: 0x615F58)
    static let neutral600 = RGB(hex: 0x2B2A26)
    static let neutral700 = RGB(hex: 0x1F1E1B)
    static let neutral800 = RGB(hex: 0x141310)
    static let error400 = RGB(hex: 0xF2705A)
    static let white = RGB(hex: 0xFFFFFF)
}

/// 계층 2 — Semantic. 역할 이름. 화면 코드가 쓰는 최소 단위.
enum Semantic {
    static let textPrimary = Primitive.neutral50
    static let textSecondary = Primitive.neutral300
    static let textTertiary = Primitive.neutral400
    static let textError = Primitive.error400

    static let surface = Primitive.neutral800
    static let surfaceContainerLow = Primitive.neutral700
    static let surfaceContainerHigh = Primitive.neutral600
    static let surfaceToast = Primitive.neutral500
}

/// 계층 3 — Component. 특정 컴포넌트 전용. Semantic 또는 Primitive를 가리킨다.
enum ComponentToken {
    static let buttonBgPrimary = Primitive.brand200
    static let buttonTextPrimary = Primitive.neutral800

    static let chipBgDefault = Semantic.surfaceContainerLow
    static let chipTextDefault = Semantic.textSecondary
    static let chipBgActive = Primitive.neutral50
    static let chipTextActive = Primitive.neutral800
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
    /// 이 조합이 실제로 쓰이는 폰트 크기(DESIGN.md 타이포 스케일 기준)
    let usedAtPt: Double
    let requirement: Requirement
}

let pairs: [Pair] = [
    Pair(label: "text-primary on surface",        foreground: Semantic.textPrimary,   background: Semantic.surface,             usedAtPt: 16, requirement: .normalText),
    Pair(label: "text-secondary on surface",      foreground: Semantic.textSecondary, background: Semantic.surface,             usedAtPt: 14, requirement: .normalText),
    Pair(label: "text-tertiary on surface",       foreground: Semantic.textTertiary,  background: Semantic.surface,             usedAtPt: 13, requirement: .normalText),
    Pair(label: "text-tertiary on container-low", foreground: Semantic.textTertiary,  background: Semantic.surfaceContainerLow, usedAtPt: 13, requirement: .normalText),
    Pair(label: "text-tertiary on container-high",foreground: Semantic.textTertiary,  background: Semantic.surfaceContainerHigh,usedAtPt: 13, requirement: .normalText),
    Pair(label: "text-error on surface",          foreground: Semantic.textError,     background: Semantic.surface,             usedAtPt: 13, requirement: .normalText),
    Pair(label: "toast text on surface-toast",    foreground: Primitive.white,        background: Semantic.surfaceToast,        usedAtPt: 14, requirement: .normalText),
    Pair(label: "button solid primary",           foreground: ComponentToken.buttonTextPrimary, background: ComponentToken.buttonBgPrimary, usedAtPt: 16, requirement: .normalText),
    Pair(label: "chip default",                   foreground: ComponentToken.chipTextDefault,   background: ComponentToken.chipBgDefault,   usedAtPt: 14, requirement: .normalText),
    Pair(label: "chip active",                    foreground: ComponentToken.chipTextActive,    background: ComponentToken.chipBgActive,    usedAtPt: 14, requirement: .normalText),
]

func auditContrast() {
    print("[1] WCAG 대비비 감사 (예제 팔레트)")
    print("    조합                            비율    기준   판정   쓰이는 크기")
    var failures = 0
    for p in pairs {
        let ratio = contrastRatio(p.foreground, p.background)
        let ok = ratio >= p.requirement.minimum
        if !ok { failures += 1 }
        let ratioText = String(format: "%.3f", ratio)
        let padded = p.label.padding(toLength: 31, withPad: " ", startingAt: 0)
        print("    \(padded) \(ratioText.padding(toLength: 7, withPad: " ", startingAt: 0))"
              + "\(String(format: "%.1f", p.requirement.minimum))    "
              + "\(ok ? "통과" : "미달")   \(Int(p.usedAtPt))pt")
    }
    print("    → \(pairs.count)개 중 \(failures)개 미달")
}

// ═══════════════════════════════════════════════════════════
// 3. 계층 참조 무결성 — Component가 Primitive를 직접 가리키는지 센다
//    DESIGN.md 규칙 1은 "화면 코드"에 대한 것이고,
//    Component 토큰이 Primitive를 가리키는 건 허용된다. 다만 얼마나 되는지는 알아야 한다.
// ═══════════════════════════════════════════════════════════

func auditLayering() {
    print("[2] Component 토큰의 참조 계층")

    let semanticValues: [RGB] = [
        Semantic.textPrimary, Semantic.textSecondary, Semantic.textTertiary, Semantic.textError,
        Semantic.surface, Semantic.surfaceContainerLow, Semantic.surfaceContainerHigh, Semantic.surfaceToast,
    ]

    let componentTokens: [(String, RGB)] = [
        ("button-bg-primary", ComponentToken.buttonBgPrimary),
        ("button-text-primary", ComponentToken.buttonTextPrimary),
        ("chip-bg-default", ComponentToken.chipBgDefault),
        ("chip-text-default", ComponentToken.chipTextDefault),
        ("chip-bg-active", ComponentToken.chipBgActive),
        ("chip-text-active", ComponentToken.chipTextActive),
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
// 4. 조합 폭발 — 파라미터 조합 수와 해석 지점 수는 다르다
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
}

auditContrast(); print()
auditLayering(); print()
countCombinations()
