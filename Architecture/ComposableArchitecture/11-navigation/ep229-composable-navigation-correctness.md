# Ep. 229 — Composable Navigation: Correctness

- 출처: [Point-Free Episode #229](https://www.pointfree.co/episodes/ep229-composable-navigation-correctness)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-04-03
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:38 | Enum Navigation |
| 31:21 | A Nicer Destination Enum API |
| 42:22 | Testing Correctness |
| 1:07:21 | Next time: Efficient State Management |

---

## 이 편이 하려는 것

여섯 형태를 다 지원하게 된 대가를 치른다.

지금 도메인 모델은 옵셔널 프로퍼티 여러 개다. 그러면 **여러 화면으로 동시에 이동한 상태**가 타입상 표현 가능해진다. 도입부가 구체적으로 든 예가 `addItem`, `duplicateItem`, `editItem`이 전부 `nil`이 아닌 경우다.

숫자로 말하는 대목이 이 편의 핵심이다.

- 옵셔널 넷 → 표현 가능한 상태 **16가지**
- 그중 실제로 유효한 것 **5가지**

11가지가 말이 안 되는 상태인데 타입이 막아 주지 않는다.

## 답 — enum

옵셔널 여럿 대신 enum 하나를 쓴다. 그러면 케이스 중 정확히 하나만 성립하므로 유효한 상태만 표현된다.

[02 섹션](../02-reducers-and-stores/00-overview.md)에서 액션을 enum으로 모델링한 것과 같은 발상이 상태 쪽에 적용된다. Point-Free가 오래 밀어 온 "불가능한 상태를 표현 불가능하게 만들라"는 원칙 그대로다.

## 그런데 enum은 다루기 불편하다

31:21의 "A Nicer Destination Enum API"가 그 문제다.

[Ep. 70](../02-reducers-and-stores/ep70-composable-state-management-action-pullbacks.md)에서 이미 겪은 것이다. Swift에 enum용 key path가 없어서 케이스에 접근하려면 보일러플레이트가 필요했다. 상태를 enum으로 바꾸면 그 불편이 그대로 따라온다.

당시엔 enum property를 손으로 만들었고 CLI로 생성했는데, 이 시점에는 CasePath가 정리돼 있다. 그걸 내비게이션 도구에 맞게 다듬는 것으로 보인다.

## 정확성 테스트

42:22부터 25분을 쓴다. enum으로 바꿨으니 불가능한 상태가 실제로 불가능한지, 그리고 화면 전환이 의도대로 되는지 검증한다.

## 확인 범위

- 영상이 유료라 enum API의 실제 형태와 테스트 방법은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 16가지 중 5가지가 유효하다는 수치는 도입부에 명시된 것이다
