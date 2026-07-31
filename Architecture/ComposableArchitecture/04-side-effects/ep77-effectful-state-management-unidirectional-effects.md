# Ep. 77 — Effectful State Management: Unidirectional Effects

- 출처: [Point-Free Episode #77](https://www.pointfree.co/episodes/ep77-effectful-state-management-unidirectional-effects)
- 코드: [0077-effectful-state-management-unidirectional-effects](https://github.com/pointfreeco/episode-code-samples/tree/main/0077-effectful-state-management-unidirectional-effects) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-10-21
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:18 | Recap |
| 1:45 | Synchronous effects that produce results |
| 8:16 | Combining multiple effects that produce results |
| 10:15 | Pulling local effects back globally |
| 14:48 | Working with our new effects |
| 18:25 | What's unidirectional data flow? |
| 20:37 | Next time: asynchronous effects |

---

## 이 편이 하려는 것

[Ep. 76](ep76-effectful-state-management-synchronous-effects.md)의 `Effect`는 `() -> Void`라 밖으로 쓰기만 했다. 디스크에 저장은 되는데 불러올 수가 없다.

도입부에서 이 문제를 뷰 쪽 관점으로도 짚는다. 즐겨찾기를 디스크에 저장하는 것 같은 부수효과가 뷰에 남아 있으면 그건 **테스트할 수 없는 코드**다. 그 로직을 리듀서로 옮기고, 뷰는 사용자 액션을 store에 보내는 역할만 남긴다.

## 결과를 돌려주는 효과

효과가 값을 만들어 낼 수 있게 타입을 바꾼다.

```swift
public typealias Effect<Action> = () -> Action?
public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]
```

두 가지가 달라졌다.

- `Effect`가 `Action?`을 반환한다. 효과가 끝나면 액션을 하나 만들어 낼 수 있고, 만들 게 없으면 `nil`이다
- 리듀서가 효과를 **배열**로 반환한다. 하나의 액션이 여러 효과를 일으킬 수 있으니 자연스러운 변화다

배열이 되면서 합성 이야기가 따라온다. `combine`으로 리듀서를 묶으면 각 리듀서가 낸 효과들도 합쳐져야 하고, `pullback`으로 지역 리듀서를 끌어올리면 지역 효과가 내놓는 지역 액션도 전역 액션으로 바뀌어야 한다. 섹션 제목의 "Combining multiple effects"와 "Pulling local effects back globally"가 그 작업이다.

## 왜 액션으로 돌려주나

"What's unidirectional data flow?" 섹션이 이 설계의 이유를 설명한다.

효과가 상태를 직접 고치게 두면 변경 경로가 다시 여러 개가 된다. 01 섹션에서 겪은 문제로 돌아가는 셈이다. 대신 효과가 **액션을 만들어 store에 돌려주면**, 상태가 바뀌는 길은 여전히 리듀서 하나뿐이다.

흐름이 한 방향으로 고정된다.

```
액션 → 리듀서 → (상태 변경 + 효과 반환) → store가 효과 실행 → 새 액션 → 리듀서 → …
```

References가 이 계보를 밝힌다. Elm의 Commands and Subscriptions가 정확히 같은 구조이고, Redux의 Data Flow 문서가 단방향 흐름을 명시한다.

## 남는 문제

`() -> Action?`은 동기다. 호출하면 그 자리에서 답이 나와야 한다. 네트워크나 디스크 읽기처럼 시간이 걸리는 일은 이 모양에 담기지 않는다.

→ [Ep. 78](ep78-effectful-state-management-asynchronous-effects.md)

## 참고자료

- [Elm: Commands and Subscriptions](https://guide.elm-lang.org/effects/) — 효과가 결과를 액션으로 매핑해 리듀서에 되먹이는 구조. 이 편의 직접적 원형
- [Redux: Data Flow](https://redux.js.org/basics/data-flow) — 엄격한 단방향 흐름
- [Redux Middleware](https://redux.js.org/advanced/middleware) / [Redux Thunk](https://github.com/reduxjs/redux-thunk)
- [ReSwift](https://github.com/ReSwift/ReSwift) / [SwiftUIFlux](https://github.com/Dimillian/SwiftUIFlux)

## 확인 범위

- 영상이 유료라 논증의 세부는 확인하지 못했다
- 타입 정의와 시그니처는 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
