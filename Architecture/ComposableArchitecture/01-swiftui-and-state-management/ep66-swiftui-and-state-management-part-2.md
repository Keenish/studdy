# Ep. 66 — SwiftUI and State Management: Part 2

- 출처: [Point-Free Episode #66](https://www.pointfree.co/collections/composable-architecture/swiftui-and-state-management/ep66-swiftui-and-state-management-part-2)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 근거: 페이지 공개 트랜스크립트 (영상은 보지 않음)

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:34 | The prime checking modal |
| 11:00 | Adding a side effect |
| 18:10 | The favorites list |
| 23:11 | Next time: what's the point? |

---

## 이 편이 하려는 것

[Ep. 65](ep65-swiftui-and-state-management-part-1.md)에서 앱 뼈대와 `AppState`까지 만들었다. 이 편은 남은 기능을 다 붙여서 앱을 완성한다.

기능 추가처럼 보이지만 실은 재료 수집이다. 모달·네트워크·목록을 붙일 때마다 서로 다른 종류의 불편이 하나씩 따라 들어오고, 그게 다음 편에서 문제 목록이 된다. 그 관점으로 읽으면 좋다.

시작은 확인부터. `@ObjectBinding` 덕에 카운터 화면을 드릴다운했다 돌아와도 값이 그대로다.

## 소수 판별 모달

카운트가 소수인지 알려주고, 소수면 즐겨찾기에 넣거나 뺄 수 있는 모달을 만든다.

당시 API는 `.presentation(Modal?)`이다. optional을 받아서 `nil`이면 안 띄우고, `Modal` 인스턴스가 들어오면 띄운다. 모달 뷰(`IsPrimeModalView`)는 부모와 같은 `AppState`를 `@ObjectBinding`으로 받는다.

```swift
Modal(IsPrimeModalView(state: self.state), onDismiss: { self.isPrimeModalShown = false })
```

### 모달이 계속 다시 뜨는 버그

닫아도 모달이 또 나타난다.

표시 여부를 `isPrimeModalShown` 불리언으로 판단하는데, 모달을 닫아도 이 값이 `true`로 남는다. 그러니 뷰가 다시 렌더링될 때마다 표시 조건이 또 만족된다. 해결은 위 코드처럼 `onDismiss`에서 직접 `false`로 되돌리는 것.

동작은 하지만 이게 다음 편의 사례가 된다. 상태를 되돌리는 책임이 뷰 쪽 클로저로 떠넘겨졌기 때문이다.

### 소수 판별과 즐겨찾기

`isPrime` 헬퍼는 `√p`까지 나눠 보는 단순한 방식이다. 알고리즘이 주제가 아니라 그냥 간다.

즐겨찾기는 `AppState`에 `favoritePrimes: [Int]`를 추가해서 담는다. 여기에도 `didSet`에서 `didChange.send()`를 다시 붙여야 한다. Ep. 65에서 봤던 반복이 벌써 두 번째다.

모달 안에서는 현재 카운트가 이미 담겨 있는지로 버튼을 갈라 보여준다.

- 판단: `self.state.favoritePrimes.contains(self.state.count)`
- 추가: `append()`
- 삭제: `removeAll(where: { $0 == self.state.count })`
- 문구도 갈라진다 — "X is prime 🎉" / "X is not prime :("

## 부수효과 붙이기

n번째 소수를 계산하는 건 앱 안에서 하기 부담스러우니 Wolfram Alpha API에 물어본다. 이 앱에 네트워크가 처음 들어오는 지점이다.

헬퍼 코드는 에피소드에서 제공한다. 응답 JSON을 그대로 미러링한 중첩 구조체다.

```
WolframAlphaResult
└─ queryresult
   └─ pods: [Pod]
      └─ subpods: [SubPod]
         └─ plaintext: String
```

- `wolframAlpha(query:callback:)` — `URLComponents`로 URL을 조립하고 `appid` 포함 쿼리 아이템을 붙인 뒤 `URLSession.shared.dataTask()`를 쏜다. 성공하면 디코딩 결과를, 실패하면 `nil`을 콜백으로 넘긴다
- `nthPrime(_:callback:)` — 질의는 `"prime \(n)"`. 응답에서 `primary == .some(true)`인 첫 pod을 찾아 그 첫 subpod의 `plaintext`를 꺼내 `Int`로 파싱한다

### 결과를 alert로 보여주기

응답이 언제 올지 모르니 결과를 담을 자리를 먼저 만들어 둔다.

- `@State var alertNthPrime: Int?`를 선언하고
- `.presentation(Binding<Int?>, alert:)`에 `self.$alertNthPrime`을 넘긴다
- 클로저는 언래핑된 정수를 받으니 그대로 문구를 조립한다 — `"The \(ordinal(self.state.count)) prime is \(n)"`
- 버튼을 누르면 `nthPrime(self.state.count) { prime in self.alertNthPrime = prime }`

alert는 닫힐 때 SwiftUI가 바인딩을 알아서 `nil`로 되돌린다. 앞의 모달 불리언은 손으로 되돌려야 했는데 여기선 안 해도 된다. 같은 앱 안에서 두 방식이 섞여 있는 셈이다.

돌려 보면 1000번째 소수는 7919, 1,000,000번째는 15,485,863이 나온다.

이 호출은 그냥 쏘고 끝난다. 취소할 방법도, 중복 호출을 막을 방법도, 테스트할 방법도 없다. 이 편에서는 동작하니 넘어가지만 다음 편에서 가장 무겁게 다뤄진다.

## 즐겨찾기 목록

`FavoritePrimes` 화면을 새로 만든다. 배열을 받아 리스트로 뿌리면 되는 간단한 화면인데 한 번 걸린다.

```swift
List { self.state.favoritePrimes.map { ... } }   // 컴파일 안 됨
```

`ForEach`로 감싸야 한다.

```swift
List {
  ForEach(self.state.favoritePrimes) { prime in Text("\(prime)") }
}
```

삭제는 `.onDelete(perform:)`에 들어오는 `IndexSet`을 돌면서 `remove(at:)`을 호출해 스와이프로 지우게 만든다.

여기까지 하면 상태 공유가 눈으로 확인된다. 모달에서 추가한 값이 화면을 옮겨도 남아 있고, 목록에서 지운 뒤 카운터로 돌아가 다시 추가해도 그대로 반영된다.

동시에 걸리는 점도 보인다. 이 화면은 `favoritePrimes` 배열 하나만 있으면 되는데 `AppState` 전체를 받고 있다.

## 다음 편 예고

Ep. 67은 "What's the point?" 편이다. SwiftUI가 UIKit보다 빠르게 만들 수 있다는 건 인정하되, 어떤 구멍이 남는지 정리하고 개선 방향을 제시하겠다고 예고한다.

## 이 편이 남긴 것

- `favoritePrimes` 추가하면서 `didSet` 반복 또 한 번 → 4.1
- 변경 코드가 버튼 클로저·`onDismiss`·`onDelete`로 흩어짐 → 4.2
- 콜백으로 쏘고 끝나는 API 호출 → 4.3
- 목록 화면이 `AppState` 전체를 받음 → 4.4

## 확인 범위

- 2019년 베타 코드다. `.presentation(Modal)`은 `.sheet(item:)`으로, alert용 `.presentation`은 `.alert(...)`로, 콜백 기반 `wolframAlpha()`는 `async/await` + `.task {}`로 바뀌었다 → [swiftui-api-updates.md](swiftui-api-updates.md)
- 트랜스크립트는 전체 공개다
- 영상은 보지 않았고 페이지 트랜스크립트만 근거로 정리했다
