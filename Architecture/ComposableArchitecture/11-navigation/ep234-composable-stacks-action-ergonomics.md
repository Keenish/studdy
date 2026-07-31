# Ep. 234 — Composable Stacks: Action Ergonomics

- 출처: [Point-Free Episode #234](https://www.pointfree.co/episodes/ep234-composable-stacks-action-ergonomics)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-05-08
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:41 | Defining NavigationStackStore |
| 17:16 | Using NavigationStackStore |
| 25:29 | Improving forEach |
| 36:17 | Next time: state ergonomics |

---

## 이 편이 하려는 것

[Ep. 233](ep233-composable-stacks-multiple-destinations.md)에서 스케치한 전용 도구를 실제로 만든다.

도입부의 진단이 분명하다. 기존 도구로 스택을 다루면 코드가 **장황하고 안전하지 않다.** 트리용으로 만든 걸 스택에 억지로 맞춰 쓰다 보니 생긴 결과다.

## NavigationStackStore

새 타입을 만든다. 도입부가 설계의 출처를 밝히는데, 트리 아크에서 만든 `PresentationState`와 `PresentationAction`에서 영감을 얻되 스택에 맞게 개념을 확장한다.

두 아크가 완전히 별개가 아니라는 뜻이다. 표시(presentation)를 다루는 방식이 하나 있고, 스택은 그것의 배열 버전에 가깝다.

## forEach 개선

25:29의 섹션이 눈에 띈다. `forEach`는 [02 섹션](../02-reducers-and-stores/00-overview.md) 시절부터 있던 연산자다. 컬렉션의 각 요소에 리듀서를 돌리는 도구인데, 스택도 결국 컬렉션이라 여기서 다시 쓰인다.

기존 연산자를 스택 용도에 맞게 다듬는 작업이다.

## 제목이 "Action" Ergonomics인 이유

이 편은 액션 쪽을, [Ep. 235](ep235-composable-stacks-state-ergonomics.md)는 상태 쪽을 다룬다.

상태와 액션을 짝지어 처리하는 게 이 시리즈의 오래된 습관이다. [Ep. 96](../07-adaptation/ep96-adaptive-state-management-actions.md) 도입부가 밝힌 원칙 그대로다 — 짝을 이루는 개념 중 한쪽에서 쓸모를 찾으면 즉시 다른 쪽도 본다. 리듀서(69·70), Store(73·74), ViewStore(95·96)에 이어 네 번째 반복이다.

## 확인 범위

- 영상이 유료라 `NavigationStackStore`의 실제 정의는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
