# Ep. 232 — Composable Stacks: Multiple Layers

- 출처: [Point-Free Episode #232](https://www.pointfree.co/episodes/ep232-composable-stacks-multiple-layers)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:40 | Drilling down more layers |
| 13:32 | Number fact feature |
| 23:47 | Multiple destinations |

---

## 이 편이 하려는 것

[Ep. 231](ep231-composable-stacks-vs-trees.md)에서 만든 스택은 아직 **한 겹만** 들어간다. 여러 겹을 파고들 수 있게 만든다.

스택 기반의 존재 이유가 바로 이것이다. 깊이가 정해지지 않은 드릴다운을 다루려고 평평한 배열을 쓴다. 한 겹만 된다면 트리로 해도 충분하다.

## 두 가지 방식

에피소드 설명이 둘을 든다.

- 새 내비게이션 링크 API를 통한 방식 — 사용자가 탭해서 들어가는 경우
- 프로그래밍 방식 — 코드가 직접 스택을 조작하는 경우

후자가 스택 모델의 이점이다. 배열이니 여러 화면을 한 번에 밀어 넣거나 특정 지점까지 되돌아 나오는 게 자연스럽다. 딥링크나 "루트로 돌아가기" 같은 동작이 여기서 나온다.

## 새 기능 추가

13:32에서 숫자 사실(number fact) 기능을 만든다. [09 섹션](../09-async-composable-architecture/00-overview.md)에서도 쓰던 예제다.

23:47의 "Multiple destinations"는 스택에 **서로 다른 종류의 화면**이 섞이는 경우다. 카운터 다음에 숫자 사실 화면이 오는 식이다. 이게 [Ep. 233](ep233-composable-stacks-multiple-destinations.md)에서 본격적으로 다뤄진다.

## 확인 범위

- 영상이 유료라 실제 API와 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 이 편은 "다음 편 예고" 섹션이 없다. 24분으로 이 섹션에서 가장 짧다
