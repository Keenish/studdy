# Ep. 65 — SwiftUI and State Management: Part 1

- 출처: [Point-Free Episode #65](https://www.pointfree.co/collections/composable-architecture/swiftui-and-state-management/ep65-swiftui-and-state-management-part-1)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 근거: 페이지 공개 트랜스크립트 (영상은 보지 않음)

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:47 | A tour of the application |
| 6:04 | The navigation screen |
| 11:21 | The counter screen |
| 17:53 | Persisting the counter screen |
| 26:21 | Next time: prime checking |

---

## 이 편이 하려는 것

아키텍처를 다루는 시리즈의 첫 편인데, 아키텍처 얘기는 거의 안 한다. 대신 예제 앱을 만든다.

함수형 원칙(순수 함수, 부수효과의 경계)을 실제 앱 설계로 연결하는 게 이 컬렉션의 목표인데, 그러려면 먼저 "평범하게 짜면 뭐가 문제인지" 보여줄 대상이 필요하다. 이 편은 그 대상을 만드는 데 다 쓴다.

## 만들 앱

카운터 앱. 기능 자체는 사소하지만 아키텍처가 감당해야 할 요소를 골고루 담도록 골랐다.

- 숫자를 증감한다 — 기본 상태
- 그 수가 소수인지 확인하는 모달을 띄운다 — 화면 간 상태 공유
- 소수를 즐겨찾기에 저장/삭제한다 — 여러 화면이 같은 데이터를 건드림
- n번째 소수를 API로 조회한다 — 부수효과

## 네비게이션 화면

`NavigationView` 안에 `List`를 두고 `NavigationLink` 두 개(Counter demo, Favorite primes)를 배치한다. 타이틀은 "State management".

이 과정에서 쓰이는 것들:

- `View` 프로토콜 — `body` 계산 프로퍼티 하나로 화면을 기술한다
- `some View` — Swift 5.1의 opaque return type. 구체 반환 타입을 감춘다
- `VStack` / `HStack` — 수직·수평 스택
- `EmptyView` — 아직 안 만든 화면 자리에 넣는 자리표시자. 다른 문맥에서 쓰던 `fatalError()`보다 이쪽이 낫다고 언급한다

## 카운터 화면

`CounterView`에 버튼과 레이블을 배치한다.

- 감소(`-`) / 증가(`+`) 버튼
- 현재 카운트 레이블
- `Is this prime?` 버튼
- `What's the Nth prime?` 버튼 — 레이블의 서수는 `NumberFormatter`에 `.ordinal` 스타일을 줘서 만든다 (1 → "1st", 2 → "2nd"). 카운터 값에 따라 같이 바뀐다

카운트는 일단 `@State`로 뷰 안에 둔다. 이때 `@State` 선언 하나가 두 가지 접근을 만들어 준다는 점을 짚고 넘어간다.

- `self.count` → `Int`. 값을 읽고 쓴다
- `self.$count` → `Binding<Int>`. SwiftUI가 변경을 감지하는 실제 통로

## 여기서 벽에 부딪힌다

카운터 화면을 나갔다 돌아오면 값이 0으로 돌아가 있다.

`@State`는 뷰에 묶인 로컬 상태다. 뷰가 재생성되면 같이 사라지고, 다른 화면과 공유되지도 않는다. 즐겨찾기 화면에서도 같은 카운트를 봐야 하는 앱이니 이대로는 안 된다.

그래서 상태를 뷰 밖으로 꺼낸다. `AppState`라는 별도 타입에 담고, 뷰들이 그걸 함께 참조하게 만드는 방향이다.

### AppState 만들기

당시 SwiftUI가 요구하는 건 `BindableObject` 채택이다. 조건이 두 가지 붙는다.

- `didChange` 퍼블리셔를 갖고 있어야 한다 — 타입은 `PassthroughSubject<Void, Never>`
- 값이 바뀌면 `didSet`에서 `self.didChange.send()`를 호출해 SwiftUI에 알려야 한다

즉 변경 통지를 손으로 해야 한다. 프로퍼티가 늘어나면 이 코드도 같이 늘어난다.

여기서 실제로 두 번 막힌다.

- `struct`로 채택하려다 컴파일 에러 — `BindableObject`가 `AnyObject`를 상속해서 참조 타입이어야 한다. 이유 설명이 붙는데, 상태가 복사되어 여러 벌 돌아다니면 안 되고 단일한 출처여야 하기 때문이다. 값 타입이면 전달할 때마다 복사본이 생긴다
- `didChange`를 빼먹어서 또 에러 — 프로토콜 요구사항이라 필수다

### 뷰에 연결하기

만들었으면 뷰마다 손으로 꽂아야 한다.

1. `AppState` 클래스 작성 — `count`, `didChange`, `count`의 `didSet`
2. `ContentView`에 `@ObjectBinding var state: AppState` 추가
3. 자식으로 전달 — `NavigationLink(destination: CounterView(state: self.state))`
4. `CounterView`에도 `@ObjectBinding var state: AppState` 추가하고 기존 `@State` 제거
5. 버튼 액션·표시부 교체 — `self.state.count -= 1`, `Text("\(self.state.count)")`
6. 진입점에서 주입 — `UIHostingController(rootView: ContentView(state: AppState()))`

이 배관 작업이 끝나면 앱 전체에서 카운트가 유지된다. 다만 부모에서 자식으로 일일이 넘겨야 한다는 점은 그대로 남는다.

> 2019년 베타 코드다. 지금은 `@Observable` 매크로 하나가 `BindableObject`·`@ObjectBinding`·`didSet` 통지를 전부 대신한다. → [swiftui-api-updates.md](swiftui-api-updates.md)

## 다음 편 예고

소수 판별 모달을 만든다고 예고만 한다. 현재 카운트가 소수인지 알려주는 레이블과 즐겨찾기 추가/삭제 버튼. 구현은 [Ep. 66](ep66-swiftui-and-state-management-part-2.md)으로 넘어간다.

## 이 편이 남긴 것

- 프로퍼티마다 `didSet { didChange.send() }` 반복 → Ep. 67의 4.1
- 부모에서 자식으로 상태를 손으로 전달 → Ep. 67의 4.4로 이어질 조짐

## 확인 범위

- 트랜스크립트는 AppState 논의(약 25:52)에서 끝난다
- `isPrime` 구현, 즐겨찾기 목록, Wolfram Alpha 연동은 이 편에 없다
- 영상은 보지 않았고 페이지 트랜스크립트만 근거로 정리했다
