# Ep. 231 — Composable Stacks: vs Trees

- 출처: [Point-Free Episode #231](https://www.pointfree.co/episodes/ep231-composable-stacks-vs-trees)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-04-17
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:31 | Tree- vs stack-based navigation |
| 16:03 | A counter feature with effects |
| 23:31 | Stack of counters |
| 45:17 | Next time: many destinations |

---

## 이 편이 하려는 것

섹션의 후반 아크가 시작된다. 도입부가 내비게이션 스택을 **Apple 플랫폼 내비게이션에서 가장 뜨거운 주제**라고 부른다.

## 두 가지 모델

이 편의 핵심은 1:31의 대조다.

**트리 기반** — 지금까지 다룬 방식이다. 기능이 다른 기능을 품고, 각 기능이 분기점이 된다. 상태가 중첩된 구조를 이룬다.

**스택 기반** — 평평한 배열이다. 값을 추가하면 화면이 밀려 들어가고 제거하면 돌아 나온다. iOS 16의 `NavigationStack`이 컬렉션 바인딩으로 화면 이동을 관리하는 방식이다.

둘 다 필요하다. 모달이나 알럿은 트리가 자연스럽고, 깊이가 정해지지 않은 드릴다운은 스택이 맞다. 이 섹션이 두 아크로 나뉜 이유다.

## 프로퍼티 래퍼가 여기서도 쓰인다

도입부가 [Ep. 230](ep230-composable-navigation-stack-vs-heap.md)에서 만든 프로퍼티 래퍼를 언급한다. 성능 문제를 해결하면서 **추가적인 내비게이션 능력도 열어 준다**는 것이다. 앞 편의 작업이 이 아크의 전제가 된다.

## 예제

효과를 가진 카운터 기능(16:03)을 만들고, 그걸 스택으로 쌓는다(23:31).

효과가 있는 기능을 고른 게 의도적이다. 스택에서 화면이 빠져나갈 때 그 화면의 효과를 어떻게 처리할지가 [Ep. 236](ep236-composable-stacks-effect-cancellation.md)의 주제가 된다.

## 확인 범위

- 영상이 유료라 실제 API와 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
