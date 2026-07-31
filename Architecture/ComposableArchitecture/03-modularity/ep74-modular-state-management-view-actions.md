# Ep. 74 — Modular State Management: View Actions

- 출처: [Point-Free Episode #74](https://www.pointfree.co/episodes/ep74-modular-state-management-view-actions)
- 코드: [episode-code-samples/0074-modular-state-management-view-actions](https://github.com/pointfreeco/episode-code-samples/tree/main/0074-modular-state-management-view-actions) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:06 | Introduction |
| 0:40 | Transforming a store's action |
| 6:35 | Combining view functions |
| 8:45 | Focusing on favorite primes actions |
| 11:27 | Extracting our first modular view |
| 13:43 | Focusing on prime modal actions |
| 15:24 | Focusing on counter actions |
| 22:11 | Next time: what's the point? |

---

## 이 편이 하려는 것

[Ep. 73](ep73-modular-state-management-view-state.md)에서 뷰가 보는 상태를 좁혔다. 그런데 액션은 그대로라 뷰가 여전히 앱의 아무 액션이나 보낼 수 있다.

도입부에서 지금 상태를 이렇게 정리한다. 뷰가 더 작은 상태 조각 위에서 돌게 됐고, 그래서 store가 그 밑의 리듀서를 닮아 가고 있다. 그리고 변경이 얼마나 단순했는지를 강조한다 — 뷰가 필요한 것만 보게 상태를 바꾸고, 넘기는 store를 그에 맞게 변환한 게 전부였다는 것이다.

이 편은 액션에 같은 일을 해서 모듈화를 끝낸다.

## 액션도 받는 view

`view` 메서드에 파라미터가 하나 늘어난다.

```swift
public func view<LocalValue, LocalAction>(
  value toLocalValue: @escaping (Value) -> LocalValue,
  action toGlobalAction: @escaping (LocalAction) -> Action
) -> Store<LocalValue, LocalAction>
```

두 함수의 방향이 반대인 게 핵심이다.

- 상태는 `(Value) -> LocalValue` — 전역에서 지역을 꺼낸다
- 액션은 `(LocalAction) -> Action` — 지역을 전역으로 감싼다

당연하다. 상태는 store에서 뷰로 내려가고, 액션은 뷰에서 store로 올라간다. 흐르는 방향이 반대니 변환 방향도 반대다. 반환 타입에서 `Store<LocalValue, LocalAction>`으로 두 축이 다 좁혀진 게 보인다.

리듀서 쪽 pullback과 비교하면 대응이 깔끔하다. 리듀서는 전역 액션에서 지역 액션을 꺼내야 했으니 실패할 수 있어 optional을 썼다. store는 지역 액션을 전역으로 감싸기만 하면 되니 실패할 일이 없다.

구현도 그만큼 단순하다. 지역 store가 액션을 받으면 전역 액션으로 감싸 원본에 보내고, 그 결과로 바뀐 전역 상태에서 지역 값을 다시 뽑아 온다.

## 모듈 안에 view state / view action

여기서 모듈의 모양이 완성된다. `Counter` 모듈을 보면 이렇다.

```swift
public enum CounterAction {
  case decrTapped
  case incrTapped
}

public enum CounterViewAction {
  case counter(CounterAction)
  case primeModal(PrimeModalAction)
}
```

액션이 두 겹이다.

- `CounterAction` — 카운터 리듀서가 다루는 순수한 도메인 액션
- `CounterViewAction` — 카운터 **화면**이 보낼 수 있는 액션 전체. 이 화면에는 소수 모달이 떠 있으니 모달 액션도 포함된다

화면 하나가 여러 기능을 품을 수 있으니 뷰가 쓰는 액션 집합과 리듀서가 쓰는 액션 집합이 다르다. 그래서 별도 타입이 필요하다.

그리고 `CounterViewAction`에도 02 섹션에서 본 enum property가 붙는다. `counter`와 `primeModal`을 optional로 꺼내는 계산 프로퍼티다. Swift에 enum key path가 없다는 문제가 여기서도 그대로 따라온다.

`CounterView`가 `public`이 되면서 모듈 밖으로 나간다. 이제 이 모듈은 앱 상태 타입을 몰라도 빌드된다.

## 참고자료

- [Contravariance](https://www.pointfree.co/episodes/ep14-contravariance) — Point-Free #14. store 변환에서 두 방향이 왜 갈리는지
- [Why Functional Programming Matters](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) — John Hughes, 1989
- [Access Control](https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html) — Swift 접근 제어
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 논증의 세부와 "Combining view functions" 섹션의 내용은 확인하지 못했다
- 시그니처와 모듈 타입 구조는 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
