# Ep. 68 — Composable State Management: Reducers

- 출처: [Point-Free Episode #68](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores/ep68-composable-state-management-reducers)
- 코드: [episode-code-samples/0068-composable-state-management-reducers](https://github.com/pointfreeco/episode-code-samples/tree/main/0068-composable-state-management-reducers) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목과 도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:06 | Introduction |
| 3:19 | Recap: our app so far |
| 9:02 | A better way to model global state |
| 14:36 | Functional state management |
| 24:02 | Ergonomics: capturing reducer in store |
| 27:52 | Ergonomics: in-out reducers |
| 32:56 | Moving more mutations into the store |
| 40:05 | Till next time |

---

## 이 편이 하려는 것

[01 섹션](../01-swiftui-and-state-management/00-overview.md)에서 SwiftUI로 앱을 짜 보고 다섯 가지 한계를 정리했다. 이제 그걸 풀기 시작한다.

출발점은 리듀서다. 상태를 액션에 따라 바꾸는 함수 하나로 변경을 모으면 흩어진 변경 문제부터 해결된다. 이 편은 그 함수의 모양을 정하고, 그걸 담을 store를 만드는 데 쓴다.

Redux(JavaScript)와 Elm이 이 방식을 퍼뜨렸다는 계보를 밝히고 시작한다.

## 리듀서 함수의 모양

두 후보에서 고른다.

- `(State, Action) -> State` — 새 상태를 반환
- `(inout State, Action) -> Void` — 기존 상태를 직접 변경

후자를 택한다. 큰 자료구조를 복사 없이 바꿀 수 있어서다.

근거로 두 가지를 든다.

- 표준 라이브러리 `reduce`에도 두 변형이 있다. `(Result, Value) -> Result`와 `(inout Result, Value) -> Void`인데, 큰 자료구조에서는 후자가 유리하다. Chris Eidhof가 Swift 포럼에 정리한 내용이다
- 이 둘은 사실 같은 것이다. `(A) -> A`와 `(inout A) -> Void`가 동등하다는 건 Point-Free 2편에서 이미 다뤘다. 성능만 다른 표현이지 표현력이 달라지는 게 아니다

두 번째가 중요하다. 성능 때문에 `inout`을 택하지만 그렇다고 함수형 성질을 포기하는 건 아니라는 뜻이다.

## 액션을 enum으로

변경을 함수로 모으려면 "무슨 일이 일어났는지"를 값으로 표현해야 한다. 화면별로 enum을 두고 전역 enum이 그걸 감싼다.

```swift
enum CounterAction {
  case decrTapped
  case incrTapped
}
enum PrimeModalAction {
  case saveFavoritePrimeTapped
  case removeFavoritePrimeTapped
}
enum FavoritePrimesAction {
  case deleteFavoritePrimes(IndexSet)
}
enum AppAction {
  case counter(CounterAction)
  case primeModal(PrimeModalAction)
  case favoritePrimes(FavoritePrimesAction)
}
```

케이스 이름이 `decrTapped`, `saveFavoritePrimeTapped`처럼 **사용자가 한 행동**으로 붙어 있다. "카운트를 1 늘려라"가 아니라 "감소 버튼이 눌렸다"다. 무엇을 할지는 리듀서가 정한다.

이 중첩 구조가 Ep. 70에서 액션을 좁힐 때 그대로 쓰인다.

## 리듀서와 store

리듀서는 전역 상태와 전역 액션을 받아 스위치문으로 분기한다.

```swift
func appReducer(value: inout AppState, action: AppAction) -> Void
```

`AppState`는 구조체다. 01 섹션에서 클래스에 `BindableObject`를 붙였던 것과 달리, 상태 자체는 값 타입으로 두고 관찰은 store가 맡는다.

store는 리듀서를 감싸 들고 변경 통로 하나만 노출한다.

```swift
final class Store<Value, Action>: ObservableObject {
  let reducer: (inout Value, Action) -> Void
  @Published private(set) var value: Value

  func send(_ action: Action) {
    self.reducer(&self.value, action)
  }
}
```

세 가지가 눈에 띈다.

- 타입 이름이 `State`가 아니라 `Value`다. 이 시리즈 내내 이 이름을 쓴다
- `value`가 `private(set)`이다. 뷰는 읽을 수만 있고 바꾸려면 `send`를 거쳐야 한다. Ep. 67의 "변경이 흩어진다"를 타입 수준에서 막는 장치다
- 리듀서를 앱 곳곳에 넘기지 않는다. 쓰는 쪽은 store만 알면 된다

## 다음 편으로

리듀서 하나에 앱 전체 액션을 몰아넣으면 스위치문이 감당 못 하게 커진다. 그래서 쪼갰다 다시 붙이는 방법이 필요하다.

- 상태 방향 → [Ep. 69](ep69-composable-state-management-state-pullbacks.md)
- 액션 방향 → [Ep. 70](ep70-composable-state-management-action-pullbacks.md)
- 감싸서 기능 얹기 → [Ep. 71](ep71-composable-state-management-higher-order-reducers.md)

## 참고자료

에피소드 페이지의 References. 유료 구간 없이 볼 수 있는 자료들이다.

- [Reduce with inout](https://forums.swift.org/t/reduce-with-inout/4897) — Chris Eidhof, 2017-01. `reduce`의 두 형태와 `inout` 쪽의 효율. 이 편의 함수 모양 결정 근거
- [Side Effects](https://www.pointfree.co/episodes/ep2-side-effects) — Point-Free #2. `(A) -> A`와 `(inout A) -> Void`의 동등성
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams, 2017 Functional Swift Conference. 이 시리즈의 핵심 아이디어를 다룬 강연이고 무료다
- [Elm](https://elm-lang.org) — 앱을 상태와 액션에서 상태로 가는 순수 함수로 모델링하는 방식의 원류
- [Redux](https://redux.js.org) — Elm에서 영향받아 리듀서 방식을 대중화한 JavaScript 라이브러리

## 확인 범위

- 영상이 유료라 논증의 세부와 화면에서 실제로 짠 순서는 확인하지 못했다
- 코드는 공개 저장소 소스로 확인했다. 다만 저장소 코드는 이후 Swift·SwiftUI 변화에 맞춰 갱신됐을 수 있어 영상 시점과 정확히 같다는 보장은 없다 (예: 위 `ObservableObject`/`@Published`는 2019년 당시 `BindableObject`였다)
