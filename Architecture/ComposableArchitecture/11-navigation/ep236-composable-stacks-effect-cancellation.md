# Ep. 236 — Composable Stacks: Effect Cancellation

- 출처: [Point-Free Episode #236](https://www.pointfree.co/episodes/ep236-composable-stacks-effect-cancellation)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-05-22
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:41 | Automatic effect cancellation |
| 9:38 | Child-driven dismissal |
| 20:22 | A more precise StackAction |
| 32:18 | Fixing a child dismissal bug |
| 36:47 | Next time: testing stack navigation |

---

## 이 편이 하려는 것

[Ep. 225](ep225-composable-navigation-effect-cancellation.md)에서 트리 쪽에 했던 일을 스택에 반복한다. 효과 자동 취소와 자식이 스스로 닫기다.

도입부가 [Ep. 235](ep235-composable-stacks-state-ergonomics.md)의 성과를 먼저 확인한다. 새 기능이 쉽게 붙고, 스택에 올라간 기능에서 일어나는 일에 즉각적이고 무한한 통찰을 얻는다.

그런데 문제가 하나 남아 있었다고 짚는다. **자식 기능이 닫힐 때 그 효과가 취소되지 않았다.** 화면이 스택에서 빠져나갔는데 효과는 계속 돌고 있는 상태다.

[Ep. 231](ep231-composable-stacks-vs-trees.md)에서 예제로 "효과를 가진 카운터"를 고른 게 여기서 값을 한다. 효과 없는 기능이었다면 이 문제가 드러나지 않았다.

## StackAction을 더 정밀하게 (20:22)

이 편에서 가장 긴 구간이다.

스택에서 일어나는 일을 액션으로 표현하는데, 그 표현이 충분히 정밀하지 않았던 것으로 보인다. 화면이 밀려 들어가는 것, 빠져나가는 것, 자식이 스스로 닫는 것이 서로 구별돼야 취소를 정확히 걸 수 있다.

[02 섹션](../02-reducers-and-stores/00-overview.md) 이래 이 아키텍처의 원칙이 "일어난 일을 액션으로 표현한다"였는데, 그 표현의 해상도를 높이는 작업이다.

## 버그 수정 (32:18)

자식 닫기 관련 버그를 잡는다. 이 시리즈가 리팩터링 중 나온 버그를 별도 섹션으로 다루는 패턴이 또 나온다.

## 확인 범위

- 영상이 유료라 `StackAction`의 실제 형태와 취소 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
