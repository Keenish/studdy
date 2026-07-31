# Ep. 269 — Shared State: The Solution, Part 1

- 출처: [Point-Free Episode #269](https://www.pointfree.co/episodes/ep269-shared-state-the-solution-part-1)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-03-04
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:12 | Shared state as a reference? |
| 11:06 | Improving the ergonomics of shared state |
| 25:48 | Complex flow case study |
| 39:05 | Next time: Adding another step to the flow |

---

## 이 편이 하려는 것

[Ep. 268](ep268-shared-state-the-problem.md)이 기존 방법 둘의 한계를 보였다. 값 타입은 동기화 부담이, 의존성은 보일러플레이트가 따른다.

도입부에서 던지는 질문이 이 섹션 전체를 연다. **처음부터 참조 타입을 기능 상태에 그냥 집어넣었으면 어땠을까?**

우회로를 계속 만드는 대신 그 발상을 실험해 보기로 한다.

## 왜 이게 파격인가

이 아키텍처는 상태를 값 타입으로 모델링하는 것이 근간이었다. [Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md)에서 `AppState`를 구조체로 만든 이래 한 번도 흔들린 적이 없는 원칙이다.

- 전수 테스트가 가능한 이유가 값 타입이라서다
- 스냅샷 비교와 `_printChanges()`도 거기서 나온다
- [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 바닐라 SwiftUI로 안 된다고 논증한 이유도 클래스 기반이라는 점이었다

그 원칙에 참조 타입을 들이는 것이니 정면으로 부딪히는 시도다. 섹션 설명도 이를 **통제된 방식으로 참조 타입을 도입**하되 이점은 지키고 단점은 최소화하는 것이라고 표현한다.

한 가지 전제가 바뀌었다는 점이 중요하다. [Ep. 273](ep273-shared-state-user-defaults-part-1.md) 도입부가 밝히듯, 참조 타입은 예전에 뷰 무효화와 잘 어울리지 않았는데 **Swift의 관찰 도구가 그 문제를 해결했다.** [13 섹션](../13-observable-architecture/00-overview.md)의 작업이 이 섹션의 전제 조건인 셈이다.

## 사용성 다듬기 (11:06)

참조를 그냥 넣는 것만으로는 쓰기 불편하다. 그걸 다듬는 과정에서 `@Shared` 프로퍼티 래퍼가 나온다.

## 회원가입 흐름 예제 (25:48)

여러 화면에 걸친 흐름을 케이스 스터디로 삼는다. 회원가입처럼 단계가 이어지는 흐름은 화면마다 같은 데이터를 조금씩 채워 나가므로, 공유 상태가 필요한 대표적 상황이다.

## 확인 범위

- 영상이 유료라 `@Shared`의 실제 정의와 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
