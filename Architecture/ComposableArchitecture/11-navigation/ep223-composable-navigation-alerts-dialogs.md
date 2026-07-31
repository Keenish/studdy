# Ep. 223 — Composable Navigation: Alerts & Dialogs

- 출처: [Point-Free Episode #223](https://www.pointfree.co/episodes/ep223-composable-navigation-alerts-dialogs)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-02-20
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:48 | Alerts today |
| 13:49 | The problem |
| 22:17 | Reducer.alert |
| 41:08 | Confirmation dialogs |
| 59:40 | Next time: sheets |

---

## 이 편이 하려는 것

알럿부터 시작하는 이유를 도입부가 밝힌다. **가장 단순한 형태의 내비게이션**이기 때문이다. 뜨고, 닫히고, 선택적으로 액션을 낸다. 자기 내부 로직을 관리할 일이 없다.

그리고 목표를 다시 못 박는다. 순수 SwiftUI 기능도 나름 이점이 있지만 신중하게 써야 하고, 진짜 목적은 **기능을 합성하고 기능끼리 통신하게 만드는 것**이다. 그게 이 아키텍처의 핵심이라서다.

## 결과물 — Reducer.alert

새 리듀서 연산자를 만든다. 에피소드 설명이 두 가지 효과를 든다.

- 로직이 간결해진다
- 구현 세부를 감춘다

[Ep. 224](ep224-composable-navigation-sheets.md) 도입부가 무엇을 감췄는지 알려준다. 명시적인 dismiss 액션과 상태를 자동으로 비우는 처리다. 알럿이 닫힐 때 상태를 `nil`로 되돌리는 걸 매번 손으로 쓰지 않아도 된다.

[Ep. 67의 4.2](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)에서 지적한 "숨은 변경"과 통하는 대목이다. 당시 모달 재등장 버그도 불리언을 되돌리지 않아서 생겼는데, 이제 연산자가 그걸 맡는다.

## 확인 다이얼로그

41:08부터 확인 다이얼로그를 같은 방식으로 만든다. 그런데 [Ep. 224](ep224-composable-navigation-sheets.md) 도입부가 이 대목을 자기비판한다. 알럿과 사실상 같은 것인데 **전부 복사해 붙이고 이름만 바꿨다**는 것이다.

그 중복이 [Ep. 226](ep226-composable-navigation-unification.md)의 통합으로 이어진다.

## 확인 범위

- 영상이 유료라 `Reducer.alert`의 실제 시그니처와 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명, 그리고 다음 편 도입부의 회고에서 읽어낸 것이다
