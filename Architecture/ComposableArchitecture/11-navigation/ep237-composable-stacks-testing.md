# Ep. 237 — Composable Stacks: Testing

- 출처: [Point-Free Episode #237](https://www.pointfree.co/episodes/ep237-composable-stacks-testing)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:25 | A basic test |
| 13:58 | Testing child effects |
| 26:10 | Testing child integration |
| 27:34 | Testing effectful navigation |
| 34:20 | Testing the summary |
| 43:27 | Testing child dismissal |
| 47:11 | Fixing problems with testing |
| 54:58 | Ergonomic testing |
| 1:05:36 | Conclusion |

---

## 이 편이 하려는 것

16편짜리 섹션의 마지막이다. 스택 내비게이션 앱에 **본격적인 테스트 스위트**를 쓴다.

도입부가 난이도를 밝힌다. 스택 도구는 표시(presentation) 도구보다 훨씬 복잡해서 테스트도 그만큼 어렵다는 것이다. 앞 편들에서 다른 기능의 단위 테스트를 보였지만 스택은 접근이 다르다.

## 도구의 부족함을 드러내는 방식

에피소드 설명이 이 편의 구조를 밝힌다. 테스트를 쓰다가 **지금까지 만든 도구의 부족한 점을 발견하고 하나씩 고쳐**, 결국 테스트하기 즐거운 도구 묶음에 이른다는 것이다.

섹션 구성이 그대로다.

- 1:25~43:27 — 여러 각도로 테스트를 써 본다
- 47:11 — 그 과정에서 드러난 문제를 고친다
- 54:58 — 테스트 사용성을 다듬는다

테스트가 설계를 검증하는 도구로 쓰이는 셈이다. [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 "테스트 가능성이 곧 아키텍처의 강도"라고 한 기준이 여기서도 작동한다.

## 테스트하는 것들

시간 배분을 보면 무엇이 어려웠는지 짐작이 된다.

| 시간 | 대상 |
|---|---|
| 13:58 | 자식 효과 (12분) |
| 27:34 | 효과가 있는 내비게이션 (7분) |
| 43:27 | 자식이 스스로 닫기 (4분) |

효과가 얽힌 것들이 대부분이다. [Ep. 236](ep236-composable-stacks-effect-cancellation.md)에서 취소를 붙였으니 그게 제대로 도는지 확인하는 자리다.

## 확인 범위

- 영상이 유료라 실제 테스트 코드와 발견된 문제, 결론의 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 이 섹션 16편 중 가장 긴 축(1시간 6분)이다
