# Composable Architecture — 컬렉션 전체 흐름

Point-Free의 [Composable Architecture 컬렉션](https://www.pointfree.co/collections/composable-architecture) 14개 섹션 84편을 **하나의 이야기로 읽기 위한 문서.**

섹션별 흐름은 각 폴더의 `00-overview.md`에, 편별 상세는 개별 문서에 있다. 여기서는 그 위층 — 전체가 어디서 시작해 어디로 갔는지, 그리고 반복되는 사고방식이 무엇인지를 다룬다.

- 정리일: 2026-07-31
- 문서 위치와 편별 요약은 [README.md](README.md)

---

## 1. 전체를 한 문장으로

**2019년 SwiftUI가 남긴 다섯 개의 구멍을 메우려고 시작해서, 그걸 다 메운 뒤에도 언어가 자랄 때마다 스스로를 다시 지은 기록.**

앞의 절반(01~05)이 문제 해결이고, 뒤의 절반(06~14)이 재건축이다.

## 2. 척추 — Ep. 67의 다섯 문제

[Ep. 67](01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)이 SwiftUI로 앱을 짜 보고 한계 다섯을 정리한다. 이 목록이 컬렉션 전체의 목차다.

| Ep. 67 | 한계 | 닫히는 곳 |
|---|---|---|
| 4.1 | 영속 상태 API가 번거롭다 | 프레임워크가 `@Observable`로 스스로 해결 |
| 4.2 | 상태 변경이 흩어져 있다 | [02 Reducers and Stores](02-reducers-and-stores/) |
| 4.3 | 부수효과에 대한 이야기가 없다 | [04 Side Effects](04-side-effects/) |
| 4.4 | 상태 관리가 합성되지 않는다 | [02](02-reducers-and-stores/) · [03 Modularity](03-modularity/) |
| 4.5 | 테스트할 수 없다 | [05 Testing](05-testing/) |

[Ep. 85](05-testing/ep85-testable-state-management-the-point.md)에서 다섯이 다 닫힌다. 문제 제기(65~67)부터 18편 만이다.

닫는 방식도 짝을 이룬다. Ep. 67은 SwiftUI로 앱을 짜며 문제를 드러냈고, Ep. 85는 **아키텍처 없이 같은 테스트를 시도해 막히는 지점을 보인다.** 그리고 막히는 이유가 하나같이 "아키텍처가 이미 내린 결정의 부재"로 설명된다.

## 3. 네 시대

01~05가 하나의 완결된 호이고, 그 뒤로 성격이 세 번 바뀐다.

### 1기 · 구축 (01~05, Ep. 65~85, 2019)

문제를 드러내고 하나씩 푼다. 위 다섯 문제가 여기서 다 닫힌다.

### 2기 · 다듬기 (06~08, Ep. 91~99, 2020)

숙제는 끝났고 **완성된 것의 약한 부분을 손본다.**

| 섹션 | 대상 | 이유 |
|---|---|---|
| 06 | 05가 도입한 전역 Environment | 모듈 여러 개를 조율할 수 없었다 |
| 07 | 03이 도입한 `Store.view` 성능 | 무관한 변경에도 뷰가 다시 그려졌다 |
| 08 | API 표면 전반 | 남이 쓸 물건이 되려면 |

06·07은 **실제 결함**이고 08은 사용성이다. [Ep. 98](08-ergonomics/ep98-ergonomic-state-management-part-1.md)이 오픈소스 공개를 앞두고 다듬는다고 밝히니, 여기까지가 초기 TCA의 완성형이다.

### 3기 · 라이브러리 시대 (09~11, Ep. 195~237, 2022~2023)

**2년이 비어 있다.** 그 사이 TCA가 공개돼 널리 쓰이게 됐고, 이제부터는 처음부터 짓는 게 아니라 **이미 쓰이는 라이브러리를 크게 고치는** 작업이다.

- [09](09-async-composable-architecture/) — 언어에 동시성이 들어와서
- [10](10-reducer-protocol/) — Swift 5.7 기능(result builder, primary associated types)이 생겨서
- [11](11-navigation/) — SwiftUI 내비게이션이 정리되고 나서야 가능해져서

전부 **언어나 프레임워크가 먼저 변했고 라이브러리가 따라간** 구조다.

### 4기 · 현대 (12~14, Ep. 243~276, 2023~2024)

- [12](12-composable-architecture-1-0/) — 완성된 도구로 앱 하나를 처음부터 만든다. 앞의 열한 섹션과 방향이 반대다
- [13](13-observable-architecture/) — Observation이 들어오며 **도구를 지운다**
- [14](14-sharing-and-persisting-state/) — 근본 원칙(값 타입)을 통제된 방식으로 흔든다

## 4. 반복되는 다섯 가지 사고방식

섹션을 가로질러 같은 패턴이 계속 나온다. 이걸 알면 새 섹션이 나와도 무엇을 할지 예측할 수 있다.

### 4.1 상태를 좁히고, 액션을 좁힌다 — 네 번 반복

| 대상 | 상태 | 액션 |
|---|---|---|
| 리듀서 | [Ep. 69](02-reducers-and-stores/ep69-composable-state-management-state-pullbacks.md) `pullback(value:)` | [Ep. 70](02-reducers-and-stores/ep70-composable-state-management-action-pullbacks.md) `pullback(action:)` |
| Store | [Ep. 73](03-modularity/ep73-modular-state-management-view-state.md) `view(value:)` | [Ep. 74](03-modularity/ep74-modular-state-management-view-actions.md) `view(action:)` |
| ViewStore | [Ep. 95](07-adaptation/ep95-adaptive-state-management-state.md) | [Ep. 96](07-adaptation/ep96-adaptive-state-management-actions.md) |
| 스택 | [Ep. 235](11-navigation/ep235-composable-stacks-state-ergonomics.md) `StackState` | [Ep. 234](11-navigation/ep234-composable-stacks-action-ergonomics.md) `NavigationStackStore` |

[Ep. 96](07-adaptation/ep96-adaptive-state-management-actions.md) 도입부가 원칙을 명시한다. **짝을 이루는 개념(상태와 액션, 구조체와 enum) 중 한쪽에서 쓸모를 찾으면 즉시 다른 쪽의 대응물을 찾아본다.**

방향이 매번 갈리는 것도 일관된다. 리듀서는 상태를 소비하니 반변(`WritableKeyPath`), store는 상태를 제공하니 공변(함수). 액션은 반대로 흐르므로 변환 방향도 반대다.

### 4.2 승격 사다리 — typealias → struct → protocol

무언가가 중요해지면 타입 계층을 한 칸씩 올린다.

| 대상 | typealias | struct | protocol |
|---|---|---|---|
| `Effect` | Ep. 76~78 | [Ep. 79](04-side-effects/ep79-effectful-state-management-the-point.md) | — |
| `Reducer` | Ep. 68~97 | [Ep. 98](08-ergonomics/ep98-ergonomic-state-management-part-1.md) | [Ep. 202](10-reducer-protocol/ep202-reducer-protocol-the-solution.md) |

올릴 때마다 얻는 게 명확하다. 구조체가 되면 메서드를 붙일 수 있고, 프로토콜이 되면 이름공간·타입추론·인라인이 함께 풀린다. [Ep. 98](08-ergonomics/ep98-ergonomic-state-management-part-1.md)에서 `pullback`의 제네릭이 6개에서 3개로 줄어드는 게 그 효과다.

### 4.3 문제 편 → 구축 → 결산 편

큰 섹션마다 같은 리듬이다.

```
The Problem  →  (구현 여러 편)  →  The Point / In Practice
```

결산 편은 주장하지 않고 **보인다.**

| 섹션 | 결산 방식 |
|---|---|
| 03 | 화면 하나하나를 독립 앱으로 띄운다 |
| 05 | 바닐라 SwiftUI로 같은 테스트를 시도해 막히는 곳을 보인다 |
| 07 | macOS 앱을 만든다 |
| 09 | 실제 출시작 isowords를 옮긴다 |
| 10 | 스택 프레임 269 → 31 |
| 13 | 시뮬레이터 통합 테스트로 측정 |

그리고 **큰 리팩터링 섹션은 무료 편 둘(문제·실물)로 열고 닫는다.** 09(195·200), 10(201·208)이 그렇다. 유료 구독자가 아니어도 왜 고쳤고 무엇이 나아졌는지는 볼 수 있게 한 구성이다.

### 4.4 불가능한 상태를 표현 불가능하게

enum이 반복해서 답으로 나온다.

| 곳 | 무엇을 enum으로 |
|---|---|
| [Ep. 68](02-reducers-and-stores/ep68-composable-state-management-reducers.md) | 액션 |
| [Ep. 229](11-navigation/ep229-composable-navigation-correctness.md) | 내비게이션 목적지 — 옵셔널 4개면 16가지 중 5가지만 유효 |
| [Ep. 247](12-composable-architecture-1-0/ep247-tour-domain-modeling.md) | 같은 논증, 5개면 90% 초과가 무효 |
| [Ep. 262](13-observable-architecture/ep262-observable-architecture-observing-enums.md) | 그 enum을 관찰 가능하게 |

대가도 매번 같다. **Swift에 enum용 key path가 없다.** [Ep. 70](02-reducers-and-stores/ep70-composable-state-management-action-pullbacks.md)에서 enum property를 손으로 만들었고, CLI로 자동화했고, 나중에 CasePath로 정리되고, [Ep. 270](14-sharing-and-persisting-state/ep270-shared-state-the-solution-part-2.md)에서는 `@Reducer` 매크로가 생성한다. 같은 불편이 도구를 갈아 가며 따라온다.

### 4.5 도구를 만들면 다음 문제가 생긴다

해결이 다음 문제를 부르는 연쇄가 반복된다. 가장 선명한 게 [Ep. 275](14-sharing-and-persisting-state/ep275-shared-state-file-storage-part-1.md)의 섹션 구성이다.

```
파일 저장 → 디스크 I/O 폭주 → 디바운싱
         → 안 쓴 변경이 남음 → 백그라운드 전환 시 저장
         → 외부에서 파일을 고침 → 외부 쓰기 관찰
         → 내가 쓴 게 나에게 돌아옴 → 피드백 루프 수정
```

같은 구조가 곳곳에 있다. [Ep. 225](11-navigation/ep225-composable-navigation-effect-cancellation.md)의 효과 취소는 시트를 만들었기 때문에 필요해졌고, [Ep. 271](14-sharing-and-persisting-state/ep271-shared-state-testing-part-1.md)의 테스트 복구는 `@Shared`를 만들었기 때문에 필요해졌다.

## 5. 한 가지 기준은 끝까지 지켜진다

[05 섹션](05-testing/)이 세운 기준이 84편 내내 흔들리지 않는다. [Ep. 196](09-async-composable-architecture/ep196-async-composable-architecture-tasks.md) 도입부의 표현이 가장 명료하다.

> 테스트가 단연 가장 중요한 기능이고, 테스트 가능성을 해치는 기능은 절대 넣지 않으려 한다.

증거가 여럿이다.

- [09](09-async-composable-architecture/) — async/await의 이점이 크지만 테스트가 비결정적이 되는 걸 용납하지 않아 `TaskResult`를 만든다. 결과적으로 **기존 테스트 스위트가 유의미한 변경 없이 통과**한다
- [10](10-reducer-protocol/) — 의존성 기본값을 "호출되면 실패"로 두어 누락이 드러나게 한다
- [14](14-sharing-and-persisting-state/) — `@Shared`를 만든 **직후 두 편을 테스트 복구에 쓴다**

## 6. 시효 — 지금도 유효한 것과 옛것

이 정리를 실무에 쓸 때 가장 중요한 구분이다.

**여전히 유효한 것 (사고방식)**

- 상태를 값 타입으로, 변경을 한곳에, 효과를 값으로
- 불가능한 상태를 표현 불가능하게
- 의존성을 통제해 테스트와 프리뷰를 살린다
- 액션은 **사용자가 UI에서 한 일**을 이름으로 삼는다 ([Ep. 243](12-composable-architecture-1-0/ep243-tour-the-basics.md))

**이미 옛것 (API)**

| 배운 곳 | 옛 API | 현재 |
|---|---|---|
| 01~08 | `BindableObject`, `@ObjectBinding` | `@Observable` |
| 02~08 | 자유 함수 `pullback`·`combine` | `Reducer` 프로토콜 메서드 |
| 06 | `Reducer<Value, Action, Environment>` | `@Dependency` |
| 07~12 | `WithViewStore`, `IfLetStore`, `SwitchStore`, `ForEachStore` | 전부 불필요 ([13](13-observable-architecture/)) |
| 09 | Combine `Scheduler` 감싸기 | `Clock` |

SwiftUI 자체의 변화는 [`01-swiftui-and-state-management/swiftui-api-updates.md`](01-swiftui-and-state-management/swiftui-api-updates.md)에 별도로 정리했다.

**결론** — 01~12는 **왜 그렇게 생겼는지**를 배우는 데 읽고, 실제 코드는 [13](13-observable-architecture/)·[14](14-sharing-and-persisting-state/)와 [공식 문서](https://pointfreeco.github.io/swift-composable-architecture/)를 기준으로 삼는다.

## 7. 목적별 읽는 경로

84편을 순서대로 볼 필요는 없다.

**TCA를 처음 본다 (약 5시간)**
[12 Tour](12-composable-architecture-1-0/) → [13 Observable](13-observable-architecture/)
완성된 도구로 앱을 만들고, 현재 API로 갱신한다. 12의 [Ep. 243](12-composable-architecture-1-0/ep243-tour-the-basics.md)과 13의 [Ep. 259](13-observable-architecture/ep259-observable-architecture-sneak-peek.md)가 무료다.

**왜 이렇게 생겼는지 알고 싶다 (약 8시간)**
[01](01-swiftui-and-state-management/) → [02](02-reducers-and-stores/) → [03](03-modularity/) → [04](04-side-effects/) → [05](05-testing/)
하나의 완결된 호다. 01의 세 편과 04의 두 편, 05의 한 편이 무료라 근거도 가장 탄탄하다.

**시간이 없다 (약 2시간)**
[Ep. 67](01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md) → [Ep. 85](05-testing/ep85-testable-state-management-the-point.md) → [Ep. 259](13-observable-architecture/ep259-observable-architecture-sneak-peek.md)
문제 제기 · 그 문제가 닫히는 논증 · 현재 모습. 셋 다 무료다.

**실무에서 막힌 게 있다**

| 문제 | 볼 곳 |
|---|---|
| 화면 전환 모델링 | [11](11-navigation/) — 목적별 읽는 순서가 그 섹션 통합본에 있다 |
| 여러 기능이 같은 상태를 씀 | [14](14-sharing-and-persisting-state/) |
| 영속화를 직접 짜야 함 | [Ep. 275](14-sharing-and-persisting-state/ep275-shared-state-file-storage-part-1.md)의 엣지 케이스 목록 |
| 프리뷰가 안 돎 | [Ep. 248](12-composable-architecture-1-0/ep248-tour-dependencies.md) |
| 테스트가 느리거나 불안정 | [Ep. 243](12-composable-architecture-1-0/ep243-tour-the-basics.md)의 테스트 클럭 |

## 8. 이 정리의 근거 지도

무료 편이 있는 섹션일수록 근거가 두껍다. 문서를 신뢰할 수준을 판단할 때 참고한다.

| 근거 수준 | 섹션 | 비고 |
|---|---|---|
| **두꺼움** — 무료 편 전문 + 코드 | 01, 04, 05, 09, 10, 12, 13 | 무료 편 9개가 여기 몰려 있다 |
| **보통** — 유료지만 코드 diff로 대조 | 02, 03, 06, 07, 08 | 시그니처 변화를 편별로 추적했다 |
| **얇음** — 공개 구간만 | 11, 14 | 무료 편 없음. 실제 API는 공식 문서로 확인할 것 |

각 문서 하단 "확인 범위"에 무엇을 확인했고 못 했는지 개별로 남겼다. 정리 방법은 [README.md](README.md)의 "유료 회원 전용 편을 정리하는 방법" 참고.

## 9. 섹션 목록

| # | 섹션 | 편 | 한 줄 |
|---|---|---|---|
| 01 | [SwiftUI and State Management](01-swiftui-and-state-management/) | 3 | 문제 다섯을 확정한다 |
| 02 | [Reducers and Stores](02-reducers-and-stores/) | 4 | 변경을 리듀서 하나로 모으고 쪼갰다 붙인다 |
| 03 | [Modularity](03-modularity/) | 4 | 컴파일러가 강제하는 모듈 경계 |
| 04 | [Side Effects](04-side-effects/) | 6 | 효과를 값으로, 이후 Combine |
| 05 | [Testing](05-testing/) | 4 | Environment, 그리고 다섯 문제가 닫힌다 |
| 06 | [Dependency Management](06-dependency-management/) | 3 | 전역 Environment를 리듀서 인자로 |
| 07 | [Adaptation](07-adaptation/) | 4 | `ViewStore`, 성능에서 플랫폼 적응으로 |
| 08 | [Ergonomics](08-ergonomics/) | 2 | 오픈소스 공개 직전의 손질 |
| 09 | [Async Composable Architecture](09-async-composable-architecture/) | 6 | 구조적 동시성으로 |
| 10 | [Reducer Protocol](10-reducer-protocol/) | 8 | 클로저를 프로토콜 타입으로 |
| 11 | [Navigation](11-navigation/) | 16 | 실제 주제는 기능 간 통신 |
| 12 | [A tour of TCA 1.0](12-composable-architecture-1-0/) | 7 | Scrumdinger를 다시 만든다 |
| 13 | [Observable Architecture](13-observable-architecture/) | 8 | 도구를 지운다 |
| 14 | [Sharing and Persisting State](14-sharing-and-persisting-state/) | 9 | 값 타입 원칙에 참조를 들인다 |
