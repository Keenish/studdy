# Ep. 99 — Ergonomic State Management: Part 2

- 출처: [Point-Free Episode #99](https://www.pointfree.co/episodes/ep99-ergonomic-state-management-part-2)
- 코드: [0099-ergonomic-state-management-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0099-ergonomic-state-management-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-04-20
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:21 | Introduction |
| 0:49 | Dynamic member lookup |
| 6:48 | Dynamic member store |
| 9:16 | Bindings and the architecture |
| 14:48 | Binding helpers |
| 22:48 | What's the point? |

---

## 이 편이 하려는 것

[Ep. 98](ep98-ergonomic-state-management-part-1.md)에서 리듀서 쪽 API를 다듬었다. 이번엔 뷰 쪽이다.

도입부가 불편을 짚는다. 뷰가 상태를 읽으려면 매번 view store의 `value` 프로퍼티를 **거쳐 들어가야** 한다. `viewStore.value.count` 같은 식이다. 한 겹이 늘 끼어든다.

두 가지로 해결한다. Swift의 새 기능 하나와 SwiftUI 헬퍼 하나다.

## 동적 멤버 조회

Swift의 key path 기반 `@dynamicMemberLookup`을 쓴다.

```swift
@dynamicMemberLookup
public final class ViewStore<Value, Action>: ObservableObject {
  public subscript<LocalValue>(dynamicMember keyPath: KeyPath<Value, LocalValue>) -> LocalValue {
    self.value[keyPath: keyPath]
  }
}
```

이러면 `viewStore.count`가 `viewStore.value.count`로 자동 해석된다. `value`를 쓸 일이 없어진다.

key path 기반이라는 게 중요하다. 문자열 기반 동적 조회와 달리 **컴파일러가 검사한다.** `Value`에 없는 프로퍼티를 쓰면 컴파일 에러가 난다. 편의를 얻으면서 타입 안전성을 잃지 않는다.

섹션이 둘로 나뉜 것도 눈에 띈다. "Dynamic member lookup"(0:49)에서 기능 자체를 설명하고 "Dynamic member store"(6:48)에서 적용한다. 당시엔 비교적 새 기능이라 소개가 필요했던 것으로 보인다.

## 바인딩

시간 배분의 절반이 여기다(9:16~22:48).

SwiftUI는 양방향 바인딩을 요구하는 컴포넌트가 많다. `TextField`, `Toggle`, `Slider` 같은 것들은 `Binding<T>`를 받는다. 그런데 이 아키텍처에서 상태를 바꾸는 유일한 길은 액션을 보내는 것이다.

바인딩이 값을 직접 쓰게 두면 [01 섹션](../01-swiftui-and-state-management/00-overview.md)에서 문제 삼았던 지점으로 돌아간다. [Ep. 67의 4.2](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)가 흩어진 변경 일곱 군데를 셀 때, 그중 둘이 바로 **alert 바인딩 안에 숨은 변경**이었다.

"Bindings and the architecture" 섹션이 이 긴장을 다루고, "Binding helpers"가 해법을 만든다. 읽기는 상태에서, 쓰기는 액션 전송으로 가는 바인딩을 만들어 주는 헬퍼일 것으로 보인다. 그러면 SwiftUI 컴포넌트를 쓰면서도 변경 경로가 하나로 유지된다.

## 시리즈의 마무리

마지막이 "What's the point?"다. 98·99 두 편의 결산이자, [01 섹션](../01-swiftui-and-state-management/00-overview.md)부터 이어진 아키텍처 구축 전체의 마무리 지점이기도 하다.

Ep. 98 도입부가 오픈소스 공개를 앞두고 다듬는다고 밝혔으니, 여기까지가 공개 직전의 모습이다.

## 참고자료

이 편도 References가 없다. 페이지에 걸린 건 샘플 코드 저장소뿐이다.

## 확인 범위

- 영상이 유료라 바인딩 헬퍼의 실제 시그니처와 결산 내용은 확인하지 못했다. 위 바인딩 부분은 섹션 제목과 도입부에서 읽어낸 것이다
- `@dynamicMemberLookup`과 서브스크립트는 저장소 소스로 확인했다. `ComposableArchitecture.swift`가 220줄 → 225줄로 늘어난다
