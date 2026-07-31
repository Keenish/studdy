# Ep. 84 — Testable State Management: Ergonomics

- 출처: [Point-Free Episode #84](https://www.pointfree.co/episodes/ep84-testable-state-management-ergonomics)
- 코드: [0084-testable-state-management-ergonomics](https://github.com/pointfreeco/episode-code-samples/tree/main/0084-testable-state-management-ergonomics) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-12-09
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:03 | Simplifying testing state |
| 6:50 | The shape of a test |
| 14:10 | Improving test feedback |
| 18:38 | Trailing closure ergonomics |
| 19:17 | Actions sent and actions received |
| 31:45 | Assertion edge cases |
| 35:18 | Conclusion |
| 40:50 | Next time: the point |

---

## 이 편이 하려는 것

[Ep. 83](ep83-testable-state-management-effects.md)에서 효과까지 테스트하게 됐다. 그런데 테스트 하나 쓰는 데 손이 너무 많이 간다.

도입부가 반복되는 단계를 나열한다.

- expectation을 만든다
- 효과를 실행한다
- expectation을 기다린다
- expectation을 충족시킨다
- 다음 액션을 붙잡는다
- 무슨 액션이 왔는지 검증하고 다시 리듀서에 먹인다

효과 하나에 이만큼이다. 이 의식(ceremony)을 줄이는 게 이 편의 목표다.

지향점도 분명하다. 테스트에서 신경 쓸 건 셋뿐이어야 한다.

- 초기 상태를 준다
- 테스트할 리듀서를 준다
- 액션과 기대값의 나열을 먹인다

## 테스트의 모양

"The shape of a test" 섹션이 이 아이디어다. 위 세 가지를 받는 헬퍼를 만들어 나머지를 감춘다.

"Trailing closure ergonomics"가 따로 있는 걸 보면 호출부가 읽히는 모양까지 다듬는다. Swift의 트레일링 클로저 문법을 이용해 액션 나열을 블록처럼 쓰는 식이다.

## 보낸 액션과 받은 액션

"Actions sent and actions received" 섹션이 이 편에서 개념적으로 가장 중요해 보인다. 시간 배분도 가장 길다(19:17~31:45).

이 아키텍처에서 액션은 두 갈래로 들어온다.

- **보낸 것** — 테스트가 직접 `send`한 액션. 사용자 행동에 해당한다
- **받은 것** — 효과가 실행돼 돌아온 액션. 네트워크 응답이나 디스크 읽기 결과다

테스트를 쓰려면 이 둘을 구분해서 기대해야 한다. "이 액션을 보내면 상태가 이렇게 되고, 뒤이어 저 액션이 돌아와서 상태가 또 이렇게 된다"는 식이다. [04 섹션](../04-side-effects/00-overview.md)에서 만든 단방향 흐름이 테스트에서 이렇게 드러난다.

## 실패했을 때 보이는 것

"Improving test feedback"과 "Assertion edge cases" 두 섹션이 실패 경험을 다룬다.

테스트 헬퍼를 만들면 편해지는 대신 실패 지점이 헬퍼 안으로 숨는 문제가 따라온다. 어느 줄에서 왜 틀렸는지 안 보이면 헬퍼가 오히려 방해가 된다. 여기에 별도 시간을 쓴다는 건 그 문제를 인지하고 다뤘다는 뜻이다.

엣지 케이스도 따로 다룬다. 기대한 액션이 안 오거나, 예상 못 한 액션이 더 오거나, 순서가 다른 경우들이다.

## 참고자료

이 편도 References가 셋뿐이다. 새 개념 없이 사용성만 다듬는 편이라 그렇다.

- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 헬퍼의 실제 시그니처와 구현은 확인하지 못했다. 위 내용은 섹션 제목과 도입부에서 읽어낸 것이다
- `ComposableArchitecture.swift`는 이 편에서도 130줄로 그대로다. 테스트 헬퍼는 아키텍처 모듈이 아니라 테스트 타깃 쪽에 있는 것으로 보인다
