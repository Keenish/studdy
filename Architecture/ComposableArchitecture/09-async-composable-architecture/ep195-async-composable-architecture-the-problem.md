# Ep. 195 — Async Composable Architecture: The Problem

- 출처: [Point-Free Episode #195](https://www.pointfree.co/episodes/ep195-async-composable-architecture-the-problem)
- 코드: [0195-tca-concurrency-pt1](https://github.com/pointfreeco/episode-code-samples/tree/main/0195-tca-concurrency-pt1) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다.** 이 섹션에서 195와 200만 그렇다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:12 | A effectful demo |
| 14:00 | Testing effects |
| 20:50 | The problem with Effect.task |
| 39:00 | Next time: the solution |

---

## 이 편이 하려는 것

[04 섹션](../04-side-effects/00-overview.md)에서 `Effect`를 Combine `Publisher`로 만들었다. 그게 2019년이었고, 이제 Swift에 언어 차원의 동시성 도구가 생겼다.

이 편은 해법을 만들지 않는다. **async/await를 지금 아키텍처에 그냥 얹으면 뭐가 깨지는지**를 보이는 데 다 쓴다. Point-Free의 전형적인 순서다.

## 예제

숫자 사실(number fact)을 외부 API로 가져오는 카운터 앱을 쓴다. 그리고 `TestStore`로 상태 변화와 효과 출력을 빠짐없이(exhaustively) 검증하는 모습을 보인다. `store.send()`와 `store.receive()`가 그 도구다.

이 테스트가 이 편의 기준점이다. 뒤에서 async/await를 넣었을 때 무엇이 무너지는지 이걸로 판단한다.

## Combine 기반에서 불편한 것

**단순한 변환에도 연산자 체인이 필요하다**

가져온 문자열에 `!!!`를 붙이는 일에 `.map()`이 끼어든다. 그냥 문자열을 이어 붙이면 될 일인데 연산자를 거친다.

**여러 비동기를 엮으려면 연산자를 알아야 한다**

`map`, `flatMap`, `zip`을 익혀야 한다. async/await면 위에서 아래로 읽히는 코드다.

**스케줄러가 의존성으로 강제된다**

`mainQueue`를 환경에 넣어 다녀야 한다. 그런데 `Effect.task`는 main actor를 통해 출력을 메인 스레드로 알아서 전달한다. 필요 없는 의존성을 들고 다니는 셈이다.

## async/await를 얹으면 생기는 문제 넷

"The problem with Effect.task" 섹션이 이 편의 본론이다.

**1. Sendable 위반**

`Effect.task`의 클로저는 `@Sendable () async throws -> Action` 형태다. 리듀서의 `inout` 상태를 클로저 안에서 그대로 쓸 수 없다. 손으로 캡처해야 한다.

```swift
[count = state.count]
```

리듀서가 `inout`으로 상태를 받는 구조([Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md)에서 성능 때문에 택한 모양)와 동시성 안전성이 부딪히는 지점이다.

**2. 에러 처리가 안 맞는다**

`Effect.task`의 이니셜라이저는 던지지 않는 클로저만 받는다. 그래서 던지는 async 호출을 do/catch로 감싸고, 예외를 액션 페이로드로 직접 바꿔야 한다. `numberFactResponse(.failure(...))` 같은 식이다.

에러를 액션에 담는다는 원칙([Ep. 81](../04-side-effects/ep81-the-combine-framework-and-effects-part-2.md)에서 `Failure == Never`로 고정한 것)은 그대로인데, 그 변환을 매번 손으로 한다.

**3. 테스트가 불안정해진다**

가장 심각한 문제다. `Effect.task`로 바꾸면 테스트가 비결정적이 된다. 효과가 아직 돌고 있다는 실패가 나온다.

그래서 임의의 대기를 넣게 된다.

```swift
XCTWaiter.wait(for: [.init()], timeout: 0.1)
```

기계마다 결과가 달라지니 신뢰할 수 없다.

**4. 의존성을 두 벌 만들게 된다**

전환기 동안 클라이언트가 Combine용과 async용 엔드포인트를 둘 다 가져야 한다. `fetch: (Int) -> Effect<String, Failure>`와 `fetchAsync: @Sendable (Int) async throws -> String`을 나란히 두고 같은 걸 두 번 구현한다.

## 핵심 긴장

async/await가 주는 것(단순함, 읽기 쉬움, 스케줄러 제거)과 이 아키텍처의 핵심 원칙(**즉시 실행되는 완전히 결정적인 테스트**)이 부딪힌다.

[05 섹션](../05-testing/00-overview.md)이 그 원칙을 세웠고 [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 그게 이 아키텍처의 존재 이유라고 논증했다. 그러니 테스트를 희생하고 async를 얻는 선택지는 없다.

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
- 샘플에 `swift-composable-architecture` 체크아웃이 통째로 들어 있는데, 이 섹션 여섯 편의 라이브러리 복사본이 서로 동일하다. 편별 변화를 코드로 추적하지는 못했다
