# Ep. 222 — Composable Navigation: Tabs

- 출처: [Point-Free Episode #222](https://www.pointfree.co/episodes/ep222-composable-navigation-tabs)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:38 | The inventory application |
| 18:21 | Feature composition |
| 36:51 | Testing |
| 42:11 | The "delegate" pattern |
| 50:56 | Comparing vanilla |
| 1:01:51 | Next time: alerts and dialogs |

---

## 이 편이 하려는 것

섹션의 문을 여는 편이다. 도입부에서 이 주제를 Point-Free가 **가장 오래 기다려온 것**이라고 부른다.

먼저 왜 이제서야 다루는지를 밝힌다. 선행 작업 두 가지가 필요했다.

- **라이브러리 현대화** — async/await 통합([09 섹션](../09-async-composable-architecture/00-overview.md)), result builder 문법을 쓰는 리듀서 프로토콜([10 섹션](../10-reducer-protocol/00-overview.md)), 그리고 별도 라이브러리로 분리된 의존성 관리
- **SwiftUI 내비게이션 자체의 정리** — iOS 16의 `navigationDestination`과 `NavigationStack`을 포함한 별도 시리즈

두 번째에서 나온 표현이 이 섹션 전체의 열쇠다. SwiftUI 내비게이션의 **"대통일 이론"** 을 발견했다는 것 — 알럿, 시트, 드릴다운이 전부 비슷한 API 모양을 공유한다는 관찰이다. 그래서 이 섹션이 형태별로 하나씩 만들다가 [Ep. 226](ep226-composable-navigation-unification.md)에서 통합할 수 있게 된다.

## 예제 앱

인벤토리 앱을 TCA로 옮기며 시작한다. 탭이 가장 단순한 형태라 첫 편의 소재다.

## 이 섹션이 실제로 다루는 것

제목은 탭이지만 시간 배분을 보면 초점이 다르다. 기능 합성(18:21)과 테스트(36:51), 그리고 delegate 패턴(42:11)에 대부분을 쓴다.

에피소드 설명도 합성 가능성, **기능 간 통신**, 테스트를 든다. 내비게이션 자체가 아니라 **화면이 서로 어떻게 대화하는가**가 이 섹션의 진짜 주제라는 신호다.

## delegate 패턴

자식 기능이 부모에게 무언가를 알려야 할 때 쓰는 방식이다. 자식이 부모를 직접 알면 모듈 경계가 깨지므로([03 섹션](../03-modularity/00-overview.md)에서 세운 원칙), 자식이 "이런 일이 일어났다"는 액션을 내보내고 부모가 그걸 해석한다.

UIKit의 델리게이트에서 이름을 빌렸지만 값과 액션으로 표현된다는 점이 다르다.

## 바닐라와 비교

마지막 섹션(50:56)이 순수 SwiftUI로 짠 것과 대조한다. [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 테스트로 했던 논증을 내비게이션에서 반복하는 셈이다.

## 확인 범위

- 영상이 유료라 실제 코드와 delegate 패턴의 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
