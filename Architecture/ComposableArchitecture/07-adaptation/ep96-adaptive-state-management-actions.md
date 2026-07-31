# Ep. 96 — Adaptive State Management: Actions

- 출처: [Point-Free Episode #96](https://www.pointfree.co/episodes/ep96-adaptive-state-management-actions)
- 코드: [0096-adaptive-state-management-pt3](https://github.com/pointfreeco/episode-code-samples/tree/main/0096-adaptive-state-management-pt3) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-03-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:19 | Action adaptation |
| 7:10 | View store action sending |
| 13:12 | View actions |
| 26:50 | Tests and the view store |
| 38:31 | Next time: what's the point? |

---

## 이 편이 하려는 것

도입부에 이 시리즈의 작업 원칙이 한 문장으로 나온다.

상태와 액션, 구조체와 enum처럼 **짝을 이루는 개념**이 있을 때, 한쪽에서 쓸모 있는 걸 발견하면 즉시 다른 쪽의 대응물을 찾아봐야 한다는 것이다.

[Ep. 95](ep95-adaptive-state-management-state.md)에서 `ViewStore`가 상태를 좁혔다. 그러니 액션도 좁혀야 한다. 지금 `ViewStore`는 성능을 위해 상태만 최소화하는데, 뷰가 접근할 수 있는 액션까지 제한하면 뷰가 아는 도메인이 더 줄어든다.

02 섹션의 리듀서, 03 섹션의 store에 이어 **세 번째로 같은 순서를 반복**하는 셈이다.

## ViewStore가 액션을 갖는다

타입 파라미터가 하나 는다.

```swift
// 전
public final class ViewStore<Value>: ObservableObject
// 후
public final class ViewStore<Value, Action>: ObservableObject {
  public let send: (Action) -> Void
}
```

`send`가 메서드가 아니라 **저장 프로퍼티**인 게 눈에 띈다. 소스에 메서드로 만들려던 흔적이 주석으로 남아 있다.

```swift
//  public func send(_ action: Action) {
//
//  }
```

클로저로 들고 있으면 만들 때 원하는 변환을 끼워 넣을 수 있다. 메서드였다면 `ViewStore`가 상위 store를 직접 알아야 했을 것이다.

생성 시점에는 부모의 `send`를 그대로 넘긴다.

```swift
let viewStore = ViewStore(
  initialValue: self.value,
  send: self.send
)
```

## View actions

"View actions" 섹션이 13:12부터 26:50까지, 이 편에서 가장 길다.

[Ep. 74](../03-modularity/ep74-modular-state-management-view-actions.md)에서 `CounterAction`과 `CounterViewAction`을 나눴던 것과 같은 발상으로 보인다. 뷰가 보낼 수 있는 액션의 집합을 따로 정의하고, 그걸 앱 액션으로 변환해 보낸다.

뷰 입장에서 얻는 게 분명하다. 자기가 보낼 수 있는 액션만 타입에 드러나므로 실수로 다른 화면의 액션을 보낼 수 없다.

## 테스트

"Tests and the view store" 섹션이 따로 있다(26:50~38:31).

`ViewStore`가 끼어들면서 테스트가 영향을 받는다. [05 섹션](../05-testing/00-overview.md)에서 만든 테스트는 리듀서를 직접 검증하는 방식이라 `ViewStore`와 무관할 텐데, 뷰 상태·뷰 액션이라는 층이 생겼으니 그 변환 자체도 검증 대상이 된다.

## 남는 것

상태와 액션 양쪽이 좁혀졌다. 이제 이게 실제로 쓸모 있는지 보일 차례다. → [Ep. 97](ep97-adaptive-state-management-the-point.md)

## 참고자료

이 편도 References가 없다. 시리즈 내부의 대칭을 따라가는 편이라 외부 자료를 끌어오지 않는다.

## 확인 범위

- 영상이 유료라 View actions의 실제 설계와 테스트 변경은 확인하지 못했다. 위 내용은 섹션 제목·도입부와 시그니처 변화에서 읽어낸 것이다
- `ViewStore<Value, Action>`과 `send` 프로퍼티는 저장소 소스로 확인했다. `ComposableArchitecture.swift`가 139줄 → 151줄로 늘어난다
