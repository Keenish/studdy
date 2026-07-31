# Ep. 95 — Adaptive State Management: State

- 출처: [Point-Free Episode #95](https://www.pointfree.co/episodes/ep95-adaptive-state-management-state)
- 코드: [0095-adaptive-state-management-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0095-adaptive-state-management-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-03-23
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:58 | View models and view stores |
| 10:05 | View store performance |
| 18:41 | Counter view performance |
| 23:41 | View store memory management |
| 27:51 | Adapting view stores |
| 39:09 | Next time: adaptive actions |

---

## 이 편이 하려는 것

[Ep. 94](ep94-adaptive-state-management-performance.md)에서 측정한 문제를 푼다.

도입부가 원인을 한 문장으로 말한다. 뷰 안의 store 하나가 **그 뷰가 UI를 그리는 데 필요한 상태뿐 아니라 자식들의 상태까지 전부** 들고 있다는 것이다. 그러니 앱 어딘가에서 상태가 바뀌면 그것과 무관한 뷰까지 다시 그려진다.

해법은 중간 객체를 하나 두는 것이다. 각 뷰에 **그 뷰가 실제로 쓰는 상태만** 노출한다.

## ViewStore

"View models and view stores" 섹션이 계보를 밝히는 자리로 보인다. MVVM의 뷰 모델과 같은 위치에 있는 개념이라는 이야기다.

```swift
public final class ViewStore<Value>: ObservableObject
```

`Store`와 `ViewStore`가 나뉜다.

- `Store` — 앱의 상태와 리듀서를 들고 실제로 액션을 처리한다
- `ViewStore` — 뷰가 관찰하는 대상. 필요한 만큼만 담는다

`ObservableObject`를 채택한 쪽이 `ViewStore`라는 게 핵심이다. SwiftUI가 다시 그리는 판단을 여기서 한다.

## 중복 제거

성능 문제의 실제 해결책이다.

```swift
extension Store where Value: Equatable {
  public var view: ViewStore<Value> {
    self.view(removeDuplicates: ==)
  }
}

public func view(
  removeDuplicates predicate: @escaping (Value, Value) -> Bool
) -> ViewStore<Value>
```

전역 상태가 바뀌어도 **이 뷰가 보는 조각이 실제로 달라졌을 때만** 갱신을 흘려보낸다. Combine의 `removeDuplicates(by:)`를 쓴다.

[Ep. 94](ep94-adaptive-state-management-performance.md) 소스에 주석으로 남아 있던 `.removeDuplicates()`가 여기서 살아난다.

API가 두 겹인 점도 눈여겨볼 만하다. `Value`가 `Equatable`이면 `==`로 알아서 비교하고, 아니면 비교 함수를 직접 준다. 상태가 항상 `Equatable`일 수는 없으니 탈출구를 열어 둔 것이다.

## 메모리 관리

"View store memory management" 섹션이 따로 있다. `ViewStore`는 전역 store를 구독하는 객체라 구독 수명을 관리해야 한다. [Ep. 94](ep94-adaptive-state-management-performance.md)에서 누수를 잡고 온 직후라 이번엔 새로 만드는 객체에서 같은 실수를 피하는 작업으로 보인다.

## 적응

"Adapting view stores" 섹션(27:51~39:09)이 이 섹션 이름의 이유다.

`ViewStore`가 뷰에 맞는 상태만 노출한다는 건, 그 상태를 **뷰가 원하는 모양으로 변환**할 수 있다는 뜻이기도 하다. 성능을 위해 도입한 장치가 플랫폼별 적응의 통로가 된다. iOS 뷰와 macOS 뷰가 같은 비즈니스 로직 위에서 서로 다른 상태 모양을 보게 만들 수 있다.

## 남는 문제

`ViewStore<Value>`는 이름대로 상태만 다룬다. 액션은 여전히 앱 전체 액션이다.

02·03 섹션에서 두 번 겪은 것과 같은 반쪽 상태다. → [Ep. 96](ep96-adaptive-state-management-actions.md)

## 참고자료

이 편은 References가 없다. 외부 개념을 들여오지 않고 앞 편의 측정 결과에 대응하는 편이라 그렇다.

## 확인 범위

- 영상이 유료라 논증의 세부와 성능 측정 결과는 확인하지 못했다
- `ViewStore` 정의와 `removeDuplicates` API는 저장소 소스로 확인했다. `ComposableArchitecture.swift`가 107줄 → 139줄로 늘어난다
