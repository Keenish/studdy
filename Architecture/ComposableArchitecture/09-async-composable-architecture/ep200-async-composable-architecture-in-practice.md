# Ep. 200 — Async Composable Architecture in Practice

- 출처: [Point-Free Episode #200](https://www.pointfree.co/episodes/ep200-async-composable-architecture-in-practice)
- 코드: [0200-tca-concurency-pt6](https://github.com/pointfreeco/episode-code-samples/tree/main/0200-tca-concurency-pt6) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다**

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:03 | SwiftUI Case Study: Animation |
| 11:54 | Demo: Speech Recognition |
| 41:05 | isowords: Playback Effects |
| 48:44 | isowords: Game Over Effects |
| 56:04 | isowords: Home Screen Effects |
| 1:02:02 | isowords: Upgrade Interstitial |
| 1:04:37 | Conclusion |

---

## 이 편이 하려는 것

10주에 걸친 작업의 결산이다. 그런데 예제 앱이 아니라 **실제 출시된 앱**으로 보인다. Point-Free가 만든 단어 게임 isowords의 실제 코드를 Combine 기반에서 async/await로 옮기며 전후를 비교한다.

이 시리즈가 결산 편마다 쓰던 방식이다. 주장 대신 실물을 보인다.

## 얼마나 줄어드는가

첫 예제가 색이 순환하는 애니메이션이다. Combine 시절엔 `keyFrames` 헬퍼까지 동원해 12줄이 필요했는데, `.run` 효과 안에서 반복문과 `sleep`으로 3줄이 된다.

이 대비가 이 편 전체의 논조다. 연산자로 표현하던 걸 그냥 순서대로 쓴다.

## 음성 인식 (11:54)

Apple 프레임워크를 감싸는 사례다. 의존성 모델링이 어떻게 진화하는지 보여준다.

- 전: `Effect`를 반환하는 구조체
- 후: 그냥 `async` 함수, 스트리밍이 필요한 곳은 `AsyncThrowingStream`

Combine 퍼블리셔가 하던 자리를 언어 기본 도구가 대신한다. 30분 가까이 쓰는 걸 보면 이 편에서 가장 공들인 부분이다.

## isowords 네 사례

**Playback Effects** (41:05) — 단어 재생 기능. 연산자를 이어 붙이던 걸 순차 `await`로 바꾸니 **위에서 아래로 읽힌다.**

**Game Over Effects** (48:44) — `withThrowingTaskGroup`으로 병렬 작업을 묶으면서 순차 의존성은 유지한다. 구조적 동시성의 장점이 드러나는 자리다.

**Home Screen Effects** (56:04) — 인증 흐름. 순차와 병렬이 섞여 있다. 이 대목의 표현이 좋다 — Combine에서는 **우발적 복잡도(accidental complexity)** 였던 것이 이제 본질적인 비즈니스 로직만 남는다.

**Upgrade Interstitial** (1:02:02) — `withTaskCancellation`으로 효과의 일부만 취소하고 나머지는 계속 돌린다.

## 이 시리즈가 만든 API

- `.run { send in }` — 비동기 문맥에서 액션을 여러 번 보낸다 ([Ep. 198](ep198-async-composable-architecture-streams.md))
- `.task` — 뷰 생명주기에 묶여 자동 취소되는 변형 ([Ep. 199](ep199-async-composable-architecture-effect-lifetimes.md))
- `.fireAndForget` — 액션을 돌려주지 않는 작업
- `TaskResult` — 값으로 비교 가능한 에러 래퍼 ([Ep. 196](ep196-async-composable-architecture-tasks.md))
- `withTaskCancellation(id:)` — 지정한 효과만 취소
- `ActorIsolated` — 테스트·프리뷰용 스레드 안전 가변 상태
- `AsyncThrowingStream` — Combine 퍼블리셔를 대체
- `withThrowingTaskGroup` — 병렬 작업 묶기
- `@preconcurrency import` — sendability 경고 억제

## 테스트는 어떻게 됐나

[Ep. 195](ep195-async-composable-architecture-the-problem.md)의 가장 큰 문제가 테스트 불안정이었다. 결과는 이렇다.

- 테스트 클래스에 `@MainActor`, 테스트 메서드는 `async`
- `send()`/`receive()`를 `await`로 호출

그리고 중요한 사실 하나. 효과를 전부 리팩터링했는데 **기존 테스트 스위트가 유의미한 변경 없이 통과했다.** 임의 대기도, 타이밍 조정도 필요 없었다.

[Ep. 196](ep196-async-composable-architecture-tasks.md) 도입부에서 "테스트 가능성을 해치는 기능은 넣지 않는다"고 못 박은 게 지켜졌다는 증거다.

## 결론

라이브러리 출시 이후 가장 큰 업데이트라고 평가한다. 그리고 async/await 덕에 효과 코드를 **위에서 아래로 읽히게** 쓸 수 있고, Combine의 `flatMap`·`merge`·`delay`가 만들던 간접 층이 사라진다고 정리한다.

마지막 주장이 세다. 구조적 동시성이 **Swift에서 비동기 코드를 테스트하는 가장 좋은 방법일 수 있다**는 것이다.

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
