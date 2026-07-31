# Ep. 227 — Composable Navigation: Links

- 출처: [Point-Free Episode #227](https://www.pointfree.co/episodes/ep227-composable-navigation-links)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-03-20
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:35 | Links |
| 15:01 | Nicer links in TCA |
| 30:04 | Next time: Testing, and destinations |

---

## 이 편이 하려는 것

도입부의 문제 제기가 직설적이다. 내비게이션 도구에 **큰 구멍**이 있는데, 그게 사람들이 "내비게이션"이라는 말을 들었을 때 가장 먼저 떠올릴 그것 — **드릴다운**이라는 것이다.

지금까지 알럿, 다이얼로그, 시트, 팝오버, 커버를 다뤘는데 정작 화면을 밀어 넣는 기본 동작이 빠져 있었다.

## deprecated API로 만든다

이 편의 특이한 선택이다. `NavigationLink`의 옛 API를 쓴다. iOS 16에서 deprecated된 것들이다.

이유는 실용적이다. **대부분의 개발자가 여전히 iOS 16 미만을 지원한다**는 판단이다. 새 API만 다루면 당장 쓸 수 없는 사람이 많다.

iOS 16의 `navigationDestination`은 [Ep. 228](ep228-composable-navigation-destinations.md)에서 다룬다. 두 편으로 나눈 게 그래서다.

## 확인 범위

- 영상이 유료라 실제 API 형태는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 2023년 기준의 판단이다. 지금은 iOS 16 미만 지원이 훨씬 드물어졌으므로 이 편의 실용적 근거는 약해졌다. `navigationDestination` 쪽을 우선해 읽는 게 낫다
