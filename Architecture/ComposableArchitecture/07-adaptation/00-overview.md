# 07 · Adaptation — 네 편 흐름

Point-Free [Adaptation](https://www.pointfree.co/collections/composable-architecture/adaptation) 섹션(Ep. 94~97)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 네 편 모두 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT) 소스로 확인했다

관련 문서

- [ep94 — Performance](ep94-adaptive-state-management-performance.md) · 누수를 잡고 뷰가 몇 번 그려지는지 잰다
- [ep95 — State](ep95-adaptive-state-management-state.md) · `ViewStore`를 도입해 상태를 좁힌다
- [ep96 — Actions](ep96-adaptive-state-management-actions.md) · 액션도 좁힌다
- [ep97 — The Point](ep97-adaptive-state-management-the-point.md) · macOS 앱을 만들어 증명한다

---

## 이 섹션이 하는 일

섹션 설명이 짧다. 아키텍처가 적응적이면 여러 상황에서 쓸 수 있고, 그걸 데모 앱을 macOS로 옮겨서 보인다.

그런데 출발점은 적응이 아니라 **성능**이다. 뷰가 필요 이상으로 자주 그려지는 문제를 풀려고 중간 객체를 하나 두는데, 그 객체가 "뷰에 맞는 상태만 노출한다"는 성질을 갖게 되면서 자연스럽게 플랫폼 적응의 통로가 된다.

성능 문제를 풀다가 적응성을 얻는 구조라 섹션 이름이 Adaptation이다.

## 네 편이 쌓이는 순서

### Ep. 94 — 재고 조사

먼저 메모리 누수 두 건을 고친다. 저장소 diff에서 확인되는 것 중 하나가 특히 인상적이다.

```swift
// 전
receiveValue: self.send
// 후
receiveValue: { [weak self] in self?.send($0) }
```

메서드 참조를 그대로 넘기면 `self`를 강하게 붙든다. 짧고 깔끔해 보이는 표기가 누수의 원인이었다. 완료 핸들러에서도 `[weak self, weak effectCancellable]`로 cancellable까지 약하게 잡는다.

그다음 시간 대부분을 `View.init`과 `body`가 몇 번 불리는지 재는 데 쓴다. 추적하고, 분석하고, 스트레스 테스트까지 한다.

이 편 소스에 다음 편의 답이 주석으로 남아 있다.

```swift
localStore.viewCancellable = self.$value
  .map(toLocalValue)
//  .removeDuplicates()      ← 여기
  .sink { ... }
```

### Ep. 95 — ViewStore

문제의 원인을 도입부가 한 문장으로 정리한다. 뷰 안의 store 하나가 그 뷰에 필요한 상태뿐 아니라 **자식들의 상태까지 전부** 들고 있다. 그러니 앱 어디서 상태가 바뀌든 무관한 뷰까지 다시 그려진다.

`Store`와 `ViewStore`를 나눈다.

```swift
public final class ViewStore<Value>: ObservableObject
```

`ObservableObject`를 채택한 쪽이 `ViewStore`인 게 핵심이다. SwiftUI가 다시 그릴지 판단하는 지점이 여기로 옮겨진다.

실제 해법은 중복 제거다.

```swift
extension Store where Value: Equatable {
  public var view: ViewStore<Value> { self.view(removeDuplicates: ==) }
}

public func view(removeDuplicates predicate: @escaping (Value, Value) -> Bool) -> ViewStore<Value>
```

전역 상태가 바뀌어도 이 뷰가 보는 조각이 실제로 달라졌을 때만 갱신한다. API가 두 겹인 것도 눈여겨볼 만하다. `Equatable`이면 `==`로 알아서 하고, 아니면 비교 함수를 직접 준다.

마지막 섹션이 "Adapting view stores"다. 뷰에 맞는 상태만 노출한다는 건 그 상태를 뷰가 원하는 모양으로 **변환**할 수 있다는 뜻이기도 하다. 성능 장치가 적응 통로가 되는 지점이다.

### Ep. 96 — 액션도

도입부에 이 시리즈의 작업 원칙이 나온다. 상태와 액션, 구조체와 enum처럼 짝을 이루는 개념이 있을 때, 한쪽에서 쓸모 있는 걸 찾으면 즉시 다른 쪽의 대응물을 찾아봐야 한다는 것이다.

```swift
public final class ViewStore<Value, Action>: ObservableObject {
  public let send: (Action) -> Void
}
```

`send`가 메서드가 아니라 저장 프로퍼티다. 소스에 메서드로 만들려던 흔적이 주석으로 남아 있는데, 클로저로 들고 있어야 만들 때 변환을 끼워 넣을 수 있어서다.

### Ep. 97 — macOS로 증명

도입부가 비용을 먼저 인정한다. `ViewStore`는 뷰마다 상태 구조체와 액션 enum을 새로 만들게 하니 복잡도가 는다. 그럼에도 값을 한다는 걸 macOS 앱을 만들어 보인다.

macOS 버전이 다른 점으로 든 예가 좋다.

- 모달 대신 팝오버 — 팝오버는 iPhone에서 지원되지 않는다
- 더블탭 제스처 제거 — Mac에서 흔한 동작이 아니다

같은 기능인데 플랫폼마다 상호작용이 다르고, 그러면 뷰가 보낼 수 있는 액션 집합도 달라진다. Ep. 96에서 액션까지 좁힌 이유가 여기서 드러난다.

전략 두 갈래를 다 보여준다. 하나의 뷰가 여러 플랫폼을 다루는 방식과, 플랫폼마다 뷰를 따로 두는 방식이다. 어느 쪽이든 리듀서와 상태는 공유된다.

## 같은 순서의 세 번째 반복

이 섹션을 읽는 열쇠다. 상태를 좁히고 액션을 좁히는 순서가 이번이 세 번째다.

| 대상 | 상태 좁히기 | 액션 좁히기 |
|---|---|---|
| 리듀서 | [Ep. 69](../02-reducers-and-stores/ep69-composable-state-management-state-pullbacks.md) `pullback(value:)` | [Ep. 70](../02-reducers-and-stores/ep70-composable-state-management-action-pullbacks.md) `pullback(action:)` |
| Store | [Ep. 73](../03-modularity/ep73-modular-state-management-view-state.md) `view(value:)` | [Ep. 74](../03-modularity/ep74-modular-state-management-view-actions.md) `view(action:)` |
| ViewStore | [Ep. 95](ep95-adaptive-state-management-state.md) | [Ep. 96](ep96-adaptive-state-management-actions.md) |

Ep. 96 도입부의 원칙("짝을 이루는 개념 중 한쪽에서 쓸모를 찾으면 다른 쪽도 보라")이 이 반복을 설명한다. 우연이 아니라 의식적인 작업 방식이다.

## 06 섹션과 같은 성격

[Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)의 숙제 다섯은 [05 섹션](../05-testing/00-overview.md)에서 다 닫혔다. [06](../06-dependency-management/00-overview.md)과 이 섹션은 완성된 아키텍처의 약한 부분을 손보는 작업이다.

- 06이 손본 것 — 05가 도입한 전역 Environment
- 07이 손본 것 — 03이 도입한 `Store.view`의 성능

둘 다 "그때는 목적에 충분했는데 실제로 써 보니 부족했다"는 구조다.

## 이 섹션의 특징 — 참고자료가 없다

앞 섹션들은 References가 풍부했다. Elm, Redux, 범주론, John Hughes 논문 같은 것들이었다. 이 섹션은 거의 없다. Ep. 94에 Apple의 메모리 프로파일링 문서 하나뿐이고 95~97은 없다.

외부 이론을 들여오는 게 아니라 **자기 코드를 실측하고 고치는** 편들이라 그렇다. 성격이 다른 섹션이라는 신호이기도 하다.

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 94](ep94-adaptive-state-management-performance.md) — 문제 측정. 누수 수정 diff는 실무에서 바로 쓸 만하다
3. [Ep. 95](ep95-adaptive-state-management-state.md) → [96](ep96-adaptive-state-management-actions.md) — 상태와 액션은 짝이니 붙여서 본다
4. [Ep. 97](ep97-adaptive-state-management-the-point.md) — 증명

## 확인 범위

확인한 것

- 섹션 제목과 타임스탬프, 도입부, 에피소드 설명, References
- 메모리 누수 수정 세 건 (Ep. 93 → 94 소스 diff)
- `ViewStore` 도입과 `removeDuplicates` API (Ep. 95), 액션 파라미터 추가 (Ep. 96)

확인하지 못한 것

- 성능 측정 방법과 스트레스 테스트 결과
- Ep. 96의 View actions 실제 설계, 테스트 변경
- Ep. 97의 macOS 앱 구현

`ComposableArchitecture.swift` 줄 수: 105(Ep. 93) → 107 → 139 → 151 → 151. Ep. 97에서 변하지 않는 게 그 편의 주장을 뒷받침한다. 아키텍처를 더 고치지 않고 이미 만든 것으로 macOS 앱을 짰다는 뜻이다.
