# Ep. 85 — Testable State Management: The Point

- 출처: [Point-Free Episode #85](https://www.pointfree.co/episodes/ep85-testable-state-management-the-point)
- 코드: [0085-testable-state-management-the-point](https://github.com/pointfreeco/episode-code-samples/tree/main/0085-testable-state-management-the-point) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-12-16
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다**

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:48 | A tour of the vanilla SwiftUI code base |
| 6:56 | Testing vanilla SwiftUI |
| 8:28 | Testing the prime modal |
| 17:13 | Testing the favorite primes view |
| 19:36 | Testing the counter view: @ObservedObject |
| 24:15 | Testing the counter view: @State |
| 29:03 | Conclusion |

---

## 이 편이 하려는 것

18편에 걸쳐 아키텍처를 만들어 놓고 마지막에 묻는다. **이게 정말 필요했나?**

방식이 정공법이다. 아키텍처 없이 평범한 SwiftUI로 짠 같은 앱을 가져와서, 거기에 테스트를 써 본다. 그리고 어디서 막히는지 하나씩 보인다.

비교 대상이 되는 바닐라 버전은 [01 섹션](../01-swiftui-and-state-management/00-overview.md)에서 만들었던 그 앱이다. `AppState`가 `ObservableObject`이고 `count`, `favoritePrimes`, `loggedInUser`, `activityFeed`가 `@Published`로 붙어 있다. 뷰는 `@ObservedObject`나 `$` 문법의 바인딩으로 상태를 받는다.

## 화면별로 막히는 지점

### 소수 모달

첫 벽이 바인딩이다. 프로퍼티 래퍼가 테스트 스코프에서는 동작하지 않아 `Binding`을 손으로 만들어야 한다. 그래서 `Binding(initialValue:)` 같은 헬퍼 확장을 따로 만든다.

로직 자체는 뷰 body에서 `removeFavoritePrime()` 같은 메서드로 빼내면 직접 호출해 검증할 수 있다. 다만 대가가 있다. **전수성(exhaustivity)이 사라진다.** 관계없는 상태가 함께 바뀌어도 잡히지 않는다.

### 즐겨찾기 화면

같은 바인딩 문제가 반복된다. `onDelete` 클로저 안의 로직과 저장·불러오기 메서드를 별도 메서드로 빼내야 테스트가 된다.

전수적으로 검증하려면 상태를 중간 구조체로 묶고 `AppState`에 계산 프로퍼티를 다는 작업이 필요하다고 짚는다. 아키텍처 없이도 결국 비슷한 구조를 만들게 된다는 뜻이다.

### 카운터 화면 — @ObservedObject

뷰를 직접 만드는 쪽이 바인딩보다는 낫다. 그런데 `AppState`가 **클래스**라 두 가지를 잃는다.

- 멤버와이즈 이니셜라이저가 없다
- `Equatable` 자동 합성이 안 된다

그래서 상태 전체를 한 번에 비교하지 못하고 `view.state.count`처럼 필드 하나씩 확인하게 된다. 전수성이 또 무너진다.

값 타입이 왜 중요했는지가 여기서 역으로 드러난다.

### 카운터 화면 — @State

여기가 결정적이다. **근본적으로 안 된다.**

`isNthPrimeButtonDisabled`나 `alertNthPrime` 같은 `@State` 필드는 메서드가 값을 바꿔도 **실제로 바뀌지 않는다.** `@State` 기계장치가 `UIHostingController` 맥락을 요구하기 때문이다. 테스트 환경에는 그게 없다.

해결책은 하나뿐이다. `@State` 필드를 `AppState`로 옮겨 `@Published`로 만드는 것. 즉 관찰 가능한 앱 상태로 바꾸는 것이다.

## 결론

주장은 이렇다. **테스트 가능한 바닐라 SwiftUI 같은 건 없다.**

테스트를 하려고 시도한 모든 것이 결국 같은 방향을 요구했다.

- 로직을 뷰 body에서 메서드로 빼내기
- `@State`를 앱 상태로 올리기
- 상태를 값 타입으로 묶기
- 전수적 비교를 위해 구조를 다듬기

이건 Composable Architecture가 내린 결정들과 사실상 같다. 그러니 테스트 가능성을 얻으려면 어차피 SwiftUI 위에 층을 하나 올려야 하고, 그렇다면 리듀서와 액션으로 원칙 있게 접근하는 쪽이 **대안이 아니라 자연스러운 귀결**이라는 것이다.

## 이 편의 논증 방식이 좋은 이유

"우리 아키텍처가 좋다"고 주장하는 대신, 안 쓴 경우를 실제로 시도해서 막히는 지점을 보인다. 그리고 막히는 이유가 하나같이 **아키텍처가 이미 내린 결정의 부재**로 설명된다.

- 값 타입이 아니라서 → 전수 비교 불가
- 변경이 뷰에 있어서 → 빼내야 함
- `@State`가 뷰에 묶여서 → 테스트 불가

[Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)에서 제기한 문제가 18편 만에 닫히는 구조다.

## 참고자료

- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams, 2017 Functional Swift Conference. 무료
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
- 2019년 SwiftUI 기준이다. `@Observable`이 나온 지금은 클래스 관련 제약 일부가 달라졌지만, `@State`가 뷰에 묶여 테스트되지 않는다는 지적과 로직을 뷰 밖으로 빼야 한다는 결론은 여전히 유효하다. → [swiftui-api-updates](../01-swiftui-and-state-management/swiftui-api-updates.md)
