# Ep. 73 — Modular State Management: View State

- 출처: [Point-Free Episode #73](https://www.pointfree.co/episodes/ep73-modular-state-management-view-state)
- 코드: [episode-code-samples/0073-modular-state-management-view-state](https://github.com/pointfreeco/episode-code-samples/tree/main/0073-modular-state-management-view-state) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-09-23
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:06 | Introduction |
| 0:44 | Modularizing our views |
| 4:06 | Transforming a store's value |
| 9:23 | A familiar-looking function |
| 14:17 | What's in a name? |
| 17:56 | Propagating global changes locally |
| 22:38 | Focusing on view state |
| 27:09 | Till next time |

---

## 이 편이 하려는 것

[Ep. 72](ep72-modular-state-management-reducers.md)에서 리듀서는 모듈로 잘 떨어졌는데 뷰는 남았다. 뷰가 `Store<AppState, AppAction>`을 받는 한, 그 뷰가 든 모듈은 앱 없이 빌드되지 않는다.

도입부에서 리듀서 분리가 얼마나 쉬웠는지를 짚고 넘어간다. 경계가 이미 명확했으니 옮기는 게 단순 작업이었고, 상태가 복잡한 컴포넌트에서만 손이 더 갔다는 것이다. 이 아키텍처가 기본적으로 모듈적이라는 근거로 든다.

이 편은 상태만 다룬다. 액션은 다음 편이다.

## store를 변환한다

리듀서는 pullback으로 상태를 좁혔다. 그런데 뷰가 받는 건 리듀서가 아니라 store다. 그러니 store 자체를 변환하는 방법이 필요하다.

전역 store에서 지역 store를 만들어 내는 메서드를 `Store`에 붙인다.

```swift
func view<LocalValue>(
  _ f: @escaping (Value) -> LocalValue
) -> Store<LocalValue, Action>
```

전역 값에서 지역 값을 꺼내는 함수를 주면, 그 지역 값을 들고 있는 새 store가 나온다.

## 방향이 리듀서 때와 반대다

섹션 제목이 "A familiar-looking function"인 게 힌트다.

- pullback은 `WritableKeyPath<GlobalValue, LocalValue>`를 받았다 — 반변
- `view`는 `(Value) -> LocalValue`를 받는다 — 공변, 즉 map 쪽이다

같은 "좁히기"인데 방향이 다르다. 리듀서는 상태를 소비하니 반변이고, store는 상태를 내놓으니 공변이다. References에 [The Many Faces of Map](https://www.pointfree.co/episodes/ep13-the-many-faces-of-map)과 [Contravariance](https://www.pointfree.co/episodes/ep14-contravariance)가 나란히 걸린 이유가 이것이다. 두 방향을 다 알아야 이 편이 읽힌다.

"What's in a name?" 섹션이 따로 있는 걸 보면 이 함수 이름을 두고 고민한 흔적이다. map 계열인데 `map`이라 부르지 않고 `view`를 골랐다.

이 편 소스에는 아직 다듬어지지 않은 흔적도 남아 있다. `transform`이라는 함수가 `fatalError()` 본문으로 선언만 돼 있는데, 리듀서를 변환하는 방향을 탐색해 보다 만 자리로 보인다.

## 변경을 되돌려 보내기

여기가 까다로운 부분이다. 지역 store를 새로 만들면 원본과 끊긴다. 전역 상태가 바뀌어도 지역 store는 옛 값을 들고 있게 된다.

그래서 지역 store의 리듀서가 받은 액션을 전역 store로 흘려보내고, 전역 상태가 바뀌면 그걸 다시 지역 값으로 뽑아 온다. 섹션 제목 "Propagating global changes locally"가 이 작업이다.

즉 `view`가 만드는 건 독립된 복사본이 아니라 **전역 store에 연결된 창**이다.

## view state라는 개념

마지막 섹션이 "Focusing on view state"다. 뷰가 필요한 것만 담은 별도 타입을 만든다는 뜻이다.

이게 단순히 프로퍼티를 골라 담는 것 이상인 이유가 있다. 뷰가 쓰는 값이 앱 상태에 그대로 있는 프로퍼티가 아닐 수 있다. 계산해서 만들어야 하거나, 여러 프로퍼티를 조합해야 할 수도 있다. `(Value) -> LocalValue` 함수를 받는 형태라 그런 변환이 자연스럽게 들어간다.

## 남는 문제

상태는 좁혔는데 액션은 그대로다. 시그니처를 보면 `Store<LocalValue, Action>`이라 액션 타입이 안 바뀐다. 뷰가 여전히 앱의 아무 액션이나 보낼 수 있다.

02 섹션에서 겪은 것과 똑같은 반쪽 상태다. → [Ep. 74](ep74-modular-state-management-view-actions.md)

## 참고자료

- [The Many Faces of Map](https://www.pointfree.co/episodes/ep13-the-many-faces-of-map) — Point-Free #13. `view`가 왜 map 계열인지
- [Contravariance](https://www.pointfree.co/episodes/ep14-contravariance) — Point-Free #14. 리듀서 쪽 pullback과의 대비
- [Why Functional Programming Matters](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) — John Hughes, 1989
- [Access Control](https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html) — Swift 접근 제어
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 논증의 세부, 특히 이름을 고르는 과정("What's in a name?")은 확인하지 못했다
- 시그니처와 구현은 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
