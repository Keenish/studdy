# Ep. 259 — Observable Architecture: Sneak Peek

- 출처: [Point-Free Episode #259](https://www.pointfree.co/episodes/ep259-observable-architecture-sneak-peek)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다.** 이 섹션에서 259만 그렇다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 3:37 | The Observable Architecture |
| 11:20 | Even Smarter Observation |
| 21:09 | Next time: Naive Observation |

---

## 이 편이 하려는 것

결과를 먼저 보여주는 편이다. 구현은 다음 편부터고 여기서는 **무엇이 달라지는지**만 시연한다.

도입부의 평가가 강하다. async/await([09](../09-async-composable-architecture/00-overview.md)), 리듀서 프로토콜([10](../10-reducer-protocol/00-overview.md)), 내비게이션 도구([11](../11-navigation/00-overview.md))도 혁신적이었지만 **이번 변화는 그보다 훨씬 크다**는 것이다.

## 무엇이 사라지는가

핵심은 `ViewStore`가 없어진다는 것이다.

```
전: WithViewStore { viewStore in ... viewStore.count ... }
후: store.count
```

[07 섹션](../07-adaptation/00-overview.md)에서 성능 때문에 도입한 중간 객체다. 뷰가 필요한 상태만 보게 해서 불필요한 재렌더를 막는 게 목적이었는데, Swift 5.9의 Observation이 같은 일을 언어 차원에서 해 준다.

곁가지 도구들도 함께 불필요해진다 — `IfLetStore`, `ForEachStore`, `SwitchStore`.

## 새로 생기는 것

| API | 역할 |
|---|---|
| `@ObservableState` | 구조체용 관찰 매크로. Swift의 `@Observable`은 구조체에 못 붙는다 |
| `@Reducer` | 리듀서 정의 매크로 |
| `WithPerceptionTracking` | iOS 17 미만 백포트 |

`@ObservableState`가 따로 필요한 이유가 이 섹션 전체의 기술적 과제다. Swift의 `@Observable`은 클래스 전용인데 이 아키텍처는 상태를 값 타입으로 모델링한다([Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md) 이래의 원칙). 그 간극을 메우는 게 [Ep. 260](ep260-observable-architecture-structural-identity.md)부터의 작업이다.

## 더 똑똑한 관찰 (11:20)

시연이 인상적인 대목이다. 뷰에서 **실제로 읽은 프로퍼티만** 자동으로 추적된다.

토글로 특정 상태를 안 읽게 만들면 그 상태가 바뀌어도 뷰가 갱신되지 않는다. 구독 해제를 손으로 할 필요가 없다.

예전에는 이걸 하려면 뷰마다 `ViewState` 구조체를 만들어 필요한 필드만 옮겨 담아야 했다. [Ep. 95](../07-adaptation/ep95-adaptive-state-management-state.md)에서 만든 그 방식이다. 이제 그 보일러플레이트가 사라진다.

## iOS 17 미만

`WithPerceptionTracking`으로 감싸면 동작한다. 감싸는 게 필요하다는 점은 `WithViewStore`와 비슷해 보이지만 훨씬 단순하다고 밝힌다.

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
