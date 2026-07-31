# 09 · Async Composable Architecture — 여섯 편 흐름

Point-Free [Async Composable Architecture](https://www.pointfree.co/collections/composable-architecture/async-composable-architecture) 섹션(Ep. 195~200)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 196~199는 영상이 유료라 섹션 제목·도입부·References만 확인했다. **195와 200은 무료라 트랜스크립트 전문을 근거로 정리했다.** 이 섹션은 샘플의 라이브러리 복사본이 편마다 동일해 코드 diff로 추적하지 못했다

관련 문서

- [ep195 — The Problem](ep195-async-composable-architecture-the-problem.md) · async/await를 얹으면 뭐가 깨지는지 (무료)
- [ep196 — Tasks](ep196-async-composable-architecture-tasks.md) · `TaskResult`와 존재 타입
- [ep197 — Schedulers](ep197-async-composable-architecture-schedulers.md) · 시간을 어떻게 통제할까
- [ep198 — Streams](ep198-async-composable-architecture-streams.md) · 액션을 여러 번 보내기
- [ep199 — Effect Lifetimes](ep199-async-composable-architecture-effect-lifetimes.md) · 효과 수명을 뷰에 묶기
- [ep200 — In Practice](ep200-async-composable-architecture-in-practice.md) · 실제 앱으로 검증 (무료)

---

## 2년의 공백

08 섹션이 Ep. 99에서 끝나는데 여기는 Ep. 195부터다. 2020년 4월과 2022년 7월 사이다.

그 사이 TCA가 오픈소스로 공개됐고([Ep. 98](../08-ergonomics/ep98-ergonomic-state-management-part-1.md)이 예고한 대로), Point-Free는 다른 시리즈들을 진행했다. 그러니 이 섹션의 코드는 **이미 널리 쓰이는 라이브러리**를 고치는 작업이다. 앞 섹션들처럼 처음부터 짓는 게 아니다.

섹션 설명도 이걸 "**2020년 5월 첫 공개 이후 라이브러리에 가해진 가장 큰 업데이트**"라고 부른다.

## 이 섹션이 하는 일

[04 섹션](../04-side-effects/00-overview.md)에서 `Effect`를 Combine `Publisher`로 만들었다. 2019년엔 그게 최선이었지만 Swift에 언어 차원의 동시성이 들어왔다.

목표는 구조적 동시성으로 복잡한 효과를 만들고, 효과 수명을 뷰 수명에 묶는 것이다. 조건이 하나 붙는다 — **테스트 가능성을 유지하면서.**

## 여섯 편이 쌓이는 순서

### Ep. 195 — 문제부터 (무료)

해법을 만들지 않고 async/await를 그냥 얹으면 뭐가 깨지는지만 보인다.

- **Sendable 위반** — `@Sendable` 클로저가 리듀서의 `inout` 상태를 못 잡는다. `[count = state.count]`처럼 손으로 캡처해야 한다
- **에러 처리 불일치** — `Effect.task`가 던지지 않는 클로저만 받아 do/catch로 감싸고 예외를 액션으로 직접 바꿔야 한다
- **테스트 불안정** — 효과가 아직 돈다는 실패가 나서 `XCTWaiter`로 0.1초씩 기다리게 된다. 기계마다 결과가 다르다
- **의존성 두 벌** — 전환기라 Combine용과 async용 엔드포인트를 나란히 구현한다

핵심 긴장은 이것이다. async/await의 이점(단순함, 스케줄러 제거)과 이 아키텍처의 원칙(**즉시 실행되는 완전히 결정적인 테스트**)이 부딪힌다. [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 세운 기준이라 양보할 수 없다.

### Ep. 196 — TaskResult

Swift의 `Result`는 실패 타입이 존재 타입이라 `Equatable`이 안 된다. 그런데 이 아키텍처의 테스트는 액션을 값으로 비교한다. 에러를 액션에 담아야 하는데 비교가 안 되면 테스트를 쓸 수 없다.

`TaskResult`가 그 자리를 메운다. 편의 절반 가까이가 존재 타입 논의인데, 실용적 필요에서 출발해 언어의 타입 이론까지 파고드는 Point-Free다운 대목이다.

도입부가 제약을 못 박는다. 테스트가 단연 가장 중요하고, 테스트 가능성을 해치는 기능은 넣지 않는다.

### Ep. 197 — 시간

`Task.sleep`을 쓰면 테스트가 실제로 기다린다. 1초 지연을 검증하려고 테스트가 1초를 쓸 수는 없다.

당분간 Combine의 `Scheduler`를 async처럼 감싸는 절충을 택한다. 도입부가 `Clock` 프로토콜 같은 새 도구가 나오고 있다고 언급하는데, **과도기의 선택**이라는 뜻이다. 지금 TCA는 클럭을 쓰므로 이 편의 결론을 현재 코드에 그대로 적용하면 안 된다.

### Ep. 198 — 여러 액션 보내기

`Effect.task`는 결과를 하나 만들고 끝난다. 타이머처럼 계속 값을 내보내거나 긴 계산이 진행 상황을 보고하는 경우가 안 담긴다.

액션을 여러 번 보낼 수 있는 헬퍼를 만든다. [Ep. 200](ep200-async-composable-architecture-in-practice.md)에서 `.run { send in }` 형태로 쓰이는 걸 볼 수 있고, `AsyncStream`이 그 바탕이다.

### Ep. 199 — 수명

효과의 수명을 뷰 수명에 묶는다. 뷰가 사라지면 자동 취소된다.

걸림돌은 Swift에 **비동기 `deinit`이 없다**는 점이다. 그래서 액션에서 `Task`를 돌려받는 방식을 택한다. 그 `Task`를 SwiftUI의 `.task` modifier에 물리면 프레임워크가 이미 하는 수명 관리에 얹을 수 있다.

### Ep. 200 — 실물로 검증 (무료)

예제 앱이 아니라 실제 출시된 게임 isowords의 코드를 옮기며 전후를 비교한다.

첫 예제가 대비를 잘 보여준다. 색 순환 애니메이션이 Combine에서는 `keyFrames` 헬퍼까지 써서 12줄이었는데, `.run` 안에서 반복문과 `sleep`으로 3줄이 된다.

isowords 사례 중 표현이 좋은 건 홈 화면 인증 흐름이다. Combine에서는 **우발적 복잡도**였던 것이 이제 본질적인 비즈니스 로직만 남는다고 말한다.

## Ep. 195의 문제 넷이 어떻게 닫히는가

| Ep. 195의 문제 | 해결 |
|---|---|
| 에러 처리 불일치 | `TaskResult` (196) |
| 테스트 불안정 | `TaskResult`로 액션 비교 가능 (196), 효과 수명을 값으로 (199) |
| 스케줄러 의존 | 당분간 Combine `Scheduler` 감싸기 (197), 이후 `Clock`으로 |
| 의존성 두 벌 | 전환이 끝나면 async 쪽만 남는다 (200) |

Sendable 위반은 여전히 남아 있는 성격의 것이다. 리듀서가 `inout`으로 상태를 받는 구조([Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md)에서 성능 때문에 택한 모양)와 동시성 안전성이 근본적으로 부딪히기 때문이다.

## 결과물 API

- `.run { send in }` — 비동기 문맥에서 액션 여러 번 전송
- `.task` — 뷰 생명주기에 묶여 자동 취소
- `.fireAndForget` — 액션을 돌려주지 않는 작업
- `TaskResult` — 값으로 비교 가능한 에러 래퍼
- `withTaskCancellation(id:)` — 지정한 효과만 취소
- `ActorIsolated` — 테스트·프리뷰용 스레드 안전 가변 상태

## 가장 중요한 결과

효과를 전부 리팩터링했는데 **기존 테스트 스위트가 유의미한 변경 없이 통과했다.** 임의 대기도 타이밍 조정도 필요 없었다.

Ep. 196에서 "테스트 가능성을 해치는 기능은 넣지 않는다"고 한 게 지켜졌다는 증거이고, 이 섹션이 성공했다는 판정 기준이기도 하다.

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 195](ep195-async-composable-architecture-the-problem.md) 원문 — **무료다.** 문제 정의가 구체적이라 직접 보는 게 낫다
3. [Ep. 196](ep196-async-composable-architecture-tasks.md) → [197](ep197-async-composable-architecture-schedulers.md) → [198](ep198-async-composable-architecture-streams.md) → [199](ep199-async-composable-architecture-effect-lifetimes.md)
4. [Ep. 200](ep200-async-composable-architecture-in-practice.md) 원문 — **무료다.** 실제 앱 전후 비교라 이 섹션에서 가장 실용적이다

시간이 없으면 195와 200 원문 두 개만 봐도 이 섹션의 값은 대부분 얻는다.

## 확인 범위

확인한 것

- 195·200: 트랜스크립트 전문
- 196~199: 섹션 제목과 타임스탬프, 도입부, 에피소드 설명, References

확인하지 못한 것

- 196~199의 실제 API 시그니처와 구현. `TaskResult` 정의, 존재 타입 논의, 스케줄러 어댑터, 스트림 헬퍼가 모두 여기 해당한다

앞 섹션들과 달리 **코드로 대조하지 못했다.** 샘플에 `swift-composable-architecture` 체크아웃이 통째로 들어 있지만 여섯 편의 복사본이 서로 동일해서, 편별 변화를 추적할 수 없었다. 대신 무료 두 편이 API 목록과 사용 예를 담고 있어 결과물은 확인된다.
