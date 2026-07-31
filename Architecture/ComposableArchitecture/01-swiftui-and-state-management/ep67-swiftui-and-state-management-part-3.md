# Ep. 67 — SwiftUI and State Management: Part 3

- 출처: [Point-Free Episode #67](https://www.pointfree.co/collections/composable-architecture/swiftui-and-state-management/ep67-swiftui-and-state-management-part-3)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 근거: 페이지 공개 트랜스크립트 (영상은 보지 않음)

| 시간 | 섹션 |
|---|---|
| 0:05 | What's the point? |
| 1:17 | What's to like? |
| 5:14 | Cumbersome persistent state API |
| 8:47 | Scattered state mutation |
| 17:55 | No story for side effects |
| 19:37 | State management isn't composable |
| 24:24 | SwiftUI isn't testable |
| 25:16 | Conclusion |

---

## 이 편이 하려는 것

Point-Free의 "What's the point?" 편이다. 두 편에 걸쳐 만든 앱을 놓고 SwiftUI로 앱을 짜 보니 어땠는지 결산한다.

새 코드는 거의 안 나온다. 대신 여기서 정리되는 다섯 가지가 이후 컬렉션 전체의 목차가 되니, 세 편 중 하나만 본다면 이 편이다.

## 좋았던 점

비판부터 하지 않고 장점을 먼저 분명히 한다.

- 선언적 UI — `body` 계산 프로퍼티 하나로 화면이 기술된다
- `@State`로 뷰 로컬 상태를 간단히 다룬다
- `@ObjectBinding`으로 화면 간 상태를 공유한다
- 방향이 하나로 잡혀 있다 — UIKit은 알림·KVO·델리게이트로 갈라져 있었는데 SwiftUI는 의견이 뚜렷하다

## 한계 다섯 가지

### 4.1 영속 상태 API가 번거롭다

전역 상태가 커질수록 통지 코드가 같이 늘어난다. 지금 `AppState`만 봐도 `count`, `favoritePrimes`, `activityFeed` 세 프로퍼티가 각각 똑같은 `didSet`을 달고 있다.

```swift
var loggedInUser: User? = nil {
  didSet { self.didChange.send() }
}
```

호스트 표현으로는 이 반복이 상태의 핵심 서술을 가린다. 뭐가 상태인지 읽으려는데 통지 코드가 먼저 눈에 들어온다는 뜻이다.

실제 앱이면 금방 붙을 것들을 상상해 보며 논증한다.

- `User` 구조체 — `id`, `name`, `bio`를 담은 optional 프로퍼티
- `Activity` 타입 — 타임스탬프 + 행동 enum (`addedFavoritePrime`, `removedFavoritePrime`)

> 정정: 이후 베타의 `@Published`로 이 보일러플레이트는 거의 사라졌고, 지금은 `@Observable`이 완전히 흡수했다.

### 4.2 상태 변경이 흩어져 있다

이 섹션의 논증이 제일 좋다.

`Counter` 뷰 하나에만 변경이 일곱 군데 있다.

- 감소·증가 버튼 액션에서 `count` 변경 (2)
- 모달 표시 불리언 토글 (1)
- n번째 소수 API 호출 (1)
- 모달 닫을 때 불리언 리셋 (1)
- alert 바인딩이 닫히면서 값을 `nil`로 되돌리는 부분 (2)

앞의 다섯은 눈에 보이지만 마지막 둘은 양방향 바인딩 안에 숨어 있어 잘 안 보인다. 변경이 몇 군데인지 세는 것조차 쉽지 않다는 게 문제의 성격을 보여준다.

그리고 이게 실제 버그로 이어진 과정을 그대로 보여준다.

1. `activityFeed`에 사용자 행동을 기록하는 기능을 붙인다
2. 즐겨찾기 삭제가 두 곳에 있다 — 모달의 삭제 버튼, 목록 화면의 `onDelete`
3. 처음엔 목록에서 스와이프로 지울 때 기록이 남지 않았다
4. 같은 로직을 두 뷰에 중복해서 넣어야 고쳐졌다

규모가 커지면 더 나빠진다. 중앙화가 없으니 나중에 합류한 사람은 변경이 어디서 일어나는지 찾을 수 없고, 흩어진 비슷한 로직들은 시간이 지나며 서로 어긋난다.

완화책으로 변경을 `AppState` 확장 메서드에 모으는 방법을 보여준다.

```swift
extension AppState {
  func addFavoritePrime() { … }
  func removeFavoritePrime(_ prime: Int) { … }
}
```

다만 완화일 뿐 해법은 아니다. 진짜 해법은 [`02-reducers-and-stores`](../02-reducers-and-stores/)에서 나온다.

### 4.3 부수효과에 대한 이야기가 없다

Apple이 외부 효과를 어떻게 다루라는 지침을 주지 않는다. Ep. 66의 Wolfram Alpha 호출이 그대로 사례다. 허공에 쏘고 끝난다.

- 취소할 방법이 없다
- 디바운스할 방법이 없다
- 테스트할 수 없다
- 효과 자체를 가리키는 데이터 타입이 없다 — 그러니 조작할 수도, 검증할 수도 없다

효과를 값으로 표현해야 한다는 게 [`04-side-effects`](../04-side-effects/)의 출발점이 된다.

### 4.4 상태 관리가 합성되지 않는다

`FavoritePrimes` 뷰는 `favoritePrimes`와 `activityFeed`만 쓰는데 `AppState` 전체를 받는다.

래퍼 클래스를 만들어 계산 프로퍼티로 필요한 부분만 터널링할 수는 있다. 그런데 이 정도 격리를 위해 치르는 비용이 "far too much"라고 표현될 만큼 크다.

```swift
class FavoritePrimesState: BindableObject {
  var didChange: PassthroughSubject<Void, Never> { … }
  private var state: AppState
  var favoritePrimes: [Int] {
    get { self.state.favoritePrimes }
    set { self.state.favoritePrimes = newValue }
  }
}
```

> 정정: 이후 베타에서 presentation 경계를 넘는 상태 전파가 고쳐져 `@Binding`을 쓸 수 있게 됐다.

### 4.5 테스트할 수 없다

테스트 지침도 도구도 없다.

확인하고 싶은 건 "플러스 버튼을 누르면 카운트가 증가하는가" 정도로 단순하다. 그런데 상태와 변경이 뷰 코드 안에 뒤엉켜 있어서 로직만 떼어낼 수가 없다.

## 결론

미해결 문제 넷으로 정리된다.

1. 상태 관리와 변경의 조직화
2. 부수효과 실행
3. 큰 앱의 분해
4. 테스트

다음 시리즈부터 함수형 접근으로 상태·변경·효과를 하나로 묶겠다고 예고한다. 이 해법이 SwiftUI 전용이 아니라 기존 UIKit에서도 돌아간다는 점을 못 박는데, 2019년 당시 SwiftUI를 못 쓰던 프로젝트를 염두에 둔 것이다.

## 지금 기준으로 읽을 때

위 다섯 중 프레임워크가 스스로 해결한 건 4.1 하나다. 나머지 넷은 그대로이거나 부분 해결이라, 지금도 TCA를 쓸 이유로 남아 있다. 판정 근거는 [swiftui-api-updates.md](swiftui-api-updates.md)에.

정정 안내가 두 건(4.1의 `@Published`, 4.4의 `@Binding`) 페이지에 붙어 있다. 당시 지적 중 일부는 이후 베타가 직접 해결했다는 걸 감안하고 읽어야 한다.

## 확인 범위

- 코드가 거의 없는 회고 편이다. 이후 섹션이 각각 어느 문제를 푸는지는 [00-overview.md](00-overview.md)에 대응표로 정리했다
- 2019년 베타 코드다 → [swiftui-api-updates.md](swiftui-api-updates.md)
- 트랜스크립트는 전체 공개다
- 영상은 보지 않았고 페이지 트랜스크립트만 근거로 정리했다
