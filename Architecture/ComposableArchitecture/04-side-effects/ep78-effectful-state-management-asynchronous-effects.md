# Ep. 78 — Effectful State Management: Asynchronous Effects

- 출처: [Point-Free Episode #78](https://www.pointfree.co/episodes/ep78-effectful-state-management-asynchronous-effects)
- 코드: [0078-effectful-state-management-async-effects](https://github.com/pointfreeco/episode-code-samples/tree/main/0078-effectful-state-management-async-effects) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:17 | Extracting our asynchronous effect |
| 6:25 | Local state to global state |
| 15:59 | The async signature |
| 21:55 | The async effect |
| 25:44 | Refactor-related bugs |
| 28:46 | Thinking unidirectionally |
| 34:35 | What's the point? |

---

## 이 편이 하려는 것

[Ep. 77](ep77-effectful-state-management-unidirectional-effects.md)의 `() -> Action?`은 동기다. 호출하면 그 자리에서 답이 나와야 한다. 디스크 읽기나 네트워크는 그 모양에 안 들어간다.

도입부가 이 차이를 분명히 한다. 디스크에서 불러오는 효과는 앞의 fire-and-forget과 성격이 다르다. 혼자 일하고 끝나는 게 아니라 **읽은 데이터를 리듀서에 돌려줘야** 한다.

## 시그니처 바꾸기

"The async signature" 섹션에서 타입이 다시 바뀐다.

```swift
public typealias Effect<Action> = (@escaping (Action) -> Void) -> Void
```

반환값으로 답을 주는 대신 **콜백을 받는다.** 효과는 자기 일이 끝나는 시점에 그 콜백을 불러 액션을 전달한다. 언제 부르든 상관없으니 비동기가 담긴다.

세 편에 걸친 변화를 나란히 놓으면 방향이 보인다.

| 편 | Effect | 할 수 있는 일 |
|---|---|---|
| 76 | `() -> Void` | 밖으로 쓰기만 |
| 77 | `() -> Action?` | 동기적으로 결과 반환 |
| 78 | `(@escaping (Action) -> Void) -> Void` | 비동기적으로 결과 전달 |

앞의 두 모양은 이 마지막 모양의 특수한 경우로 표현할 수 있다. 콜백을 즉시 부르면 동기고, 안 부르면 fire-and-forget이다.

## store가 하는 일

도입부가 store의 역할을 정리한다. store는 효과를 **해석**한다. 리듀서가 돌려준 효과를 실행하고, 거기서 나온 액션을 다시 리듀서에 먹인다.

이 되먹임 구조 덕에 상태가 바뀌는 길이 하나로 유지된다. 효과가 아무리 비동기여도 결과는 액션으로 들어오고, 액션은 리듀서만 통과한다.

## 리팩터링 버그

"Refactor-related bugs" 섹션이 따로 있는 게 눈에 띈다. 효과를 뷰에서 리듀서로 옮기는 과정에서 실제로 문제가 생겼다는 뜻이다.

"Local state to global state" 섹션과 묶어 보면 짐작이 간다. 뷰에 있던 alert 상태 같은 것들을 앱 상태로 끌어올려야 하는데, 그 과정에서 뷰가 들고 있던 것과 리듀서가 들고 있는 것이 어긋날 여지가 생긴다. [Ep. 79](ep79-effectful-state-management-the-point.md) 도입부도 alert 표시 상태 관리가 이 편의 난점이었다고 언급한다.

## 참고자료

- [Elm: Commands and Subscriptions](https://guide.elm-lang.org/effects/) — 순수 함수형 언어가 비동기 효과를 다루는 방식
- [Redux: Data Flow](https://redux.js.org/basics/data-flow) — 단방향 흐름
- [Redux Thunk](https://github.com/reduxjs/redux-thunk) — 클로저로 비동기 효과를 다루는 구현 예
- [Redux Middleware](https://redux.js.org/advanced/middleware) / [ReSwift](https://github.com/ReSwift/ReSwift) / [SwiftUIFlux](https://github.com/Dimillian/SwiftUIFlux)
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연

## 확인 범위

- 영상이 유료라 논증의 세부, 특히 어떤 버그가 났는지는 확인하지 못했다
- 타입 정의와 시그니처는 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
