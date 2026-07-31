# 13 · Observable Architecture — 여덟 편 흐름

Point-Free [Observable Architecture](https://www.pointfree.co/collections/composable-architecture/observable-architecture) 섹션(Ep. 259~266)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 260~266은 영상이 유료라 섹션 제목·도입부만 확인했다. **259는 무료라 트랜스크립트 전문을 근거로 정리했다**

관련 문서

- [ep259 — Sneak Peek](ep259-observable-architecture-sneak-peek.md) · 결과를 먼저 보인다 (무료)
- [ep260 — Structural Identity](ep260-observable-architecture-structural-identity.md) · 값 타입을 어떻게 관찰할 것인가
- [ep261 — Observing Optionals](ep261-observable-architecture-observing-optionals.md) · `@ObservableState` 매크로, `IfLetStore` 제거
- [ep262 — Observing Enums](ep262-observable-architecture-observing-enums.md) · `SwitchStore` 제거
- [ep263 — Observing Collections](ep263-observable-architecture-observing-collections.md) · `ForEachStore` 제거
- [ep264 — Observing Navigation](ep264-observable-architecture-observing-navigation.md) · 전용 modifier 제거
- [ep265 — Observing Bindings](ep265-observable-architecture-observing-bindings.md) · 첫날부터의 빚을 갚는다
- [ep266 — The Point](ep266-observable-architecture-the-point.md) · 측정과 Todos 회고

---

## 이 섹션의 성격 — 지우는 작업

섹션 설명이 배경을 밝힌다. Swift 5.9와 iOS 17이 새 관찰 도구를 가져왔고 SwiftUI로 기능을 만드는 방식을 완전히 바꿔 놓았다. 이 섹션은 그걸 라이브러리에 들이는 이야기다.

[Ep. 259](ep259-observable-architecture-sneak-peek.md) 도입부의 평가가 세다. async/await([09](../09-async-composable-architecture/00-overview.md)), 리듀서 프로토콜([10](../10-reducer-protocol/00-overview.md)), 내비게이션([11](../11-navigation/00-overview.md))도 혁신적이었지만 **이번이 그보다 훨씬 크다**는 것이다.

다른 섹션들과 결정적으로 다른 점이 있다. 앞 섹션들은 도구를 **더했는데** 이 섹션은 **지운다.**

## 무엇이 사라지는가

| 사라지는 것 | 만든 곳 | 대체 |
|---|---|---|
| `ViewStore` / `WithViewStore` | [07 섹션](../07-adaptation/00-overview.md) | `store.count` 직접 접근 |
| `IfLetStore` | 옵셔널 상태용 | 평범한 `if let` |
| `SwitchStore` / `CaseLet` | enum 상태용 | 평범한 `switch` |
| `ForEachStore` | 컬렉션용 | 평범한 `ForEach` |
| 내비게이션 전용 modifier | [11 섹션](../11-navigation/00-overview.md) | 평범한 `.sheet` 등 |

공통점이 있다. **전부 "최소 관찰"을 손으로 하려고 만든 것들**이다. 뷰가 필요한 상태만 보게 해서 불필요한 재렌더를 막는 게 목적이었는데, 언어가 그걸 해 주자 존재 이유를 잃는다.

[Ep. 263](ep263-observable-architecture-observing-collections.md) 도입부가 그 시점까지 넷이 사라졌다고 센다 — `WithViewStore`, `IfLetStore`, `SwitchStore`, `CaseLet`.

## 기술적 과제 — 값 타입

이 섹션이 어려운 이유는 하나다.

- 이 아키텍처는 상태를 **값 타입**으로 모델링한다 ([Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md) 이래의 원칙)
- Swift의 `@Observable`은 **클래스 전용**이다

값 타입을 포기할 수는 없다. 전수 테스트도, `_printChanges()` 같은 도구도, 스냅샷 비교도 전부 거기서 나왔다. [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 바닐라 SwiftUI로 안 되는 이유로 든 것이 정확히 클래스 기반이라는 점이었다.

해법이 **구조적 정체성**이다. 값 타입은 동일성 기준이 없으니, 상태가 통째로 교체된 것인지 제자리에서 변경된 것인지 구별할 장치를 만든다([Ep. 260](ep260-observable-architecture-structural-identity.md)). 그 위에 구조체용 `@ObservableState` 매크로를 얹는다([Ep. 261](ep261-observable-architecture-observing-optionals.md)).

매크로 구현은 Swift 오픈소스 프로젝트의 `@Observable`을 가져다 고친다. 언어 기능이 오픈소스라 가능한 접근이다.

## 여덟 편이 쌓이는 순서

**259** — 결과를 먼저 시연한다. `WithViewStore { viewStore in ... }`이 `store.count`가 된다. 뷰에서 실제로 읽은 프로퍼티만 자동 추적되므로, 예전에 뷰마다 `ViewState` 구조체를 만들던 보일러플레이트가 사라진다. iOS 17 미만은 `WithPerceptionTracking`으로 백포트된다.

**260** — 구현 시작. 순진하게 통합해 보고 Apple 도구와 갈라져야 할 지점을 찾는다.

**261 · 262 · 263** — 상태의 형태별로 정복한다. 옵셔널 → enum → 컬렉션 순이고, 각각 `IfLetStore`·`SwitchStore`·`ForEachStore`가 없어진다. 컬렉션이 가장 길다(53분) — 요소가 여러 개라 최소 관찰의 난이도가 한 단계 높다.

**264** — [11 섹션](../11-navigation/00-overview.md)의 전용 modifier들을 걷어낸다.

**265** — 바인딩. 도입부가 **첫날부터 껄끄러웠다**고 인정하고, Observation이 처음부터 하고 싶었던 방식을 가능하게 했다고 말한다.

**266** — 측정으로 결산한다. 시뮬레이터에서 기능을 실제로 돌리는 통합 테스트 스위트로 store 생성·scope 연산·뷰 재계산을 잰다. 그리고 가장 오래된 예제인 Todos를 새 도구로 옮겨 보인다.

## 11 섹션이 헛수고였나

가장 궁금해질 지점이라 짚어 둔다. 16편·13시간짜리 섹션의 결과물이 여기서 상당 부분 없어진다.

그 섹션이 만든 건 두 층이었다.

- **도메인 모델링** — 옵셔널·enum으로 목적지를 표현하는 방식, `PresentationState`, `StackState`, 부모·자식 통신 규약
- **뷰 층 헬퍼** — 그 상태를 SwiftUI에 연결하는 전용 modifier들

사라지는 건 두 번째다. [Ep. 229](../11-navigation/ep229-composable-navigation-correctness.md)의 enum 논증(16가지 중 5가지만 유효)이나 [Ep. 247](../12-composable-architecture-1-0/ep247-tour-domain-modeling.md)의 수치는 관찰과 무관하게 유효하다. 오히려 [Ep. 262](ep262-observable-architecture-observing-enums.md)가 enum 상태를 관찰 가능하게 만드는 데 공을 들이는 걸 보면, enum 모델링이 전제로 남아 있다는 게 확인된다.

## 01 섹션과 이어진다

[Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)이 든 SwiftUI의 한계 다섯 중 4.1(영속 상태 API가 번거롭다)은 **프레임워크가 스스로 해결한** 유일한 항목이었다. 그 해결책이 바로 `@Observable`이다.

[`swiftui-api-updates.md`](../01-swiftui-and-state-management/swiftui-api-updates.md)에 정리해 둔 그 변화가, 이 섹션에서는 라이브러리 쪽 대응으로 나타난다. 같은 언어 변화가 두 문서에서 다른 각도로 다뤄지는 셈이다.

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 259](ep259-observable-architecture-sneak-peek.md) 원문 — **무료다.** 22분이고 결과를 다 보여준다. 이 섹션에서 하나만 본다면 이것
3. 구현이 궁금하면 260 → 261 → 262 → 263 순
4. [Ep. 264](ep264-observable-architecture-observing-navigation.md)·[265](ep265-observable-architecture-observing-bindings.md) — 11 섹션과 08 섹션을 읽었다면 대비가 크게 느껴질 부분
5. [Ep. 266](ep266-observable-architecture-the-point.md)

**지금 TCA를 쓴다면 이 섹션이 현재 상태에 가장 가깝다.** 01~12에서 배운 것 중 `WithViewStore`·`IfLetStore` 같은 것들은 이미 옛 API다.

## 확인 범위

확인한 것

- 259: 트랜스크립트 전문. 사라지는 API 목록과 새 API 포함
- 260~266: 섹션 제목과 타임스탬프, 도입부, 에피소드 설명

확인하지 못한 것

- 260~266의 실제 구현. `@ObservableState` 매크로, 구조적 정체성 부여 방식, 바인딩 API가 전부 여기 해당한다
- Ep. 266의 측정 수치. 앞의 결산 편들(Ep. 200·208)은 무료라 구체적 수치를 확인할 수 있었는데 이 편은 그렇지 않다

"11 섹션의 무엇이 남고 무엇이 사라지는가"는 두 섹션의 구성을 비교해 제가 정리한 것이다. 영상에서 그렇게 구분했는지는 확인하지 못했다.
