# Ep. 230 — Composable Navigation: Stack vs Heap

- 출처: [Point-Free Episode #230](https://www.pointfree.co/episodes/ep230-composable-navigation-stack-vs-heap)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-04-10
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:38 | Stack vs heap |
| 12:10 | Copy-on-write |
| 24:11 | Property-wrapped presentation |
| 31:11 | Fixing a bug with hidden state |
| 49:01 | Next time: Navigation stacks |

---

## 이 편이 하려는 것

트리 기반 내비게이션 아크의 마지막 편이고, 성능을 다룬다.

도입부가 흔한 우려를 소개한다. 앱이 커지고 기능이 중첩될수록 **루트 상태가 크게 부푼다.** 화면 A가 B를 품고 B가 C를 품는 식으로 값 타입이 중첩되면 최상위 구조체 하나가 앱 전체를 담게 된다. 스택 오버플로 걱정이 나올 만하다.

## 답의 절반은 이미 있다

도입부가 완화 요인을 짚는다. **컬렉션과 대부분의 문자열은 힙에 있다.** 구조체가 배열이나 문자열을 담고 있어도 스택에 놓이는 건 참조뿐이다.

앞의 두 섹션(2:38, 12:10)이 이 배경을 설명한다. 스택과 힙의 차이, 그리고 Swift의 copy-on-write다. 값 타입 의미론을 유지하면서도 실제 복사는 필요할 때만 일어나는 구조가 이 아키텍처가 값 타입을 마음껏 쓸 수 있는 근거였다.

## 도구에 효율을 심기

24:11의 "Property-wrapped presentation"이 결과물이다. 프로퍼티 래퍼로 표시 상태를 감싸 **효율을 내비게이션 도구 자체에 넣는다.**

쓰는 쪽이 성능을 신경 쓰지 않아도 되게 만드는 방향이다. [Ep. 229](ep229-composable-navigation-correctness.md)에서 enum으로 정확성을 얻은 것과 짝을 이룬다 — 정확성도 효율도 도구가 책임진다.

## 숨은 상태 버그

31:11의 섹션이 눈에 띈다. 프로퍼티 래퍼를 도입하면서 숨은 상태 관련 버그를 잡는다.

값이 어디에 저장되고 언제 복사되는지가 바뀌면 예상 못 한 동작이 나올 수 있다. 이 시리즈가 리팩터링 중 생긴 버그를 감추지 않고 별도 섹션으로 다루는 패턴이 여기서도 반복된다([Ep. 78](../04-side-effects/ep78-effectful-state-management-asynchronous-effects.md)의 "Refactor-related bugs"처럼).

## 여기서 아크가 바뀐다

다음 편부터 **스택 기반 내비게이션**으로 넘어간다. 지금까지는 기능이 기능을 품는 트리 구조였다면, 앞으로는 평평한 배열로 화면을 쌓는 구조다.

## 확인 범위

- 영상이 유료라 프로퍼티 래퍼의 실제 구현과 버그의 정체는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
