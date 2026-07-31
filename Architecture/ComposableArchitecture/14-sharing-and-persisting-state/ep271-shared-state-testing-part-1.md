# Ep. 271 — Shared State: Testing, Part 1

- 출처: [Point-Free Episode #271](https://www.pointfree.co/episodes/ep271-shared-state-testing-part-1)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-03-18
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:11 | The problem with testing |
| 6:09 | How to test shared state |
| 22:38 | Testing improvements |
| 30:49 | Next time: advanced testing |

---

## 이 편이 하려는 것

[Ep. 269](ep269-shared-state-the-solution-part-1.md)~[270](ep270-shared-state-the-solution-part-2.md)에서 `@Shared`가 공유 문제를 잘 푸는 걸 보였다. 그런데 대가가 하나 남아 있다.

에피소드 설명이 정확히 짚는다. `@Shared`의 **참조 타입 기반이 이 아키텍처의 값 지향 테스트와 충돌한다.**

## 참조 타입이 왜 테스트하기 어려운가

도입부의 설명이 명료하다. 참조 타입은 **데이터와 동작이 뒤섞인 덩어리**라 테스트하기 악명 높고, **복사할 수 없어서** 상태 변경에 대한 단언이 복잡해진다.

이 아키텍처의 테스트 방식을 떠올리면 문제가 분명하다. [Ep. 243](../12-composable-architecture-1-0/ep243-tour-the-basics.md)에서 정리했듯 액션 전후의 상태를 **스냅샷으로 비교**하는 것이 전수 검증의 기반이었다. 값 타입이라 이전 상태의 사본을 들고 있다가 이후와 대조할 수 있었다.

참조 타입은 사본을 뜰 수 없으니 "이전 상태"라는 것이 존재하지 않는다. 변경하면 그냥 변경된 것만 남는다.

## 이 섹션의 성격

[05 섹션](../05-testing/00-overview.md) 이래 이 시리즈의 기준은 일관됐다. [Ep. 196](../09-async-composable-architecture/ep196-async-composable-architecture-tasks.md) 도입부의 표현으로는 **테스트 가능성을 해치는 기능은 절대 넣지 않으려 한다**는 것이다.

그러니 `@Shared`가 테스트를 망가뜨린다면 그건 미완성이다. 두 편을 들여 그걸 복구한다.

[Ep. 268](ep268-shared-state-the-problem.md)이 예고에서 "완전히 테스트 가능할 것"이라고 약속한 것도 그래서다.

## 확인 범위

- 영상이 유료라 실제 테스트 방식과 개선 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
