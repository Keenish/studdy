# Ep. 69 — Composable State Management: State Pullbacks

- 출처: [Point-Free Episode #69](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores/ep69-composable-state-management-state-pullbacks)
- 코드: [episode-code-samples/0069-...-state-pullbacks](https://github.com/pointfreeco/episode-code-samples/tree/main/0069-composable-state-management-state-pullbacks) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목과 도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:41 | Combining reducers |
| 8:37 | Focusing a reducer's state |
| 12:55 | Pulling back reducers along state |
| 18:11 | Key path pullbacks |
| 21:03 | Pulling back more reducers |
| 24:32 | Till next time |

---

## 이 편이 하려는 것

[Ep. 68](ep68-composable-state-management-reducers.md)에서 리듀서 하나로 변경을 모았다. 문제는 그 하나가 앱 전체를 떠안는다는 점이다.

화면이 스물 몇 개쯤 되는 앱이면 `appReducer`의 스위치문이 모든 화면의 모든 액션을 받는다. 유지보수가 안 되는 크기가 된다. 그래서 큰 리듀서를 작게 쪼갠 뒤 다시 합치는 도구를 만든다.

이 편은 상태 방향만 다룬다. 액션은 다음 편이다.

## 먼저 합치는 도구

리듀서를 쪼개려면 도로 붙이는 방법이 먼저 있어야 한다. `combine`은 리듀서 여러 개를 받아 하나로 만든다.

```swift
func combine<Value, Action>(
  _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
  return { value, action in
    for reducer in reducers {
      reducer(&value, action)
    }
  }
}
```

하는 일은 단순하다. 들어온 액션을 받은 리듀서마다 차례로 통과시킨다. 여러 리듀서가 같은 액션에 반응해도 되고, 대부분은 자기 것이 아니면 아무 일도 하지 않는다.

## 상태를 좁히기

이제 리듀서를 쪼갠다. 카운터 리듀서는 `AppState` 전체가 아니라 `Int` 하나만 있으면 된다.

```swift
func counterReducer(state: inout Int, action: AppAction)
```

문제는 store가 `AppState`를 들고 있다는 것이다. `Int`에서 도는 리듀서를 `AppState`에서 도는 리듀서로 바꿔야 한다. 그 변환이 pullback이다.

```swift
func pullback<LocalValue, GlobalValue, Action>(
  _ reducer: @escaping (inout LocalValue, Action) -> Void,
  value: WritableKeyPath<GlobalValue, LocalValue>
) -> (inout GlobalValue, Action) -> Void
```

전역 상태에서 지역 상태로 가는 key path를 주면, 지역 리듀서를 전역 리듀서로 끌어올려 준다.

### 왜 map이 아니라 pullback인가

이름이 헷갈리기 쉬운데 방향을 보면 이해가 된다.

- key path는 전역 → 지역 방향이다 (`AppState`에서 `Int`를 꺼낸다)
- 그런데 리듀서는 지역 → 전역 방향으로 승격된다

값이 흐르는 방향과 리듀서가 승격되는 방향이 반대다. 리듀서가 상태를 소비하는 쪽이라 상태 타입에 대해 반변(contravariant)이기 때문이다. 이렇게 방향이 뒤집히는 변환을 pullback이라 부른다.

새로 나온 개념은 아니다. Point-Free 14편에서 이미 다뤘는데 그때는 `contramap`이라는 이름이었고, 이후 수학 용어를 따라 `pullback`으로 바꿨다. 이름을 바꾼 이유를 정리한 글이 따로 있다. 직관에 반해 보이는 합성이라 이름이라도 근거가 있는 편이 낫다는 판단이었다.

여기서 한 발 더 나간다. 원래 pullback은 함수에 대해 정의되는데 이 편은 key path에 대해 쓴다. 그게 정당한 근거로 범주론을 든다. key path도 사상(morphism)으로 볼 수 있으니 개념을 그대로 확장할 수 있다는 것이다.

읽기만 하는 게 아니라 바꿔서 되돌려 놔야 하니 `KeyPath`가 아니라 `WritableKeyPath`가 필요하다.

## 조립

쪼갠 리듀서들을 combine으로 묶고, 그 결과를 다시 pullback한다.

```swift
let appReducer = pullback(_appReducer, value: \.self)
```

`\.self`가 눈에 띈다. 여기서는 이미 전역 상태 기준이라 항등 pullback이지만, 시그니처를 맞춰 두면 나중에 이 리듀서 자체를 더 큰 상태에 끼워 넣을 수 있다.

## 아직 남는 것

상태는 좁혔는데 액션은 그대로다. 위 `counterReducer`를 보면 상태는 `Int`인데 액션은 여전히 `AppAction`이다. 카운터 리듀서가 즐겨찾기 액션까지 받고 있는 셈이라 캡슐화가 반쪽이다.

이걸 [Ep. 70](ep70-composable-state-management-action-pullbacks.md)에서 맞춘다.

## 참고자료

에피소드 페이지의 References 중 이 편의 이해에 직접 걸리는 것들.

- [Contravariance](https://www.pointfree.co/episodes/ep14-contravariance) — Point-Free #14. pullback의 원형. 처음 볼 때 직관에 반하는 합성이라고 스스로 밝힌다
- [Some news about contramap](https://www.pointfree.co/blog/posts/22-some-news-about-contramap) — 2018-10. `contramap`을 `pullback`으로 개명한 경위
- [Pullback](https://en.wikipedia.org/wiki/Pullback) / [Category Theory](https://en.wikipedia.org/wiki/Category_theory) — 용어의 수학적 배경. key path를 사상으로 보는 근거
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams의 2017 Functional Swift Conference 강연. 무료
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 논증의 세부는 확인하지 못했다
- 코드는 공개 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있어 영상 시점과 정확히 같다는 보장은 없다
