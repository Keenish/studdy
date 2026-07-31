# 04 · Side Effects — 여섯 편 흐름

Point-Free [Side Effects](https://www.pointfree.co/collections/composable-architecture/side-effects) 섹션(Ep. 76~81)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 76~79는 영상이 유료라 섹션 제목·도입부·References만 확인했고, 코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT) 소스로 확인했다. **80·81은 무료 영상이라 트랜스크립트 전문을 근거로 정리했다**

관련 문서

- [ep76 — Synchronous Effects](ep76-effectful-state-management-synchronous-effects.md) · 효과를 값으로 반환한다
- [ep77 — Unidirectional Effects](ep77-effectful-state-management-unidirectional-effects.md) · 효과가 액션을 돌려준다
- [ep78 — Asynchronous Effects](ep78-effectful-state-management-asynchronous-effects.md) · 콜백을 받아 비동기를 담는다
- [ep79 — The Point](ep79-effectful-state-management-the-point.md) · Effect가 타입이 되고 재사용 가능해진다
- [ep80 — Combine and Effects 1](ep80-the-combine-framework-and-effects-part-1.md) · Combine과 대조한다 (무료)
- [ep81 — Combine and Effects 2](ep81-the-combine-framework-and-effects-part-2.md) · Combine으로 갈아 끼운다 (무료)

---

## 이 섹션이 하는 일

섹션 설명이 부수효과를 "애플리케이션에서 가장 복잡한 부분"이라고 부른다. [Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)의 숙제 넷 중 셋째다.

풀어야 할 문제는 이렇다. 리듀서가 순수 함수라는 게 이 아키텍처의 전제인데, 네트워크나 디스크를 리듀서 안에서 부르면 그 전제가 깨진다. 그렇다고 뷰에 두면 앞 섹션에서 애써 모은 로직이 다시 흩어지고 테스트도 안 된다.

답은 한 문장이다. **리듀서는 효과를 실행하지 않고 값으로 반환하고, 실행은 store가 한다.** 리듀서는 순수한 채로 남고 불순한 부분은 한 지점에 격리된다.

## Effect 타입의 변천이 곧 이 섹션의 줄거리

편마다 `Effect`의 정의가 한 단계씩 바뀐다. 소스에서 이 줄만 따라가도 흐름이 보인다.

| 편 | Effect | 할 수 있게 된 일 |
|---|---|---|
| 76 | `() -> Void` | 밖으로 쓰기만 (fire-and-forget) |
| 77 | `() -> Action?` | 동기적으로 결과를 액션으로 반환 |
| 78 | `(@escaping (Action) -> Void) -> Void` | 콜백으로 비동기 결과 전달 |
| 79 | `struct Effect<A> { let run: … }` | 타입이 되어 `map` 등 메서드를 가짐 |
| 81 | `struct Effect<Output>: Publisher` | Combine 생태계 전체를 쓸 수 있음 |

리듀서 시그니처도 76에서 `-> Effect` 하나였다가 77부터 `-> [Effect<Action>]` 배열이 된다. 하나의 액션이 여러 효과를 일으킬 수 있으니 자연스러운 변화다.

## 여섯 편이 쌓이는 순서

### Ep. 76 — 효과를 값으로

리듀서가 부수효과를 실행하는 대신 반환한다. 이 시점의 `Effect`는 `() -> Void`라 밖으로 쓰기만 하고 읽어 올 수는 없다. 디스크에 저장은 되는데 불러올 수는 없는 상태다.

References가 특징적이다. Redux Middleware, Redux Thunk, ReSwift, SwiftUIFlux가 나란히 걸려 있다. 같은 문제를 미들웨어로 푸는 다른 구현들이고, 이 아키텍처가 택하지 않은 길이다.

### Ep. 77 — 효과가 액션을 돌려준다

`() -> Action?`으로 바뀐다. 효과가 끝나면 액션을 만들어 낼 수 있다.

왜 상태를 직접 고치게 하지 않고 액션으로 돌려주는가. 효과가 상태를 직접 건드리면 변경 경로가 다시 여러 개가 되고, 01 섹션에서 겪은 문제로 돌아간다. 액션으로 되먹이면 상태가 바뀌는 길은 여전히 리듀서 하나다.

```
액션 → 리듀서 → (상태 변경 + 효과 반환) → store가 효과 실행 → 새 액션 → 리듀서 → …
```

Elm의 Commands and Subscriptions가 정확히 같은 구조이고, References에 그대로 걸려 있다.

### Ep. 78 — 비동기

`() -> Action?`은 동기라 호출하면 그 자리에서 답이 나와야 한다. 네트워크나 디스크 읽기는 안 담긴다.

그래서 반환값 대신 콜백을 받는 모양으로 바꾼다. 효과가 자기 일이 끝나는 시점에 콜백을 불러 액션을 넘긴다. 앞의 두 모양은 이 모양의 특수한 경우다 — 콜백을 즉시 부르면 동기, 안 부르면 fire-and-forget.

"Refactor-related bugs"라는 섹션이 따로 있다. 효과를 뷰에서 리듀서로 옮기면서 alert 상태 같은 것들을 앱 상태로 끌어올려야 했고, 그 과정에서 실제로 문제가 생겼다.

### Ep. 79 — 결산

`Effect`가 `typealias`를 벗고 구조체가 된다. 담은 함수 모양은 같은데 이제 메서드를 붙일 수 있다. `map`이 대표적이다.

네트워크 요청과 스레딩을 재사용 가능한 효과로 뽑아 보인다. 스레딩이 별도 섹션인 게 의미가 있는데, 결과를 메인 큐로 되돌리는 일은 원래 호출 지점마다 흩어지기 쉽다. 효과가 값이니 "메인 큐에서 받게 한다"는 변환을 만들어 어디에나 붙일 수 있다. [Ep. 71](../02-reducers-and-stores/ep71-composable-state-management-higher-order-reducers.md)의 고차 리듀서와 같은 발상이 대상만 바뀌어 반복된다.

### Ep. 80 — Combine과 대조 (무료)

네 편에 걸쳐 만든 `Effect`가 Apple의 Combine과 같은 것을 가리킨다는 걸 확인한다. 코드는 고치지 않는다. 저장소에도 `Combine.playground` 하나뿐이다.

| Effect | Combine |
|---|---|
| `Effect<A>` | `Publisher` |
| `run` 호출 | `Subscriber` / `sink` |

이 편에서 가장 실질적인 발견은 `Future`가 **성급하다**는 것이다. 구독할 때가 아니라 만들어지는 순간 실행된다. 리듀서가 효과를 반환만 하고 실행은 store가 해야 하는 구조에서는 치명적이다. 리듀서가 상태를 계산하는 도중에 부수효과가 터진다.

해법은 `Deferred`로 감싸 구독 시점까지 미루는 것이다.

### Ep. 81 — 갈아 끼우기 (무료)

`Effect`가 Combine 퍼블리셔를 감싸는 구조체가 된다. `Failure`는 `Never`로 고정한다. 효과는 실패할 수 없고, 에러가 날 수 있는 일이면 그 에러를 액션에 담아야 한다.

store가 `Set<AnyCancellable>`로 구독을 관리한다. 여기서 경쟁 조건이 하나 나온다. 퍼블리셔가 즉시 완료되면 cancellable이 집합에 들어가기 전에 완료 핸들러가 먼저 돌아서, 플래그로 순서를 정리해야 한다. 동기 효과가 흔한 아키텍처라 실제로 부딪히는 문제다.

## 결론에서 인정하는 한계

Ep. 81의 마지막이 이 섹션 전체의 값을 정리한다.

**얻은 것** — 초점이 좁고 변환 가능한 추상을 만들어 두면 큰 리팩터링에 열려 있다. `Effect`의 구현을 통째로 갈아 끼웠는데 리듀서 시그니처(`-> [Effect<Action>]`)는 그대로였고 위에 쌓인 코드도 대부분 살았다.

**한계** — Swift의 타입 시스템으로는 효과를 일반화해 표현할 수 없다. 그래서 RxSwift 같은 다른 리액티브 라이브러리를 끼워 넣을 방법이 없고 Combine으로 고정된다.

두 번째를 솔직하게 인정하는 게 이 편의 미덕이다. 합성 가능하게 만들었다고 모든 축에서 자유로워지는 건 아니다.

## 01 섹션의 숙제 대조

| Ep. 67 | 한계 | 상태 |
|---|---|---|
| 4.2 | 상태 변경이 흩어져 있다 | 02 섹션에서 해결 |
| 4.4 | 상태 관리가 합성되지 않는다 | 02·03 섹션에서 해결 |
| 4.3 | 부수효과 이야기가 없다 | **이 섹션에서 해결** |
| 4.5 | 테스트할 수 없다 | 아직 — [`05-testing`](../05-testing/) |

Ep. 67이 부수효과 문제로 든 것이 취소·디바운스 부재, 테스트 불가, 그리고 **효과를 가리키는 데이터 타입이 없다**는 점이었다. 마지막 항목이 이 섹션의 답이다. 효과가 값이 되면 나머지가 따라온다.

## 영상 없이 볼 수 있는 것

- [Ep. 80](https://www.pointfree.co/episodes/ep80-the-combine-framework-and-effects-part-1)·[Ep. 81](https://www.pointfree.co/episodes/ep81-the-combine-framework-and-effects-part-2) — **이 두 편은 무료다.** 섹션의 종착지이자 Combine 대조라 독립적으로도 읽힌다
- [episode-code-samples](https://github.com/pointfreeco/episode-code-samples) — 76 → 81 순으로 `ComposableArchitecture.swift`의 `Effect` 정의 한 줄만 따라가도 흐름이 잡힌다
- [Elm: Commands and Subscriptions](https://guide.elm-lang.org/effects/) — 이 설계의 직접적 원형
- [Promises Are Not Neutral Enough](https://staltz.com/promises-are-not-neutral-enough.html) — André Staltz. Ep. 80의 `Future` 성급함 문제의 배경

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 76](ep76-effectful-state-management-synchronous-effects.md) → [77](ep77-effectful-state-management-unidirectional-effects.md) → [78](ep78-effectful-state-management-asynchronous-effects.md) — `Effect` 타입이 바뀌는 세 단계. 붙여서 본다
3. [Ep. 79](ep79-effectful-state-management-the-point.md) — 결산
4. [Ep. 80](ep80-the-combine-framework-and-effects-part-1.md) → [81](ep81-the-combine-framework-and-effects-part-2.md) — 무료라 원문을 직접 보는 걸 권한다

시간이 없으면 위 Effect 변천 표를 보고 80·81 원문으로 바로 가도 된다.

## 확인 범위

확인한 것

- 76~79: 섹션 제목과 타임스탬프, 도입부, 에피소드 설명, References. `Effect`와 `Reducer` 타입 정의의 편별 변화
- 80~81: 트랜스크립트 전문. 81은 코드도 대조했다

확인하지 못한 것

- 76~79의 논증 세부, Ep. 78에서 실제로 난 버그, Ep. 79의 재사용 효과 구현

저장소 코드는 이후 갱신됐을 수 있어 2019년 영상 시점과 정확히 같다는 보장은 없다.
