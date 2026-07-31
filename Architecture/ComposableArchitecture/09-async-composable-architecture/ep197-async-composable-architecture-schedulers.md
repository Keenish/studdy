# Ep. 197 — Async Composable Architecture: Schedulers

- 출처: [Point-Free Episode #197](https://www.pointfree.co/episodes/ep197-async-composable-architecture-schedulers)
- 코드: [0197-tca-concurrency-pt3](https://github.com/pointfreeco/episode-code-samples/tree/main/0197-tca-concurrency-pt3) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-07-18
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:56 | Timing effects |
| 15:56 | Async scheduling |
| 29:51 | Next time: streams |

---

## 이 편이 하려는 것

[Ep. 196](ep196-async-composable-architecture-tasks.md)까지 오면 리듀서에서 async/await를 직접 쓸 수 있다. 작업을 이어 붙이거나 병렬로 돌리는 것도 된다.

남은 게 **시간**이다. 도입부가 시간 기반 비동기는 여전히 문제라고 짚는다.

## 문제

`Task.sleep` 같은 걸 쓰면 테스트가 실제로 기다리게 된다. [Ep. 195](ep195-async-composable-architecture-the-problem.md)에서 본 임의 대기와 같은 함정이다. 1초 지연을 테스트하려고 테스트가 1초를 쓰면 안 된다.

Combine 시절엔 이 문제를 스케줄러로 풀었다. 테스트에서 즉시 진행하는 스케줄러를 주입해 시간을 제어했다. 그런데 async/await로 넘어오면서 그 장치가 어정쩡해진다.

## 해법 — 당분간 Combine의 Scheduler를 쓴다

도입부가 상황을 솔직히 말한다.

- Combine의 `Scheduler` 프로토콜이 스케줄링 기능을 제공한다
- Swift에 `Clock` 프로토콜 같은 새 도구가 나오고 있다

즉 언어 차원의 답이 아직 무르익지 않은 시점이다. 그래서 **Combine API를 async처럼 보이게 감싸는** 쪽을 택한다. 이주를 쉽게 하면서 테스트 가능성을 지키는 절충이다.

"Async scheduling" 섹션(15:56~29:51)이 그 작업으로 보인다.

## 이 편을 읽을 때 감안할 것

이건 **과도기의 선택**이다. 이후 Swift가 `Clock` 프로토콜을 정식으로 들이면서 Point-Free도 `swift-clocks` 라이브러리를 내놓는다. 지금 TCA는 스케줄러 대신 클럭을 쓴다.

그러니 이 편의 결론을 현재 코드에 그대로 적용하면 안 된다. 다만 "테스트에서 시간을 통제해야 한다"는 요구 자체는 변하지 않았고, 그걸 어떻게 풀지의 도구만 바뀌었다.

## 참고자료

- [Collection: Concurrency](https://www.pointfree.co/collections/concurrency) — Brandon Williams & Stephen Celis. 이 섹션 여섯 편이 공통으로 거는 자료

## 확인 범위

- 영상이 유료라 실제 스케줄러 어댑터 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- `Clock`으로 대체됐다는 서술은 이후 TCA의 방향에 대한 일반 지식이다. 이 에피소드에서 확인한 건 "`Clock` 같은 새 도구가 나오고 있다"는 언급까지다
