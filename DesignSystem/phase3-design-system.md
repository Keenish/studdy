# Phase 3 — 디자인 시스템 · 공통 컴포넌트 설계

[study_list.md](../study_list.md) §6의 정리.

- **통과 기준**: variant enum 폭발 없이 확장 가능한 컴포넌트 API를 설계·문서화할 수 있다 → [§6](#6-통과-기준-자기-평가)
- **코드**: [`DesignSystem/code/phase3/`](code/phase3/) — 리포 루트에서 `swift -swift-version 6 DesignSystem/code/phase3/token_audit.swift`
- **근거**: 아래 수치는 전부 이 저장소의 코드를 돌려 나온 출력이다. 팔레트는 실습용으로 직접 정한 예제 값이다

선행: [Phase 0 §7](../Swift/phase0-language-core.md#7-통과-기준-실습--button-96조합-해체)에서 Button 조합 폭발을 PAT로 해체했다. 이 문서는 그 설계에 토큰·접근성·테스트를 붙인다.

---

## 이 Phase에서 답할 것

- 토큰 계층은 왜 3개인가. 2개나 4개면 무엇이 달라지는가 ([§1](#1-토큰-3계층))
- 조합 폭발에 답이 하나가 아니다 ([§3](#3-조합-폭발--답이-두-개다))
- 품질(접근성·모션·테스트)은 무엇으로 담보하는가. 실측하면 구멍이 보인다 ([§4](#4-접근성--실측-감사) · [모션](#모션-토큰))
- 테마가 축을 하나 더 늘리는가. 어느 층에서 흡수해야 하는가 ([테마](#테마--스킴은-semantic-층이-흡수한다))

---

## 1. 토큰 3계층

### 왜 나누나

한 계층이면 화면 코드가 `#b9a7f5`를 직접 쓴다. 브랜드 색이 바뀌면 전수 검색이다. 그래서 이름을 붙인다. 문제는 **이름을 몇 겹으로 붙일지**다.

- **Primitive** — 팔레트 원본. `brand-200 = #b9a7f5`. "무슨 색인가"
- **Semantic** — 역할. `text-primary`, `surface-container-low`. "어디에 쓰는가"
- **Component** — 특정 컴포넌트 전용. `button-bg-primary`, `chip-text-active`. "이 부품의 어디인가"

계층이 2개(Primitive + Semantic)면 컴포넌트가 늘 때 semantic이 오염된다. `text-primary`가 버튼 텍스트도 겸하면, 버튼만 바꾸려는 순간 다른 곳이 같이 바뀐다. 반대로 4계층 이상은 추적 비용이 이득을 넘는다.

**계층별 개수에는 자연스러운 모양이 있다.** Component가 가장 많고(컴포넌트 수만큼 늘어난다), Semantic이 가장 적다(역할 이름은 늘어날 이유가 적다). Semantic이 빠르게 느는 프로젝트는 역할 정의가 흔들리고 있다는 신호로 읽을 수 있다.

### 계층을 살리는 것은 규칙이다

계층을 만들어놓고 화면에서 Primitive를 직접 쓰면 계층이 없는 것과 같다. 문서에 "Primitive 직접 참조 금지"라고 적는 것만으로는 안 지켜지므로 **접근 제어로 강제**한다.

```swift
/// 계층 1 — Primitive. 팔레트 원본. 모듈 밖으로 노출하지 않는다.
fileprivate enum Primitive {
    static let brand200 = RGB(hex: 0xB9A7F5)
    ...
}

/// 계층 2 — Semantic. 화면 코드가 쓰는 최소 단위.
enum Semantic {
    static let textPrimary = Primitive.neutral50
    static let surface = Primitive.neutral800
}
```

실제 모듈에서는 `internal`(모듈 내부)과 `public`(외부)의 경계가 이 일을 한다. Primitive를 `internal`로 두면 Feature 모듈에서 아예 보이지 않는다. [Phase 2-B §2](../Architecture/phase2-clean-layered.md#2-경계는-선언만으로-지켜지지-않는다)의 레이어 가드와 같은 발상이다.

### 계층 검사의 함정 — 값으로는 참조를 알 수 없다

Component 토큰이 Semantic을 경유하는지 Primitive를 직결하는지 세어보려 했다.

```
[2] Component 토큰의 참조 계층
    Semantic 경유: 5개 ["button-text-primary", "chip-bg-default", ...]
    Primitive 직결: 1개 ["button-bg-primary"]
```

이 결과는 **틀렸다.** `button-text-primary`는 `Primitive.neutral800`을 직접 가리키는데, 그 값이 `Semantic.surface`와 같아서 "Semantic 경유"로 분류됐다.

- 토큰 그래프는 **값이 아니라 참조**로 표현해야 검사할 수 있다. `#141310`이라는 값은 어디서 왔는지 말해주지 않는다
- 그래서 토큰 파일이 `{"value": "{primitives.color.neutral.800}"}` 같은 **참조 표현**을 쓰는 데 이유가 있다. 값으로 평탄화(flatten)하는 순간 계층 정보가 사라진다
- 코드 생성 파이프라인이 참조를 유지하지 않고 값만 뽑아내면, 그 후로는 계층 규칙을 기계적으로 검사할 수 없다

이 오류는 컴파일도 실행도 통과했다. **출력을 읽고 예상과 다름을 알아차린 것이 유일한 탐지 경로였다** ([§4-B 사례 6](../AI/phase-parallel-ai-verification.md#6--컴파일러가-잡아주지-못한-유일한-사례)).

### backward-compat alias의 비용

토큰을 리네임할 때 구 이름을 alias로 남기는 것은 흔한 선택이다.

```
--sem-text-primary   (Backward-compat alias: --text-primary)
```

- 토큰 리네임은 코드 전수 수정이라, 구 이름을 남겨 이행 기간을 버는 것이 실무적이다
- 대가: 같은 색에 두 이름이 존재하는 기간이 생긴다. 새 코드가 어느 쪽을 쓰는지 강제하지 않으면 alias가 영구화된다
- 한 토큰에 구 이름이 서넛씩 붙어 있으면 리네임이 여러 번 있었고 매번 지우지 않았다는 뜻이다
- [§5 리팩토링](../Refactoring/)에서 본 "중간 상태는 임시가 아니라 수년간 유지될 상태"가 토큰 레벨에서 나타난 것이다. 만료 없는 alias는 부채다 ([버전 정책](#버전-정책과-breaking-change))

---

## 2. 웹 토큰을 iOS로 옮길 때

### 스키마가 W3C 표준이 아닐 수 있다

study_list §6은 [W3C DTCG](https://www.designtokens.org/tr/drafts/format/)를 §6-A의 기준으로 삼으라고 적어뒀다. 실무 파일을 열어보면 다른 경우가 많다.

```json
// DTCG        : { "$value": "#b9a7f5", "$type": "color" }
// Tokens Studio: { "value":  "#b9a7f5", "type":  "color" }
```

- Figma 플러그인이 내보내는 포맷이 그대로 SoT가 되기 쉽다. 표준을 배우는 것과 별개로, **내 프로젝트가 실제로 어떤 포맷을 쓰는지 확인**해야 파이프라인을 짤 수 있다
- DTCG는 2025-10-28에 첫 안정 버전이 나왔으니, 기존 프로젝트가 아직 옮기지 않은 상태가 정상이다

### 파이프라인 — 생성물을 커밋할 것인가

```
Figma → 토큰 익스포트 → tokens.json → 생성 스크립트 → *+generated.swift
```

- **생성물을 git에 커밋하는 선택**: 빌드에 파이썬·네트워크가 필요 없고, diff로 토큰 변경이 리뷰된다
- 대가: 생성물과 원본이 어긋날 수 있다. 스크립트를 돌리지 않으면 조용히 낡는다. **CI에서 "생성 후 diff 없음"을 검사하지 않으면 신뢰할 수 없다**
- 색·폰트·치수를 다 생성하면 파일 하나가 천 줄을 쉽게 넘는다. 사람이 읽는 코드가 아니라는 전제로 다뤄야 한다

### 번역이 필요한 값이 있다

웹 토큰을 그대로 옮길 수 없는 경우가 있다. `radius-full`이 CSS에서는 `9999px`인데, iOS에서 9999를 그대로 쓰면 안 된다.

```swift
/// `.full`(센티널 9999)은 고정 숫자가 아니라 높이 기준 pill(Capsule)로 처리.
func cornerRadius(_ token: RadiusToken) -> some View {
    let shape: AnyShape = token.value >= 1000
        ? AnyShape(Capsule())
        : AnyShape(RoundedRectangle(cornerRadius: token.value, style: .continuous))
    return clipShape(shape)
}
```

- CSS의 `border-radius: 9999px`는 "충분히 큰 값"이라는 관용구다. 의미는 "pill"이고 숫자가 아니다
- iOS에서 같은 의미를 내려면 `Capsule()`이라는 **다른 타입**이어야 한다. 값 변환이 아니라 개념 번역이다
- 토큰 파이프라인을 짤 때 이런 센티널이 몇 개 있는지 먼저 찾아야 한다. 자동 변환으로 처리되지 않는다

`[중]` 이 절은 서술이다. 실제 토큰 파이프라인을 이 저장소에서 돌려보지는 않았다.

### 토큰 접근을 타입으로 좁힌다

```swift
public extension CGFloat {
    static func spacing(_ token: SpacingToken) -> CGFloat { token.value }
    static func radius(_ token: RadiusToken) -> CGFloat { token.value }
}

// 사용부
.padding(.horizontal, .spacing(.s24))
Capsule().strokeBorder(border, lineWidth: .stroke(.s1))
```

- 리터럴 `24`와 `.spacing(.s24)`는 컴파일 결과가 같지만, 후자는 **어디서 왔는지 코드가 말해준다**
- `CGFloat` 확장에 정적 팩토리를 두면 호출부가 짧아진다. `SpacingToken.s24.value`보다 `.spacing(.s24)`가 읽힌다
- 대가: 자동완성 목록이 커지고, 토큰이 아닌 값을 쓰는 걸 막지는 못한다. 강제가 아니라 유도다

---

## 테마 — 스킴은 Semantic 층이 흡수한다

study_list §6-A의 "다크모드 / 테마 스위칭". 답할 것은 하나다. **테마가 축을 하나 더 늘리는가.**

늘리지 않는 것이 정답이고, 그러려면 스킴이 **어느 층에서 흡수되는지**를 정해야 한다.

### 어느 층이 바뀌나

| 계층 | 스킴에 따라 바뀌나 | 이유 |
|---|---|---|
| **Primitive** | ✗ | "brand-200은 이 색"이라는 사실은 라이트든 다크든 같다 |
| **Semantic** | ✅ | **여기가 테마 스위칭이 사는 층이다.** 같은 역할 이름이 다른 Primitive를 가리킨다 |
| **Component** | 따라온다 | Semantic을 경유하면 자동으로. **Primitive를 직결한 것만 따로 정해야 한다** |

세 번째 줄이 §1에서 센 "Primitive 직결"의 대가가 드러나는 자리다. 계층을 건너뛴 토큰은 테마가 늘 때마다 손으로 늘려야 한다.

그리고 이게 조합 폭발과 만나지 않는 이유이기도 하다.

```
※ 스킴(dark/light)은 여기 곱해지지 않는다. Semantic 층이 흡수하므로
  컴포넌트 분기 수는 그대로다 — 테마를 Semantic에 두는 실익이 이것이다
```

컴포넌트가 `Semantic.textPrimary`만 알고 스킴을 모르면, 스킴이 둘이든 넷이든 **분기 수는 15로 고정**이다([§3 수치](#수치)). 반대로 컴포넌트가 `if isDark`를 들고 있으면 그 순간 축이 하나 늘어난다.

### "램프만 뒤집으면 된다"가 틀리는 지점

라이트 테마를 만들 때 가장 먼저 드는 생각은 밝기 순서를 뒤집는 것이다. 중성색은 그걸로 된다. **강조색은 안 된다.**

```
[4] '램프만 뒤집으면 된다'가 성립하지 않는 항목
    error400 on light surface  (다크 값 재사용)      2.704  미달
    error700 on light surface  (스킴 전용 토큰)      6.411  통과
    brand200 배경 + neutral50 글자 (재사용)           1.976  미달
    brand600 배경 + neutral50 글자 (스킴 전용)         8.575  통과
```

- 밝기 램프의 양 끝은 **대칭이 아니다.** 흰 배경 위의 밝은 색은 어두운 배경 위의 어두운 색보다 훨씬 안 보인다
- 색상이 있는 토큰(brand·error)일수록 심하다. 채도가 휘도를 끌어올려서, 뒤집었을 때 대비가 두 배 넘게 벌어진다
- 그래서 강조색은 **스킴 전용 값**이 필요하다. `brand-200`과 `brand-600`이 따로 있는 팔레트를 보면 이 이유다

### 두 스킴을 다 재야 한다

감사를 두 스킴에 각각 돌린다. 조합 목록은 하나만 정의하고 팔레트를 갈아 끼운다 — 목록이 갈라지면 한쪽만 검사하는 상태가 조용히 생긴다.

```
⇒ dark 1개 미달 · light 0개 미달
⇒ 한 스킴만 재면 나머지 절반은 검사되지 않은 채 출시된다
```

같은 토큰 세트인데 결과가 다르다. **한 스킴에서 통과한 것이 다른 스킴에서 통과한다는 보장이 없다.**

### 내 컴포넌트에 붙였다 (2026-07-31)

[`component_api_theme.swift`](../Swift/code/phase0/component_api_theme.swift) — `ButtonTheme`가 팔레트 **한 벌**을 들고, 역할 이름(`ButtonRole`)으로 고른다.

```swift
DSButton("저장", action: save)
    .dsButtonRole(.primary, in: theme)     // 이름은 같고 값은 테마가 정한다
```

- 팔레트를 하나씩 고르게 두지 않고 **한 벌**을 단위로 삼았다. 개별로 고를 수 있으면 "다크 배경에 라이트 버튼"이 타입으로 표현 가능해진다
- `dsButtonThemeFollowingSystem()`으로 `@Environment(\.colorScheme)`을 따라가는 경로도 뒀다
- **`component_api.swift`는 또 한 줄도 안 고쳤다.** Phase 0 §7의 확장성 주장이 세 번째 요구(색 추가 → 접근성 수정 → 테마)에서도 성립했다

### 가드가 내 팔레트의 결함을 잡았다

테마를 붙이고 대비비 테스트를 두 스킴으로 늘렸더니 **기존 테스트는 전부 통과하는데 뭔가 이상했다.** 라이트 테마에 다크 값을 일부러 꽂아 보니 이렇게 갈렸다.

| 검사 | 다크 값을 라이트에 재사용했을 때 |
|---|---|
| 스냅샷 `테마_전조합` | ❌ 실패 |
| `라이트_테마가_다크_강조색을_재사용하지_않는다` | ❌ 실패 |
| **`두_스킴_모두_WCAG_AA를_통과한다`** | **✅ 통과** ← |

세 번째가 문제다. `foregroundContrastRatio`는 팔레트 **안쪽**(글자 vs 버튼 배경)만 잰다. 다크용 팔레트는 그 값이 8.766이라 어디에 놓든 통과한다. **버튼 내부는 읽히는데 버튼이 화면 배경과 구분되지 않는** 상태를 이 검사가 못 본다.

빠진 것은 WCAG 2.1 §1.4.11(Non-text Contrast)이고 기준은 3.0이다. 그 검사를 추가하자 **내가 쓴 팔레트가 바로 걸렸다.**

```
light/assistive: surface 대비 1.293 < 기준 3.0
dark/assistive:  surface 대비 1.293 < 기준 3.0
```

두 스킴 모두 assistive 버튼이 배경과 거의 구분되지 않았다. 글자는 13:1로 선명한데 **버튼의 경계가 안 보인다.**

**고치는 데서 또 하나 나왔다.** 두 기준이 서로를 밀어낸다.

| assistive 배경 | surface 대비 (≥3.0) | 글자 대비 (≥4.5) |
|---|---|---|
| `#2B2A26` (원래) | 1.293 ❌ | 13.392 ✅ |
| `#615F58` | 2.907 ❌ | 5.958 ✅ |
| **`#6B6961` (채택)** | **3.378 ✅** | **5.127 ✅** |
| `#7A776D` | 4.146 ✅ | 4.177 ❌ |

**창이 좁다.** 배경을 밝히면 surface와 구분되지만 흰 글자가 안 읽히고, 어둡게 하면 반대가 된다. "은은한 보조 버튼"은 두 기준을 동시에 만족하기 어렵다는 뜻이고, 실제 디자인 시스템이 보조 버튼에 **테두리**를 두르는 이유가 이것이다.

테두리로 풀지 않은 이유는 정직 때문이다. `ButtonPalette`에 `border` 필드가 있지만 **`SolidButtonStyling`이 그걸 렌더하지 않는다.** 렌더되지 않는 값으로 가드를 통과시키면 [사례 6](../AI/phase-parallel-ai-verification.md#6--컴파일러가-잡아주지-못한-유일한-사례)과 같은 "통과하는 미통과"가 된다. 그래서 값 자체를 고쳤다.

`[중]` 헬퍼 하나(`components(of:)`)는 file-private에서 열어야 했다. `component_api.swift`는 안 고쳤지만 **확장만으로 100% 되지는 않았다**는 것을 적어둔다.

### 스냅샷으로 두 스킴을 고정한다

```
swift test --filter SnapshotTests    # 6건 — 테마 2장 포함
```

`테마_전조합`이 dark·light 두 장을 따로 기록한다. 한 장만 두면 "라이트에서 안 보이는 버튼"이 회귀로 잡히지 않는다 — 위에서 실제로 그 상황을 만들어 확인했다.

---

## 3. 조합 폭발 — 답이 두 개다

### 문제 재확인

Button만의 문제가 아니다. 흔한 컴포넌트의 조합 수를 세어 보면:

- **Input**: 4 Types × 5 States = **20 variants**
- **Button**: Variant 2 × Color 4 × Size 3 × IconOnly 2 × Disable 2 × Loading 2 = **192**
- **Subscription 류**: 결제 상태처럼 축의 곱이 아니라 **열거된 조합**인 것도 있다. 축으로 분해되지 않는 경우가 존재한다

### 답 A — 확장 지점을 프로토콜로 연다

[Phase 0 §7](../Swift/phase0-language-core.md#7-통과-기준-실습--button-96조합-해체)에서 내가 설계한 방향이다.

- 외형을 PAT 프로토콜(`DSButtonStyling`)로 만들어 스타일을 **타입**으로 추가
- 색·치수는 값 토큰(`static let`)
- 콘텐츠는 제네릭 슬롯, iconOnly는 조건부 확장
- 상태는 환경값

얻는 것: 새 variant 추가가 기존 코드 수정 없이 된다(개방-폐쇄). 잃는 것: 타입 소거(`AnyView`) 비용과 간접 계층.

### 답 B — 축을 유지하고 해석을 집중한다

성숙한 디자인 시스템에서 흔히 보는 반대 선택이다.

```swift
public struct DSButton: View {
    public enum Style: Sendable, CaseIterable { case solid, outlined }
    public enum Role: Sendable, CaseIterable { case primary, assistive, error, white }
    public enum Size: Sendable, CaseIterable { case large, medium, small }

    public init(_ title: String, style: Style, role: Role, size: Size, action: @escaping () -> Void)
    public init(icon: Icon, style: Style, role: Role, size: Size, action: @escaping () -> Void)
}
```

enum 파라미터를 그대로 둔다. "조합 폭발"이라고 지적하는 바로 그 형태다. 그런데 **body에는 분기가 없다.**

```swift
public var body: some View {
    let palette = Palette.resolve(style: style, role: role, enabled: isEnabled)
    let metrics = Metrics(size)
    Button { ... } label: { Label(content: content, palette: palette, metrics: metrics) }
        .buttonStyle(Surface(metrics: metrics, palette: palette))
}
```

조합 해석이 **두 곳에 모여 있다**.

- `Palette.resolve(style:role:enabled:)` — 색 결정 전부. `switch style` 안에 `switch role`
- `Metrics(size)` — 치수 전부. 높이·패딩·gap·아이콘 크기·폰트를 한 `switch`에서
- 상태 축은 파라미터가 아니다. `.disabled()`(표준) + loading·fullWidth modifier + 환경값
- iconOnly는 `fileprivate enum Content { case text(...), iconOnly(...) }` + 별도 이니셜라이저

### 수치

```
[3] Button 조합 수와 해석 지점
    파라미터를 전부 축으로 세면: 2×4×3×2×2×2 = 192
    해석 지점의 분기: 8(색) + 2(비활성) + 3(치수) + 2(콘텐츠) = 15
    환경으로 뺀 축: 3개 (조합에서 제외됨)
```

192개 조합을 15개 분기로 다룬다. **축을 없앤 게 아니라 해석을 두 함수에 모았다.**

### 어느 쪽이 맞나

둘 다 맞고, 전제가 다르다.

| | A: 프로토콜 확장 | B: 축 유지 + 해석 집중 |
|---|---|---|
| 새 variant 추가 | 기존 코드 수정 없음 | `Palette.resolve`의 switch 수정 |
| 외부(앱 코드)에서 확장 | 가능 | 불가 — `Palette`·`Metrics`가 `private` |
| 타입 소거 비용 | `AnyView` 발생 | 없음 |
| 간접 계층 | 프로토콜 + 어댑터 | 없음 |
| 호출부 | modifier 체인 | 이니셜라이저 인자 |

**디자인이 SoT인 조직에서는 B의 전제가 더 그럴듯하다.**

- 앱 코드가 임의로 새 버튼 스타일을 만들 수 있으면, 그건 디자인 시스템을 우회하는 통로다. **확장 지점을 닫는 것이 기능**이다
- 새 variant는 디자이너가 추가할 때만 생긴다. 그때 `Palette.resolve`에 case를 추가하는 건 비용이 아니라 절차다
- `CaseIterable`을 붙여두는 이유도 여기 있다. 갤러리에서 전 조합을 자동 나열하려면 축이 열거 가능해야 한다

반대로 앱 레벨 컴포넌트나 오픈소스 라이브러리라면 A가 맞다. 소비자가 확장할 것을 전제하기 때문이다.

`[중]` B는 이 저장소에 구현하지 않았다. 널리 쓰이는 배치를 정리한 것이고, 수치는 위 파라미터 구성을 가정해 센 것이다.

### 두 답이 공유하는 것

- **상태 축은 환경으로 뺀다.** disabled·loading은 variant가 아니다. A도 B도 이걸 파라미터에서 제거했다. 축을 3개 줄이는 가장 값싼 수단이다
- **콘텐츠 구조는 별도 이니셜라이저로.** iconOnly를 `Bool`로 받으면 "텍스트도 있고 iconOnly도 true"인 무의미한 조합이 타입으로 표현된다. A는 조건부 확장, B는 `Content` enum + 별도 init으로 그걸 막았다
- **표면 처리는 `ButtonStyle`로.** 눌림 상태·배경·테두리를 `ButtonStyle` 구현으로 분리하면 `isPressed`를 공짜로 얻고 본체가 얇아진다

### 슬롯 패턴 — 통제를 내려놓는 지점

위에서 "콘텐츠는 슬롯"이라고 한 줄로 지나갔는데, 실은 **조합 폭발 문제의 절반이 여기 있다.** Nathan Curtis가 [Subcomponents](https://medium.com/eightshapes-llc/subcomponents-753ce9f6600a)에서 정리한 표현으로는 *"통제를 내려놓고 부품을 제공한다"*이다.

**슬롯이란**: 컴포넌트가 콘텐츠를 **값으로 받는** 대신 **뷰로 받는 것**. SwiftUI에서는 `@ViewBuilder` 파라미터다.

```swift
// 값으로 받기 — 컴포넌트가 콘텐츠 구조를 통제한다
DSButton(title: "저장", icon: .check, badge: 3, ...)

// 슬롯으로 받기 — 호출부가 통제한다
DSButton(action: save) { Label("저장", systemImage: "checkmark") }
```

[`Swift/code/phase0/component_api.swift:150`](../Swift/code/phase0/component_api.swift)의 답 A가 후자다.

```swift
struct DSButton<Label: View>: View {
    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label)
}
```

**왜 조합 폭발과 관계있나.** 콘텐츠를 값으로 받으면 콘텐츠의 변형이 전부 파라미터 축이 된다 — `title`, `icon`, `iconPosition`, `badge`, `subtitle`… 각각이 옵셔널이면 조합은 곱으로 늘고, 그중 다수는 무의미하다("텍스트 없이 subtitle만"). 슬롯으로 받으면 **그 축들이 전부 사라지고 타입 하나(`Label`)가 된다.**

**그리고 무의미한 조합을 타입으로 막을 수 있다.** 같은 파일의 조건부 확장이 그 예다.

```swift
extension DSButton where Label == Image { ... }   // iconOnly는 Label이 Image일 때만 존재
extension DSButton where Label == Text  { ... }   // 텍스트 편의 init
```

`iconOnly: Bool`로 받았다면 "텍스트가 있는데 iconOnly=true"가 타입 수준에서 표현 가능해진다. 슬롯 + 조건부 확장은 그 상태를 **컴파일되지 않게** 만든다.

**대가 — 슬롯은 확장 지점이고, 확장 지점은 우회로다.**

여기서 §3 본문의 결론과 정면으로 만난다. 디자인 시스템에서는 "앱 코드가 임의로 만들 수 있는 것"이 **결함**이다. 슬롯을 열면 호출부가 라벨 자리에 무엇이든 넣을 수 있다 — 잘못된 폰트, 토큰 밖의 색, 규격 밖의 아이콘 크기. 답 B가 콘텐츠를 `fileprivate enum`으로 닫는 이유가 이것이다.

**판단 기준** — 슬롯을 열지 닫을지는 취향이 아니라 **누가 SoT인가**로 갈린다.

| 조건 | 슬롯 | 이유 |
|---|---|---|
| 디자인이 SoT, 콘텐츠 형태가 스펙에 열거돼 있다 | **닫는다** (enum + 전용 init) | 스펙 밖 조합은 만들 수 없어야 한다 |
| 콘텐츠 형태가 무한하다 (카드 본문, 시트 내용, 리스트 행) | **연다** | 열거가 불가능하고, 열거하려 들면 파라미터가 폭발한다 |
| 컨테이너·레이아웃 역할 (Stack·Sheet·Section) | **연다** | 콘텐츠를 모르는 것이 이 컴포넌트의 정의다 |
| 앱 레벨 컴포넌트·오픈소스 라이브러리 | **연다** | 소비자 확장이 전제 |

즉 **컨테이너는 슬롯, 리프(leaf)는 닫힌 파라미터**가 기본값이 된다. Button은 리프다.

---

## 4. 접근성 — 실측 감사

문서에 "접근성 고려"라고 적는 것과 실제로 통과하는 것은 다르다. 계산할 수 있는 것부터 계산했다.

### 대비비 — 10개 중 1개 미달

`token_audit.swift`의 예제 팔레트로 WCAG 상대 휘도를 계산했다.

```
    조합                            비율    기준   판정   쓰이는 크기
    text-primary on surface         17.320 4.5    통과   16pt
    text-secondary on surface       8.374  4.5    통과   14pt
    text-tertiary on surface        5.232  4.5    통과   13pt
    text-tertiary on container-low  4.694  4.5    통과   13pt
    text-tertiary on container-high 4.045  4.5    미달   13pt
    text-error on surface           6.406  4.5    통과   13pt
    toast text on surface-toast     6.391  4.5    통과   14pt
    button solid primary            8.766  4.5    통과   16pt
    chip default                    7.514  4.5    통과   14pt
    chip active                     17.320 4.5    통과   14pt
    → 10개 중 1개 미달
```

읽어낼 것은 숫자 하나가 아니라 **패턴**이다.

- **미달은 항상 같은 자리에서 난다.** 보조 텍스트(`text-tertiary`)를 밝은 컨테이너 위에 올릴 때다. 본문·버튼처럼 대비가 큰 조합은 여유가 많다
- **경계선이 위험하다.** `container-low`에서 4.694는 통과지만, 컨테이너를 한 단계만 밝게 조정하면 바로 미달로 넘어간다. 소수점 한 자리로 반올림해 보고하면 이 위험이 안 보인다
- **작은 글씨일수록 기준이 높다.** 위 미달 조합은 전부 13pt다. 18pt 이상이면 기준이 3.0으로 내려간다 — 같은 색이라도 크기에 따라 판정이 갈린다

**감사는 찾는 것까지다.** 남의 디자인 시스템에서 미달을 찾았을 때 그것을 결함으로 확정하면 안 된다. 디자인 SoT가 따로 있고, WCAG는 가이드라인이며, 보조 텍스트라 대비를 낮춘 것이 의도된 수용일 수 있다. **수치는 확인됐으니 물어볼 근거가 된다**까지가 정확한 결론이다 ([§4-B §3의 "발견을 결함으로 단정하지 않는다"](../AI/phase-parallel-ai-verification.md#3-실제로-쓴-검증-루프)).

### 실제로 닫은 것 (2026-07-31)

감사가 지적한 항목을 [Phase 0 §7에서 설계한 컴포넌트](../Swift/phase0-language-core.md#7-통과-기준-실습--button-96조합-해체)에 적용했다. **찾는 데서 끝내지 않고 내 코드에서 닫는다.**

```
swift test --filter AccessibilityTests    # 7건 (1건은 플랫폼 한계로 비활성)
```

**대비비 — 일회성 계산을 회귀 가드로.** 위 표는 스크립트를 한 번 돌려 찍은 것이다. 이제 팔레트에 실제로 들어 있는 `Color` 값에서 성분을 꺼내 계산한다([`component_api_dynamic_type.swift`](../Swift/code/phase0/component_api_dynamic_type.swift)의 `WCAG`). 토큰이 바뀌면 계산도 따라 바뀐다.

| 팔레트 | 대비비 | 기준 4.5 |
|---|---|---|
| primary | 8.766 | 통과 |
| assistive | 6.475 | 통과 |
| error | 6.406 | 통과 |
| white | 17.320 | 통과 |
| warning *(Phase 0에서 추가)* | 8.763 | 통과 |

`primary`의 8.766이 **감사 스크립트의 `button solid primary 8.766`과 소수 셋째 자리까지 일치한다.** 서로 다른 두 구현이 같은 수를 냈다는 게 요점이다 — 감사 스크립트도 검증 대상이고([§1의 계층 검사 함정](#계층-검사의-함정--값으로는-참조를-알-수-없다)), 교차 확인이 그 검증이다. 테스트가 이 일치를 고정한다.

**Dynamic Type — 고쳤지만 검증은 못 했다.** `UIFontMetrics`는 UIKit이라 이 환경에서 컴파일되지 않는다. SwiftUI `@ScaledMetric`으로 다시 써서 **컴파일되는 `DynamicTypeButtonStyling`을 만들었다.** 흔한 함정("Button 높이가 52pt 고정이면 폰트만 커져도 텍스트가 잘린다")을 피하려고 폰트만이 아니라 높이·패딩도 같은 배율로 곱한다.

그런데 **동작을 확인할 수 없었다.** macOS에 Dynamic Type이 없다. 측정으로 확정했다:

```
Text("확인").font(.body) 의 높이
  xSmall: 16.0   large: 16.0   xxxLarge: 16.0
  accessibility1: 16.0   accessibility5: 16.0
@ScaledMetric(relativeTo: .body) var k = 100
  large: 100.0   accessibility5: 100.0
```

즉 이 플랫폼에서는 **고친 코드와 안 고친 코드를 구별할 방법이 없다.** 스케일 테스트는 지우지 않고 `.disabled("macOS는 Dynamic Type을 지원하지 않는다")`로 남겨 열린 항목이 보이게 했다. `xcodebuild`로 iOS 목적지를 잡아 보려 했으나 이 패키지에 스킴이 잡히지 않았다.

검증된 것은 여기까지다 — 고친 외형이 **기본 크기에서 기존과 같은 치수를 낸다**(망가뜨리지 않았다). 실제로 커지는지는 `[검증되지 않음]`.

또 하나 얻은 것: 이 수정도 **`component_api.swift`를 고치지 않고 새 타입 하나를 더해서** 했다. Phase 0 §7이 주장한 확장성이 접근성 수정이라는 실제 요구에서도 성립했다.

### 계산되지 않는 축

대비비는 계산되지만 나머지는 아니다. 체크리스트로만 남긴다.

- **VoiceOver** — 아이콘 전용 버튼에 라벨이 있는가. 선택 상태를 트레잇으로 알리는가. **시각 정보(빨간 점 등)를 문장으로 옮겼는가**가 특히 빠지기 쉽다
- **reduce motion** — 애니메이션이 있는 컴포넌트마다 `accessibilityReduceMotion` 분기가 있는가. shimmer·로딩 점처럼 무한 반복하는 것이 우선순위다
- **Dynamic Type** — 폰트뿐 아니라 **높이·패딩도** 스케일되는가. 폰트만 키우면 잘린다

`[중]` 이 셋은 grep으로 존재 여부만 셀 수 있고, 실제로 올바른지는 기기에서 봐야 한다.

---

## 모션 토큰

study_list §6-C의 "토큰화된 duration/easing, 화면 전환 일관성". 색 토큰과 결정적으로 다른 점이 하나 있다.

**모션은 틀려도 컴파일된다.** 0.25초가 0.8초가 돼도 아무것도 실패하지 않는다. 대비비는 계산이라도 되는데 "이 전환이 너무 느리다"는 계산되지 않는다. 그래서 **규칙을 코드로 적어 검사하는 것** 말고는 방법이 없다.

[`motion_tokens.swift`](code/phase3/motion_tokens.swift) — 색과 같은 3계층을 쓴다.

### 계층

- **Primitive** — `d100`·`d250`·`d400`, `decelerate`·`accelerate`. 역할을 모른다
- **Semantic** — `state-change`·`surface-enter`·`page-exit`. 화면 코드는 이 이름만 쓴다
- 호출부가 `0.25`가 아니라 `.surfaceEnter`라고 쓰는 이유는 색과 같다. 값을 한 곳에서 바꾸면 전부 따라오고, **이름이 의도를 말한다**

```
state-change     100   ms  cubic-bezier(0.2, 0.0, 0.0, 1.0)
micro-enter      150   ms  cubic-bezier(0.0, 0.0, 0.0, 1.0)
micro-exit       100   ms  cubic-bezier(0.3, 0.0, 1.0, 1.0)
surface-enter    250   ms  cubic-bezier(0.0, 0.0, 0.0, 1.0)
surface-exit     150   ms  cubic-bezier(0.3, 0.0, 1.0, 1.0)
page-enter       400   ms  cubic-bezier(0.0, 0.0, 0.0, 1.0)
page-exit        250   ms  cubic-bezier(0.3, 0.0, 1.0, 1.0)
loop             400   ms  cubic-bezier(0.0, 0.0, 1.0, 1.0)
```

### 일관성을 규칙으로 적는다

"화면 전환 일관성"은 느낌이 아니라 몇 개의 부등식으로 적힌다. 적어두면 검사할 수 있다.

| 규칙 | 근거 |
|---|---|
| **퇴장 ≤ 등장** | 사라지는 것을 기다리게 하면 앱이 굼떠 보인다. 등장은 눈이 따라가야 하므로 여유가 필요하다 |
| **등장=감속, 퇴장=가속** | 등장은 빨리 시작해 천천히 멈추고, 퇴장은 천천히 시작해 빨리 사라진다. 반대로 하면 어색하다 |
| **상태 전환 ≤ 100ms** | 눌림·호버는 "즉각"으로 느껴져야 한다 |
| **모든 토큰 ≤ 400ms** | 넘으면 기다리는 느낌이 된다 |
| **스케일 밖 duration 금지** | Primitive에 없는 임의값을 쓰면 토큰 체계가 무의미해진다 |

```
✅ 퇴장 ≤ 등장: micro-exit ≤ micro-enter             100ms ≤ 150ms
✅ 퇴장 ≤ 등장: surface-exit ≤ surface-enter         150ms ≤ 250ms
✅ 퇴장 ≤ 등장: page-exit ≤ page-enter               250ms ≤ 400ms
✅ 등장=decelerate / 퇴장=accelerate  (짝 3개 전부)
✅ 상태 전환 ≤ 100ms                                 100ms
✅ 모든 토큰 ≤ 400ms
✅ 스케일 밖 duration 없음
```

### reduce motion — "느리게"가 아니라 두 갈래다

접근성 설정이 켜졌을 때 duration을 0으로 만드는 것으로 끝내면 **한 종류가 망가진다.**

| 종류 | 해석 | 이유 |
|---|---|---|
| 일반 전환 | `immediate` (duration 0) | 애니메이션은 건너뛰되 **상태 변화는 일어나야 한다** |
| 무한 반복 (shimmer·로딩 점) | `disabled` | 0초로 두면 무한 루프가 그대로 돌면서 **CPU만 태운다** |

```
state-change     → immediate
surface-enter    → immediate
page-enter       → immediate
loop             → disabled
```

이 구분이 없으면 "reduce motion을 지원한다"고 적어놓고 가장 거슬리는 애니메이션(끝없이 반짝이는 스켈레톤)만 남는다.

### 가드를 일부러 깨뜨렸다

규칙 검사가 통과하는 것만 보면 **검사가 죽어 있어도 통과로 보인다.** 두 가지를 심어 확인했다.

| 심은 위반 | 결과 |
|---|---|
| `micro-exit`를 900ms로 (퇴장 > 등장, 상한 초과, 스케일 밖) | ❌ 3건 검출 |
| reduce motion에서 `loop`를 `immediate`로 | ❌ 1건 검출 |

양성 대조도 규칙에 넣었다 — **설정이 꺼져 있으면 원래 값이 그대로 나온다**를 검사한다. 이게 없으면 `resolve`가 항상 `immediate`를 반환해도 위 검사들이 전부 통과한다.

### 남은 것

`[중]` 이 규칙 세트는 **값이 규칙을 지키는지**만 본다. 실제 화면에서 그 전환이 자연스러운지는 눈으로 봐야 하고, 여기서는 렌더하지 않았다.

`[저]` duration 상한(100ms·400ms)은 널리 인용되는 값이지만 이 저장소에서 사용자 반응으로 측정한 것이 아니다.

---

## 5. 카탈로그와 테스트

### 갤러리가 필요한 지점

컴포넌트가 수십 종을 넘으면 카탈로그가 선택이 아니다. 만들지 않으면 "이미 있는 걸 또 만드는" 일이 반복된다.

- 컴포넌트군별 Preview + **별도 Example 앱 타깃**. 앱을 띄우지 않고 디자인 시스템만 실행해 볼 수 있다 ([§2-D §5](../Architecture/phase2d-comparison.md#5-모듈화))
- 앱 안에서도 디버그 메뉴 → 프리뷰 경로를 두면 실기기에서 확인할 수 있다

### Preview로 대체되지 않는 것 셋

Preview가 있으면 스냅샷이 필요 없다고 생각하기 쉬운데, 셋이 안 된다.

- **회귀 검출.** Preview는 사람이 봐야 한다. 토큰 하나를 바꿔 컴포넌트 45개 중 3개가 깨졌을 때, 눈으로 전부 확인하지 않으면 모른다
- **조합 커버리지.** `CaseIterable`이 붙어 있으면 전 조합을 자동 렌더할 수 있는데, 그 결과를 고정해 비교하지 않으면 조합별 검증이 안 된다
- **접근성 상태 렌더링.** Dynamic Type 최대 크기, reduce motion on/off는 Preview 스위치로 매번 확인하기 어렵다

### 붙였다 (2026-07-31)

주장으로 두지 않고 내 컴포넌트에 붙여서 **셋 중 무엇이 실제로 성립하는지** 확인했다.

```
swift test --filter SnapshotTests    # 5건
```

[`DesignSystem/code/phase3Tests/`](code/phase3Tests/) — `swift-snapshot-testing` 1.19.4, 참조 이미지는 `__Snapshots__/`에 커밋한다.

**조합 커버리지.** 외형 3종 각각에 대해 팔레트 5 × 치수 4 = **20 조합을 한 장에** 렌더한다. 조합마다 파일을 만들면 60장이 되고 리뷰에서 아무도 안 본다.

**회귀 검출 — 실제로 되는지 확인했다.** 주장만 적지 않고 토큰을 실제로 깨뜨려 봤다. `ButtonPalette.warning`의 배경 하나를 바꾸고 돌린 결과:

| 테스트 | 결과 |
|---|---|
| `solid_전조합` | **실패** — warning 포함 |
| `outlined_전조합` | **실패** — warning 포함 |
| `ghost_전조합` | **실패** — warning 포함 |
| `상태_모음` | 통과 — warning 안 씀 |
| `토큰이_바뀌면_렌더가_달라진다` | 통과 |

되돌리니 5건 전부 복구됐다. **토큰 하나가 정확히 그것을 쓰는 3개만 깨뜨렸다** — "토큰 하나를 바꿔 45개 중 3개가 깨졌을 때"가 문자 그대로 재현됐고, 무관한 것은 안 깨졌다.

**접근성 상태 렌더링 — 못 닫았다.** Dynamic Type 상태를 스냅샷으로 고정하려면 플랫폼이 Dynamic Type을 지원해야 한다. macOS는 안 한다(§4). 이 항목은 열려 있다.

렌더 안정성도 확인했다 — 같은 입력을 두 번 렌더해 바이트가 같았다(`토큰이_바뀌면_렌더가_달라진다`). 이게 깨지면 스냅샷은 노이즈만 만든다.

### 승격 기준

"언제 공통 컴포넌트가 되는가"의 답은 **누가 SoT인가**에 따라 갈린다.

- **디자인이 SoT인 조직**: 디자인 도구에 컴포넌트로 존재할 때가 승격 시점이다. 코드가 먼저 판단하지 않는다. 사용 횟수(2회? 3회?) 기준이 필요한 것은 디자인 시스템이 없는 조직의 이야기다
- **코드가 먼저인 조직**: 사용 횟수 기준이 실질적이다. 다만 "세 번째 사용처에서 승격"은 두 번째까지의 중복을 감수하겠다는 뜻이다
- 어느 쪽이든 **양방향 drift 감지**가 남는 문제다. 디자인에 있는데 코드에 없는 것, 코드에 있는데 디자인에서 지워진 것을 무엇이 알려주는가. 동기화 날짜를 기록하는 것이 최소한의 관리다

---

## 버전 정책과 breaking change

study_list §6-C의 마지막 항목이다. 앞 절들이 "무엇을 만드나"였다면 여기는 **"만든 것을 어떻게 바꾸나"**다.

### 디자인 시스템의 breaking은 두 종류다

일반 라이브러리와 다른 점이 여기 있다.

| 종류 | 예 | 무엇이 잡나 |
|---|---|---|
| **API breaking** | `Size.large` 제거, 이니셜라이저 시그니처 변경, 토큰 리네임 | 컴파일 |
| **시각 breaking** | 토큰 값 변경, 패딩 2pt 조정, 색 미세 수정 | **아무것도 안 잡는다** — 컴파일도 테스트도 통과한다 |

두 번째가 디자인 시스템 고유의 문제다. surface 토큰의 hex를 한 글자 바꾸면 컴포넌트 수십 종이 전부 달라지는데, **모든 코드가 컴파일되고 모든 유닛 테스트가 통과한다.** semver로 표현할 방법도 없다 — 공개 API는 하나도 안 바뀌었기 때문이다.

### 그래서 스냅샷이 버전 정책의 일부다

[§5](#붙였다-2026-07-31)에서 실증한 게 정확히 이것이다. 토큰 **1개**를 바꾸고 돌렸더니:

```
관련 3건 실패 / 무관 1건 통과
```

이건 "회귀를 잡았다"보다 **"시각 변경의 영향 범위를 기계가 알려줬다"**가 더 정확한 서술이다. 3건은 리뷰해야 할 변경이고, 1건은 안 봐도 된다. 스냅샷 diff가 없으면 이 판단을 사람이 전 컴포넌트에서 해야 한다.

정책으로 쓰면: **토큰 값을 바꾸는 PR은 스냅샷 diff가 리뷰 대상이다.** 스냅샷이 하나도 안 깨졌으면 그것도 정보다 — "의도한 변경이 반영되지 않았다"는 신호일 수 있다(양성 대조, [§4-B](../AI/phase-parallel-ai-verification.md#2-무엇이-무엇을-잡는가)).

### semver를 쓸 수 있는 경우와 없는 경우

디자인 시스템이 **같은 리포·같은 빌드 안의 로컬 모듈**이면 버전 번호가 없고, 소비자가 "이전 버전에 머무를" 선택지도 없다.

| | 로컬 모듈 | 별도 배포 패키지 |
|---|---|---|
| 소비자가 버전을 고정할 수 있나 | 아니오 | 예 |
| breaking의 비용 | **즉시, 전원** | 각자 올릴 때 |
| 필요한 것 | 같은 커밋에서 호출부까지 고치기 | semver + 마이그레이션 문서 |
| deprecation의 의미 | 이행 기간을 **버는 것** | 이행 기간을 **주는 것** |

**로컬 모듈이면 semver는 형식이고, 실질은 "한 PR에서 다 고칠 수 있나"다.** 못 고칠 규모면 alias·deprecation으로 두 상태를 공존시키는 수밖에 없다.

### alias는 이행 장치이고, 만료가 없으면 부채다

[§1](#backward-compat-alias의-비용)에서 본 그대로다. alias를 만들 때 같이 정해야 하는 것:

1. **만료 시점** — "다음 릴리스"처럼 지나가면 아무도 모르는 기준 말고, 날짜나 마일스톤
2. **새 코드가 구 이름을 쓰는 것을 막는 수단** — alias는 이행 중인 코드를 위한 것이지 새 코드를 위한 게 아니다. 이건 grep 한 줄로 강제된다 ([§2-B의 레이어 가드](../Architecture/phase2-clean-layered.md#2-경계는-선언만으로-지켜지지-않는다)와 같은 방식)
3. **누가 지우나** — 정해두지 않으면 아무도 안 지운다

`[저]` 이 세 항목은 실행해 본 게 아니라 alias가 쌓이는 양상에서 역산한 것이다.

### 정리 — 이 규모에서 실제로 필요한 것

버전 번호가 아니라 **변경의 영향 범위를 보이게 만드는 장치**다.

- 시각 변경 → **스냅샷 diff**가 영향 범위를 낸다 (실증됨)
- API 변경 → **컴파일**이 호출부를 전부 짚어준다 (로컬 모듈이라 가능한 것)
- 토큰 리네임 → **alias + 만료 + 새 사용 차단 grep**
- 접근성 회귀 → **대비비 회귀 가드**가 토큰 변경 시 자동 재계산 ([§4](#실제로-닫은-것-2026-07-31))

앞의 셋 중 스냅샷과 컴파일은 이 저장소에서 돌려 봤고, alias 운영은 안 해봤다.

---

## 6. 통과 기준 자기 평가

> variant enum 폭발 없이 확장 가능한 컴포넌트 API를 설계·문서화할 수 있다

- [x] 조합 폭발을 축 분해로 해체하는 설계를 만들었다 ([Phase 0 §7](../Swift/phase0-language-core.md#7-통과-기준-실습--button-96조합-해체), 타입체크 통과)
- [x] 확장 가능성을 **실제 확장으로** 확인했다 — 축 3개 추가에 기존 코드 0줄 수정, 테스트 6건
- [x] 반대 설계(축 유지 + 해석 집중)와 트레이드오프를 정리했다 (§3)
- [x] 토큰 3계층과 계층 강제 수단을 코드로 확인했다 (§1)
- [x] 접근성을 실측하고 **회귀 가드로 고정했다** (§4)
- [x] 스냅샷을 붙이고 **일부러 깨뜨려** 회귀 검출을 실증했다 (§5)
- [x] 버전 정책 — 시각 breaking을 무엇이 잡는지 정리했다 ([버전 정책](#버전-정책과-breaking-change))
- [x] **테마(라이트/다크)를 붙이고 두 스킴을 각각 검사했다** ([테마](#테마--스킴은-semantic-층이-흡수한다)) — 축은 늘지 않았고, 가드가 내 팔레트의 결함을 잡았다
- [x] **모션을 토큰화하고 일관성 규칙을 검사로 만들었다** ([모션](#모션-토큰)) — 일부러 깨뜨려 4건 검출 확인
- [ ] Dynamic Type이 **실제로 스케일되는지**는 검증 못 했다 — macOS에 Dynamic Type이 없다. iOS 시뮬레이터 필요

§6-A·§6-B·§6-C가 전부 닫혔다. 남은 하나는 **플랫폼 한계**라 이 환경에서 더 밀 수 없다.

---

## 7. 스스로 물어볼 것

- 토큰 계층이 2개면 무엇이 오염되는가 (§1)
- 계층 규칙을 문서가 아니라 코드로 강제하는 방법 (§1)
- 값으로 토큰 참조를 검사하면 왜 틀리는가 (§1)
- 웹 토큰을 iOS로 옮길 때 값 변환으로 안 되는 예 (§2)
- 조합 폭발의 두 답과, 각각이 전제하는 조직 조건 (§3)
- 슬롯을 열지 닫을지 무엇으로 판단하는가 (§3)
- 대비비 미달이 항상 나는 자리와 그 이유 (§4)
- 감사에서 찾은 미달을 결함으로 확정하지 않는 이유 (§4)
- Preview가 스냅샷을 대체하지 못하는 세 가지 (§5)
- 테마 스위칭이 Semantic 층에 있어야 하는 이유. Component에 두면 무엇이 늘어나는가 ([테마](#테마--스킴은-semantic-층이-흡수한다))
- 라이트 테마를 만들 때 밝기 램프를 뒤집기만 하면 안 되는 항목 ([테마](#램프만-뒤집으면-된다가-틀리는-지점))
- 팔레트 안쪽 대비만 재면 무엇을 놓치는가 ([테마](#가드가-내-팔레트의-결함을-잡았다))
- 모션을 토큰화해야 하는 이유가 색과 다른 점 ([모션](#모션-토큰))
- reduce motion에서 무한 반복을 immediate로 두면 무슨 일이 생기는가 ([모션](#reduce-motion--느리게가-아니라-두-갈래다))
- 시각 breaking을 semver로 표현할 수 없는 이유 ([버전 정책](#버전-정책과-breaking-change))

---

## 8. 검증 기록

### 환경

```
swift-driver version: 1.148.6 Apple Swift version 6.3.3
Target: arm64-apple-macosx26.0
```

### 실행한 것

| 대상 | 명령 | 결과 |
|---|---|---|
| §1·§3·§4 감사 | `swift -swift-version 6 DesignSystem/code/phase3/token_audit.swift` | 실행, 경고 0. 출력을 그대로 인용 |
| §4 접근성 | `swift test --filter AccessibilityTests` | **7건 통과** (1건은 플랫폼 한계로 비활성) |
| §4 대비비 교차검증 | 같음 | 테스트 계산이 감사 스크립트의 8.766과 소수 셋째 자리까지 일치 |
| §4 macOS Dynamic Type | `Text` 높이를 5개 크기에서 측정 | 전부 16.0 — **플랫폼이 무시한다** |
| §5 스냅샷 | `swift test --filter SnapshotTests` | **5건 통과**, 참조 이미지 4장 |
| §5 회귀 검출 실증 | `warning` 배경 토큰 1개 변경 후 재실행 | **관련 3건만 실패**, 무관한 1건은 통과. 되돌리니 복구 |
| 테마 감사 (두 스킴) | `token_audit.swift` | dark 1개 미달 · light 0개 미달. 강조색 재사용 시 2.704·1.976로 미달 |
| 테마 접근성 가드 | `swift test --filter AccessibilityTests` | **10건 통과**. §1.4.11 검사를 추가하자 assistive가 1.293로 걸려 팔레트를 고쳤다 |
| 테마 스냅샷 | `swift test --filter SnapshotTests` | **6건 통과**, dark·light 2장 추가 기록 |
| 테마 회귀 검출 실증 | 라이트 primary에 다크 값을 꽂고 재실행 | 스냅샷·재사용 검사는 검출, **팔레트 내부 대비 검사는 통과** → 검사 하나가 빠져 있었다 |
| 모션 규칙 검사 | `swift -swift-version 6 DesignSystem/code/phase3/motion_tokens.swift` | **규칙 12건 전부 통과** |
| 모션 가드 실증 | duration 900ms · loop를 immediate로 각각 심음 | **3건 / 1건 검출** |

### 확인하지 못한 것

| 주장 | 상태 |
|---|---|
| Dynamic Type이 iOS에서 실제로 커지는지 | **검증되지 않음.** iOS 시뮬레이터에서 돌려야 하는데 이 패키지에 `xcodebuild` iOS 스킴이 잡히지 않았다 |
| 스냅샷 참조 이미지의 기계 간 재현성 | **검증되지 않음.** 이 맥에서만 기록·비교했다. 폰트·렌더러가 다르면 깨질 수 있다 — CI에 걸려면 확인해야 할 항목 |
| §3 답 B | **미구현 [중]**. 널리 쓰이는 배치를 정리했고 수치는 가정한 파라미터 구성에서 센 것이다 |
| §2 토큰 파이프라인 | **미실행 [중]**. 생성 스크립트를 돌려보지 않았다 |
| §4 VoiceOver·reduce motion | **미검증 [중]**. 체크리스트만 남겼다. 실제 확인은 기기가 필요하다 |
| 팔레트 값 자체의 타당성 | **해당 없음.** 실습용으로 직접 정한 예제 값이다. 브랜드 색이 아니다 |
| 테마 전환의 **실제 동작** | **미검증 [중]**. `@Environment(\\.colorScheme)` 경로는 컴파일·스냅샷까지다. 시스템 설정을 바꿔 앱이 따라가는 것을 보지 않았다 |
| 모션 값이 화면에서 자연스러운지 | **미검증 [중]**. 값이 규칙을 지키는지만 검사했다. 렌더해서 보지 않았다 |
| duration 상한(100ms·400ms)의 근거 | **관례 [저]**. 널리 인용되는 값이고 여기서 사용자 반응으로 측정한 것이 아니다 |
| 보조 버튼의 테두리 해법 | **미구현 [중]**. `SolidButtonStyling`이 `border`를 렌더하지 않아 값으로 풀었다. 테두리로 푸는 쪽이 디자인적으로는 더 흔하다 |

---

## 참고 자료

**토큰 (표준)**
- 📘 [Design Tokens Format Module](https://www.designtokens.org/tr/drafts/format/) — W3C DTCG. 2025-10-28 첫 안정 버전
- 📄 [Style Dictionary — DTCG 지원](https://styledictionary.com/info/dtcg/) — 토큰 → 플랫폼별 코드 변환

**컴포넌트 API 설계 — Nathan Curtis (EightShapes)**
- 📄 [Crafting Component API, Together](https://medium.com/eightshapes-llc/crafting-ui-component-api-together-81946d140371) — anatomy / properties / layout 3축. variant enum 폭발의 정면 해법
- 📄 [Subcomponents](https://medium.com/eightshapes-llc/subcomponents-753ce9f6600a) — slot 패턴의 설계 논리
- 📄 [Component Specifications](https://medium.com/eightshapes-llc/component-specifications-1492ca4c94c)

**접근성·품질**
- 📘 [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) — Accessibility·Typography·Layout
- 💻 [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) — §5의 사실상 표준

다음은 [Phase 4 — 대규모 리팩토링](../Refactoring/phase4-large-scale-refactoring.md). 여기까지가 "무엇을 만드나"였고, 거기서는 **이미 있는 것을 어떻게 옮기나**를 남의 사례로 배운다.
