# Phase 1a — SwiftUI 렌더링 모델

[study_list.md](../study_list.md) §1-B의 정리.

- **통과 기준**: 불필요한 body 재계산을 Instruments로 찾아 고칠 수 있다 → [§7](#7-통과-기준--재계산-잡는-절차)
- **런타임으로 확인한 것**: 무효화 범위. 출력은 실제 실행 결과다
- **body 호출 횟수는 실측했다** ([§7](#절차를-실제로-돌렸다-2026-07-31)) — UI 호스트 [`code/phase1/RenderingLab/`](code/phase1/RenderingLab/)을 만들어 돌렸다. 결과가 예상과 달랐다
- **확인 못 한 것**: Instruments SwiftUI 템플릿은 이 환경에서 데이터를 내지 않았다. 나머지는 [§9](#9-검증-기록)
- **전체 소스**: [`Swift/code/phase1/`](code/phase1/) — 리포 루트에서 `swift -swift-version 6 Swift/code/phase1/observation_demo.swift`

선행: [Phase 0](phase0-language-core.md). 값 의미론과 `@resultBuilder`가 여기서 바로 쓰인다.

---

## 처음에 하는 착각 세 개

이 문서는 아래 세 가지를 깨는 순서로 되어 있다.

- **body가 화면을 그린다** → 아니다. body는 화면의 *설명*을 만들고, 여러 번 불릴 수 있다 ([§1](#1-body는-언제-다시-불리는가))
- **상태가 바뀌면 그 화면이 다시 그려진다** → 무효화 범위가 프로퍼티 래퍼마다 다르다 ([§2](#2-무효화-범위는-래퍼마다-다르다))
- **느리면 뷰를 쪼개면 된다** → 쪼개도 의존성이 그대로면 같이 무효화된다 ([§3](#3-재평가를-끊는-세-가지-방법))

---

## 1. body는 언제 다시 불리는가

### 이런 데서 물린다

- 리스트를 스크롤하면 프레임이 튄다
- 텍스트 필드에 타이핑할 때마다 화면 전체가 버벅인다
- 관계없는 화면이 같이 갱신된다

### View는 값이고, body는 자주 불린다

- `View`는 struct다. 상태가 바뀌면 SwiftUI는 View 인스턴스를 **새로 만들고** body를 다시 평가한다
- body 재평가는 "다시 그리기"가 아니다. SwiftUI가 새 설명과 이전 설명을 비교해 실제 렌더 대상만 갱신한다
- 그래서 body 안에서 비싼 일(정렬, 필터, 포매터 생성, 파일 접근)을 하면 그 비용이 재평가마다 반복된다

`init`도 마찬가지다. View의 `init`은 화면 생성 시 한 번이 아니라 재평가마다 불린다.

### 무엇이 body를 불렀는지 보는 법

```swift
struct ObservedBodyView: View {
    let title: String
    var body: some View {
        let _ = Self._printChanges()   // 어떤 의존성이 바뀌었는지 콘솔에 찍는다
        return Text(title)
    }
}
```

- 언더스코어 API라 비공개다. 디버깅 중에만 쓰고 커밋하지 않는다
- 출력 형식과 Instruments SwiftUI 템플릿 화면은 확인하지 않았다 ([§9](#9-검증-기록))

---

## 2. 무효화 범위는 래퍼마다 다르다

### 이런 데서 물린다

- ViewModel의 프로퍼티 하나를 바꿨는데 그 모델을 쓰는 화면이 전부 갱신된다
- `@Observable`로 바꾸면 빨라진다는 말은 들었는데 왜인지는 모른다

### 확인 — `@Observable`은 읽은 프로퍼티만 추적한다

`withObservationTracking`으로 SwiftUI 없이도 추적 범위를 볼 수 있다.

```swift
@Observable
final class NewModel {
    var title = "a"
    var unrelated = 0
}

withObservationTracking {
    _ = model.title              // title만 읽는다
} onChange: {
    fired.withLock { $0 += 1 }
}
model.unrelated = 99             // 읽지 않은 프로퍼티
model.title = "b"                // 읽은 프로퍼티
```

```
읽지 않은 프로퍼티 변경 → onChange 호출 횟수: 0
읽은 프로퍼티 변경   → onChange 호출 횟수: 1
```

### 확인 — `ObservableObject`는 객체 단위로 알린다

같은 상황을 `@Published`로 바꿔보면 결과가 다르다.

```swift
final class OldModel: ObservableObject {
    @Published var title = "a"
    @Published var unrelated = 0
}
model.objectWillChange.sink { ... }
```

```
무관한 프로퍼티 변경 → objectWillChange 발행 횟수: 1
관련 프로퍼티 변경   → objectWillChange 발행 횟수: 2
```

- `title`만 쓰는 뷰도 `unrelated` 변경에 딸려 무효화된다. 이게 `@Observable` 마이그레이션의 실질적 이유다
- 뷰를 잘게 쪼개도 `ObservableObject`를 통째로 받고 있으면 소용이 없다

### 확인 — 읽지 않으면 추적되지 않는다

조건 분기로 접근하지 않은 프로퍼티는 그 회차의 추적 대상이 아니다.

```swift
withObservationTracking {
    if model.showDetail { _ = model.detail }   // false면 detail을 안 읽는다
} onChange: { ... }
```

```
detail 변경 → onChange: 0
showDetail 변경 → onChange: 1
```

의존성이 **런타임 실행 경로에 따라 달라진다.** 같은 뷰가 상태에 따라 다른 것에 묶인다.

### 확인 — 추적은 one-shot이다

```
3번 변경했지만 onChange 호출: 1
```

- `withObservationTracking`은 첫 변경만 알린다
- SwiftUI는 body를 재평가할 때마다 추적을 다시 건다. "재평가 → 새 의존성 수집"이 매번 반복되는 구조다

### 범위 정리

| 래퍼 | 소유 | 무효화 범위 |
|---|---|---|
| `@State` | 이 뷰가 소유 | 이 뷰의 body |
| `@Binding` | 남이 소유, 참조만 | 원본 소유자 기준 |
| `@Observable` + `@State` | 이 뷰가 소유 | body가 **읽은 프로퍼티** 단위 |
| `ObservableObject` + `@ObservedObject` | 외부 | **객체 전체** |
| `@Environment` | 환경 | 그 키를 읽는 뷰 |

---

## 3. 재평가를 끊는 세 가지 방법

### 값만 넘긴다

모델 전체를 하위 뷰에 넘기면 그 뷰가 모델의 모든 읽기에 묶인다.

```swift
// ❌ 하위 뷰가 model에 묶인다
struct BadRow: View {
    let model: FeedModel
    let index: Int
    var body: some View { Text(model.items[index]) }
}

// ✅ 필요한 값만
struct GoodRow: View {
    let text: String
    var body: some View { Text(text) }
}
```

### Equatable View

값이 같으면 body 재평가를 건너뛸 수 있다.

```swift
struct ExpensiveRow: View, Equatable {
    let id: Int
    let label: String

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.label == rhs.label
    }
    var body: some View { Text(label) }
}

ExpensiveRow(id: row.id, label: row.label)
    .equatable()          // = EquatableView 래핑
```

두 가지 걸림돌이 있다.

**클로저 프로퍼티가 있으면 `==`를 만들 수 없다.** 클로저는 비교 대상이 아니다.

```swift
// ❌ Equatable로 만들 수 없다
struct BadButtonRow: View {
    let title: String
    let onTap: () -> Void
}
```

동작을 환경으로 빼서 비교 대상에서 제외한다.

```swift
struct GoodButtonRow: View, Equatable {
    let title: String
    let isEnabled: Bool
    @Environment(\.rowAction) private var action    // 비교 대상 아님
}
```

**컴파일러가 잡아준 것 — `View`는 `@MainActor`다.** Swift 6 모드에서 `nonisolated`를 빠뜨리면 준수 자체가 실패한다.

```swift
struct ExpensiveRow: View, Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool { ... }
}
// error: conformance of 'ExpensiveRow' to protocol 'Equatable'
//        crosses into main actor-isolated code and can cause data races
// note: main actor-isolated operator function '==' cannot satisfy nonisolated requirement
```

`nonisolated static func ==`로 고친다. Swift 5 모드에서는 나지 않던 에러다.

### 파생 값을 body 안에서 만들지 않는다

```swift
// ❌ 부모가 재평가되면 매번 다시 정렬한다
var body: some View {
    ForEach(items.sorted(), id: \.self) { Text($0) }
}

// ✅ 정렬된 값을 받는다
var body: some View {
    ForEach(sortedItems, id: \.self) { Text($0) }
}
```

파생 값은 모델 쪽에서 계산해 캐시하거나 최소한 뷰 밖에서 만든다.

---

## 4. 레이아웃은 협상이다

### 3단계

1. **부모가 제안한다** — `ProposedViewSize`. `nil`은 "네가 정해라", `.zero`·`.infinity`는 극단값 질의
2. **자식이 자기 크기를 답한다** — `sizeThatFits`
3. **부모가 배치한다** — `placeSubviews`

제안은 강제가 아니다. 자식은 제안을 무시할 수 있다. `frame(width:)`이 항상 먹지 않는 이유가 여기 있다.

### Layout 프로토콜로 직접 구현하면 3단계가 그대로 보인다

```swift
struct EqualWidthHStack: Layout {
    var spacing: CGFloat = 8

    // 1~2단계: 자식에게 묻고, 내가 필요한 크기를 부모에게 답한다
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let widest = sizes.map(\.width).max() ?? 0
        ...
    }

    // 3단계: 확정된 bounds 안에 놓는다
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        subview.place(at: point, anchor: .leading,
                      proposal: ProposedViewSize(width: widest, height: bounds.height))
    }
}
```

### `GeometryReader` 남용

- `GeometryReader`는 부모의 제안을 **전부 받아** 채우려 든다. 자식 크기에 맞춰 줄지 않는다
- 그래서 `VStack` 안에 넣으면 남은 공간을 다 먹는 사고가 난다
- 크기를 알아야 배치가 되는 구조라면 `Layout`이나 `alignmentGuide`가 맞는 도구다

---

## 5. 리스트와 identity

### Lazy 계열

- `LazyVStack`·`LazyVGrid`는 보이는 것만 body를 평가한다. 큰 리스트에서는 기본값으로 삼는다
- `VStack`은 전부 만든다. 항목이 수십 개를 넘으면 재평가 비용이 눈에 보인다

### id가 안정적이어야 한다

```swift
struct Item: Identifiable {
    let id: UUID     // 모델을 다시 만들 때마다 새 UUID면 전부 새 뷰가 된다
    let text: String
}
```

- id가 바뀌면 SwiftUI는 "같은 항목의 변경"이 아니라 **다른 항목**으로 본다
- 상태·애니메이션이 초기화되고 재사용이 깨진다
- 서버가 주는 안정적인 식별자를 쓴다. 없으면 만들어서 저장한다

### `if`가 타입을 갈라놓는다

[Phase 0 §5](phase0-language-core.md#5-resultbuilder)에서 확인한 내용이 여기서 증상으로 나타난다.

- `if`/`else`는 `buildEither`로 번역되고, 두 가지가 서로 다른 타입이 된다
- 조건이 뒤집히면 "같은 뷰의 변경"이 아니라 **교체**로 처리될 수 있다. 상태가 날아가고 전환 애니메이션이 끊긴다
- 같은 뷰로 유지하고 싶으면 분기 대신 값을 바꾼다. 다른 뷰로 확실히 갈라야 하면 `id()`를 명시해 의도를 드러낸다

---

## 6. 네비게이션

### path 기반 라우팅

```swift
enum Route: Hashable {
    case detail(id: Int)
    case settings
}

struct RootView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            List { Button("상세 42") { path.append(.detail(id: 42)) } }
                .navigationDestination(for: Route.self) { route in
                    switch route { ... }
                }
        }
    }

    func restore(from deepLink: [Route]) { path = deepLink }   // 딥링크 복원
}
```

- 네비게이션 상태가 **값(배열)**이 되는 것이 핵심 이득이다. 테스트도 복원도 배열 조작으로 끝난다
- `Route`는 `Hashable`이어야 한다. 연관값에 참조 타입을 넣으면 [Phase 0 §1](phase0-language-core.md#1-값-의미론과-copy-on-write)의 값 의미론 문제가 그대로 따라온다
- 딥링크 복원은 화면을 순차로 push하는 게 아니라 path를 한 번에 갈아끼우는 것이다

---

## UIKit 상호운용

> ⚠️ **이 절만 검증 강도가 다르다.** 이 저장소는 macOS에서 빌드하고 **macOS에는 UIKit이 없다.** 아래 코드는 컴파일된 적이 없고, 서술은 전부 문서·경험 기반이다. 신뢰도 라벨을 절 끝에 몰아 적었다. 다른 절과 같은 무게로 읽으면 안 된다.

앞 절들이 SwiftUI 안쪽 규칙이었다면 여기는 **경계**다. 요점 하나로 줄이면: **경계를 넘을 때 identity·값 의미론·레이아웃 협상 셋이 전부 번역돼야 하고, 셋 다 자동으로 되지 않는다.**

### 두 방향

| | SwiftUI 안에 UIKit | UIKit 안에 SwiftUI |
|---|---|---|
| 도구 | `UIViewRepresentable` / `UIViewControllerRepresentable` | `UIHostingController` |
| 언제 | 지도·카메라·웹뷰·성숙한 커스텀 컨트롤 | 기존 앱에 화면 단위로 SwiftUI 도입 |
| 주된 함정 | 업데이트 루프, 레이아웃 협상 | 크기 결정, safe area |

### `makeUIView`는 identity당 한 번이다

여기가 [§1](#1-body는-언제-다시-불리는가)·[§5](#5-리스트와-identity)에서 정리한 규칙이 그대로 걸리는 자리다.

```swift
struct MapView: UIViewRepresentable {
    var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView { MKMapView() }      // identity당 1회
    func updateUIView(_ view: MKMapView, context: Context) {            // body 재평가마다
        view.setRegion(region, animated: true)
    }
}
```

- `Representable`은 **struct라 매번 새로 만들어진다.** 반면 `MKMapView`는 참조 타입이고 살아남는다. 값-참조 경계가 여기 그어진다
- 그래서 `.id()`가 바뀌거나 `if` 분기가 뒤집히면([§5](#if가-타입을-갈라놓는다)) **UIView가 통째로 새로 만들어진다.** 지도가 초기 위치로 돌아가고 스크롤 위치가 날아가는 버그의 정체가 대개 이것이다
- 무거운 UIKit 뷰일수록 identity를 안정적으로 유지하는 비용이 크다. SwiftUI 쪽에서는 뷰 하나 갈아끼우는 정도로 보이는 일이 여기서는 카메라 세션 재시작이다

### 업데이트는 단방향이어야 한다

```swift
func updateUIView(_ view: UITextView, context: Context) {
    guard view.text != text else { return }    // ← 이 가드가 없으면 루프가 돈다
    view.text = text
}
```

- `updateUIView`에서 상태를 쓰면 body가 다시 평가되고 `updateUIView`가 다시 불린다
- 반대 방향(UIKit → SwiftUI)은 `Coordinator`가 delegate를 받아 `@Binding`에 쓴다. **Coordinator가 수명 있는 유일한 조각**이라 참조 타입이고, delegate·target-action·옵저버가 전부 여기 산다
- 두 방향이 만나면 왕복이 생긴다. 그래서 위 같은 **"값이 같으면 쓰지 않는다"** 가드가 관용구가 된다. [§3의 재평가 끊기](#3-재평가를-끊는-세-가지-방법)와 같은 문제를 경계에서 다시 푸는 것이다

### 레이아웃 협상이 자동으로 이어지지 않는다

[§4](#4-레이아웃은-협상이다)의 3단계와 UIKit의 Auto Layout / `intrinsicContentSize`는 **다른 체계**다.

```swift
func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
    // 구현하지 않으면 nil — SwiftUI 가 알아서 정하고, 대개 제안을 다 채운다
}
```

- 구현하지 않으면 `GeometryReader`와 같은 증상이 난다 — 부모 제안을 다 먹는다([§4](#geometryreader-남용))
- UIKit 뷰가 `intrinsicContentSize`를 갖고 있어도 SwiftUI가 그걸 자동으로 협상에 넣어주지 않는다. 다리를 놓는 게 `sizeThatFits(_:uiView:context:)`다
- `UIHostingController` 쪽에도 대칭인 문제가 있다. 호스팅 컨트롤러의 뷰가 자기 크기를 UIKit 레이아웃에 알리도록 `sizingOptions`를 설정해야 한다. 안 하면 부모가 크기를 모른다

### 제스처와 포커스는 두 시스템이 겹쳐 있는 것이다

- SwiftUI 제스처와 `UIGestureRecognizer`는 **서로를 모른다.** 중첩되면 둘 중 하나가 이기고, 어느 쪽이 이길지는 뷰 계층 순서에 달린다
- 스크롤 중첩(SwiftUI `ScrollView` 안의 `UIScrollView`, 또는 그 반대)이 가장 흔한 충돌 지점이다. 동시 인식을 원하면 UIKit 쪽 delegate에서 명시해야 한다
- 포커스도 개념이 둘이다 — UIKit의 **first responder**와 SwiftUI의 **`@FocusState`**. 하나를 바꿔도 다른 쪽이 따라오지 않는다. 경계를 넘는 폼에서는 어느 쪽을 SoT로 둘지 먼저 정하는 편이 낫다

### 격리 — Phase 1b가 여기서 걸린다

`UIView`·`UIViewController`는 `@MainActor`이고, `Representable`의 메서드도 그렇다. [Phase 1b](../Concurrency/phase1-concurrency.md)에서 정리한 규칙이 그대로 적용된다.

- Coordinator가 받는 delegate 콜백이 메인 액터인지 확인해야 한다. UIKit delegate는 대개 메인에서 불리지만 **"대개"는 컴파일러 근거가 아니다**
- 비동기 작업을 Coordinator에 들고 있으면 그 Task의 격리를 명시한다. 여기가 [사례 4](../AI/phase-parallel-ai-verification.md#4--언어-모드에-따라-나타나는-오류)와 같은 유형의 진단이 나오는 자리다

### 대체 검증의 유혹

이 절을 쓰면서 **`NSViewRepresentable`로 같은 걸 해보고 "확인했다"고 쓸까** 고민했다. macOS에는 AppKit이 있으니 컴파일은 된다.

하지 않았다. **다른 API다.** `sizeThatFits(_:uiView:context:)`도, `sizingOptions`도, first responder 동작도 AppKit에서 같지 않다. 컴파일되는 유사 코드를 근거로 삼으면 [사례 21](../AI/phase-parallel-ai-verification.md#1-실제로-틀렸던-것들)과 같은 종류의 오류가 된다 — **통과했는데 통과가 아닌 것**, 그것도 이번에는 대상이 아예 다른 것.

### 신뢰도

| 주장 | 상태 |
|---|---|
| `makeUIView`가 identity당 1회, `updateUIView`가 재평가마다 | **미검증 [중]**. 문서화된 계약이지만 여기서 호출 횟수를 세지 않았다 |
| 업데이트 루프와 값 비교 가드 | **미검증 [중]**. 널리 쓰이는 관용구 |
| `sizeThatFits` 미구현 시 제안을 다 채운다 | **미검증 [저]**. §4의 `GeometryReader` 관찰에서 유추한 것이고 UIKit 경계에서 직접 보지 않았다 |
| 제스처·포커스 충돌의 구체적 해소 방법 | **미검증 [저]**. 증상만 정리했고 실제로 겪은 기록이 없다 |
| 위 코드 조각 전부 | **컴파일된 적 없음.** macOS에 UIKit이 없다 |

이 절은 **iOS 타깃을 가진 프로젝트에서 다시 써야 한다.** [study_list 다음 사이클](../study_list.md#다음-사이클-2026-07-31)의 "실행·타 레포가 필요해 열어두는 것"에 걸어뒀다.

---

## 7. 통과 기준 — 재계산 잡는 절차

통과 기준은 "찾아서 고친다"다. 절차로 정리하면 이렇다.

**1. 재현한다**
- 실기기, Release 빌드. 시뮬레이터와 Debug 빌드의 체감은 신뢰하지 않는다

**2. 어디가 다시 불리는지 본다**
- 의심되는 뷰에 `let _ = Self._printChanges()`
- Instruments SwiftUI 템플릿으로 body 호출이 몰리는 뷰를 찾는다

**3. 원인을 분류한다**

| 증상 | 원인 | 처방 |
|---|---|---|
| 무관한 상태 변경에 같이 불린다 | 모델을 통째로 받았다 | 값만 넘긴다 (§3) |
| 부모가 불릴 때마다 같이 불린다 | 값이 같은데 비교가 안 된다 | `Equatable` + `.equatable()` (§3) |
| 재평가 자체가 느리다 | body 안에서 계산한다 | 파생 값을 밖으로 (§3) |
| 스크롤에서만 튄다 | 전체를 미리 만든다 | `LazyVStack` (§5) |
| 상태·애니메이션이 초기화된다 | id가 불안정하거나 `if`로 타입이 갈렸다 | id 고정, 분기 대신 값 (§5) |
| 레이아웃이 공간을 다 먹는다 | `GeometryReader` | `Layout`·`alignmentGuide` (§4) |

**4. 고친 뒤 다시 측정한다**
- 호출 횟수가 실제로 줄었는지 같은 방법으로 확인한다. 감으로 판정하지 않는다

### 절차를 실제로 돌렸다 (2026-07-31)

위 절차는 오래 계획으로만 있었다. UI 호스트가 없어 실행할 수 없었기 때문이다. [`code/phase1/RenderingLab/`](code/phase1/RenderingLab/)이 그 호스트다 — **사람이 클릭하지 않아도 같은 수가 나오도록** 앱이 스스로 상태를 정해진 횟수만큼 바꾸고, 세고, 출력하고 끝낸다.

```
swift run RenderingLab
```

측정 대상: 행 20개짜리 목록. 목록 내용과 무관한 값(`model.tick`)을 **10회** 변경한다.

| 모드 | 무엇이 다른가 |
|---|---|
| ❌ BAD | 목록 body 가 `model.tick` 을 직접 읽는다 (`Text("업데이트 \(model.tick)회")`) |
| ✅ GOOD | `model.tick` 을 읽는 부분만 `CounterBadge` 잎 뷰로 뺐다 |

두 모드의 행 뷰는 **똑같이 `String` 하나만 받는다.** 차이는 오직 "누가 바뀌는 값을 읽는가"뿐이다.

#### 결과

```
=== 초기 렌더에서 실제로 body 가 불렸는가 ===
  BadList          1
  BadRow           20

=== body 호출 횟수 (행 20개 · 무관한 값 10회 변경) ===
  모드      뷰               호출      변경당
  bad     BadList         10      1.0
  good    CounterBadge    10      1.0
```

초기 렌더 수치를 따로 찍은 이유는 **0이 '무효화 없음'인지 '측정 실패'인지 구별하려고**다. BadRow 20건이 찍혔으니 렌더는 실제로 일어났다.

#### 예상과 달랐던 것 — 행 body 는 한 번도 다시 안 불렸다

`BadRow`의 재평가 횟수가 **0**이다. "부모가 다시 불리면 자식도 다 다시 불린다"는 통념이 이 조건에서는 성립하지 않았다.

- 부모 body 가 10번 돌면서 `BadRow` **값**은 매번 20개 새로 만들어졌다
- 그런데 SwiftUI 가 이전 값과 비교해 같다고 판정하고 **body 호출을 건너뛰었다**
- 즉 과잉 읽기의 비용은 **자식 body 가 아니라 부모 body + `ForEach` 재구성**에 있다

고치기 전후로 실제로 줄어든 건 `BadList` body 10회다. 그 자리를 `CounterBadge` 10회가 대신한다 — 같은 10회지만 **재구성되는 서브트리 크기가 목록 전체에서 `Text` 하나로** 줄었다.

이 결과는 §3의 `Equatable` 논의와 이어진다. 자식 입력이 값 타입이고 실제로 같으면 `.equatable()` 없이도 이미 건너뛴다. `Equatable` 이 필요한 건 **비교가 안 되는 입력**(클로저 등)을 들고 있을 때다.

#### Instruments SwiftUI 템플릿은 데이터를 내지 않았다

절차 2단계가 요구하는 Instruments 경로는 **이 환경에서 완주하지 못했다.**

```
$ xcrun xctrace record --template SwiftUI --output rl.trace --launch -- RenderingLab.app
* [Warning] Trace file had no SwiftUI data
```

번들 없이 실행 / `.app` 번들로 감싸고 ad-hoc 서명까지 해서 재시도 — **둘 다 같은 경고**. 트레이스에 `swiftui-updates`·`swiftui-causes` 스키마는 있는데 **행이 0개**다.

파이프라인 문제가 아니라는 건 확인했다. 같은 앱을 `Logging` 템플릿으로 기록하면 **os-signpost 511행**이 잡히고, 그중 **67행이 내 subsystem**(`studdy.rendering`)이다. 그 67행이 인앱 카운터와 정확히 맞는다:

| | 건수 |
|---|---|
| 초기 렌더 (BadList 1 + BadRow 20) | 21 |
| BAD 구간 (BadList 10) | 10 |
| 모드 전환 (GoodList 1 + CounterBadge 1 + GoodRow 20) | 22 |
| GOOD 구간 (CounterBadge 10) | 10 |
| 구간 마커 (begin/end × 2 모드) | 4 |
| **합계** | **67** ← 트레이스 실측과 일치 |

**결론**: body 호출 횟수는 실측했지만 **Instruments SwiftUI 템플릿을 통해서는 아니다.** 이 조합(macOS · SPM 실행 타겟 · Instruments 16.0)에서 SwiftUI 계측기가 데이터를 내지 않는 이유는 확인하지 못했다 `[미검증]`. iOS 시뮬레이터/실기기나 Xcode 프로젝트로 빌드한 앱에서는 다를 수 있다.

대안 경로는 유효하다 — **`OSSignposter` + 인앱 카운터**로 같은 숫자를 얻었고, 두 방법이 서로를 검증했다.

---

### `.equatable()` 이 실제로 재평가를 줄이는가 (2026-07-31)

§9가 오래 "미검증"으로 남겨둔 항목이다. 위 실측에서 행 body가 0회였던 이유는 **입력이 이미 같아 SwiftUI가 알아서 건너뛴 것**이라, `.equatable()`의 효과를 잰 게 아니었다.

효과를 재려면 **자동 건너뛰기가 실패하는 조건**을 먼저 만들어야 한다. 두 번 틀렸다.

**첫 번째 설계 — 비캡처 클로저.** 뷰가 클로저를 들고 있으면 비교가 안 될 것이라 보고 `onTap: {}`를 넘겼다.

```
closure ClosureList  10   1.0
                          ← ClosureRow 가 아예 없다 = 0회
```

**틀렸다.** 비캡처 클로저는 매번 같은 값이라 SwiftUI가 그냥 건너뛴다. [사례 17](../AI/phase-parallel-ai-verification.md#1-실제로-틀렸던-것들)과 같은 종류 — **실험이 측정하려는 것을 건드리지 않았다.**

**두 번째 설계 — 값을 캡처한다.** 렌더마다 새 컨텍스트가 생기게 했다.

```swift
let t = model.tick
let captured: () -> Void = { _ = t }   // 렌더마다 새 컨텍스트
```

이번엔 조건이 만들어졌고, 결과가 갈렸다.

```
=== 모드 전환 시 렌더 (양성 대조 — 뷰가 그려지긴 했는가) ===
  closure   총 21      ClosureList 1 · ClosureRow 20
  equatable 총 21      EquatableList 1 · EquatableRow 20

=== body 호출 횟수 (행 20개 · 무관한 값 10회 변경) ===
  closure   ClosureList    10    1.0
  closure   ClosureRow     200   20.0
  equatable EquatableList  10    1.0
                                 ← EquatableRow 가 없다 = 0회
```

**200회 → 0회.** 같은 조건에서 `.equatable()` 하나가 행 재평가를 전부 없앴다.

`==`는 클로저를 **비교에서 뺀다**. 렌더 결과에 영향이 없기 때문이다.

```swift
struct EquatableRow: View, Equatable {
    let title: String
    let onTap: () -> Void

    nonisolated static func == (lhs: EquatableRow, rhs: EquatableRow) -> Bool {
        lhs.title == rhs.title      // onTap 은 렌더에 영향이 없다
    }
}
```

읽어낼 것 셋.

- **`.equatable()`은 자동 비교가 실패할 때만 값어치가 있다.** 입력이 이미 비교 가능하면 SwiftUI가 알아서 건너뛰므로 붙여도 0이 0이다. 통념처럼 "성능이 걱정되면 붙인다"가 아니라 **비교 불가능한 필드가 있을 때** 붙인다
- **비교 불가능한 필드의 대표가 캡처하는 클로저다.** 콜백을 받는 행 컴포넌트가 리스트에 들어가면 이 조건이 자연스럽게 생긴다
- **`nonisolated`가 필요하다.** `View`가 `@MainActor`라 준수가 격리를 넘는다 — [사례 4](../AI/phase-parallel-ai-verification.md#4--언어-모드에-따라-나타나는-오류)와 같은 진단이고, 이번에도 그대로 났다

양성 대조를 같이 붙였다. "모드 전환 시 렌더" 줄이 그것이다 — 이게 없으면 **행이 아예 안 그려진 것**과 **그려졌지만 재평가가 없는 것**이 똑같이 0으로 보인다. 첫 번째 설계가 틀렸다는 것도 이 줄이 있어서 알았다.

---

## 8. 스스로 물어볼 것

- body 재평가와 화면 갱신은 어떻게 다른가 (§1)
- `@Observable`과 `ObservableObject`의 무효화 범위 차이를 수치로 말할 수 있는가 (§2)
- 같은 뷰가 상태에 따라 다른 프로퍼티에 묶이는 이유는 (§2)
- 클로저를 프로퍼티로 받은 뷰를 `Equatable`로 만들 수 없는 이유와 우회법 (§3)
- Swift 6에서 뷰의 `==`에 `nonisolated`가 필요한 이유 (§3)
- 부모의 제안을 자식이 무시할 수 있는가 (§4)
- `id`가 매번 바뀌면 무엇이 깨지는가 (§5)
- `if`/`else`로 뷰를 갈랐을 때 상태가 날아가는 이유 (§5)

---

## 9. 검증 기록

### 환경

```
swift-driver version: 1.148.6 Apple Swift version 6.3.3
Target: arm64-apple-macosx26.0
```

### 실행한 것

| 대상 | 명령 | 결과 |
|---|---|---|
| §2 무효화 범위 데모 4개 | `swift -swift-version 6 Swift/code/phase1/observation_demo.swift` | 전부 실행. 출력을 그대로 인용 |
| §1·3~6 코드 | `swiftc -typecheck -swift-version 6 Swift/code/phase1/rendering_views.swift` | 에러·경고 0 |
| §7 body 호출 횟수 (2026-07-31) | `swift run RenderingLab` | BAD: 부모 body 10회 / 행 **0회** · GOOD: 잎 뷰 10회 |
| §7 Instruments SwiftUI 템플릿 | `xctrace record --template SwiftUI` | **데이터 없음** — `swiftui-updates` 0행 (번들·서명 후에도 동일) |
| §7 signpost 대조 | `xctrace record --template Logging` | os-signpost 511행 중 내 subsystem **67행** — 인앱 카운터와 일치 |

`View`의 `==`에 `nonisolated`가 필요하다는 §3의 내용은 위 타입체크가 실제로 실패해서 알게 된 것이다. 인용한 에러 메시지는 컴파일러 출력이다.

### 확인하지 못한 것

| 주장 | 상태 |
|---|---|
| ~~body 호출 횟수 실측~~ | **해소 (2026-07-31)** — [§7](#절차를-실제로-돌렸다-2026-07-31)에서 측정. 결과가 예상과 달랐다(행 body 0회) |
| ~~`Equatable`로 실제로 재평가가 줄어드는지~~ | **해소 (2026-07-31)** — 자동 비교가 실패하는 조건(캡처하는 클로저)을 만들어 측정. **200회 → 0회** ([§7](#equatable-이-실제로-재평가를-줄이는가-2026-07-31)). 첫 설계는 틀렸고 양성 대조가 그걸 드러냈다 |
| `Self._printChanges()`의 출력 형식 | **미검증 [중]**. 비공개 API |
| Instruments SwiftUI 템플릿 화면·사용법 | **여전히 미검증 [저]** — 시도했으나 **이 환경에서 데이터가 안 나왔다.** macOS·SPM 실행 타겟 조합의 문제인지 확인 못 했다. 대신 `OSSignposter`로 우회했고 두 측정이 일치한다 ([§7](#instruments-swiftui-템플릿은-데이터를-내지-않았다)) |
| macOS 결과가 iOS에서도 같은지 | **검증되지 않음.** macOS 앱으로만 측정했다. 행 body 를 건너뛰는 판정이 플랫폼별로 다를 수 있다 |
| **UIKit 상호운용 절 전체** | **컴파일된 적 없음.** macOS에 UIKit이 없다. 항목별 라벨은 [해당 절](#신뢰도)에 따로 있다 — 이 문서에서 검증 강도가 가장 낮은 부분이다 |
| `LazyVStack`의 재사용·해제 시점 | **미검증 [중]**. "보이는 것만 평가한다"는 문서 수준의 진술 |
| `GeometryReader`가 제안을 다 채운다 | **미검증 [중]**. 널리 알려진 동작이지만 여기서 측정하지 않았다 |

런타임 근거가 있는 건 **무효화 범위(§2)와 body 호출 횟수(§7)** 둘이다. 나머지 절(레이아웃 협상·Lazy 재사용·`GeometryReader`)은 코드가 타입체크된다는 것까지만 확인했다.

---

## 참고 자료

[study_list.md §1](../study_list.md#1-swift--swiftui)에서 Phase 1a에 해당하는 것.

- 🎬 [Demystify SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10022/) — Identity / Lifetime / Dependencies. 이 문서 §1·§5의 원출처
- 🎬 [Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/) — §7 절차에 직결
- 🎬 [Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/) — §2 마이그레이션
- 🎬 [Compose custom layouts with SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10056/) — §4
- 📕 [Thinking in SwiftUI](https://www.objc.io/books/thinking-in-swiftui/) — 직관을 기르는 쪽. Phase 1 목표와 맞는다

다음은 [Phase 1b — Swift Concurrency](../Concurrency/phase1-concurrency.md). `@MainActor`와 뷰 갱신의 경계가 거기서 이어진다.
