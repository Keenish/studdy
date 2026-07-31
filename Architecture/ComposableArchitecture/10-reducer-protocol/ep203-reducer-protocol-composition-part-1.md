# Ep. 203 — Reducer Protocol: Composition, Part 1

- 출처: [Point-Free Episode #203](https://www.pointfree.co/episodes/ep203-reducer-protocol-composition-part-1)
- 코드: [0203-reducer-protocol-pt3](https://github.com/pointfreeco/episode-code-samples/tree/main/0203-reducer-protocol-pt3) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:56 | Reducer builders |
| 17:23 | Reducer builder operators |
| 29:04 | Next time: reducer bodies |

---

## 이 편이 하려는 것

[Ep. 202](ep202-reducer-protocol-the-solution.md)에서 프로토콜로 옮기고 나온 코드에 대해 도입부가 솔직하다. 결과물이 **이상적이지 않다**고 스스로 말한다.

프로토콜의 이점은 분명한데 합성하는 모양이 아직 지저분하다. 그걸 result builder로 다시 상상한다.

## Result builder

Swift 5.7의 result builder를 쓴다. SwiftUI의 `@ViewBuilder`와 같은 장치다.

도입부가 노리는 것 셋을 든다.

- 불필요한 복잡함 제거
- **정확성 보장의 강제**
- 컴파일러 한계 우회

두 번째가 [Ep. 201](ep201-reducer-protocol-the-problem.md)의 문제와 직접 연결된다. `.optional()`과 `.forEach()`의 조합 순서를 API가 강제하지 못해 문서와 런타임 경고에 의존하던 문제다. 빌더 안에서 어떤 조합이 허용되는지 타입으로 제한할 수 있다.

## 가변 제네릭 우회

세 번째가 흥미롭다. 당시 Swift에는 가변 제네릭(variadic generics)이 없었다.

리듀서 N개를 합성하려면 인자 개수마다 오버로드를 만들어야 한다. 2개용, 3개용, 4개용… 이런 식이다. Combine의 `zip`이 그렇게 생겼다.

References에 걸린 [SE-0348 buildPartialBlock](https://github.com/apple/swift-evolution/blob/main/proposals/0348-buildpartialblock.md)이 그 우회로다. 결과를 하나씩 누적하는 방식이라 오버로드를 잔뜩 정의하지 않아도 여러 컴포넌트를 다룰 수 있다.

## 참고자료

- [SE-0348: buildPartialBlock for result builders](https://github.com/apple/swift-evolution/blob/main/proposals/0348-buildpartialblock.md) — Richard Wei, 2022-03. 오버로드 없이 결과를 누적하는 result builder 확장

## 확인 범위

- 영상이 유료라 빌더의 실제 정의와 연산자 처리 방식은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명·References에서 읽어낸 것이다
