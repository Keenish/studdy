# Ep. 233 — Composable Stacks: Multiple Destinations

- 출처: [Point-Free Episode #233](https://www.pointfree.co/episodes/ep233-composable-stacks-multiple-destinations)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-05-01
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:49 | Multiple destinations |
| 22:44 | Sketching out a better way |
| 29:40 | Next time: improving ergonomics |

---

## 이 편이 하려는 것

스택에 **종류가 다른 화면**을 섞는다. 에피소드 설명이 방식을 밝힌다. enum 하나로 여러 기능을 담고, 기존 API를 조금씩 고쳐 쓰다가, 스택 전용 도구를 새로 스케치한다.

[Ep. 229](ep229-composable-navigation-correctness.md)에서 트리 쪽 목적지를 enum으로 정리한 것과 같은 발상이다. 스택의 각 칸이 여러 기능 중 하나이므로 enum이 맞는 모양이다.

## 도입부의 다른 이야기 — 모듈화와 프리뷰

도입부가 본론과 별개로 실무 문제를 짚는데 기록해 둘 만하다.

숫자 사실 기능을 모듈로 분리하려는데 **의존성이 통제되지 않으면 곤란하다**는 이야기다. 구체적으로는 SPM 모듈에 Info.plist가 없어서 Xcode 프리뷰를 동작시키는 데 필요한 조치를 적용할 수 없고, 결국 시뮬레이터를 써야 한다는 것이다.

그러면 프리뷰의 이점인 빠른 반복이 사라진다. [Ep. 205](../10-reducer-protocol/ep205-reducer-protocol-dependencies-part-1.md)의 `@Dependency`와 [Ep. 208](../10-reducer-protocol/ep208-reducer-protocol-in-practice.md)의 `previewValue`가 왜 필요했는지가 여기서 다시 확인된다.

## 기존 API의 한계

22:44의 "Sketching out a better way"가 전환점이다. 지금 도구로 스택을 다뤄 보니 부족해서 전용 도구를 구상하기 시작한다.

그 구상이 [Ep. 234](ep234-composable-stacks-action-ergonomics.md)의 `NavigationStackStore`와 [Ep. 235](ep235-composable-stacks-state-ergonomics.md)의 `StackState`로 이어진다.

## 확인 범위

- 영상이 유료라 실제 구현과 스케치의 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
