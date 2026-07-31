# 05 · Testing — 네 편 흐름

Point-Free [Testing](https://www.pointfree.co/collections/composable-architecture/testing) 섹션(Ep. 82~85)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 82~84는 영상이 유료라 섹션 제목·도입부·References만 확인했고, 코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT) 소스로 확인했다. **85는 무료 영상이라 트랜스크립트 전문을 근거로 정리했다**

관련 문서

- [ep82 — Reducers](ep82-testable-state-management-reducers.md) · 순수 함수라 준비 없이 테스트된다
- [ep83 — Effects](ep83-testable-state-management-effects.md) · Environment로 바깥세상을 갈아 끼운다
- [ep84 — Ergonomics](ep84-testable-state-management-ergonomics.md) · 반복되는 의식을 걷어낸다
- [ep85 — The Point](ep85-testable-state-management-the-point.md) · 바닐라 SwiftUI로 같은 테스트를 시도해 본다 (무료)

---

## 이 섹션이 하는 일

섹션 설명이 이렇게 연다. 아키텍처는 테스트 가능한 만큼만 강하다.

[Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)이 남긴 다섯 문제 중 **마지막**이다. 그리고 앞의 넷을 푼 방식이 여기서 배당금으로 돌아온다. 상태를 값 타입으로 만들고, 변경을 리듀서에 모으고, 모듈로 쪼개고, 효과를 값으로 반환하게 한 결정들이 전부 테스트 가능성에 기여한다.

## 네 편이 쌓이는 순서

### Ep. 82 — 리듀서는 그냥 테스트된다

리듀서는 `(inout Value, Action) -> [Effect<Action>]`, 즉 순수 함수다. 초기 상태를 만들고 액션을 넣고 결과를 보면 끝이다. 목 객체도 DI 컨테이너도 뷰 계층도 필요 없다.

세 리듀서를 차례로 테스트하고, 마지막에 통합 테스트를 다룬다. 작은 리듀서를 각각 검증하는 것과 `combine`·`pullback`으로 붙였을 때 잘 도는지는 다른 문제라서다.

### Ep. 83 — 효과는 갈아 끼운다

리듀서는 순수했지만 효과는 바깥세상과 얘기한다. 그대로 실행하면 실제 파일을 쓰고 실제 네트워크를 부른다.

답은 Environment다. 바깥과 얘기하는 함수들을 구조체에 모으고 전역 변수로 두되, 테스트에서 바꿔 끼운다.

```swift
struct FileClient {
  var load: (String) -> Effect<Data?>
  var save: (String, Data) -> Effect<Never>
}

var Current = FavoritePrimesEnvironment.live   // 테스트에서는 .mock
```

프로토콜이 아니라 **함수를 담은 구조체**인 게 특징이다. 목을 만들려고 클래스를 상속하거나 프로토콜을 구현할 필요 없이 클로저만 바꾸면 된다.

섹션 구성이 "Controlling …" 다음에 "Testing …"으로 반복되는 것도 메시지다. 의존성을 값으로 바꾸는 리팩터링이 먼저고 테스트는 그다음이다.

### Ep. 84 — 쓰기 편하게

효과까지 테스트되지만 한 건 쓰는 데 손이 너무 많이 간다. expectation 만들고, 효과 실행하고, 기다리고, 다음 액션 붙잡고, 검증하고, 다시 리듀서에 먹이고.

지향점은 셋만 신경 쓰는 것이다. 초기 상태, 테스트할 리듀서, 그리고 액션과 기대값의 나열.

개념적으로 중요한 건 **보낸 액션과 받은 액션의 구분**이다(시간 배분도 이 섹션이 가장 길다). 테스트가 직접 보낸 액션은 사용자 행동이고, 효과가 실행돼 돌아온 액션은 네트워크 응답이나 디스크 결과다. [04 섹션](../04-side-effects/00-overview.md)에서 만든 단방향 흐름이 테스트에서 이렇게 드러난다.

헬퍼를 만들면 실패 지점이 헬퍼 안으로 숨는 문제가 따라오는데, 거기에도 별도 섹션을 쓴다.

### Ep. 85 — 그래서 이게 필요했나 (무료)

18편 만에 스스로 묻는다. 방식이 정공법이라 이 편이 좋다. 아키텍처 없이 평범한 SwiftUI로 짠 같은 앱에 테스트를 써 보고, 어디서 막히는지 하나씩 보인다.

| 대상 | 막히는 지점 |
|---|---|
| 소수 모달 | `Binding`을 손으로 만들어야 하고, 로직을 메서드로 빼도 전수성이 사라진다 |
| 즐겨찾기 | 전수 검증하려면 결국 상태를 구조체로 묶고 계산 프로퍼티를 달아야 한다 |
| 카운터 (`@ObservedObject`) | `AppState`가 클래스라 멤버와이즈 이니셜라이저도 `Equatable` 합성도 없다. 필드 하나씩 확인하게 된다 |
| 카운터 (`@State`) | **근본적으로 안 된다.** 메서드가 값을 바꿔도 실제로 안 바뀐다. `@State`가 `UIHostingController` 맥락을 요구한다 |

결론은 테스트 가능한 바닐라 SwiftUI 같은 건 없다는 것이다. 시도한 모든 것이 로직을 뷰 밖으로 빼고, `@State`를 앱 상태로 올리고, 상태를 값 타입으로 묶으라고 요구했다. 이건 이 아키텍처가 내린 결정들과 사실상 같다. 그러니 리듀서와 액션으로 원칙 있게 가는 건 대안이 아니라 자연스러운 귀결이라는 주장이다.

## Ep. 67의 숙제, 전부 닫힘

| Ep. 67 | 한계 | 푼 섹션 |
|---|---|---|
| 4.1 | 영속 상태 API가 번거롭다 | (프레임워크가 `@Observable`로 해결) |
| 4.2 | 상태 변경이 흩어져 있다 | [02](../02-reducers-and-stores/) |
| 4.3 | 부수효과 이야기가 없다 | [04](../04-side-effects/) |
| 4.4 | 상태 관리가 합성되지 않는다 | [02](../02-reducers-and-stores/) · [03](../03-modularity/) |
| 4.5 | 테스트할 수 없다 | **이 섹션** |

01~05 섹션이 하나의 완결된 호를 이룬다. 문제 제기(01) → 변경 조직화(02) → 모듈화(03) → 부수효과(04) → 테스트(05). Ep. 85의 결론이 Ep. 67의 문제 제기와 정확히 맞물리며 닫힌다.

이후 섹션들([`06-dependency-management`](../06-dependency-management/) 이후)은 이 완성본을 다듬거나, Swift·SwiftUI의 변화에 맞춰 다시 짓는 이야기다.

## 영상 없이 볼 수 있는 것

- [Ep. 85](https://www.pointfree.co/episodes/ep85-testable-state-management-the-point) — **무료다.** 시리즈 전체의 결산이라 독립적으로도 읽힌다. 이 섹션에서 하나만 본다면 이것
- [How to Control the World](https://vimeo.com/291588126) — Stephen Celis, NSSpain 2018. Ep. 83의 Environment 패턴 강연. 무료
- [Structure and Interpretation of Swift Programs](https://www.youtube.com/watch?v=V-YvI83QdMs) — Colin Barrett, Functional Swift 2015. Environment 개념의 출처
- [episode-code-samples](https://github.com/pointfreeco/episode-code-samples) — 83편의 `FavoritePrimes.swift`가 87줄 → 189줄로 늘어나는데, 그 차이가 Environment 도입분이다

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 85](ep85-testable-state-management-the-point.md) 원문 — 무료이고 결산이라 먼저 봐도 좋다. 무엇이 문제인지 알고 82~84에 들어가면 잘 읽힌다
3. [Ep. 82](ep82-testable-state-management-reducers.md) → [83](ep83-testable-state-management-effects.md) → [84](ep84-testable-state-management-ergonomics.md)

## 확인 범위

확인한 것

- 82~84: 섹션 제목과 타임스탬프, 도입부, 에피소드 설명, References. Environment 구조는 저장소 소스로 확인
- 85: 트랜스크립트 전문

확인하지 못한 것

- 82~84의 실제 테스트 코드, Ep. 84 테스트 헬퍼의 시그니처와 구현

82~84에서 `ComposableArchitecture.swift`는 130줄로 변하지 않는다. 테스트를 위해 아키텍처 자체를 고치지 않았다는 뜻이고, 이 섹션의 주장을 뒷받침하는 사실이다.
