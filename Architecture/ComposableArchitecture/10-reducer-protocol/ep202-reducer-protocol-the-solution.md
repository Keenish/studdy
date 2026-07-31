# Ep. 202 — Reducer Protocol: The Solution

- 출처: [Point-Free Episode #202](https://www.pointfree.co/episodes/ep202-reducer-protocol-the-solution)
- 코드: [0202-reducer-protocol-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0202-reducer-protocol-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-08-29
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:16 | The protocol |
| 9:04 | Operator conformances |
| 24:36 | Refactoring leaf features |
| 41:25 | Refactoring combined features |
| 52:03 | Next time: composition |

---

## 이 편이 하려는 것

[Ep. 201](ep201-reducer-protocol-the-problem.md)이 늘어놓은 문제를 푸는 첫 편이다.

도입부가 개선 목표 다섯을 정리하는데 201의 문제 다섯과 그대로 대응한다.

- 상태·액션·로직의 조직화
- 컴파일러 성능 — 타입 추론과 자동완성을 살릴 것
- 합성된 리듀서의 가독성
- 의존성 관리의 사용성
- 깊은 콜 스택의 성능

해법은 한 문장으로 요약된다. **리듀서 앞에 프로토콜을 두고**, 깊게 중첩된 이스케이핑 클로저 대신 **프로토콜을 준수하는 구체 타입**으로 리듀서를 만든다.

## 왜 프로토콜인가

201의 문제들이 대부분 "리듀서가 값(클로저)이라서" 생겼다.

- 클로저라 이름공간에 담기지 않았다
- 클로저라 타입 추론이 압박받았다
- 클로저라 인라인되지 않았다

리듀서를 타입으로 만들면 셋이 한꺼번에 풀린다. 기능마다 구조체를 하나 만들고 그 안에 상태·액션·로직을 담으면 조직화가 되고, 구체 타입이라 컴파일러가 추론할 게 줄고, 프로토콜 준수는 인라인될 수 있다.

[Ep. 79](../04-side-effects/ep79-effectful-state-management-the-point.md)에서 `Effect`를, [Ep. 98](../08-ergonomics/ep98-ergonomic-state-management-part-1.md)에서 `Reducer`를 `typealias`에서 구조체로 올린 것과 같은 방향이다. 이번엔 구조체에서 프로토콜로 한 단계 더 올라간다.

## 연산자도 타입이 된다

"Operator conformances" 섹션(9:04~24:36)이 이 편의 핵심으로 보인다.

기존에 `pullback`, `combine`, `optional`, `forEach`는 리듀서를 받아 리듀서를 돌려주는 **메서드**였다. 프로토콜 체계에서는 각각이 **프로토콜을 준수하는 타입**이 된다.

`Publisher`에서 `map`이 `Publishers.Map` 타입을 만드는 것과 같은 구조다. 그러면 합성 결과가 구체 타입으로 남아 인라인이 가능해지고, 타입 시스템이 조합의 정당성을 검사할 여지도 생긴다.

## 두 갈래 리팩터링

- **말단 기능** (24:36) — 로직이 직접 들어 있는 단순한 기능
- **합성된 기능** (41:25) — 여러 하위 기능을 조립하는 기능

두 종류가 프로토콜을 준수하는 방식이 달라진다. 이 불일치가 [Ep. 204](ep204-reducer-protocol-composition-part-2.md)에서 다시 다뤄진다.

## 확인 범위

- 영상이 유료라 프로토콜의 실제 정의와 연산자 타입들의 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
