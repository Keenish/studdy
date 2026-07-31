# Ep. 76 — Effectful State Management: Synchronous Effects

- 출처: [Point-Free Episode #76](https://www.pointfree.co/episodes/ep76-effectful-state-management-synchronous-effects)
- 코드: [0076-effectful-state-management-synchronous-effects](https://github.com/pointfreeco/episode-code-samples/tree/main/0076-effectful-state-management-synchronous-effects) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-10-14
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:19 | Adding some simple side effects |
| 8:35 | Effects in reducers |
| 11:25 | Reducers as pure functions |
| 16:01 | Effects as values |
| 17:14 | Updating our architecture for effects |
| 23:44 | Reflecting on our first effect |

---

## 이 편이 하려는 것

[Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)이 남긴 숙제 넷 중 셋째다. 도입부에서 지금까지의 성적을 정리한다 — 상태 모델링, 리듀서를 통한 변경, 모듈 분해까지 끝났고 이제 부수효과 차례다.

목표는 부수효과를 **합성하고 변환할 수 있는 형태**로 모델링하는 것이다. 그냥 동작하게 만드는 게 아니라, 지금까지 리듀서와 store에 했던 것처럼 조각내고 다시 붙일 수 있어야 한다.

## 문제의 성격

섹션 제목 "Reducers as pure functions"가 핵심을 짚는다.

리듀서가 순수 함수라는 게 이 아키텍처의 전제였다. 같은 상태와 액션을 넣으면 항상 같은 결과가 나오니 추론도 되고 테스트도 된다. 그런데 리듀서 안에서 네트워크를 부르거나 디스크에 쓰면 그 전제가 깨진다.

그렇다고 부수효과를 뷰에 두면 앞 섹션에서 애써 모은 로직이 다시 흩어진다. 어딘가에는 있어야 하는데 리듀서를 더럽히면 안 된다.

## 답 — 효과를 값으로

"Effects as values" 섹션이 해법이다. 리듀서가 부수효과를 **실행하지 않고 값으로 반환**한다. 실제 실행은 store가 맡는다.

리듀서는 여전히 순수하다. "이런 일이 일어나야 한다"고 서술한 값을 돌려줄 뿐 스스로 하지 않는다. 실행이라는 불순한 부분은 아키텍처의 한 지점(store)에 격리된다.

그래서 리듀서 시그니처가 바뀐다.

```swift
public typealias Effect = () -> Void
public typealias Reducer<Value, Action> = (inout Value, Action) -> Effect
```

이 시점의 `Effect`는 단순하다. 인자도 반환값도 없는 클로저다. 실행하면 뭔가 일어나지만 결과를 돌려주지는 않는다. 흔히 fire-and-forget이라 부르는 형태다.

리듀서가 효과를 **하나만** 반환한다는 점도 눈에 띈다. 다음 편에서 배열로 바뀐다.

## 남는 문제

`() -> Void`라 밖으로 쓰기만 하고 읽어 올 수가 없다. 디스크에 저장은 되는데 불러올 수는 없는 상태다.

이걸 [Ep. 77](ep77-effectful-state-management-unidirectional-effects.md)에서 푼다.

## 참고자료

이 편의 References는 다른 Redux 계열이 부수효과를 어떻게 다루는지에 몰려 있다. 같은 문제를 남들은 어떻게 풀었는지 비교하는 셈이다.

- [Side Effects](https://www.pointfree.co/episodes/ep2-side-effects) — Point-Free #2. 부수효과를 함수 시그니처에 드러내 통제하는 방법. 이 편의 뿌리
- [Dependency Injection Made Easy](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy) — Point-Free #16
- [Redux Middleware](https://redux.js.org/advanced/middleware) / [Redux Thunk](https://github.com/reduxjs/redux-thunk) — Redux는 미들웨어로 푼다. 이 아키텍처가 택하지 않은 길
- [ReSwift](https://github.com/ReSwift/ReSwift) / [SwiftUIFlux](https://github.com/Dimillian/SwiftUIFlux) — 미들웨어 방식을 따른 Swift 구현들
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 논증의 세부는 확인하지 못했다
- 타입 정의와 시그니처는 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
