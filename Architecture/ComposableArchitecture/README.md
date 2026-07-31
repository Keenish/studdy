# Composable Architecture 학습 정리

[Point-Free · Composable Architecture 컬렉션](https://www.pointfree.co/collections/composable-architecture) 을 섹션별로 나눠 영상 내용을 정리한다. **14개 섹션 84편 전부 완료** (2026-07-30).

> ## → [00-overview.md](00-overview.md) 부터 읽는다
>
> 84편을 하나의 이야기로 잇는 **컬렉션 전체 흐름**. 이 README는 문서 위치를 찾는 인덱스이고, 전체 맥락은 그쪽에 있다.
>
> - Ep. 67의 다섯 문제가 어디서 닫히는지 — 컬렉션의 척추
> - 네 시대 — 구축 / 다듬기 / 라이브러리 시대 / 현대
> - 섹션을 가로질러 반복되는 다섯 가지 사고방식
> - **시효** — 지금도 유효한 것과 이미 옛 API인 것
> - 목적별 읽는 경로 (입문 5시간 / 근거 8시간 / 요약 2시간)

문서 규칙

- 폴더명 = 사이트의 섹션 슬러그 + 순서 접두사 (URL 경로와 1:1 대응)
- 파일명 = `ep{번호}-{슬러그}.md`, 섹션마다 `00-overview.md`로 흐름을 잇는다
- 정리본을 추가할 때마다 아래 표에 문서 위치 + 한 줄 요약을 함께 기록한다

## 유료 회원 전용 편을 정리하는 방법

무료 편은 트랜스크립트 전문이 열리지만 대부분의 편은 유료다. 유료 우회는 하지 않고 공개된 자료로만 정리한다.

1. **에피소드 페이지** — 섹션 제목·타임스탬프·도입부·에피소드 설명은 유료 편에서도 열린다. 진행 순서와 문제의식은 여기서 얻는다
2. **샘플 코드** — [episode-code-samples](https://github.com/pointfreeco/episode-code-samples)(MIT)에 편별 플레이그라운드가 공개돼 있다. 시그니처·타입·조립 방식은 여기서 확인한다. 편 사이 `Contents.swift`를 비교하면 무엇이 달라졌는지 그대로 보인다
3. **References** — 에피소드 페이지의 참고자료 목록도 열려 있다. 배경 개념의 출처(선행 에피소드·논문·강연)를 여기서 얻고, 무료로 볼 수 있는 자료는 문서에 링크해 둔다

각 문서 끝의 "확인 범위"에 무엇을 확인했고 무엇을 못 했는지 남긴다. 저장소 코드는 이후 갱신됐을 수 있으니 영상 시점과 일치한다고 단정하지 않는다.

---

## 진행 상황

이후 Point-Free가 새 섹션을 추가하면 같은 방식으로 이어간다. 아래 표의 괄호는 **근거 수준**이다 — 무료 편이 있는 섹션일수록 두껍다. 목적별 읽는 순서는 [00-overview.md §7](00-overview.md), 근거 지도는 [§8](00-overview.md)에 있다.

| # | 섹션 | 정리한 영상 |
|---|---|---|
| 01 | [SwiftUI and State Management](01-swiftui-and-state-management/) | 3 |
| 02 | [Reducers and Stores](02-reducers-and-stores/) | 4 (영상 유료 · 코드는 확인) |
| 03 | [Modularity](03-modularity/) | 4 (영상 유료 · 코드는 확인) |
| 04 | [Side Effects](04-side-effects/) | 6 (80·81은 무료 · 전문 확인) |
| 05 | [Testing](05-testing/) | 4 (85는 무료 · 전문 확인) |
| 06 | [Dependency Management](06-dependency-management/) | 3 (영상 유료 · 코드는 확인) |
| 07 | [Adaptation](07-adaptation/) | 4 (영상 유료 · 코드는 확인) |
| 08 | [Ergonomics](08-ergonomics/) | 2 (영상 유료 · 코드는 확인) |
| 09 | [Async Composable Architecture](09-async-composable-architecture/) | 6 (195·200은 무료 · 전문 확인) |
| 10 | [Reducer Protocol](10-reducer-protocol/) | 8 (201·208은 무료 · 전문 확인) |
| 11 | [Navigation](11-navigation/) | 16 (전편 유료 · 근거 얇음) |
| 12 | [A tour of the Composable Architecture 1.0](12-composable-architecture-1-0/) | 7 (243은 무료 · 전문 확인) |
| 13 | [Observable Architecture](13-observable-architecture/) | 8 (259는 무료 · 전문 확인) |
| 14 | [Sharing and Persisting State](14-sharing-and-persisting-state/) | 9 (전편 유료 · 근거 얇음) |

---

## 정리 문서 목록

### 01 · SwiftUI and State Management

> **먼저 읽을 것** → [`01-swiftui-and-state-management/00-overview.md`](01-swiftui-and-state-management/00-overview.md) — 세 편을 하나의 흐름으로 잇는 **섹션 통합본**. 각 편이 무엇을 쌓아 어디로 가는지, 그리고 이 섹션이 2026년에도 유효한지까지.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`01-swiftui-and-state-management/00-overview.md`](01-swiftui-and-state-management/00-overview.md) | 세 편의 흐름 — 앱을 만들고(65) → 문제 재료를 쌓고(66) → 한계 5가지로 결산(67). 각 마찰이 어느 문제로 이어지는지, 그 문제를 이후 어느 섹션이 푸는지까지 연결한다. |
| Ep. 65 — SwiftUI and State Management: Part 1 | [`01-swiftui-and-state-management/ep65-swiftui-and-state-management-part-1.md`](01-swiftui-and-state-management/ep65-swiftui-and-state-management-part-1.md) | 카운터 예제 앱을 만들며 `@State`의 한계(화면 이탈 시 초기화·화면 간 공유 불가)를 드러내고, `AppState` + `BindableObject`로 상태를 뷰 밖으로 끌어낸다 — 해법이 아니라 시리즈가 풀 문제를 세팅하는 편. |
| Ep. 66 — SwiftUI and State Management: Part 2 | [`01-swiftui-and-state-management/ep66-swiftui-and-state-management-part-2.md`](01-swiftui-and-state-management/ep66-swiftui-and-state-management-part-2.md) | 소수 판별 모달 · Wolfram Alpha API 호출 · 즐겨찾기 목록까지 붙여 앱을 완성하면서, 흩어진 변경·통제 없는 부수효과·상태 전체를 통째로 넘기는 구조 등 Ep. 67에서 문제로 지목될 재료를 쌓는다. |
| Ep. 67 — SwiftUI and State Management: Part 3 | [`01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md`](01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md) | "What's the point?" — SwiftUI의 장점을 인정한 뒤 한계 5가지(영속 상태 보일러플레이트 · 흩어진 변경 · 부수효과 부재 · 합성 불가 · 테스트 불가)를 결산해 시리즈 전체가 풀 문제 목록을 확정한다. |
| _(영상 아님 · 보조 문서)_ | [`01-swiftui-and-state-management/swiftui-api-updates.md`](01-swiftui-and-state-management/swiftui-api-updates.md) | 2019 베타 → 현재 SwiftUI 치환표(`@Observable`·`NavigationStack`·`.task` 등)와 **Ep. 67의 비판 5가지가 지금 각각 해결됐는지 판정한 표** — 해결된 건 하나뿐. |

### 02 · Reducers and Stores

> **먼저 읽을 것** → [`02-reducers-and-stores/00-overview.md`](02-reducers-and-stores/00-overview.md) — 네 편을 하나의 흐름으로 잇는 섹션 통합본.
>
> 이 섹션은 **영상이 유료 회원 전용**이라 트랜스크립트는 섹션 제목·도입부만 열린다. 대신 **코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT)의 실제 소스로 확인**했으므로 시그니처와 구조는 근거가 있다. 논증의 세부와 Ep. 71 결산 내용은 확인하지 못했다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`02-reducers-and-stores/00-overview.md`](02-reducers-and-stores/00-overview.md) | 변경을 리듀서 하나로 모으고(68) → 상태·액션 양쪽으로 쪼갰다 붙이는 도구를 만들고(69·70) → 감싸서 교차 기능을 얹는다(71). 01 섹션의 숙제 4.2·4.4를 가져간다. |
| Ep. 68 — Reducers | [`02-reducers-and-stores/ep68-composable-state-management-reducers.md`](02-reducers-and-stores/ep68-composable-state-management-reducers.md) | 리듀서 모양을 `(inout State, Action) -> Void`로 정하고(복사 비용 때문) store가 그걸 감싸 들게 한다. Redux·Elm 계보를 밝히고 시작. |
| Ep. 69 — State Pullbacks | [`02-reducers-and-stores/ep69-composable-state-management-state-pullbacks.md`](02-reducers-and-stores/ep69-composable-state-management-state-pullbacks.md) | 커진 리듀서를 쪼개려고 combine과 pullback을 만든다. 리듀서가 상태에 대해 반변이라 map이 아니라 pullback이고, 쓰기까지 하니 `WritableKeyPath`가 필요하다. |
| Ep. 70 — Action Pullbacks | [`02-reducers-and-stores/ep70-composable-state-management-action-pullbacks.md`](02-reducers-and-stores/ep70-composable-state-management-action-pullbacks.md) | 액션에도 같은 걸 하려는데 Swift에 enum용 key path가 없다. enum property로 접근자를 손수 만들어 메운다(#52에서 다룬 내용, #55에서 CLI로 자동화). |
| Ep. 71 — Higher-Order Reducers | [`02-reducers-and-stores/ep71-composable-state-management-higher-order-reducers.md`](02-reducers-and-stores/ep71-composable-state-management-higher-order-reducers.md) | 리듀서를 받아 리듀서를 반환해 활동 기록·로깅 같은 교차 기능을 얹는다. Ep. 67 4.2에서 버그를 냈던 바로 그 활동 기록이 예제다. |

### 03 · Modularity

> **먼저 읽을 것** → [`03-modularity/00-overview.md`](03-modularity/00-overview.md) — 네 편을 하나의 흐름으로 잇는 섹션 통합본. 02 섹션과 대칭 구조라 대조표를 함께 뒀다.
>
> 영상은 유료지만 코드·References는 공개다. 근거 범위는 각 문서 하단 "확인 범위" 참고.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`03-modularity/00-overview.md`](03-modularity/00-overview.md) | 리듀서를 프레임워크로 쪼개고(72) → store를 상태·액션 양쪽으로 변환할 수 있게 만들면(73·74) → 각 화면이 앱을 몰라도 빌드·실행·테스트된다(75). 02 섹션과 같은 순서를 store에 대해 반복한다. |
| Ep. 72 — Reducers | [`03-modularity/ep72-modular-state-management-reducers.md`](03-modularity/ep72-modular-state-management-reducers.md) | 플레이그라운드 하나였던 코드가 프레임워크 5개로 갈라진다. 리듀서가 이미 지역 상태·액션만 알았기에 옮기는 데 구조 변경이 없었다 — 02의 배당금. |
| Ep. 73 — View State | [`03-modularity/ep73-modular-state-management-view-state.md`](03-modularity/ep73-modular-state-management-view-state.md) | `Store.view`로 뷰가 보는 상태를 좁힌다. 리듀서 pullback은 반변이었는데 store는 공변(map 쪽)이라 방향이 반대다. 지역 store는 복사본이 아니라 전역에 연결된 창. |
| Ep. 74 — View Actions | [`03-modularity/ep74-modular-state-management-view-actions.md`](03-modularity/ep74-modular-state-management-view-actions.md) | `view`에 `action:`이 붙어 두 축이 완성된다. 상태는 전역→지역, 액션은 지역→전역으로 방향이 갈린다. 모듈 안에서 `CounterAction`과 `CounterViewAction`이 나뉜다. |
| Ep. 75 — The Point | [`03-modularity/ep75-modular-state-management-the-point.md`](03-modularity/ep75-modular-state-management-the-point.md) | 결산을 말이 아니라 실행으로 한다 — 화면 하나하나를 독립 앱으로 띄운다. Playground Driven Development 자료가 References에 셋. 목표는 "앱 구조를 몰라도 그 화면을 테스트할 수 있게". |

### 04 · Side Effects

> **먼저 읽을 것** → [`04-side-effects/00-overview.md`](04-side-effects/00-overview.md) — 여섯 편을 잇는 섹션 통합본. `Effect` 타입이 편마다 한 단계씩 바뀌는 게 줄거리라 변천표를 앞에 뒀다.
>
> 76~79는 영상이 유료(코드·References는 확인), **80·81은 무료라 트랜스크립트 전문을 근거로 정리**했다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`04-side-effects/00-overview.md`](04-side-effects/00-overview.md) | 리듀서는 효과를 실행하지 않고 값으로 반환하고 store가 실행한다. `Effect`가 `() -> Void` → `() -> Action?` → 콜백 → 구조체 → Combine `Publisher`로 한 단계씩 자란다. |
| Ep. 76 — Synchronous Effects | [`04-side-effects/ep76-...md`](04-side-effects/ep76-effectful-state-management-synchronous-effects.md) | 리듀서를 순수하게 유지하려고 효과를 값으로 반환한다. 이 시점 `Effect = () -> Void`라 밖으로 쓰기만 하고 읽어 올 수 없다. |
| Ep. 77 — Unidirectional Effects | [`04-side-effects/ep77-...md`](04-side-effects/ep77-effectful-state-management-unidirectional-effects.md) | `() -> Action?`으로 결과를 액션으로 되먹인다. 효과가 상태를 직접 고치면 변경 경로가 다시 늘어나므로 액션으로만 돌려준다. Elm의 Commands가 원형. |
| Ep. 78 — Asynchronous Effects | [`04-side-effects/ep78-...md`](04-side-effects/ep78-effectful-state-management-asynchronous-effects.md) | 반환값 대신 콜백을 받아 비동기를 담는다. 앞의 두 모양은 이것의 특수한 경우. 뷰 상태를 앱 상태로 끌어올리다 실제 버그가 났다. |
| Ep. 79 — The Point | [`04-side-effects/ep79-...md`](04-side-effects/ep79-effectful-state-management-the-point.md) | `Effect`가 구조체가 되어 `map`을 갖는다. 네트워크·스레딩을 재사용 효과로 뽑는다 — 고차 리듀서와 같은 발상의 반복. |
| Ep. 80 — Combine 1 (무료) | [`04-side-effects/ep80-...md`](04-side-effects/ep80-the-combine-framework-and-effects-part-1.md) | 직접 만든 `Effect`와 Combine을 대조만 한다. `Future`가 생성 시점에 실행돼 리듀서 순수성을 깨는 문제와 `Deferred` 해법. |
| Ep. 81 — Combine 2 (무료) | [`04-side-effects/ep81-...md`](04-side-effects/ep81-the-combine-framework-and-effects-part-2.md) | `Effect: Publisher`로 갈아 끼운다(`Failure == Never`). 구현을 통째로 바꿔도 리듀서 시그니처가 안 변한 게 결론의 근거. 다만 RxSwift 등으로 교체는 불가능하다고 인정. |

### 05 · Testing

> **먼저 읽을 것** → [`05-testing/00-overview.md`](05-testing/00-overview.md) — 네 편을 잇는 섹션 통합본. 여기서 Ep. 67의 숙제 다섯이 전부 닫히므로 01~05 대조표를 함께 뒀다.
>
> 82~84는 영상이 유료(코드·References는 확인), **85는 무료라 트랜스크립트 전문을 근거로** 정리했다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`05-testing/00-overview.md`](05-testing/00-overview.md) | 앞의 네 섹션에서 내린 결정(값 타입·리듀서·모듈·효과를 값으로)이 전부 테스트 가능성으로 돌아온다. 01~05가 하나의 완결된 호를 이루며 닫힌다. |
| Ep. 82 — Reducers | [`05-testing/ep82-...md`](05-testing/ep82-testable-state-management-reducers.md) | 리듀서가 순수 함수라 목도 DI 컨테이너도 뷰 계층도 없이 테스트된다. 마지막에 `combine`·`pullback`으로 붙였을 때의 통합 테스트. |
| Ep. 83 — Effects | [`05-testing/ep83-...md`](05-testing/ep83-testable-state-management-effects.md) | 바깥세상과 얘기하는 함수를 구조체에 모으는 Environment 패턴. 프로토콜이 아니라 함수를 담은 값이라 클로저만 갈아 끼우면 된다. |
| Ep. 84 — Ergonomics | [`05-testing/ep84-...md`](05-testing/ep84-testable-state-management-ergonomics.md) | 테스트 한 건에 드는 의식을 걷어낸다. 핵심은 "보낸 액션 vs 받은 액션" 구분 — 단방향 흐름이 테스트에서 드러나는 지점. |
| Ep. 85 — The Point (무료) | [`05-testing/ep85-...md`](05-testing/ep85-testable-state-management-the-point.md) | 바닐라 SwiftUI로 같은 테스트를 시도해 막히는 곳을 보인다. `@State`는 `UIHostingController` 없이는 값이 안 바뀌어 근본적으로 불가. |

### 06 · Dependency Management

> **먼저 읽을 것** → [`06-dependency-management/00-overview.md`](06-dependency-management/00-overview.md) — 세 편을 잇는 섹션 통합본.
>
> Ep. 67의 숙제는 05에서 다 닫혔다. 여기서부터는 **완성된 아키텍처의 약한 부분을 다시 손보는** 성격이다. 05가 도입한 전역 Environment가 그 대상.
>
> 05 섹션이 Ep. 85로 끝나는데 여기는 Ep. 91부터다. 86~90은 다른 주제의 에피소드다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`06-dependency-management/00-overview.md`](06-dependency-management/00-overview.md) | 전역 `var Current`를 걷어내고 환경을 리듀서 인자로 만든다. 의존성이 타입에 드러나 컴파일러가 검사하게 된다. |
| Ep. 91 — Made Composable | [`06-dependency-management/ep91-...md`](06-dependency-management/ep91-dependency-injection-made-composable.md) | `Reducer<Value, Action, Environment>`로 축이 하나 는다. `pullback`은 제네릭 6개짜리가 되고, `Store`는 뷰를 지키려 환경 타입을 `Any`로 지운다. |
| Ep. 92 — Made Modular | [`06-dependency-management/ep92-...md`](06-dependency-management/ep92-dependency-injection-made-modular.md) | 모듈과 테스트를 새 시그니처로 옮긴다. 앱 환경을 구조체 대신 튜플로 묶어 반복 작업을 줄인다. 테스트는 전역 교체 대신 인자 전달로. |
| Ep. 93 — The Point | [`06-dependency-management/ep93-...md`](06-dependency-management/ep93-modular-dependency-injection-the-point.md) | 전역으로는 안 되던 셋 — 환경 여러 개 조율(정적 보장), 같은 화면을 다른 환경으로 재사용, 공통 의존성 공유. 단 이 이점은 아키텍처를 채택해야 얻는다고 인정. |

### 07 · Adaptation

> **먼저 읽을 것** → [`07-adaptation/00-overview.md`](07-adaptation/00-overview.md) — 네 편을 잇는 섹션 통합본.
>
> 06과 같은 성격이다. 06이 05의 전역 Environment를 손봤다면, 07은 03의 `Store.view` 성능을 손본다. 그리고 **상태 → 액션 순서로 좁히는 작업이 이번이 세 번째**라 대조표를 뒀다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`07-adaptation/00-overview.md`](07-adaptation/00-overview.md) | 성능 문제를 풀려고 `ViewStore`를 두는데, 그게 "뷰에 맞는 상태만 노출"하는 성질 때문에 플랫폼 적응의 통로가 된다. 섹션 이름이 Adaptation인 이유. |
| Ep. 94 — Performance | [`07-adaptation/ep94-...md`](07-adaptation/ep94-adaptive-state-management-performance.md) | 누수 두 건 수정 — `receiveValue: self.send`처럼 깔끔해 보이는 메서드 참조가 `self`를 강하게 붙들고 있었다. 이후 `View.init`/`body` 호출 횟수 실측. |
| Ep. 95 — State | [`07-adaptation/ep95-...md`](07-adaptation/ep95-adaptive-state-management-state.md) | `ViewStore`를 도입하고 `removeDuplicates`로 실제 값이 달라졌을 때만 갱신한다. `ObservableObject`가 `Store`에서 `ViewStore`로 옮겨간다. |
| Ep. 96 — Actions | [`07-adaptation/ep96-...md`](07-adaptation/ep96-adaptive-state-management-actions.md) | 액션도 좁힌다. 도입부에 작업 원칙이 나온다 — 짝을 이루는 개념 중 한쪽에서 쓸모를 찾으면 즉시 다른 쪽도 보라. |
| Ep. 97 — The Point | [`07-adaptation/ep97-...md`](07-adaptation/ep97-adaptive-state-management-the-point.md) | macOS 앱을 만들어 증명한다. 팝오버 vs 모달, 더블탭 제거처럼 플랫폼마다 상호작용이 달라지니 액션 집합도 갈린다. 아키텍처 코드는 한 줄도 안 바뀐다. |

### 08 · Ergonomics

> **먼저 읽을 것** → [`08-ergonomics/00-overview.md`](08-ergonomics/00-overview.md) — 두 편을 잇는 섹션 통합본.
>
> 06·07이 동작의 결함을 고쳤다면 08은 **쓰는 사람 입장**에서 다듬는다. Ep. 98 도입부가 오픈소스 공개를 앞두고 손본다고 밝히므로, 여기까지가 초기 TCA의 완성형이다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`08-ergonomics/00-overview.md`](08-ergonomics/00-overview.md) | 자유 함수를 `Reducer` 구조체 메서드로 옮기고(98), 뷰 쪽 접근과 바인딩을 다듬는다(99). 아키텍처의 의미는 그대로고 표현만 바뀐다. |
| Ep. 98 — Part 1 | [`08-ergonomics/ep98-...md`](08-ergonomics/ep98-ergonomic-state-management-part-1.md) | `combine`·`pullback`·`logging`이 전역 이름공간을 차지하던 걸 `Reducer` 구조체 안으로. `pullback`의 제네릭이 6개 → 3개로 줄어든다. |
| Ep. 99 — Part 2 | [`08-ergonomics/ep99-...md`](08-ergonomics/ep99-ergonomic-state-management-part-2.md) | key path 기반 `@dynamicMemberLookup`으로 `viewStore.value.count`를 `viewStore.count`로. 절반은 바인딩 — 읽기는 상태, 쓰기는 액션으로 가는 헬퍼. |

### 09 · Async Composable Architecture

> **먼저 읽을 것** → [`09-async-composable-architecture/00-overview.md`](09-async-composable-architecture/00-overview.md) — 여섯 편을 잇는 섹션 통합본.
>
> 08(Ep. 99)에서 여기(Ep. 195)까지 2년이 비어 있다. 그 사이 TCA가 오픈소스로 공개됐으므로, 이 섹션은 **이미 널리 쓰이는 라이브러리**를 고치는 작업이다. 섹션 설명도 "2020년 5월 공개 이후 가장 큰 업데이트"라고 부른다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`09-.../00-overview.md`](09-async-composable-architecture/00-overview.md) | Combine 기반 `Effect`를 구조적 동시성으로 옮긴다. 조건은 하나 — 즉시 실행되는 결정적 테스트를 유지할 것. |
| Ep. 195 — The Problem (무료) | [`ep195-...md`](09-async-composable-architecture/ep195-async-composable-architecture-the-problem.md) | async/await를 그냥 얹으면 깨지는 것 넷: Sendable 위반, 에러 처리 불일치, 테스트 불안정(`XCTWaiter`로 0.1초 대기), 의존성 두 벌. |
| Ep. 196 — Tasks | [`ep196-...md`](09-async-composable-architecture/ep196-async-composable-architecture-tasks.md) | `Result`는 실패 타입이 존재 타입이라 `Equatable`이 안 되는데 테스트는 액션을 값으로 비교한다. 그 자리를 `TaskResult`가 메운다. |
| Ep. 197 — Schedulers | [`ep197-...md`](09-async-composable-architecture/ep197-async-composable-architecture-schedulers.md) | `Task.sleep`을 쓰면 테스트가 실제로 기다린다. 당분간 Combine `Scheduler`를 async처럼 감싸는 절충 — 이후 `Clock`으로 대체된다. |
| Ep. 198 — Streams | [`ep198-...md`](09-async-composable-architecture/ep198-async-composable-architecture-streams.md) | `task`는 결과를 하나 내고 끝난다. 액션을 여러 번 보내는 헬퍼(`.run { send in }`)를 만들어 타이머·진행 보고를 담는다. |
| Ep. 199 — Effect Lifetimes | [`ep199-...md`](09-async-composable-architecture/ep199-async-composable-architecture-effect-lifetimes.md) | Swift에 비동기 `deinit`이 없어서, 액션에서 `Task`를 돌려받아 SwiftUI `.task`에 물린다. 뷰가 사라지면 효과가 자동 취소. |
| Ep. 200 — In Practice (무료) | [`ep200-...md`](09-async-composable-architecture/ep200-async-composable-architecture-in-practice.md) | 실제 출시작 isowords를 옮기며 전후 비교. 12줄 애니메이션이 3줄로. **기존 테스트가 유의미한 변경 없이 통과**한 게 핵심 성과. |

### 10 · Reducer Protocol

> **먼저 읽을 것** → [`10-reducer-protocol/00-overview.md`](10-reducer-protocol/00-overview.md) — 여덟 편을 잇는 섹션 통합본. 이 컬렉션에서 가장 긴 섹션이고, Ep. 201의 문제 다섯이 이후 일곱 편의 목차라 대응표를 앞에 뒀다.
>
> 09와 성격이 같다. 이미 공개된 라이브러리를 크게 고치는 작업이고, 무료 편 둘(문제·실물)로 열고 닫는다. 해법이 Swift 5.7 기능(result builder, primary associated types)에 크게 기댄다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`10-.../00-overview.md`](10-reducer-protocol/00-overview.md) | 클로저였던 리듀서를 프로토콜 준수 타입으로 바꾼다. 이름공간·타입추론·인라인 문제가 한꺼번에 풀리고, environment가 `@Dependency`로 대체된다. |
| Ep. 201 — The Problem (무료) | [`ep201-...md`](10-reducer-protocol/ep201-reducer-protocol-the-problem.md) | 구조체 기반의 한계 다섯. 자동완성이 깨지고, 조합 순서를 API가 강제 못 하고, 말단에 의존성 하나 추가하면 위 계층을 전부 고쳐야 하고, 스택 프레임이 100개 쌓인다. |
| Ep. 202 — The Solution | [`ep202-...md`](10-reducer-protocol/ep202-reducer-protocol-the-solution.md) | 리듀서를 타입으로. `pullback`·`combine`도 메서드가 아니라 타입이 된다 — `Publishers.Map`과 같은 구조. |
| Ep. 203 — Composition 1 | [`ep203-...md`](10-reducer-protocol/ep203-reducer-protocol-composition-part-1.md) | 202 결과물이 "이상적이지 않다"고 스스로 인정하고 result builder로 다시 짠다. 가변 제네릭이 없던 시절이라 SE-0348로 우회. |
| Ep. 204 — Composition 2 | [`ep204-...md`](10-reducer-protocol/ep204-reducer-protocol-composition-part-2.md) | 말단/합성 두 스타일을 SwiftUI `View`처럼 하나의 프로토콜로 통합. primary associated types(SE-0346)가 결정적. |
| Ep. 205 — Dependencies 1 | [`ep205-...md`](10-reducer-protocol/ep205-reducer-protocol-dependencies-part-1.md) | 리듀서에서 environment가 이미 사라진 상태. SwiftUI `@Environment`를 본떠 `DependencyKey`·`DependencyValues`·`@Dependency`를 만든다. |
| Ep. 206 — Dependencies 2 | [`ep206-...md`](10-reducer-protocol/ep206-reducer-protocol-dependencies-part-2.md) | 암묵적으로 흐르되 **범위를 좁혀 덮어쓰기**. 온보딩·프리뷰용. 06 섹션이 전역을 걷어낸 이유를 새 체계에서 지킨다. |
| Ep. 207 — Testing | [`ep207-...md`](10-reducer-protocol/ep207-reducer-protocol-testing.md) | 테스트 패턴을 라이브러리에 심는다. 의존성 기본값을 **호출되면 실패**로 두어 빠뜨린 것이 드러나게. |
| Ep. 208 — In Practice (무료) | [`ep208-...md`](10-reducer-protocol/ep208-reducer-protocol-in-practice.md) | 스택 프레임 269 → 113 → **31**. 재귀 리듀서가 `Self()` 참조만으로 되고, `previewValue`·`ifCaseLet`이 추가된다. 100% 하위 호환. |

### 11 · Navigation

> **먼저 읽을 것** → [`11-navigation/00-overview.md`](11-navigation/00-overview.md) — 열여섯 편을 잇는 섹션 통합본.
>
> **이 컬렉션에서 가장 큰 섹션**(16편 · 약 13시간, 01~08 합친 규모)이자 **근거가 가장 얇은 섹션**이다. 무료 편이 하나도 없어 섹션 제목·도입부·시간 배분에서 읽어낸 서술이다. 실제 API는 [TCA 공식 문서](https://pointfreeco.github.io/swift-composable-architecture/)로 확인할 것.
>
> 제목은 내비게이션이지만 실제 주제는 **기능 간 통신**이다. 트리 기반(222~230)과 스택 기반(231~237) 두 아크로 갈린다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`11-navigation/00-overview.md`](11-navigation/00-overview.md) | 두 아크의 대칭, 트리 vs 스택 대조표, 목적별 읽는 순서. 16편을 통째로 볼 필요는 없다. |
| Ep. 222 — Tabs | [`ep222-...md`](11-navigation/ep222-composable-navigation-tabs.md) | 09·10 섹션과 SwiftUI 내비게이션 정리가 선행돼야 했던 이유. "대통일 이론" — 모든 형태가 비슷한 API를 공유한다. delegate 패턴. |
| Ep. 223 — Alerts & Dialogs | [`ep223-...md`](11-navigation/ep223-composable-navigation-alerts-dialogs.md) | 가장 단순한 형태부터. `Reducer.alert`가 dismiss 액션과 상태 비우기를 감춘다. |
| Ep. 224 — Sheets | [`ep224-...md`](11-navigation/ep224-composable-navigation-sheets.md) | 시트는 안에 온전한 기능이 들어가 부모·자식이 진짜로 통신해야 한다. 223의 복붙을 스스로 비판하며 시작. |
| Ep. 225 — Effect Cancellation | [`ep225-...md`](11-navigation/ep225-composable-navigation-effect-cancellation.md) | 닫힌 뒤 남은 효과의 액션은 허공으로 사라진다. `.task`가 못 덮는 빈틈을 메운다. 비전수 테스트 도입. |
| Ep. 226 — Unification | [`ep226-...md`](11-navigation/ep226-composable-navigation-unification.md) | 알럿·다이얼로그·시트를 하나로. 그러자 팝오버 6분, 커버 2분에 붙는다. |
| Ep. 227 — Links | [`ep227-...md`](11-navigation/ep227-composable-navigation-links.md) | 드릴다운. 당시 iOS 16 미만 지원이 많아 deprecated API로 먼저 만든다. |
| Ep. 228 — Destinations | [`ep228-...md`](11-navigation/ep228-composable-navigation-destinations.md) | iOS 16 `navigationDestination`. 여섯 형태를 균일하게 다룰 수 있는 건 도메인을 먼저 모델링했기 때문. |
| Ep. 229 — Correctness | [`ep229-...md`](11-navigation/ep229-composable-navigation-correctness.md) | 옵셔널 넷이면 16가지 상태 중 유효한 건 5가지. enum 하나로 불가능한 상태를 표현 불가능하게. |
| Ep. 230 — Stack vs Heap | [`ep230-...md`](11-navigation/ep230-composable-navigation-stack-vs-heap.md) | 중첩으로 루트 상태가 부푸는 우려. 컬렉션·문자열은 힙에 있고, 나머지는 프로퍼티 래퍼로 도구에 효율을 심는다. |
| Ep. 231 — vs Trees | [`ep231-...md`](11-navigation/ep231-composable-stacks-vs-trees.md) | 트리(기능이 기능을 품음) vs 스택(평평한 배열). 둘 다 필요한 이유. |
| Ep. 232 — Multiple Layers | [`ep232-...md`](11-navigation/ep232-composable-stacks-multiple-layers.md) | 여러 겹 드릴다운. 프로그래밍 방식 조작이 스택 모델의 이점. |
| Ep. 233 — Multiple Destinations | [`ep233-...md`](11-navigation/ep233-composable-stacks-multiple-destinations.md) | 종류가 다른 화면을 enum으로 섞는다. 기존 도구의 한계를 인정하고 전용 도구를 구상. |
| Ep. 234 — Action Ergonomics | [`ep234-...md`](11-navigation/ep234-composable-stacks-action-ergonomics.md) | `NavigationStackStore`. `PresentationState`/`Action`에서 영감을 얻어 스택으로 확장. |
| Ep. 235 — State Ergonomics | [`ep235-...md`](11-navigation/ep235-composable-stacks-state-ergonomics.md) | `StackState`. "identifiable 광기"와 통제되지 않는 UUID로 인한 테스트 복잡도를 해결. |
| Ep. 236 — Effect Cancellation | [`ep236-...md`](11-navigation/ep236-composable-stacks-effect-cancellation.md) | 스택판 효과 취소. `StackAction`의 해상도를 높여 밀어넣기·빠져나오기·자식 닫기를 구별. |
| Ep. 237 — Testing | [`ep237-...md`](11-navigation/ep237-composable-stacks-testing.md) | 테스트를 쓰다가 도구의 부족함을 발견하고 고친다. 테스트가 설계 검증 도구로 쓰인다. |

### 12 · A tour of the Composable Architecture 1.0

> **먼저 읽을 것** → [`12-composable-architecture-1-0/00-overview.md`](12-composable-architecture-1-0/00-overview.md) — 일곱 편을 잇는 섹션 통합본.
>
> **앞의 열한 섹션과 방향이 반대다.** 01~11이 "왜 이렇게 만들었나"라면 12는 "완성된 걸 어떻게 쓰나"다. **TCA를 처음 배운다면 여기부터 시작해도 된다.**
>
> Apple의 Scrumdinger를 TCA로 다시 만든다(이름은 Standups). Apple 공식 샘플이 비교 대상이라는 점이 이 섹션의 무게다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`12-.../00-overview.md`](12-composable-architecture-1-0/00-overview.md) | 카운터로 코어를 훑고(243) Scrumdinger 규모의 앱을 완성한다. 앞 섹션들의 결정이 실제 앱에서 어떻게 값을 하는지 대조표로 정리. |
| Ep. 243 — The Basics (무료) | [`ep243-...md`](12-composable-architecture-1-0/ep243-tour-the-basics.md) | 57분 중 26분이 테스트. 액션 이름은 사용자가 UI에서 한 일을 반영해야 한다는 원칙, 테스트 클럭으로 60배 빨라지는 테스트. |
| Ep. 244 — Introducing Standups | [`ep244-...md`](12-composable-architecture-1-0/ep244-tour-introducing-standups.md) | Scrumdinger 투어 후 폼부터 만든다. 말단 기능이라 독립적으로 만들고 테스트할 수 있다. |
| Ep. 245 — Navigation | [`ep245-...md`](12-composable-architecture-1-0/ep245-tour-navigation.md) | 시트로 폼 붙이기(트리 기반). "Scrumdinger 회고" 섹션에서 Apple 원본과 대조한다. |
| Ep. 246 — Stacks | [`ep246-...md`](12-composable-architecture-1-0/ep246-tour-stacks.md) | 상세로 드릴다운(스택 기반). 상태가 배열이라 딥링크가 자연스럽다. |
| Ep. 247 — Domain Modeling | [`ep247-...md`](12-composable-architecture-1-0/ep247-tour-domain-modeling.md) | 목적지 4개면 16 중 5만 유효(70% 무효), 5개면 90% 초과. 옵셔널 여럿 대신 enum. |
| Ep. 248 — Dependencies | [`ep248-...md`](12-composable-architecture-1-0/ep248-tour-dependencies.md) | 음성 인식 권한 조회 `await`가 프리뷰에서 영영 재개되지 않는다. `previewValue`가 왜 필요했는지 실물로 확인되는 자리. |
| Ep. 249 — Persistence | [`ep249-...md`](12-composable-architecture-1-0/ep249-tour-persistence.md) | 영속화가 프리뷰·테스트를 망가뜨리는 방식과 통제의 이점. 로직을 효과에 두어 리듀서는 단순 함수로 유지. |

### 13 · Observable Architecture

> **먼저 읽을 것** → [`13-observable-architecture/00-overview.md`](13-observable-architecture/00-overview.md) — 여덟 편을 잇는 섹션 통합본.
>
> **앞 섹션들이 도구를 더했다면 이 섹션은 지운다.** `ViewStore`·`IfLetStore`·`SwitchStore`·`ForEachStore`·내비게이션 전용 modifier가 전부 사라진다. 공통점은 "최소 관찰을 손으로 하려고 만든 것"이라는 점 — 언어가 그걸 해 주자 존재 이유를 잃는다.
>
> **지금 TCA를 쓴다면 이 섹션이 현재 상태에 가장 가깝다.** 01~12에서 배운 `WithViewStore` 같은 건 이미 옛 API다.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`13-.../00-overview.md`](13-observable-architecture/00-overview.md) | 사라지는 API 대조표, 값 타입 관찰이라는 기술적 과제, "11 섹션이 헛수고였나"에 대한 정리. |
| Ep. 259 — Sneak Peek (무료) | [`ep259-...md`](13-observable-architecture/ep259-observable-architecture-sneak-peek.md) | 22분에 결과를 다 보여준다. `WithViewStore { ... }`가 `store.count`가 되고, 뷰가 읽은 프로퍼티만 자동 추적된다. |
| Ep. 260 — Structural Identity | [`ep260-...md`](13-observable-architecture/ep260-observable-architecture-structural-identity.md) | 근본 불일치 — 이 아키텍처는 값 타입, `@Observable`은 클래스 전용. 상태에 구조적 정체성을 부여해 해결. |
| Ep. 261 — Observing Optionals | [`ep261-...md`](13-observable-architecture/ep261-observable-architecture-observing-optionals.md) | 구조체용 `@ObservableState` 매크로(Swift 오픈소스 구현을 가져다 고침). `IfLetStore` → 평범한 `if let`. |
| Ep. 262 — Observing Enums | [`ep262-...md`](13-observable-architecture/ep262-observable-architecture-observing-enums.md) | `SwitchStore`는 enum 최소 관찰만을 위해 존재했으므로 완전히 불필요해진다. |
| Ep. 263 — Observing Collections | [`ep263-...md`](13-observable-architecture/ep263-observable-architecture-observing-collections.md) | 요소가 여럿이라 난이도가 한 단계 높다(53분). `ForEachStore` → 평범한 `ForEach`, 그러면서 새 능력도 얻는다. |
| Ep. 264 — Observing Navigation | [`ep264-...md`](13-observable-architecture/ep264-observable-architecture-observing-navigation.md) | 11 섹션의 전용 modifier를 걷어내고 평범한 `.sheet` 등을 쓴다. 도메인 모델링은 남고 뷰 층 헬퍼만 사라진다. |
| Ep. 265 — Observing Bindings | [`ep265-...md`](13-observable-architecture/ep265-observable-architecture-observing-bindings.md) | "첫날부터 껄끄러웠다"고 인정. Observation이 처음부터 하고 싶었던 방식을 가능하게 했다. |
| Ep. 266 — The Point | [`ep266-...md`](13-observable-architecture/ep266-observable-architecture-the-point.md) | 시뮬레이터 통합 테스트로 store 생성·scope·뷰 재계산을 측정. 가장 오래된 예제 Todos를 새 도구로 옮긴다. |

### 14 · Sharing and Persisting State

> **먼저 읽을 것** → [`14-sharing-and-persisting-state/00-overview.md`](14-sharing-and-persisting-state/00-overview.md) — 아홉 편을 잇는 섹션 통합본.
>
> **이 컬렉션의 근본 원칙을 건드리는 섹션이다.** Ep. 68 이래 흔들린 적 없던 "상태는 값 타입"에 참조 타입을 들인다. 13 섹션의 관찰 도구가 뷰 무효화 문제를 풀어 준 덕에 가능해졌다.
>
> 11 섹션과 함께 근거가 얇다 — 무료 편이 하나도 없다. 실제 API는 [TCA 공식 문서](https://pointfreeco.github.io/swift-composable-architecture/)로 확인할 것.

| 영상 | 문서 | 한 줄 요약 |
|---|---|---|
| _(통합본)_ | [`14-.../00-overview.md`](14-sharing-and-persisting-state/00-overview.md) | 참조 타입을 통제된 방식으로 들인다. 만든 뒤 곧바로 두 편을 테스트 복구에 쓰는 게 이 시리즈의 일관된 기준. |
| Ep. 268 — The Problem | [`ep268-...md`](14-sharing-and-persisting-state/ep268-shared-state-the-problem.md) | TCA 사용자에게서 가장 흔한 질문 중 하나. 단일 진실 공급원인데 기능은 자기 조각만 본다는 역설. 값 타입 동기화와 의존성, 둘 다 대가가 있다. |
| Ep. 269 — The Solution 1 | [`ep269-...md`](14-sharing-and-persisting-state/ep269-shared-state-the-solution-part-1.md) | "처음부터 참조 타입을 그냥 넣었으면 어땠을까?" 우회로 대신 정면 실험. `@Shared`가 나온다. |
| Ep. 270 — The Solution 2 | [`ep270-...md`](14-sharing-and-persisting-state/ep270-shared-state-the-solution-part-2.md) | 회원가입 흐름으로 검증. `@Reducer` 매크로가 기능 enum 보일러플레이트를 생성해 준다는 점도 확인된다. |
| Ep. 271 — Testing 1 | [`ep271-...md`](14-sharing-and-persisting-state/ep271-shared-state-testing-part-1.md) | 참조 타입은 복사가 안 되니 "이전 상태"가 없다. 전후 스냅샷 비교가 기반이던 전수 검증이 깨진다. |
| Ep. 272 — Testing 2 | [`ep272-...md`](14-sharing-and-persisting-state/ep272-shared-state-testing-part-2.md) | 참조 타입 기능을 값 타입인 것처럼 빠짐없이 테스트하는 데 이른다. 공유 상태 기법으로 디버깅 도구도 만든다. |
| Ep. 273 — User Defaults 1 | [`ep273-...md`](14-sharing-and-persisting-state/ep273-shared-state-user-defaults-part-1.md) | 넘겨주는 상태에서 **편재하는 상태**로. `@Dependency`가 의존성에 한 일을 상태에 한다. |
| Ep. 274 — User Defaults 2 | [`ep274-...md`](14-sharing-and-persisting-state/ep274-shared-state-user-defaults-part-2.md) | 바깥에서 값이 바뀐 걸 감지 못 하는 문제. `PersistenceKey` 프로토콜에 외부 변경 서술 능력을 넣어 일반화. |
| Ep. 275 — File Storage 1 | [`ep275-...md`](14-sharing-and-persisting-state/ep275-shared-state-file-storage-part-1.md) | 엣지 케이스 넷 — 디바운싱 → 백그라운드 저장 → 외부 쓰기 관찰 → 피드백 루프. 기능이 다음 문제를 만드는 순서. |
| Ep. 276 — File Storage 2 | [`ep276-...md`](14-sharing-and-persisting-state/ep276-shared-state-file-storage-part-2.md) | 파일 시스템은 "크고 전역적이고 가변인 덩어리"라 테스트 격리가 깨진다. 그리고 큰 상태에서 작은 공유 상태 파생. |
