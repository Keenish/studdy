# Ep. 224 — Composable Navigation: Sheets

- 출처: [Point-Free Episode #224](https://www.pointfree.co/episodes/ep224-composable-navigation-sheets)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:32 | The "add item" feature |
| 9:12 | Integrating "add item" |
| 33:19 | The good, bad, and ugly |
| 42:18 | A better sheet API |
| 1:12:47 | Next time: effect cancellation |

---

## 이 편이 하려는 것

시트로 넘어간다. 도입부가 시트를 **상태 주도 내비게이션의 좋은 예**라고 부른다. 옵셔널 상태로 표시 여부를 제어하는 방식이 기능 단위와 잘 맞는다는 뜻이다.

알럿과 결정적으로 다른 점이 있다. 알럿은 자기 내부 로직이 없지만 시트는 **그 안에 온전한 기능이 들어간다.** 그래서 부모와 자식이 진짜로 통신해야 한다.

## 자기비판으로 시작한다

도입부가 [Ep. 223](ep223-composable-navigation-alerts-dialogs.md)을 되짚는다.

연산자가 dismiss 액션과 상태 비우기 같은 구현 세부를 잘 감춘 건 맞다. 그런데 확인 다이얼로그로 API를 넓힐 때 **전부 복사해 붙이고 이름만 바꿨다**고 인정한다.

시리즈가 자기 코드의 약점을 먼저 말하고 가는 패턴이 여기서도 반복된다.

## 좋은 점, 나쁜 점, 추한 점

33:19의 섹션 제목이 이 편의 성격을 보여준다. 기존 도구로 시트를 붙여 보고 나서 평가한다.

그 평가를 근거로 42:18부터 **더 나은 시트 API**를 만든다. 이 편이 가장 긴 축(1시간 14분)인 이유다.

## 확인 범위

- 영상이 유료라 새 시트 API의 실제 형태는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
