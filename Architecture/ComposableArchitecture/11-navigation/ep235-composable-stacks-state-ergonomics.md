# Ep. 235 — Composable Stacks: State Ergonomics

- 출처: [Point-Free Episode #235](https://www.pointfree.co/episodes/ep235-composable-stacks-state-ergonomics)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-05-15
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:02 | Introducing StackState |
| 13:22 | Integrating StackState |
| 26:39 | Introspecting StackState |
| 43:10 | New feature, existing stack |
| 57:54 | Next time: effect cancellation |

---

## 이 편이 하려는 것

[Ep. 234](ep234-composable-stacks-action-ergonomics.md)가 액션 쪽을 다뤘으니 이번엔 상태 쪽이다.

문제는 기존 타입을 갖다 쓴 데서 온다. 스택 상태를 식별 가능한 배열(identified array)로 표현했는데, 그게 스택 용도로는 어색하다.

도입부가 증상을 든다.

- 기능들이 `Identifiable`과 `Hashable`을 어색하게 채택하고 있다. 도입부의 표현으로는 **"온갖 identifiable 광기"** 다
- 기능이 늘 때마다 `Path.State` enum의 프로토콜 준수를 유지하는 게 성가시다
- **통제되지 않는 UUID** 때문에 테스트가 복잡해진다

세 번째가 특히 실무적이다. 스택의 각 칸에 ID가 필요한데 그게 자동 생성 UUID면 테스트에서 값을 예측할 수 없다. [Ep. 83](../05-testing/ep83-testable-state-management-effects.md) 이래로 이 시리즈가 통제되지 않는 것을 어떻게 다뤄 왔는지 생각하면, 같은 문제가 여기서 다시 나온 셈이다.

## StackState

내비게이션 스택 전용 데이터 타입을 만든다. ID 생성과 프로토콜 준수를 타입이 책임지므로 기능 쪽이 그걸 신경 쓰지 않아도 된다.

## Introspecting (26:39)

들여다보기가 별도 섹션이다. [Ep. 236](ep236-composable-stacks-effect-cancellation.md) 도입부의 표현이 이 결과를 요약한다 — 스택에 올라간 기능에서 일어나는 모든 일에 **즉각적이고 무한한 통찰**을 얻는다는 것이다.

부모가 자식 스택의 상태를 읽고 조작할 수 있다는 뜻이고, 그게 테스트와 프로그래밍 방식 내비게이션의 기반이 된다.

## 새 기능 붙이기 (43:10)

만든 도구로 기존 스택에 기능을 추가해 본다. 14분을 쓰는 걸 보면 얼마나 쉬워졌는지 보이는 대목으로 짐작된다. 이 시리즈가 도구를 만든 뒤 그 값을 실제로 보이는 패턴이다.

## 확인 범위

- 영상이 유료라 `StackState`의 실제 정의와 ID 처리 방식은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
