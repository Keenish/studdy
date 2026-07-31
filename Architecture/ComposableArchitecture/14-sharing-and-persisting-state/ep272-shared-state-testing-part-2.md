# Ep. 272 — Shared State: Testing, Part 2

- 출처: [Point-Free Episode #272](https://www.pointfree.co/episodes/ep272-shared-state-testing-part-2)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-03-25
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:51 | Testing the sign up flow |
| 22:23 | Debugging shared state |
| 30:10 | Next time: ubiquity and persistence |

---

## 이 편이 하려는 것

[Ep. 271](ep271-shared-state-testing-part-1.md)에서 만든 방법을 실제 흐름에 적용한다. 대상은 [Ep. 269](ep269-shared-state-the-solution-part-1.md)~[270](ep270-shared-state-the-solution-part-2.md)에서 만든 회원가입 흐름이다.

## 성과

도입부가 결과를 요약한다. 참조 타입을 쓰는 기능을 **값 타입인 것처럼** 테스트하면서, 모든 측면을 **빠짐없이(exhaustively)** 검증한다.

이게 이 섹션의 목표였다. [Ep. 271](ep271-shared-state-testing-part-1.md)이 지적한 문제 — 참조 타입은 복사할 수 없어 전후 비교가 안 된다 — 를 넘어서고, [05 섹션](../05-testing/00-overview.md)이 세운 전수 테스트 기준을 지킨다.

깊게 중첩된 기능들이 같은 상태를 공유하는 상황도 단순하게 테스트된다고 밝힌다. 회원가입 흐름을 예제로 고른 게 그래서다. 여러 단계가 한 데이터를 함께 쓰는 실제적인 예다.

## 공유 상태 디버깅 (22:23)

리듀서에 디버깅 도구를 붙이는 이야기다. 그런데 방식이 흥미롭다. 에피소드 설명이 **공유 상태 기법을 써서** 디버깅 도구를 만든다고 밝힌다.

방금 만든 도구를 그 도구 자신의 개발에 쓰는 셈이다. [Ep. 71](../02-reducers-and-stores/ep71-composable-state-management-higher-order-reducers.md)의 고차 리듀서로 로깅을 붙이던 것과 같은 계열의 발상이다.

## 확인 범위

- 영상이 유료라 실제 테스트 코드와 디버깅 도구 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
