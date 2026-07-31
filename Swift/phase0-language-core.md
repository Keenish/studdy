# Phase 0 — Swift 언어 코어

[study_list.md](../study_list.md) §1-A의 정리.

- **통과 기준**: 제네릭 + PAT로 공통 컴포넌트 시그니처를 직접 설계할 수 있다 → [§7](#7-통과-기준-실습--button-96조합-해체)
- **코드**: 전부 Swift 6.3.3에서 돌려봤다. 문서에 인용한 출력은 실제 실행 결과다
- **검증 못 한 것**: [§9](#9-검증-기록)에 따로 모아뒀다
- **전체 소스**: [`Swift/code/phase0/`](code/phase0/) — 리포 루트에서 `swift Swift/code/phase0/phase0_demo.swift`, `swift -swift-version 6 Swift/code/phase0/existential_layout.swift`
- **§7 컴포넌트 API**는 SPM 타겟이다 (`swift test --filter ComponentAPITests`) — 확장 가능성 주장을 실제로 확장해서 확인하려고 승격했다

---

## 왜 언어부터 보는가

SwiftUI를 먼저 잡으면 관용구는 손에 붙는데 "왜 저렇게 쓰는지"가 안 남는다. `@State`가 언제 무효화되는지, `@ViewBuilder`가 왜 그 모양인지, 컴포넌트 API를 어디로 열어둘지는 모두 아래 6개 위에 얹혀 있다.

| 배울 것 | 뒤에서 만나는 자리 |
|---|---|
| 값 의미론 · COW | View가 struct인 이유, `Equatable` View로 재계산 끊기 (Phase 1) |
| 실패 표현 설계 | Repository ↔ UseCase 경계의 에러 매핑 (Phase 2) |
| 프로토콜 · PAT | `ButtonStyle`류 확장 지점 (Phase 3) |
| 제네릭 · opaque type | 슬롯 API 시그니처, `some View` (Phase 1·3) |
| `@resultBuilder` | `@ViewBuilder`의 정체, `if`가 뷰를 갈라놓는 이유 (Phase 1) |
| 참조 순환 | ViewModel 누수, Task 수명 (Phase 1·2) |

> **나중에 대조한 결과**: 대부분 맞았지만 **PAT 항목은 어긋났다.** Phase 3에서 실제 출시된 컴포넌트는 PAT 확장 지점을 열지 않고 enum 축을 유지한 채 해석만 두 함수에 모았다. 디자인 시스템은 Figma가 SoT라서 **확장 지점을 닫는 것이 오히려 기능**이었다 ([Phase 3 §3](../DesignSystem/phase3-design-system.md#3-조합-폭발--답이-두-개다)). PAT는 여전히 배울 값어치가 있지만 — [§2-B](../Architecture/phase2-clean-layered.md#3-포트를-어디-두는가--교과서가-지는-사례)의 Repository 포트가 그 예다 — "Phase 3에서 `ButtonStyle`류로 쓰인다"는 예고는 정확하지 않았다.

---

## 1. 값 의미론과 copy-on-write

### 이런 데서 물린다

- 상태 struct에 `class` 프로퍼티 하나가 섞였는데 화면이 갱신되지 않는다
- 큰 배열을 함수마다 넘기면서 복사 비용을 걱정한다
- "struct니까 안전하다"고 믿고 공유 상태를 만들어버린다

### struct는 자기가 든 참조까지 복사하지 않는다

이게 셋 중 첫 번째 문제의 원인이다.

```swift
final class Box { var value = 0 }
struct Leaky { var box = Box(); var count = 0 }

var a = Leaky()
let b = a       // 복사한 셈
a.count = 99
a.box.value = 99
```

```
a.count=99 b.count=0             (독립)
a.box.value=99 b.box.value=99    (공유)
```

- `count`는 갈라졌고 `box.value`는 붙어 있다
- SwiftUI는 이전 값과 새 값을 비교해 갱신 여부를 정한다. 내용이 바뀌어도 참조는 그대로니 "변한 게 없다"로 읽힐 수 있다
- 그래서 `@State`에 넣는 타입에는 참조를 섞지 않는다

### 컬렉션은 쓰기 직전에 복사한다

두 번째 걱정은 대개 기우다. `Array`·`Dictionary`·`Set`·`String`은 COW라서 대입만으로는 복사가 일어나지 않는다.

```swift
let arr1 = [1, 2, 3]
var arr2 = arr1
arr2.append(4)
```

```
대입 직후 버퍼 공유: true
변경 직후 버퍼 공유: false
```

버퍼 주소(`withUnsafeBufferPointer`의 `baseAddress`)를 비교해 확인한 값이다.

### 큰 저장소를 값처럼 쓰려면

직접 COW를 붙인다. 관용구는 `isKnownUniquelyReferenced` 하나다.

```swift
mutating func append(_ x: Int) {
    if !isKnownUniquelyReferenced(&storage) {
        storage = Storage(storage.data)   // 공유 중일 때만 복사
    }
    storage.data.append(x)
}
```

```
유일 참조일 때 복사 발생: false
공유 중일 때 복사 발생: true
원본 보존: [1, 2] / 변경본: [1, 2, 3]
```

### struct냐 class냐

| 상황 | 선택 |
|---|---|
| 정체성 없이 값 자체로 의미가 있다 | `struct` |
| 두 곳이 같은 인스턴스를 봐야 한다 | `class` |
| 상속이나 Objective-C 상호운용이 필요하다 | `class` |
| 크기가 크고 복사가 잦다 | `struct` + 내부 COW |
| SwiftUI 상태로 쓴다 | `struct`, 참조 섞지 않기 |

---

## 2. 실패를 표현하는 네 가지 방법

### 고르는 기준

먼저 이 표로 좁히고 들어가는 편이 빠르다.

| 표현 | 쓸 자리 |
|---|---|
| `Optional` | 실패 이유가 하나거나 이유가 필요 없다 (`dict[key]`) |
| `throws` | 이유별로 다르게 대응해야 하고, 이유가 앞으로 늘어날 수 있다 |
| `throws(E)` | 이유가 닫힌 집합이고 호출자가 전수 대응해야 한다 |
| `Result` | 실패를 값으로 저장하거나 넘겨야 한다 (콜백 경계, 캐시) |

### typed throws가 바꾸는 것

Swift 6부터 던지는 에러 타입을 적을 수 있다.

```swift
enum LoadError: Error, Equatable { case notFound, decode(field: String) }

func load(_ id: Int) throws(LoadError) -> String {
    guard id > 0 else { throw .notFound }   // 문맥으로 타입이 정해져 enum 이름 생략
    ...
}

do { _ = try load(0) }
catch { print(error == .notFound) }         // error의 정적 타입이 LoadError
```

```
catch에서 바로 패턴 매칭: true
```

- `catch`에서 `as? MyError` 캐스팅이 사라진다
- 케이스를 빠뜨리면 컴파일러가 잡는다
- 대신 **에러 케이스 추가가 breaking change가 된다.** 공개 API 경계에는 신중하게

### 컴파일러가 잡아준 것 ① — `Result.init(catching:)`

typed throws를 `Result`로 감싸려다 막혔다.

```swift
let r: Result<String, LoadError> = Result { try load(13) }
// error: invalid conversion of thrown error type 'any Error' to 'LoadError'
```

`Result.init(catching:)`은 `Failure == any Error`로 고정이라 던지는 타입이 그대로 흐르지 않는다. 실패 타입을 살리려면 직접 감싼다.

```swift
func loadResult(_ id: Int) -> Result<String, LoadError> {
    do { return .success(try load(id)) }
    catch { return .failure(error) }
}
```

### `try?`를 조심할 자리

```
try? 는 에러 종류를 버린다: nil
성공 시엔 평탄화된 Optional: Optional("item-7")
```

- 위 `nil`이 `notFound`였는지 `decode`였는지 알 방법이 없다. 로그가 필요한 경계에서 쓰면 원인 추적이 끊긴다
- 결과가 평탄화된다. `String?`을 던지는 함수에 `try?`를 쓰면 `String??`이 아니라 `String?`이 되어 실패와 "값 없음"이 구분되지 않는다

---

## 3. 프로토콜 — PAT와 `some` / `any`

### 이런 데서 물린다

- 스타일 프로토콜을 만들어 커스텀 구현을 넣었는데 기본 구현이 호출된다
- `any Container`를 만들었더니 정작 쓸 수 있는 멤버가 없다
- `some`과 `any` 중 뭘 쓸지 매번 감으로 고른다

### associated type을 밖에서 제약하려면

`associatedtype`만 있으면 호출자가 타입을 좁힐 수 없다. primary associated type으로 올려둬야 한다.

```swift
protocol Container<Item> {      // <Item>이 primary associated type
    associatedtype Item
    var items: [Item] { get }
}

let boxed: any Container<Int> = Bag<Int>()   // 제약을 적을 수 있다
func makeBag() -> some Container<Int> { Bag<Int>() }
```

프로토콜을 설계할 때 **호출자가 제약하고 싶어할 타입을 primary로 올리는 것**이 그대로 API 결정이 된다.

### 컴파일러가 잡아준 것 ② — 위치 인자

```swift
func makeBag() -> some Container<Item: Int> { ... }
// error: expected '>' to complete generic argument list
```

primary associated type은 레이블 없는 위치 인자다. `Container<Int>`가 맞고, `Item:` 같은 레이블 문법은 없다.

### `some`과 `any`

| | `some P` | `any P` |
|---|---|---|
| 구체 타입 | 컴파일 타임에 하나로 고정 | 런타임에 달라질 수 있다 |
| 디스패치 | 정적, 특수화·인라이닝 가능 | 동적, witness table 경유 |
| 이종 타입 담기 | 안 된다 | `[any P]` 가능 |
| PAT 제약 | 자유롭게 | primary associated type이나 `where`로만 |

- 기본값은 `some`. 이종 타입을 한 컨테이너에 담거나 런타임에 타입이 갈려야 할 때만 `any`로 내린다
- `any P`는 값을 존재 컨테이너에 담고, 인라인 버퍼에 안 들어가는 큰 값은 힙에 박싱된다

### 컨테이너를 실제로 재봤다

[`existential_layout.swift`](code/phase0/existential_layout.swift)로 측정했다 (Swift 6.3.3, arm64).

```
[1] existential 컨테이너 크기 (1워드 = 8바이트)
  any Plain                        40바이트 (5워드)
  any Plain & Second               48바이트 (6워드)
  any ClassOnly (AnyObject 제약)     16바이트 (2워드)
  any Error                        8바이트 (1워드)

[2] 값이 컨테이너 안에 들어가는가 (3회 반복해 안정성 확인)
  시도 1: W1(8B)=인라인  W2(16B)=인라인  W3(24B)=인라인  W4(32B)=힙  W5(40B)=힙
  → 관측: 24바이트까지 인라인, 32바이트부터 힙
     컨테이너 40 = 인라인 버퍼 24 + 메타데이터·witness table 16
```

- **인라인 버퍼는 3워드(24바이트)**다. 그보다 큰 값은 힙에 박싱된다
- 컨테이너 크기는 **담는 값과 무관하게 고정**이다. 프로토콜을 더 요구하면 witness table이 늘어 커진다(`any Plain & Second`가 48바이트)
- `AnyObject` 제약이 붙으면 참조 1개 + witness table = 2워드로 훨씬 작다
- **이 수치는 구현 세부다.** 버전에 따라 달라질 수 있으니 API 계약처럼 쓰면 안 된다. 남기는 결론은 "**작은 값은 공짜에 가깝고, 3워드를 넘으면 할당이 생긴다**"

### 측정하려다 걸린 것 — existential은 제네릭 경계에서 열린다

컨테이너를 재려고 `MemoryLayout`을 제네릭 함수로 넘겼는데 값마다 다른 크기가 나왔다.

```swift
func sizeSeenByGeneric<T>(_ value: T) -> Int { MemoryLayout<T>.size }

let small: any Plain = W1(a: 7)   // 8바이트
let big:   any Plain = W5(...)    // 40바이트
sizeSeenByGeneric(small)  // 8   ← 40이 아니다
sizeSeenByGeneric(big)    // 40
```

existential을 제네릭 파라미터로 넘기면 **암묵적으로 열려서**(SE-0352) `T`가 컨테이너가 아니라 **동적 타입**에 바인딩된다.

- 그래서 `any P`를 제네릭 함수에 넘기면 그 안에서는 사실상 `some P`처럼 동작한다. 동적 디스패치 비용이 경계에서 한 번만 나고 안쪽은 특수화될 수 있다
- 컨테이너를 관찰하려면 제네릭 경계를 통과시키지 말아야 한다. struct 프로퍼티로 담으면 `T`가 그 struct로 바인딩돼 컨테이너가 그대로 보인다
- 실용적 함의: **`any`를 받는 API라도 내부에서 제네릭 함수로 넘기면 그 지점에서 열린다.** `any`의 비용은 "담아두는 동안"에 있고, 넘길 때마다 무는 게 아니다

### extension 메서드는 오버라이드되지 않는다

첫 번째 증상의 정체다. 이 절이 Phase 3에서 제일 자주 쓰인다.

```swift
protocol Greeter {
    func hello()                                 // 요구사항
}
extension Greeter {
    func hello() { print("default hello") }
    func bye()   { print("default bye") }        // 요구사항 아님
}
struct Korean: Greeter {
    func hello() { print("안녕") }
    func bye()   { print("안녕히") }              // 오버라이드처럼 보이지만 아니다
}

let g: any Greeter = Korean()
g.hello()
g.bye()
```

```
요구사항 hello() →   안녕
비요구사항 bye()  →   default bye
```

`Korean`이 `bye()`를 구현했는데도 기본 구현이 불린다. 프로토콜 **선언부에 없는** extension 메서드는 witness table에 안 들어가서 정적으로 결정된다.

- 커스터마이즈 지점으로 열 메서드는 반드시 프로토콜 선언부에 요구사항으로 적는다
- extension은 기본 구현을 주는 곳일 뿐이다
- 이걸 틀리면 커스텀 스타일이 조용히 무시되는 버그가 된다. 컴파일 에러도 경고도 없다

### 프로토콜로 안 되는 것

- 저장 프로퍼티를 둘 수 없다. 공통 상태는 값 타입으로 뽑아 합성한다
- 계층이 깊어지면 "이 메서드가 어디서 왔는지" 찾는 비용이 커진다
- 구현이 하나뿐인 프로토콜은 대개 이르다. 두 번째 구현이 나타날 때 뽑는다

---

## 4. 제네릭 — 제약과 조건부 준수

컴포넌트 API를 짜다 보면 "원소가 X면 컨테이너도 X" 같은 규칙이 필요해진다. 조건부 준수가 그 자리를 채운다.

```swift
protocol CSSToken { var raw: String { get } }
struct ClassToken: CSSToken { let raw: String }

extension Array: CSSToken where Element: CSSToken {          // 조건부 준수
    var raw: String { map(\.raw).joined(separator: " ") }
}

func render(_ token: some CSSToken) -> String { token.raw }  // 파라미터 위치
func chipTokens(active: Bool) -> some Collection<String> {    // 반환 위치
    active ? ["chip", "chip--active-brand"] : ["chip"]
}
```

```
[ClassToken]도 CSSToken이 된다: "chip chip--md"
opaque 반환: ["chip", "chip--active-brand"]
```

- 조건부 준수는 `Array`를 건드리지 않고 규칙만 얹는다. 재귀적 합성이 공짜로 생긴다
- opaque return은 구체 타입을 감추면서 정적 디스패치를 유지한다. `some View`가 `any View`가 아닌 이유다
- 방향이 반대다. **파라미터 위치의 `some`은 호출자가, 반환 위치의 `some`은 구현자가** 타입을 고른다

---

## 5. `@resultBuilder`

### 왜 이걸 보는가

`@ViewBuilder`는 컴파일러 마법이 아니라 `@resultBuilder` 위에 얹힌 평범한 빌더다. 이걸 알면 SwiftUI에서 `if`를 쓸 때 무슨 일이 벌어지는지 짐작할 수 있다.

### 구문과 메서드의 대응

| 작성한 구문 | 호출되는 메서드 |
|---|---|
| 표현식 한 줄 | `buildExpression(_:)` |
| 여러 줄 나열 | `buildPartialBlock(first:)` + `buildPartialBlock(accumulated:next:)` |
| `if` (else 없음) | `buildOptional(_:)` |
| `if`/`else`, `switch` | `buildEither(first:)` / `buildEither(second:)` |
| `for ... in` | `buildArray(_:)` |
| 블록 최종 결과 | `buildFinalResult(_:)` |

### 직접 만들어 보기

디자인 시스템 Chip의 CSS 클래스를 조립해봤다. 흔한 Chip 스펙(활성·비활성·아이콘 유무)을 소재로 삼았다.

```swift
let result = classes {
    "chip"
    if isActive { "chip--active-brand" }               // buildOptional
    if size == "md" { "chip--md" } else { "chip--sm" } // buildEither
    for i in 0..<2 { "data-idx-\(i)" }                // buildArray
}
```

```
chip chip--active-brand chip--md data-idx-0 data-idx-1
```

### `if`가 타입을 갈라놓는다

- `if`/`else`가 `buildEither`로 번역되니 두 가지가 **서로 다른 타입**(앞가지/뒷가지)이 된다
- 그래서 조건이 뒤집히면 SwiftUI가 "같은 뷰의 변경"이 아니라 **다른 뷰로 교체**로 볼 수 있다. 상태나 애니메이션이 끊기는 원인이 여기다
- `@ViewBuilder`가 만드는 내부 타입 이름은 비공개라 의존하지 않는다. Demystify SwiftUI(WWDC21)의 identity 논의와 같은 이야기 ([§9](#9-검증-기록))
- 옛 자료의 "`@ViewBuilder`는 10개까지"는 `buildPartialBlock`(Swift 5.7) 이전 이야기다

---

## 6. 참조 순환

### 상황

콜백을 프로퍼티로 들고 있는 타입은 거의 다 후보다. ViewModel, 로더, 코디네이터.

```swift
final class Node {
    var onDone: (() -> Void)?
    deinit { print("deinit \(name)") }
}

do {
    let n = Node(name: "strong")
    n.onDone = { print("\(n.name) 실행") }              // 강한 캡처
}
do {
    let n = Node(name: "weak")
    n.onDone = { [weak n] in print("\(n?.name ?? "해제됨") 실행") }
}
```

```
strong 실행
스코프 종료 — strong의 deinit이 위에 없으면 누수
weak 실행
deinit weak
스코프 종료 — weak의 deinit이 위에 있으면 정상 해제
```

`strong`의 `deinit`은 끝까지 찍히지 않는다. 객체가 클로저를 갖고 클로저가 객체를 갖는 2-사이클이다.

### weak냐 unowned냐

| | `weak` | `unowned` |
|---|---|---|
| 타입 | Optional | non-Optional |
| 해제 후 접근 | `nil` | 크래시 |
| 쓸 자리 | 상대가 먼저 사라질 수 있다 | 상대 수명이 확실히 더 길다 |

애매하면 `weak`. `unowned`는 "수명 보장을 내가 증명한다"는 주장이고, 리팩토링으로 그 전제가 깨지면 크래시로 나타난다.

### 자주 나오는 세 가지 모양

- 저장된 클로저. 위 예시
- `weak var`로 선언하지 않은 delegate
- `Timer`·`NotificationCenter`. 등록만 하고 해제하지 않으면 등록처가 대상을 붙잡는다

관용구는 하나다.

```swift
someAsyncWork { [weak self] result in
    guard let self else { return }
    self.apply(result)
}
```

### 순환과 수명 연장은 다르다

`Task { await self.load() }`는 순환이 아니다. Task가 끝날 때까지 `self`를 살려두는 것이고, 끝나면 풀린다. 반면 위 2-사이클은 스스로 풀리지 않는다. 둘을 같게 보면 `[weak self]`를 필요 없는 곳에 뿌리게 되고, 정작 필요한 작업이 조용히 취소된다.

---

## 7. 통과 기준 실습 — Button 96조합 해체

### 문제

흔한 디자인 시스템의 Button 변형 표를 그대로 옮기면 이렇게 된다.

| Prop | 값 | 개수 |
|---|---|---|
| Variant | `Solid` · `Outlined` | 2 |
| Color | `Primary` · `Assistive` · `Error` · `White` | 4 |
| Size | `Large` · `Medium` · `Small` | 3 |
| Icon Only | `True` · `False` | 2 |
| Disable | `True` · `False` | 2 |

`2 × 4 × 3 × 2 × 2 = 96`. body 하나가 96가지를 분기해야 한다.

문제는 코드량이 아니라 **늘어나는 방향**이다. 색 하나를 더하면 `2 × 3 × 2 × 2 = 24`개 조합이 새로 생기고, 그 24개가 전부 검증 대상이 된다.

### 스펙에도 이미 구멍이 있다

CSS를 보면 `Disabled 배경` 토큰이 Primary에만 있고(`Button.md:39-42`), 나머지 색은 `.btn:disabled { opacity: 0.4 }` 공통 규칙으로 처리된다(`:69`, override는 `:91`). 스펙 자체가 96조합을 다 정의하지 않았다. 축을 곱하는 설계는 코드보다 먼저 문서에서 구멍을 만든다.

### 축을 나눈다

판단은 하나다. **다섯 축은 서로 직교한다.** 곱집합으로 한 타입에 넣지 말고, 축마다 성격에 맞는 확장 지점을 따로 준다.

| 축 | 성격 | 기법 | 확장 방법 |
|---|---|---|---|
| Variant | 외형 알고리즘 | PAT 프로토콜 | 준수 타입 추가 |
| Color | 값 | `struct` + `static let` | 상수 추가 |
| Size | 값 | `struct` + `static let` | 상수 추가 |
| Icon Only | 콘텐츠 구조 | 제네릭 슬롯 + 조건부 확장 | `where Label == Image` |
| Disable | 환경 상태 | 표준 `@Environment(\.isEnabled)` | 없음, 있는 걸 쓴다 |

### 코드

```swift
// 외형을 값이 아니라 타입으로 만든다
protocol DSButtonStyling {
    associatedtype Body: View      // PAT
    @ViewBuilder func makeBody(_ configuration: DSButtonConfiguration) -> Body
}

struct DSButtonConfiguration {
    // 타입 소거를 이 한 지점에 격리한다
    // SwiftUI의 ButtonStyleConfiguration.Label과 같은 트릭
    struct Label: View {
        fileprivate let content: AnyView
        var body: some View { content }
    }
    let label: Label
    let metrics: ButtonMetrics
    let palette: ButtonPalette
    let isPressed: Bool
    let isEnabled: Bool
    let isIconOnly: Bool
}

// 콘텐츠는 슬롯으로 받는다
struct DSButton<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dsButtonStyling) private var styling
    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label)
}

// Label이 Image일 때만 존재하는 이니셜라이저
extension DSButton where Label == Image {
    init(icon: Image, action: @escaping () -> Void)
}
```

쓸 때는 축이 따로 움직인다.

```swift
DSButton("취소") {}
    .dsButtonStyling(OutlinedButtonStyling())
    .dsButtonColor(.assistive)

DSButton(icon: Image(systemName: "xmark")) {}

DSButton("비활성") {}
    .disabled(true)              // 표준 modifier 그대로

DSButton {} label: {       // 슬롯이라 새 prop이 필요 없다
    HStack(spacing: 6) { Image(systemName: "sparkles"); Text("AI 추천") }
}

VStack {                          // 한 번 적용하면 자식이 상속
    DSButton("확인") {}
    DSButton("삭제") {}.dsButtonColor(.error)
}
.dsButtonSize(.large)
```

전체는 [`Swift/code/phase0/component_api.swift`](code/phase0/component_api.swift). `swiftc -typecheck` 통과.

### 결과

| | Before | After |
|---|---|---|
| 표현할 조합 | 96 | 축이 독립이라 곱해지지 않는다 |
| 선언 개수 | enum 3개 + prop 5개, body가 전부 분기 | 스타일 타입 2 + 토큰 상수 7 + 이니셜라이저 3 = **12** |
| 색 1개 추가 | **+24 조합** | **+1 선언** |
| Variant 1개 추가 | **+48 조합** | **+1 타입**, 기존 코드 수정 없음 |
| disabled | prop (×2) | 환경값 재사용, 추가 0 |

곱셈을 덧셈으로 바꾼 것이 전부다.

### 대가

- PAT는 정적 디스패치와 조합 자유를 주지만, 환경에 담으려면 타입 소거가 필요하다. `associatedtype Body`를 가진 프로토콜의 existential로는 `makeBody`를 부를 수 없다
- 그래서 `AnyButtonStyling`을 만들고 `AnyView` 비용을 한 지점에 몰아넣었다. SwiftUI도 `ButtonStyle`을 환경에 담을 때 같은 값을 치른다. [§3](#3-프로토콜--pat와-some--any)의 "`any`는 박싱과 동적 디스패치를 부른다"가 설계 결정으로 나타나는 자리다
- `isIconOnly`는 `Bool`로 남겼다. 외형이 아니라 레이아웃 축(정사각 프레임, 패딩 0)이라 스타일 타입으로 쪼갤 이유가 없고, 곱셈이 아니라 덧셈으로 들어온다. 목표는 `Bool` 박멸이 아니라 곱집합 제거다

### 주장을 실제로 확장해서 확인했다 (2026-07-31)

위 결과 표는 **설계를 보고 추론한 것**이었다. `-typecheck`만 돌렸으니 "+1 선언"도 "기존 코드 수정 없음"도 해 본 게 아니라 그럴 것이라고 적은 것이다. 그래서 실제로 축 세 개를 늘려 봤다.

[`code/phase0/component_api_extensions.swift`](code/phase0/component_api_extensions.swift) — **새 파일 하나만 만들고 `component_api.swift`는 열지 않았다.**

| 늘린 축 | 추가한 것 | 기존 코드 수정 |
|---|---|---|
| 색 (`ButtonPalette`) | `static let warning` — **1 선언** | 0줄 |
| 치수 (`ButtonMetrics`) | `static let xlarge` — **1 선언** | 0줄 |
| 외형 (PAT) | `struct GhostButtonStyling` — **1 타입** | 0줄 |

수정 없음은 주장이 아니라 git이 판정한다:

```
$ git diff --quiet HEAD -- Swift/code/phase0/component_api.swift && echo "변경 0줄"
변경 0줄 — 원본 그대로
```

확장 후 색 5 × 외형 3 × 치수 4 × iconOnly 2 × disabled 2 = **240 조합**을 곱집합 설계라면 표현해야 한다(원래 96에서 +144). 실제로 쓴 코드는 **3 선언, 50줄**이다.

테스트 6건이 축 독립성을 확인한다 ([`code/phase0Tests/`](code/phase0Tests/)):

```
swift test --filter ComponentAPITests    # 6건 통과 (0.001s)
```

- 새 색·치수가 기존 값을 덮어쓰지 않는다
- `GhostButtonStyling`이 `AnyButtonStyling`에 담긴다 — **`AnyButtonStyling`은 이 타입의 존재를 모르는데도** 담긴다. PAT 확장 지점이 실제로 열려 있다는 뜻
- 색 5 × 치수 4 = 20 조합을 만드는 데 추가 선언 0개

### 확장하다 걸린 것 — `fileprivate`가 렌더 검증을 막는다

`makeBody`가 실제로 무엇을 그리는지는 **테스트할 수 없었다.** `DSButtonConfiguration.Label`의 저장 프로퍼티가 `fileprivate`라 다른 파일에서 `Configuration`을 만들 수 없다.

```swift
struct Label: View {
    fileprivate let content: AnyView   // ← 다른 파일에서 생성 불가
    var body: some View { content }
}
```

이건 실수가 아니라 **SwiftUI가 `ButtonStyleConfiguration`에 하는 것과 같은 제약**이다. 프레임워크만 Configuration을 만들 수 있어야 스타일이 임의로 합성되는 걸 막는다. 대가는 스타일 단위 테스트가 렌더 없이는 불가능하다는 것이고, 그래서 **렌더 검증은 Phase 3 스냅샷의 몫으로 넘어간다**.

즉 이 설계에서 확장성은 컴파일러가 보증하지만 **외형의 정확성은 보증하지 않는다.** 둘을 같이 얻으려면 스냅샷 테스트가 필요하다.

### 자기 평가

- [x] `associatedtype`을 가진 프로토콜로 확장 지점을 만들었다
- [x] 제네릭 파라미터(`Label: View`)로 콘텐츠 슬롯을 열었다
- [x] 조건부 확장으로 특수 이니셜라이저를 제한했다
- [x] `some` / `any` / 타입 소거의 선택 근거를 비용으로 말할 수 있다
- [x] 확장 비용을 수치로 비교했다 (+24 vs +1)
- [x] **그 비교를 실제로 확장해서 확인했다** — 축 3개 추가, 기존 코드 0줄 수정 (git 판정), 테스트 6건

---

## 8. 스스로 물어볼 것

막히면 해당 절로 돌아간다.

- `struct` 안에 `class` 프로퍼티를 두면 무엇이 깨지고, SwiftUI에서 어떤 증상이 되는가 (§1)
- `try?`를 쓰면 안 되는 경계는 어디인가 (§2)
- `throws(E)`를 공개 API에 쓰면 무엇이 breaking change가 되는가 (§2)
- 프로토콜 extension에만 있는 메서드를 구현 타입이 재정의하면 어느 쪽이 불리는가, 왜 (§3)
- `some P`를 `any P`로 바꿔야 하는 상황 두 가지 (§3)
- primary associated type이 없는 PAT 프로토콜의 existential은 왜 쓸모가 없는가 (§3)
- `if`/`else`가 `@ViewBuilder`에서 어떤 메서드로 번역되고, 그게 뷰 identity에 왜 영향을 주는가 (§5)
- `Task { await self.f() }`와 저장된 클로저의 `self` 캡처는 어떻게 다른가 (§6)
- 조합 폭발 컴포넌트를 받았을 때 어떤 축을 프로토콜로 올리고 어떤 축을 토큰으로 내리는가 (§7)

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
| §1~6 데모 8개 | `swift Swift/code/phase0/phase0_demo.swift` | 전부 실행. 출력을 문서에 그대로 인용 |
| §3 existential 레이아웃 | `swift -swift-version 6 Swift/code/phase0/existential_layout.swift` | 컨테이너 40바이트, 인라인 버퍼 24바이트, 3회 반복 동일 |
| §7 컴포넌트 API | `swiftc -typecheck Swift/code/phase0/component_api.swift` | 에러·경고 0 |
| §7 확장 (2026-07-31) | `swift build --target ComponentAPI` | 통과 (3.39s) |
| §7 확장 테스트 | `swift test --filter ComponentAPITests` | **6건 통과** (0.001s) |
| §7 "기존 코드 수정 없음" | `git diff --quiet HEAD -- .../component_api.swift` | **변경 0줄** |

### 검증하지 못한 것

| 주장 | 상태 |
|---|---|
| 측정한 인라인 버퍼 크기(24바이트)의 안정성 | **구현 세부 [중]**. 이 환경(Swift 6.3.3·arm64)에서 3회 반복해 같았다. 다른 버전·아키텍처는 확인하지 않았다 |
| `@ViewBuilder`가 만드는 내부 타입 이름 | 미검증 **[중]**. 비공개 구현이라 "조건 분기가 타입을 갈라놓는다"는 성질만 썼다 |
| `@Entry` 매크로의 하위 OS 배포 범위 | 미검증 **[중]**. 이 환경(macOS 26 SDK) 컴파일만 확인. 하위 타깃이 필요하면 `EnvironmentKey`를 직접 선언 |
| §7 스타일이 실제로 그리는 외형 | **검증되지 않음.** `DSButtonConfiguration.Label.content`가 `fileprivate`라 다른 파일에서 `Configuration`을 만들 수 없어 `makeBody`를 호출할 수 없다. SwiftUI의 `ButtonStyleConfiguration`과 같은 제약이다 — [§7](#확장하다-걸린-것--fileprivate가-렌더-검증을-막는다) 참조. 렌더 검증은 Phase 3 스냅샷의 몫 |
| §7 설계가 iOS 실기기에서 동작하는지 | **검증되지 않음.** macOS 타겟으로만 빌드했다 |
| Phase 1·2·3과의 연결 서술 | **대조 완료 [중]**. 값 의미론·`@resultBuilder`·참조 순환은 [Phase 1a](phase1-swiftui-rendering.md)에서, 에러 설계는 [Phase 2-B §4](../Architecture/phase2-clean-layered.md#4-dto--domain-매핑-위치)에서 확인됐다. **PAT 항목은 어긋났다** — §0 표 아래 주석 참조 |

### 스펙 대조에서 나온 관찰

`Button.md`에 Disabled 색 토큰이 Primary에만 있다(`:39-42` vs `:69`, `:91`). 스펙 결함일 수도, 의도한 공통 규칙일 수도 있다. Figma가 SoT이므로 판단하지 않고 관찰만 남긴다. Phase 3에서 확인할 항목.

---

## 참고 자료

[study_list.md §1](../study_list.md#1-swift--swiftui)에서 Phase 0에 직접 쓰이는 것만.

- 📘 [The Swift Programming Language](https://docs.swift.org/swift-book/) — 기준 문서
- 📕 [Advanced Swift](https://www.objc.io/books/advanced-swift/) — 값 의미론·제네릭·메모리. Phase 0 주교재
- 📄 [Swift Evolution](https://www.swift.org/swift-evolution/) — typed throws(SE-0413), primary associated types(SE-0346), `buildPartialBlock`(SE-0348). 제안서 본문에 대안과 트레이드오프가 적혀 있다

다음은 Phase 1 — [SwiftUI 렌더링 모델](phase1-swiftui-rendering.md)과 [Swift Concurrency](../Concurrency/phase1-concurrency.md). §1의 값 의미론과 §5의 `@resultBuilder`가 거기서 바로 쓰인다.
