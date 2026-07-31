# Ep. 204 — Reducer Protocol: Composition, Part 2

- 출처: [Point-Free Episode #204](https://www.pointfree.co/episodes/ep204-reducer-protocol-composition-part-2)
- 코드: [0204-reducer-protocol-pt4](https://github.com/pointfreeco/episode-code-samples/tree/main/0204-reducer-protocol-pt4) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-09-12
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:43 | Inspiration from SwiftUI |
| 14:55 | Primary associated types |
| 21:34 | Result builder type inference |
| 29:43 | Next time: dependencies |

---

## 이 편이 하려는 것

[Ep. 202](ep202-reducer-protocol-the-solution.md)에서 남은 어색함을 정리한다.

문제는 리듀서를 정의하는 방식이 **두 가지로 갈렸다**는 점이다.

- 말단 기능 — 로직을 직접 담는다
- 복잡한 기능 — 여러 하위 리듀서를 합성한다

도입부가 구체적인 증상을 든다. `VoiceMemos` 리듀서가 합성된 리듀서를 만드는데, 그걸 **오직 `reduce` 메서드를 부르기 위해서만** 만든다. 조립한 결과를 쓰는 게 아니라 한 번 호출하고 버리는 모양이다.

목표는 두 방식을 `ReducerProtocol` 하나 안에서 통합하고, 준수하는 쪽이 원하는 스타일을 고르게 하는 것이다.

## SwiftUI에서 빌려오기

"Inspiration from SwiftUI"가 답의 출처다.

SwiftUI의 `View`가 정확히 이 구조다. `body` 계산 프로퍼티에서 다른 뷰를 조립하되, 원시적인 뷰는 그리기 로직을 직접 갖는다. 하나의 프로토콜이 두 스타일을 다 받는다.

리듀서도 같게 만든다. 합성하는 기능은 `body`를 쓰고, 말단 기능은 `reduce`를 직접 구현한다. 어느 쪽이든 `ReducerProtocol`이다.

`View`가 `body`의 재귀를 끊기 위해 `Never`를 쓰는 것도 여기 그대로 온다. References에 [SE-0215](https://github.com/apple/swift-evolution/blob/main/proposals/0215-conform-never-to-hashable-and-equatable.md)(`Never`를 `Equatable`·`Hashable`에 준수)가 걸린 게 그 흔적이다.

## Primary associated types

Swift 5.7의 새 기능을 쓴다. [SE-0346](https://github.com/apple/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md)이 도입한 것으로, `some ReducerProtocol<State, Action>`처럼 연관 타입을 꺾쇠로 지정할 수 있게 해준다.

이게 없으면 `where Self.State == ..., Self.Action == ...` 같은 제약을 매번 길게 써야 한다. References가 이 기능이 **이 아키텍처의 사용성 있는 합성을 가능하게 했다**고 밝힌다.

이 섹션이 Swift 5.7에 얼마나 기대고 있는지 보여주는 대목이다. result builder, primary associated types 둘 다 그 버전 것이다.

## Result builder 타입 추론

마지막 섹션(21:34)이 빌더의 타입 추론 한계를 다룬다. References에 2020년 Swift 포럼의 result builder 제네릭 추론 논의가 걸려 있다.

빌더가 편의를 주는 대신 추론이 복잡해지는 지점이 있고, 그걸 다루는 것으로 보인다.

## 참고자료

- [SE-0346: Lightweight same-type requirements for primary associated types](https://github.com/apple/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md) — 2022-03. `some ReducerProtocol<State, Action>` 문법을 가능하게 한 제안
- [SE-0215: Conform Never to Equatable and Hashable](https://github.com/apple/swift-evolution/blob/main/proposals/0215-conform-never-to-hashable-and-equatable.md) — 2018-05
- Function builder generic parameter inference (Swift 포럼, 2020-04) — result builder의 타입 추론 한계 논의

## 확인 범위

- 영상이 유료라 프로토콜의 최종 형태와 추론 문제 해결책은 확인하지 못했다. 위 내용은 섹션 제목·도입부·References에서 읽어낸 것이다
