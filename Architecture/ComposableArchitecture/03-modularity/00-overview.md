# 03 · Modularity — 네 편 흐름

Point-Free [Modularity](https://www.pointfree.co/collections/composable-architecture/modularity) 섹션(Ep. 72~75)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 네 편 모두 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT)의 실제 소스로 확인했다

관련 문서

- [ep72 — Reducers](ep72-modular-state-management-reducers.md) · 리듀서를 프레임워크로 쪼갠다
- [ep73 — View State](ep73-modular-state-management-view-state.md) · 뷰가 보는 상태를 좁힌다
- [ep74 — View Actions](ep74-modular-state-management-view-actions.md) · 뷰가 보내는 액션을 좁힌다
- [ep75 — The Point](ep75-modular-state-management-the-point.md) · 각 화면을 독립 앱으로 띄워 결산한다

---

## 이 섹션이 하는 일

섹션 설명이 모듈화를 이렇게 정의한다. 각 기능을 자기 모듈에 넣어 독립적으로 빌드되게 하면서도, 앱 전체에는 그대로 끼워 넣을 수 있는 상태.

[02 섹션](../02-reducers-and-stores/00-overview.md)에서 리듀서를 쪼개고 붙이는 도구를 만들었지만 그건 파일 안에서의 분리였다. 여기서는 그걸 컴파일러가 강제하는 경계로 만든다. 모듈 밖에서 보이려면 `public`을 붙여야 하고, 안 붙인 건 접근 자체가 안 된다. 규율의 문제가 타입 시스템의 문제가 된다.

## 네 편이 쌓이는 순서

### Ep. 72 — 리듀서를 프레임워크로

코드 구조가 이 편에서 완전히 바뀐다. 02 섹션까지는 플레이그라운드 파일 하나였는데 실제 Xcode 프로젝트에 프레임워크 여러 개로 나뉜다.

```
PrimeTime/
├── ComposableArchitecture/   Store, combine, pullback, logging
├── Counter/
├── FavoritePrimes/
├── PrimeModal/
└── PrimeTime/                앱
```

모듈마다 테스트 타깃이 하나씩 붙는다. 아키텍처 프레임워크가 밖으로 내놓는 건 `Store`, `combine`, `pullback`, `logging` 넷뿐이고, 02 섹션에서 만든 것들에 `public`을 붙였을 뿐 새 개념은 없다.

여기서 이 아키텍처의 성질이 드러난다. 리듀서가 이미 지역 상태·지역 액션만 알도록 만들어져 있었으니 옮기는 데 구조를 바꿀 게 없었다. 02 섹션에서 합성 가능하게 설계한 것의 배당금이다.

그런데 뷰는 여전히 `Store<AppState, AppAction>`을 받는다. 모듈이 앱 상태 타입을 알아야 한다면 앱 없이 빌드될 수 없으니 모듈로 나눈 의미가 없다.

### Ep. 73 — 뷰가 보는 상태를 좁히다

store 자체를 변환하는 메서드를 만든다.

```swift
func view<LocalValue>(_ f: @escaping (Value) -> LocalValue) -> Store<LocalValue, Action>
```

리듀서 때와 방향이 반대인 게 이 편의 핵심이다.

- pullback은 `WritableKeyPath<GlobalValue, LocalValue>`를 받았다 — 반변
- `view`는 `(Value) -> LocalValue`를 받는다 — 공변, map 쪽

리듀서는 상태를 소비하니 반변이고, store는 상태를 내놓으니 공변이다. References에 [#13 The Many Faces of Map](https://www.pointfree.co/episodes/ep13-the-many-faces-of-map)과 [#14 Contravariance](https://www.pointfree.co/episodes/ep14-contravariance)가 나란히 걸린 이유다.

까다로운 부분은 연결 유지다. 지역 store를 새로 만들면 원본과 끊기니, 액션을 전역으로 흘려보내고 전역 상태가 바뀌면 다시 지역 값을 뽑아 온다. `view`가 만드는 건 복사본이 아니라 전역 store에 연결된 창이다.

### Ep. 74 — 뷰가 보내는 액션을 좁히다

`view`에 파라미터가 하나 늘어난다.

```swift
public func view<LocalValue, LocalAction>(
  value toLocalValue: @escaping (Value) -> LocalValue,
  action toGlobalAction: @escaping (LocalAction) -> Action
) -> Store<LocalValue, LocalAction>
```

두 함수의 방향이 반대다. 상태는 store에서 뷰로 내려오니 전역에서 지역을 꺼내고, 액션은 뷰에서 store로 올라가니 지역을 전역으로 감싼다.

리듀서 쪽과 비교하면 대응이 깔끔하다. 리듀서는 전역 액션에서 지역 액션을 꺼내야 해서 실패할 수 있어 optional을 썼지만, store는 감싸기만 하면 되니 실패할 일이 없다.

모듈 안에서는 액션이 두 겹이 된다. `CounterAction`은 카운터 리듀서의 도메인 액션이고, `CounterViewAction`은 카운터 화면이 보낼 수 있는 액션 전체다. 이 화면에 소수 모달이 떠 있으니 모달 액션도 들어간다. 화면 하나가 여러 기능을 품을 수 있어서 두 집합이 갈린다.

### Ep. 75 — 화면 하나하나를 앱으로 띄우다

결산 방식이 특이하다. 모듈화가 됐다고 주장하는 대신 **화면 하나하나를 독립된 앱처럼 실행해 보인다.** 즐겨찾기만, 소수 모달만, 카운터만 따로 돌린다.

References에 Playground Driven Development 자료가 세 개 걸려 있고, 저장소에도 `PrimeTime.playground`가 들어 있다. 앱 전체를 빌드하고 그 화면까지 네비게이션하는 대신 그 화면만 몇 초에 띄우는 방식이다.

목적도 분명히 한다. 각 화면이 격리된 미니 앱이면 앱 전체 구조를 몰라도 그 화면을 테스트할 수 있고, 그게 모듈형 상태 관리의 핵심 목표라는 것이다.

마지막에 루트 앱을 손본다. 모듈이 독립하면 조립하는 쪽에 일이 남는다. 전역 상태에서 화면 상태를 뽑고 지역 액션을 전역으로 감싸는 배선이다. 복잡함이 사라진 게 아니라 앱 타깃 한곳에 모이고 나머지 모듈이 깨끗해진다.

## 네 편을 한 줄로

리듀서를 모듈로 쪼갠 다음, store를 상태와 액션 양쪽으로 변환할 수 있게 만들면, 각 화면이 앱을 몰라도 빌드되고 실행되고 테스트된다.

## 02 섹션과 대칭

같은 순서를 두 번 반복한다는 게 이 섹션을 읽는 열쇠다.

| | 리듀서 (02 섹션) | store (03 섹션) |
|---|---|---|
| 상태 좁히기 | `pullback(value:)` — 반변, `WritableKeyPath` | `view(value:)` — 공변, 함수 |
| 액션 좁히기 | `pullback(action:)` — 전역에서 지역 꺼내기, optional | `view(action:)` — 지역을 전역으로 감싸기, 실패 없음 |
| 방향 | 상태를 소비 | 상태를 제공 |

## 01 섹션의 숙제 대조

| Ep. 67 | 한계 | 상태 |
|---|---|---|
| 4.2 | 상태 변경이 흩어져 있다 | 02 섹션에서 해결 |
| 4.4 | 상태 관리가 합성되지 않는다 | 02에서 도구, 03에서 모듈 경계까지 완료 |
| 4.3 | 부수효과 이야기가 없다 | 아직 — [`04-side-effects`](../04-side-effects/) |
| 4.5 | 테스트할 수 없다 | 아직 — [`05-testing`](../05-testing/). 다만 03이 그 조건을 갖췄다 |

## 영상 없이 볼 수 있는 것

- [episode-code-samples](https://github.com/pointfreeco/episode-code-samples) — 0072부터는 플레이그라운드가 아니라 `PrimeTime` 프로젝트다. 72 → 73 → 74 → 75 순으로 `ComposableArchitecture/ComposableArchitecture.swift`를 비교하면 `view`가 어떻게 자라는지 보인다 (50줄 → 87줄)
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams, 2017 Functional Swift Conference
- [Playground Driven Development](https://www.youtube.com/watch?v=DrdxSNG-_DE) — Brandon Williams, FrenchKit 2017. Ep. 75의 시연 방식을 이해하는 데 도움이 된다
- [Why Functional Programming Matters](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) — John Hughes, 1989. 네 편 모두에 걸려 있는 고전

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 72](ep72-modular-state-management-reducers.md) — 모듈화의 정의와 프레임워크 분리
3. [Ep. 73](ep73-modular-state-management-view-state.md) → [Ep. 74](ep74-modular-state-management-view-actions.md) — 상태와 액션은 짝이니 붙여서 본다
4. [Ep. 75](ep75-modular-state-management-the-point.md) — 결산

02 섹션과 대칭이라 위 대조표를 옆에 두고 읽으면 빠르다.

## 확인 범위

확인한 것

- 섹션 제목과 타임스탬프, 도입부, 에피소드 설명, References 전체
- 모듈 구조와 공개 API, `view` 메서드 시그니처의 편별 변화

확인하지 못한 것

- 논증의 세부, 이름을 고르는 과정(Ep. 73 "What's in a name?"), Ep. 74 "Combining view functions"
- Ep. 75의 결산 내용과 화면별 실행 시연

저장소 코드는 이후 갱신됐을 수 있어 2019년 영상 시점과 정확히 같다는 보장은 없다.
