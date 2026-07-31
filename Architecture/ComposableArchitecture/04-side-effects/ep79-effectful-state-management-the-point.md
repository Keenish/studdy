# Ep. 79 — Effectful State Management: The Point

- 출처: [Point-Free Episode #79](https://www.pointfree.co/episodes/ep79-effectful-state-management-the-point)
- 코드: [0079-effectful-state-management-wtp](https://github.com/pointfreeco/episode-code-samples/tree/main/0079-effectful-state-management-wtp) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:47 | What's the point? |
| 4:13 | Composable, transformable effects |
| 11:16 | Reusable effects: network requests |
| 17:02 | Reusable effects: threading |
| 20:59 | Getting everything building again |
| 26:26 | Conclusion |

---

## 이 편이 하려는 것

세 편에 걸친 부수효과 작업의 결산이다. 에피소드 설명이 요지를 한 줄로 말한다 — 부수효과도 합성된다. 공통 부분을 뽑아 공유할 수 있고, 복잡한 효과는 단순한 조각으로 쪼갤 수 있다.

도입부가 지금까지의 난점도 짚는다. alert 표시 상태를 다루는 것과 스레딩 문제가 [Ep. 78](ep78-effectful-state-management-asynchronous-effects.md)의 고비였다고 언급한다.

## Effect가 타입이 된다

이 편에서 `Effect`가 `typealias`를 벗고 구조체가 된다.

```swift
public struct Effect<A> {
  public let run: (@escaping (A) -> Void) -> Void
}
```

담고 있는 함수 모양은 Ep. 78과 같다. 달라진 건 이제 **메서드를 붙일 수 있다**는 점이다. `map`이 대표적이다. 효과가 만들어 낼 액션을 다른 액션으로 바꾸는 변환인데, `typealias`였을 때는 자유 함수로만 쓸 수 있었다.

섹션 제목 "Composable, transformable effects"가 이 이야기다. 이 시리즈가 리듀서와 store에 했던 것을 효과에도 한다. 조각내고, 변환하고, 다시 붙인다.

## 재사용 가능한 효과

두 섹션이 실제 응용을 보여준다.

- **네트워크 요청** — API 호출마다 반복되는 부분을 효과로 뽑아 공유한다
- **스레딩** — 어느 큐에서 실행할지를 효과 위에 얹는 관심사로 다룬다

스레딩이 별도 섹션인 게 의미가 있다. 비동기 작업의 결과를 메인 큐로 되돌리는 일은 원래 호출 지점마다 흩어지기 쉬운데, 효과가 값이니 "이 효과를 메인 큐에서 받게 한다"는 변환을 따로 만들어 어디에나 붙일 수 있다.

여기서 [Ep. 71](../02-reducers-and-stores/ep71-composable-state-management-higher-order-reducers.md)의 고차 리듀서와 같은 발상이 반복된다. 감싸서 관심사를 얹는 방식이다. 대상이 리듀서에서 효과로 바뀌었을 뿐이다.

## 정리된 그림

도입부가 전체 구조를 요약한다.

- 리듀서는 효과 **배열**을 반환한다. 여러 효과가 병렬로 있는 형태다
- store가 그 효과들을 실행하고 결과 액션을 되먹인다
- 효과가 앱 상태를 바꿀 수 있는 유일한 길은 store에 액션을 보내는 것이다

마지막 항목이 단방향 흐름의 정의다. 효과가 아무리 많고 비동기여도 상태 변경 경로는 리듀서 하나로 유지된다.

## 다음으로

여기까지가 자체 제작한 `Effect`의 완성형이다. 그런데 Apple이 같은 문제를 푸는 프레임워크를 이미 내놨다. 그게 Combine이고, [Ep. 80](ep80-the-combine-framework-and-effects-part-1.md)부터 두 편에 걸쳐 대조한다.

## 참고자료

- [Elm: Commands and Subscriptions](https://guide.elm-lang.org/effects/) / [Redux: Data Flow](https://redux.js.org/basics/data-flow) — 단방향 흐름의 계보
- [Why Functional Programming Matters](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) — John Hughes, 1989. 이 편에서 다시 등장한다
- [Redux Middleware](https://redux.js.org/advanced/middleware) / [Redux Thunk](https://github.com/reduxjs/redux-thunk) / [ReSwift](https://github.com/ReSwift/ReSwift) / [SwiftUIFlux](https://github.com/Dimillian/SwiftUIFlux)
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연

## 확인 범위

- 영상이 유료라 결산의 내용과 재사용 효과의 구체적 구현은 확인하지 못했다
- `Effect` 구조체 정의는 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
