# 08 · Ergonomics — 두 편 흐름

Point-Free [Ergonomics](https://www.pointfree.co/collections/composable-architecture/ergonomics) 섹션(Ep. 98~99)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 두 편 모두 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다. 코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT) 소스로 확인했다

관련 문서

- [ep98 — Part 1](ep98-ergonomic-state-management-part-1.md) · 자유 함수를 `Reducer` 구조체의 메서드로
- [ep99 — Part 2](ep99-ergonomic-state-management-part-2.md) · 뷰 쪽 접근을 다듬고 바인딩을 붙인다

---

## 이 섹션이 하는 일

섹션 설명이 위치를 정확히 말한다. 지금까지 만든 아키텍처는 합성 가능하고 모듈적이고 테스트 가능하지만, **본선에 내보내기 전에** 손볼 작은 것들이 남았다.

Ep. 98 도입부가 그 목적을 더 분명히 한다. 더 널리 쓰이거나 **오픈소스로 공개하기 전에** 사용성을 다듬어야 한다는 것이다. 실제로 TCA는 이 무렵 공개된다. 그러니 이 두 편은 공개 직전의 마지막 손질이다.

같은 도입부에서 라이브러리가 **200줄이 채 안 된다**고 밝힌다. 그 작은 코드로 여기까지 왔다는 점을 짚는 대목이다.

## 두 편이 나눠 맡는 것

### Ep. 98 — 리듀서 쪽

문제는 표면적이다. 아키텍처가 내놓는 게 자유 함수들이라 `combine`, `pullback`, `logging` 같은 흔한 단어가 전역 이름공간에 놓인다. 라이브러리로 배포하면 쓰는 쪽과 부딪히기 쉽고, `Reducer`가 `typealias`라 확장할 수도 없다.

그래서 `Reducer`를 구조체로 만든다.

```swift
public struct Reducer<Value, Action, Environment> {
  public init(_ reducer: @escaping (inout Value, Action, Environment) -> [Effect<Action>])
}
```

담은 함수 모양은 그대로다. [Ep. 79](../04-side-effects/ep79-effectful-state-management-the-point.md)에서 `Effect`에 했던 것과 같은 수순이고, 타입이 되니 메서드를 붙일 수 있다.

효과가 가장 잘 드러나는 건 `pullback`이다.

```swift
// 전 — 자유 함수, 제네릭 6개
func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(...)

// 후 — 인스턴스 메서드, 제네릭 3개
func pullback<GlobalValue, GlobalAction, GlobalEnvironment>(...)
```

지역 쪽 세 타입이 `Self`에서 나오니 전역 쪽만 남는다. [Ep. 91](../06-dependency-management/ep91-dependency-injection-made-composable.md)에서 환경 축이 붙으며 여섯까지 늘었던 게 절반이 된다.

`combine`은 정적 메서드가 되고 제네릭이 아예 사라진다. `logging` 같은 고차 리듀서도 인스턴스 메서드가 된다.

### Ep. 99 — 뷰 쪽

불편은 한 겹이 끼어드는 것이다. 상태를 읽으려면 매번 `viewStore.value.count`처럼 `value`를 거쳐야 한다.

key path 기반 `@dynamicMemberLookup`으로 없앤다.

```swift
@dynamicMemberLookup
public final class ViewStore<Value, Action>: ObservableObject {
  public subscript<LocalValue>(dynamicMember keyPath: KeyPath<Value, LocalValue>) -> LocalValue {
    self.value[keyPath: keyPath]
  }
}
```

`viewStore.count`로 쓸 수 있게 된다. key path 기반이라 컴파일러가 검사하니 편의를 얻으면서 타입 안전성은 유지된다.

시간의 절반은 바인딩에 쓴다. SwiftUI의 `TextField`·`Toggle` 같은 컴포넌트는 `Binding<T>`를 요구하는데, 이 아키텍처에서 상태를 바꾸는 유일한 길은 액션 전송이다. 바인딩이 값을 직접 쓰게 두면 [Ep. 67의 4.2](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)가 문제 삼았던 지점으로 돌아간다. 당시 흩어진 변경 일곱 군데를 셀 때 둘이 바로 바인딩 안에 숨은 변경이었다.

읽기는 상태에서, 쓰기는 액션으로 가는 바인딩 헬퍼를 만들어 그 긴장을 푼다.

## 이 섹션의 성격

06·07과 같은 계열이지만 결이 조금 다르다.

| 섹션 | 손보는 것 | 동기 |
|---|---|---|
| 06 | 05의 전역 Environment | 모듈 여러 개를 조율할 수 없었다 |
| 07 | 03의 `Store.view` 성능 | 무관한 상태 변경에 뷰가 다시 그려졌다 |
| 08 | API 표면 전반 | 남이 쓸 물건이 되려면 |

06·07은 **동작에 실제 결함**이 있었다. 08은 동작은 멀쩡한데 **쓰는 사람 입장**에서 다듬는 작업이다. 그래서 아키텍처의 의미가 달라지지 않고 표현만 바뀐다.

두 편 다 References가 없는 것도 같은 이유다. 외부 개념을 들여오지 않고 자기 API를 정리한다.

## 여기가 하나의 매듭

[01 섹션](../01-swiftui-and-state-management/00-overview.md)의 문제 제기부터 시작해 02~05에서 아키텍처를 완성하고, 06~08에서 약한 부분을 손봤다. Ep. 98이 오픈소스 공개를 앞두고 있다고 밝혔으니 여기까지가 **초기 TCA의 완성형**이다.

이후 섹션들은 성격이 또 달라진다. Swift와 SwiftUI 자체가 변하면서 아키텍처를 다시 짓는 이야기다.

- [`09-async-composable-architecture`](../09-async-composable-architecture/) — async/await 도입
- [`10-reducer-protocol`](../10-reducer-protocol/) — `Reducer` 구조체를 프로토콜로
- [`13-observable-architecture`](../13-observable-architecture/) — Observation 프레임워크

이 섹션에서 만든 `Reducer` 구조체가 10에서 프로토콜로 바뀌고, `ViewStore`가 13에서 사라지는 식이다. 지금 모습이 최종형이 아니라는 걸 염두에 두고 읽는 게 좋다.

## 읽는 순서

두 편뿐이고 각각 리듀서 쪽과 뷰 쪽으로 나뉘어 있어 순서대로 보면 된다.

1. 이 문서
2. [Ep. 98](ep98-ergonomic-state-management-part-1.md) — 제네릭 6개가 3개로 줄어드는 부분이 핵심
3. [Ep. 99](ep99-ergonomic-state-management-part-2.md) — 바인딩 쪽이 개념적으로 더 중요하다

## 확인 범위

확인한 것

- 섹션 제목과 타임스탬프, 도입부, 에피소드 설명
- `Reducer` 구조체화와 메서드 시그니처 (Ep. 98), `@dynamicMemberLookup` 서브스크립트 (Ep. 99) — 저장소 소스

확인하지 못한 것

- 바인딩 헬퍼의 실제 시그니처와 구현
- Ep. 99 "What's the point?"의 결산 내용

`ComposableArchitecture.swift` 줄 수: 151(Ep. 97) → 220 → 225. Ep. 98의 증가분에는 옛 자유 함수가 주석으로 남은 분량이 포함돼 있어 실제 코드 증가는 그보다 적다.
