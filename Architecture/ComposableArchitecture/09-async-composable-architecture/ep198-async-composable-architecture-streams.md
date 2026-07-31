# Ep. 198 — Async Composable Architecture: Streams

- 출처: [Point-Free Episode #198](https://www.pointfree.co/episodes/ep198-async-composable-architecture-streams)
- 코드: [0198-tca-concurrency-pt4](https://github.com/pointfreeco/episode-code-samples/tree/main/0198-tca-concurrency-pt4) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:07 | Timer counter |
| 8:27 | A better timer |
| 21:16 | Prime computation |
| 39:43 | Next time: effect lifetimes |

---

## 이 편이 하려는 것

`Effect.task`로 비동기 문맥을 얻었고 `sleep`으로 지연도 된다. 그런데 도입부가 빈 자리를 짚는다. **액션을 여러 번 돌려보내야 하는 효과**가 안 된다.

`task`는 결과를 하나 만들고 끝난다. 타이머처럼 계속 값을 내보내거나, 긴 계산이 중간 진행 상황을 보고해야 하는 경우가 담기지 않는다.

이걸 해결하면 복잡한 효과가 크게 단순해지고 Combine 의존도 더 줄어든다는 게 목표다.

## 예제 둘

**타이머** (1:07, 8:27)

액션을 반복해서 보내는 가장 단순한 사례다. 섹션이 "Timer counter"와 "A better timer"로 나뉜 걸 보면, 먼저 만들어 보고 나서 개선하는 순서다.

Combine 시절 TCA에는 `Effect.timer` 헬퍼가 따로 있었다. 구조적 동시성에서는 반복문과 `sleep`으로 자연스럽게 표현되니 별도 헬퍼가 덜 필요해진다.

**소수 계산** (21:16, 이 편에서 가장 길다)

긴 계산이 진행 상황을 중간중간 보고하는 사례로 보인다. 한 번에 결과 하나가 아니라 여러 값을 흘려보내는 형태다.

## 결과물

에피소드 설명이 말하는 건 `Effect`에 붙는 헬퍼 하나다. 비동기 문맥에서 액션을 **여러 번** 보낼 수 있게 해준다.

[Ep. 200](ep200-async-composable-architecture-in-practice.md)에서 이게 `.run { send in }` 형태로 쓰이는 걸 볼 수 있다. 클로저가 `send`를 받아 원하는 만큼 액션을 보낸다.

`AsyncStream`·`AsyncThrowingStream`이 그 바탕이다. Combine의 퍼블리셔가 하던 일을 언어 기본 도구가 대신한다.

## 참고자료

- [Collection: Concurrency](https://www.pointfree.co/collections/concurrency) — Brandon Williams & Stephen Celis

## 확인 범위

- 영상이 유료라 헬퍼의 실제 시그니처와 두 예제의 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명, 그리고 무료인 [Ep. 200](ep200-async-composable-architecture-in-practice.md)에서 이 API가 쓰이는 모습에서 읽어낸 것이다
- 샘플의 라이브러리 복사본이 이 섹션 여섯 편에서 동일해 코드로 대조하지 못했다
