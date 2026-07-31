# Ep. 196 — Async Composable Architecture: Tasks

- 출처: [Point-Free Episode #196](https://www.pointfree.co/episodes/ep196-async-composable-architecture-tasks)
- 코드: [0196-tca-concurrency-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0196-tca-concurrency-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-07-11
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:36 | Testing async-received actions |
| 12:34 | Introducing TaskResult |
| 18:12 | An existential digression |
| 36:28 | A universal thought experiment |
| 43:06 | TaskResult equality and ergonomics |
| 51:07 | Next time: streams |

---

## 이 편이 하려는 것

[Ep. 195](ep195-async-composable-architecture-the-problem.md)가 문제를 넷 늘어놨다. 이 편은 그중 테스트와 에러 처리를 푼다.

도입부가 `Effect.task`로 얻는 것을 먼저 정리한다.

- 의존성 클라이언트가 `Effect`를 반환하지 않고 그냥 `async` 함수면 된다
- 실제 구현과 목 구현이 둘 다 단순해진다
- 비동기 작업을 손으로 합성하지 않고 그대로 이어 쓴다
- 시간 관련 작업이 없으면 스케줄러를 아예 뺄 수 있다

그리고 제약을 못 박는다. **테스트가 단연 가장 중요한 기능**이고, 테스트 가능성을 해치는 기능은 절대 넣지 않으려 한다는 것이다. [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 세운 기준이 그대로 유지된다.

## TaskResult

이 편의 결과물이다.

Swift의 `Result`는 실패 타입이 제네릭이라 `Result<String, Error>`처럼 쓰면 `Equatable`이 되지 않는다. `Error`는 존재 타입이라 비교할 수 없기 때문이다.

그런데 이 아키텍처의 테스트는 액션을 값으로 비교한다. 에러를 액션에 담아야 하는데([Ep. 195](ep195-async-composable-architecture-the-problem.md)에서 본 `numberFactResponse(.failure(...))`) 그 액션이 비교되지 않으면 테스트를 쓸 수 없다.

`TaskResult`가 그 자리를 메운다. 에러를 담되 값으로 비교할 수 있는 형태다.

"TaskResult equality and ergonomics" 섹션(43:06~51:07)이 그 동등성 문제를 다룬다.

## 존재 타입 여담

18:12부터 43:06까지, 이 편의 절반 가까이가 존재 타입(existential type) 이야기다. 섹션 제목도 "An existential digression"과 "A universal thought experiment"로 붙어 있다.

`TaskResult`를 만들려면 "타입이 지워진 에러를 어떻게 비교할 것인가"를 풀어야 하고, 그게 Swift의 존재 타입과 전칭 타입(universal type)의 차이로 이어진다. 에피소드 설명도 복잡한 타입 문제를 풀기 위해 존재 타입을 탐구한다고 밝힌다.

Point-Free답게 실용적 필요에서 출발해 언어의 타입 이론까지 파고드는 대목이다.

## 참고자료

이 섹션 여섯 편이 모두 같은 자료 하나를 건다.

- [Collection: Concurrency](https://www.pointfree.co/collections/concurrency) — Brandon Williams & Stephen Celis. 스레드·오퍼레이션 큐·디스패치·Combine부터 언어 내장 도구까지 Swift 동시성 전반을 다룬 컬렉션. 이 섹션의 배경 지식이 거기 있다

## 확인 범위

- 영상이 유료라 `TaskResult`의 실제 정의와 존재 타입 논의의 세부는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 샘플의 라이브러리 복사본이 이 섹션 여섯 편에서 동일해 코드로 대조하지 못했다
