# Ep. 70 — Composable State Management: Action Pullbacks

- 출처: [Point-Free Episode #70](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores/ep70-composable-state-management-action-pullbacks)
- 코드: [episode-code-samples/0070-...-action-pullbacks](https://github.com/pointfreeco/episode-code-samples/tree/main/0070-composable-state-management-action-pullbacks) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목과 도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:14 | Focusing a reducer's actions |
| 3:40 | Enums and key paths |
| 8:58 | Enum properties |
| 15:16 | Pulling back reducers along actions |
| 21:40 | Pulling back more reducers |
| 26:26 | Till next time |

---

## 이 편이 하려는 것

[Ep. 69](ep69-composable-state-management-state-pullbacks.md)에서 리듀서가 상태의 일부만 보게 만들었다. 그런데 액션은 여전히 전부 받는다.

카운터 리듀서가 `Int`만 건드리면서도 `AppAction`을 통째로 받고 있었다. 상태 쪽만 캡슐화되고 액션 쪽은 뚫려 있는 상태다. 이 편은 액션에도 같은 일을 해서 짝을 맞춘다.

목표 지점은 명확하다. 카운터 리듀서가 이렇게 되면 된다.

```swift
func counterReducer(state: inout Int, action: CounterAction)
```

## 막히는 지점 — enum에는 key path가 없다

상태 쪽은 `WritableKeyPath<AppState, Int>`로 간단히 됐다. 액션도 `WritableKeyPath<AppAction, CounterAction?>` 같은 게 있으면 끝인데, Swift에 enum용 key path 문법이 없다.

구조체는 `\.counter`로 프로퍼티를 가리킬 수 있지만 enum 케이스에는 그런 게 없다. Swift가 구조체와 enum을 대칭으로 다루지 않는다는 점을 문제로 짚는다.

이건 이 편에서 처음 꺼낸 불만이 아니다. Point-Free 51편이 "Swift가 구조체 편을 든다"는 주제를 통째로 다룬다. 두 타입이 원리상 대등한데도 언어가 구조체 쪽에만 편의를 몰아준다는 이야기고, 그 불균형이 여기서 실제 비용으로 돌아온다.

## 메우는 방법 — enum property

없으면 손으로 만든다. 각 케이스마다 값을 꺼내고 넣는 계산 프로퍼티를 `AppAction`에 붙인다.

```swift
extension AppAction {
  var counter: CounterAction? {
    get { ... }
    set { ... }
  }
  var primeModal: PrimeModalAction? { ... }
  var favoritePrimes: FavoritePrimesAction? { ... }
}
```

optional인 게 핵심이다. 전역 액션에서 지역 액션을 꺼내는 건 실패할 수 있다. 카운터 리듀서에 즐겨찾기 액션이 오면 꺼낼 게 없다. 상태 쪽 `WritableKeyPath`는 항상 성공하지만 액션 쪽은 아니라는 차이가 여기서 나온다.

이렇게 만들어 두면 `\.counter`가 `WritableKeyPath<AppAction, CounterAction?>`으로 성립한다. 소스에도 그 타입이 주석으로 달려 있다.

계보도 밝힌다.

- enum property 자체는 Episode #52에서 다룬 내용이다
- 이 보일러플레이트를 자동 생성하는 CLI 도구를 Episode #55에서 만들었고, [swift-enum-properties](https://github.com/pointfreeco/swift-enum-properties)로 공개돼 있다

(이 optional 접근자 방식이 나중에 CasePath로 정리된다. 이 시점에는 아직 그 이름이 없다.)

## 액션까지 받는 pullback

파라미터가 하나 늘고 제네릭이 넷으로 늘어난다.

```swift
func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
  _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
  value: WritableKeyPath<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
  return { globalValue, globalAction in
    guard let localAction = globalAction[keyPath: action] else { return }
    reducer(&globalValue[keyPath: value], localAction)
  }
}
```

동작은 두 줄이다.

- 전역 액션에서 지역 액션을 꺼내 본다. 없으면 그냥 나간다
- 있으면 전역 상태에서 지역 상태를 꺼내 리듀서를 돌린다

Ep. 69 버전과 비교하면 `guard let` 한 줄이 늘었을 뿐인데, 이걸로 각 리듀서가 자기 액션에만 반응하게 된다.

## 상태 조각이 프로퍼티 하나가 아닐 때

`FavoritePrimesView`는 즐겨찾기 배열과 활동 기록 둘 다 필요하다. `AppState`에 그런 프로퍼티가 따로 있는 게 아니니 계산 프로퍼티로 만들어 준다.

```swift
extension AppState {
  var favoritePrimesState: FavoritePrimesState {
    get { ... }   // 두 프로퍼티를 묶어 새 값으로
    set { ... }   // 받은 값을 두 프로퍼티에 도로 흩뿌림
  }
}
```

getter와 setter가 둘 다 있으니 `WritableKeyPath`가 성립하고, 그대로 pullback에 넘길 수 있다. 상태를 어떻게 자를지가 저장 프로퍼티 구조에 매이지 않는다는 뜻이다.

## 여기까지 오면

화면별 리듀서를 그 화면의 상태와 액션만 아는 상태로 짤 수 있다. 조립은 pullback 두 축 + combine이다.

## 다음 편

리듀서를 감싸서 기능을 얹는 방향으로 넘어간다. → [Ep. 71](ep71-composable-state-management-higher-order-reducers.md)

## 참고자료

이 편은 References가 가장 많다. enum 쪽 계보가 길어서다.

- [Structs 🤝 Enums](https://www.pointfree.co/episodes/ep51-structs-enums) — Point-Free #51. Swift가 구조체 쪽에 편의를 몰아주는 비대칭. 이 편이 막히는 근본 원인
- [Enum Properties](https://www.pointfree.co/episodes/ep52-enum-properties) — Point-Free #52. 여기서 쓰는 패턴의 출처
- [Swift Syntax Command Line Tool](https://www.pointfree.co/episodes/ep55-swift-syntax-command-line-tool) — Point-Free #55. 보일러플레이트 자동 생성 도구를 만드는 편
- [swift-enum-properties](https://github.com/pointfreeco/swift-enum-properties) — 그 도구의 공개 저장소
- [Contravariance](https://www.pointfree.co/episodes/ep14-contravariance) — pullback의 원형
- [Category Theory](https://en.wikipedia.org/wiki/Category_theory) / [Pullback](https://en.wikipedia.org/wiki/Pullback) — key path를 사상으로 보는 근거
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 논증의 세부는 확인하지 못했다
- 코드는 공개 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있어 영상 시점과 정확히 같다는 보장은 없다
