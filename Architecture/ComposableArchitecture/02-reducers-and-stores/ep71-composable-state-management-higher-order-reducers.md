# Ep. 71 — Composable State Management: Higher-Order Reducers

- 출처: [Point-Free Episode #71](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores/ep71-composable-state-management-higher-order-reducers)
- 코드: [episode-code-samples/0071-...-hor](https://github.com/pointfreeco/episode-code-samples/tree/main/0071-composable-state-management-hor) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목과 도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:06 | Introduction |
| 1:56 | What's a higher-order reducer? |
| 6:32 | Higher-order activity feeds |
| 12:25 | Higher-order logging |
| 20:15 | What's the point? |

---

## 이 편이 하려는 것

앞의 두 편은 리듀서를 나란히 붙이는 합성이었다. 이 편은 방향이 다르다. 리듀서를 감싸서 없던 기능을 얹는다.

같은 타입을 받아 같은 타입을 돌려주는 구성을 Point-Free는 여러 번 다뤄 왔다. 고차 함수, 고차 랜덤 생성기, 고차 파서 같은 것들이다. 리듀서에도 같은 걸 한다.

노리는 건 앱 전체를 가로지르는 기능이다. 화면마다 코드를 심지 않고도 붙일 수 있는 종류의 것.

## 활동 기록

첫 예제가 활동 기록인 게 우연이 아니다. [Ep. 67의 4.2](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)에서 문제 제기의 근거로 쓰인 게 바로 이 기능이다. 당시엔 즐겨찾기 삭제가 두 곳에 있어 기록 코드를 양쪽에 중복해 넣어야 했고, 한쪽을 빠뜨려 버그가 났다.

고차 리듀서로 감싸면 지나가는 모든 액션이 한자리를 통과한다.

```swift
func activityFeed(
  _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void
```

받은 리듀서를 실행하는 김에, 액션을 보고 기록을 남긴다. 즐겨찾기 추가/삭제면 타임스탬프와 함께 `activityFeed`에 붙이고, 카운터 액션이면 아무것도 안 한다.

시그니처를 보면 제네릭이 아니다. `AppState`와 `AppAction`에 묶여 있다. 기록할 내용이 이 앱의 도메인에 달린 기능이니 당연한데, 바로 다음 예제와 대비돼서 눈에 띈다.

## 로깅

로깅은 제네릭이다.

```swift
func logging<Value, Action>(
  _ reducer: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
  return { value, action in
    reducer(&value, action)
    print("Action: \(action)")
    print("Value:")
    dump(value)
    print("---")
  }
}
```

감싼 리듀서를 먼저 돌리고, 그다음 액션과 바뀐 상태를 출력한다. 상태와 액션이 뭐든 상관없으니 어떤 리듀서에도 붙는다.

두 예제를 나란히 놓으면 고차 리듀서의 폭이 보인다. 도메인에 묶인 기능도, 완전히 일반적인 기능도 같은 방식으로 얹힌다.

## 조립

감싸는 것이니 중첩된다. 로깅으로 감싼 걸 다시 활동 기록으로 감싸는 식이다. `appReducer` 자체도 항등 pullback을 거쳐 만들어진다.

```swift
let appReducer = pullback(_appReducer, value: \.self, action: \.self)
```

Ep. 69에서는 `value:`만 있었는데 이제 `action:`도 붙는다. 두 축이 다 갖춰졌다.

## 이 섹션의 결산

마지막 섹션이 "What's the point?"다. 여기서 네 편을 결산할 텐데 유료 구간이라 내용을 확인하지 못했다. 다만 남은 숙제는 분명하다. 이 시점까지도 부수효과와 테스트는 손대지 않았다.

## 참고자료

- [Contravariance](https://www.pointfree.co/episodes/ep14-contravariance) — Point-Free #14. 이 섹션 전반을 받치는 pullback의 원형
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams, 2017 Functional Swift Conference. 이 시리즈의 핵심 아이디어를 다룬 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 논증의 세부와 결산 섹션 내용은 확인하지 못했다
- 코드는 공개 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있어 영상 시점과 정확히 같다는 보장은 없다
