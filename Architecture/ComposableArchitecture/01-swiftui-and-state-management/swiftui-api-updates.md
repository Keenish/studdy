# 2019 베타 → 지금의 SwiftUI

Ep. 65~67의 코드는 2019년 SwiftUI 베타 기준이다. 그대로 따라 치면 컴파일이 안 되는 것도 많고, 더 중요하게는 **당시 지적된 문제 중 일부를 프레임워크가 이미 해결했다.** 그래서 두 가지를 정리한다. 뭘로 바꿔 읽어야 하는지, 그리고 그 한계가 지금도 유효한지.

- 정리일: 2026-07-30
- 대상: [ep65](ep65-swiftui-and-state-management-part-1.md) · [ep66](ep66-swiftui-and-state-management-part-2.md) · [ep67](ep67-swiftui-and-state-management-part-3.md)

---

## 치환표

| 영상 (2019 beta) | 지금 | 도입 |
|---|---|---|
| `BindableObject` | `ObservableObject` → `@Observable` | iOS 13 → 17 |
| `@ObjectBinding` | `@ObservedObject` → `@Bindable` | iOS 13 → 17 |
| `PassthroughSubject` + `didSet` 수동 방출 | `@Published` → 불필요 | iOS 13 → 17 |
| `@StateObject` | `@State` | iOS 17 |
| `@EnvironmentObject` | `@Environment(AppState.self)` | iOS 17 |
| `NavigationView` | `NavigationStack` / `NavigationSplitView` | iOS 16 |
| — | `.navigationDestination(for:)` + `NavigationPath` | iOS 16 |
| `.presentation(Modal)` | `.sheet(isPresented:)` / `.sheet(item:)` | iOS 13 정식 |
| `.presentation(Binding<Optional>)` (alert) | `.alert(_:isPresented:presenting:actions:message:)` | iOS 15 |
| — | `.presentationDetents` | iOS 16 |
| 콜백 기반 `wolframAlpha()` | `async/await` + `URLSession.data(from:)` | iOS 15 |
| — | `.task { }` — 뷰 생명주기에 묶인 자동 취소 | iOS 15 |

## Observation (iOS 17)

가장 큰 변화다. `@Observable` 매크로가 `ObservableObject` + `@Published` + `@ObservedObject`를 통째로 대체한다. Ep. 65의 `AppState`는 지금이면 이렇게 끝난다.

```swift
@Observable
class AppState {
  var count = 0
  var favoritePrimes: [Int] = []
}
```

`didChange`도 `didSet`도 `@Published`도 없다. Ep. 67이 첫 번째 문제로 지적한 반복이 사라진 지점이다.

무효화 방식도 바뀌었다.

- 예전은 push였다. 객체가 "뭔가 바뀜" 신호를 쏘면 그 객체를 관찰하는 뷰가 전부 갱신됐다
- 지금은 pull이다. 뷰가 `body`에서 실제로 읽은 프로퍼티만 추적해서 그 프로퍼티가 바뀔 때만 갱신한다

정밀 무효화라 성능이 좋아졌고, 쓰지도 않는 상태 때문에 뷰가 다시 그려지는 일이 구조적으로 없어졌다.

한 가지 함정이 있었다. `@StateObject`는 `@autoclosure`로 초기화를 지연시켜 한 번만 생성했는데, `@State`는 값을 그대로 받아서 뷰가 재구성될 때마다 이니셜라이저가 호출됐다. 무거운 객체를 `@State`에 넣으면 성능 문제가 생겼다. 아래 WWDC 2026에서 해결됐다.

## WWDC 2026 변경사항

> 신뢰도 중간. 서드파티 글에 근거했고 Apple 공식 문서로 직접 확인하지 않았다. 채택 전 [공식 세션](https://developer.apple.com/videos/play/wwdc2026/269/)으로 확인할 것.

- `@State`가 Dynamic Property에서 매크로로 바뀌었다. `@State`에 담은 `@Observable` 클래스가 뷰 생명주기당 한 번만 초기화되고, 부모가 재초기화돼도 객체가 살아남는다. iOS 17 / macOS 14까지 백포트됐다 — 위 함정을 피하려고 쓰던 우회 코드는 걷어내도 된다
- 디스크 접근·스냅샷 기반 `Document` 프로토콜
- 리스트·그리드·섹션 항목 재정렬 API
- 툴바 개선 (visibility priority, 자동 최소화)
- 아무 뷰에서나 스와이프 액션
- `AsyncImage` 캐싱

## 그 밖에 이 세 편에 걸리는 것

- 네비게이션 — `.navigationDestination(for:)`와 `NavigationPath`로 값 기반·프로그래밍 방식 네비게이션이 된다. 나중에 [`11-navigation`](../11-navigation/)을 읽을 때 배경이 된다
- 부수효과 — `.task {}`는 뷰가 사라지면 작업을 자동 취소한다. Ep. 67이 지적한 "취소할 방법이 없다"가 프레임워크 차원에서 풀린 부분이다
- 동시성 — `View.body`가 `@MainActor` 격리이고 Swift 6의 strict concurrency가 기본이다. 2019년엔 없던 제약이다

## Ep. 67의 다섯 가지, 지금은

이 문서에서 제일 중요한 부분이다.

| Ep. 67 | 한계 | 판정 | 근거 |
|---|---|---|---|
| 4.1 | 영속 상태 API가 번거롭다 | 해결 | `@Observable`이 보일러플레이트를 흡수 |
| 4.2 | 상태 변경이 흩어져 있다 | 그대로 | 프레임워크가 답하지 않는 앱 설계 문제 |
| 4.3 | 부수효과 이야기가 없다 | 부분 | 취소·생명주기는 `.task`로 해결. 효과를 데이터로 표현해 검증하는 문제는 남음 |
| 4.4 | 합성되지 않는다 | 부분 | 프로퍼티 단위 추적이라 하위 모델 분리는 자연스러워짐. 기능 모듈 격리에 대한 프레임워크 차원의 답은 여전히 없음 |
| 4.5 | 테스트할 수 없다 | 부분 | `@Observable` 모델은 평범한 클래스라 직접 테스트된다. 뷰 로직 단위 테스트용 공식 API는 여전히 없음 |

정리하면, Ep. 67을 읽으면서 "옛날 얘기"로 넘길 항목은 4.1 하나다. 흩어진 변경 · 효과의 데이터화 · 모듈화 · 테스트는 그대로 남아 있고, 이후 섹션들이 그걸 하나씩 가져간다.

## 유지보수 메모

새 iOS 버전이 나오면 치환표와 판정표를 갱신한다. 특히 판정이 "부분"이나 "그대로"에서 "해결"로 바뀌는 순간이 중요하다. 그만큼 TCA를 쓸 이유가 줄어든다는 뜻이니 [../README.md](../README.md)에도 표시한다.

## 출처

- [What is new in SwiftUI after WWDC26 — Swift with Majid](https://swiftwithmajid.com/2026/06/08/what-is-new-in-swiftui-after-wwdc26/)
- [WWDC26 SwiftUI guide — Apple Developer](https://developer.apple.com/wwdc26/guides/swiftui/)
- [What's new in SwiftUI — WWDC26 세션 269](https://developer.apple.com/videos/play/wwdc2026/269/)
- [SwiftUI Adds New Document Protocol, Improves Performance, and More — InfoQ](https://www.infoq.com/news/2026/07/swiftui-wwdc26/)
- [Migrating to the Observation framework in SwiftUI — tanaschita](https://tanaschita.com/swiftui-observation-migrating-to-observation/)
- [@Observable Macro performance increase over ObservableObject — SwiftLee](https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/)
- [SwiftUI's Observable macro is not a drop-in replacement for ObservableObject — Jesse Squires](https://www.jessesquires.com/blog/2024/09/09/swift-observable-macro/)
