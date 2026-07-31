# Ep. 226 — Composable Navigation: Unification

- 출처: [Point-Free Episode #226](https://www.pointfree.co/episodes/ep226-composable-navigation-unification)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:23 | Alert, dialog, sheet unification |
| 15:15 | Popovers |
| 21:47 | Covers |
| 23:35 | Tests |
| 26:55 | Next time: links |

---

## 이 편이 하려는 것

빚을 갚는 편이다.

알럿([Ep. 223](ep223-composable-navigation-alerts-dialogs.md)), 다이얼로그, 시트([Ep. 224](ep224-composable-navigation-sheets.md))를 각각 만들었는데 셋의 구조가 사실상 같다. 도입부가 이를 **반복된 코드 패턴으로 따로따로 만들었다**고 정리하고, 더 많은 표시 형태로 일반화하기 전에 통합이 먼저라고 말한다.

[Ep. 222](ep222-composable-navigation-tabs.md) 도입부에서 언급한 "SwiftUI 내비게이션의 대통일 이론"이 여기서 실현된다. 모든 내비게이션 형태가 비슷한 API 모양을 공유한다는 관찰이 하나의 도구로 정리된다.

## 통합의 배당금

통합하자마자 새 형태가 거의 공짜로 붙는다.

| 시간 | 형태 | 분량 |
|---|---|---|
| 1:23 | 알럿·다이얼로그·시트 통합 | 14분 |
| 15:15 | 팝오버 | 6분 |
| 21:47 | 커버(fullScreenCover) | 2분 |

팝오버와 커버가 각각 6분, 2분이다. 통합된 도구가 있으니 새 형태를 붙이는 게 그만큼 싸다는 뜻이다.

이 시리즈가 반복해 보여준 논증 방식이다. 추상을 제대로 잡으면 그 위에서 얻는 게 늘어난다.

## 테스트

23:35에 테스트가 따로 있다. 통합했으니 테스트도 하나로 정리된다.

## 확인 범위

- 영상이 유료라 통합된 도구의 실제 형태는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명, 그리고 각 섹션의 시간 배분에서 읽어낸 것이다
