# Ep. 98 — Ergonomic State Management: Part 1

- 출처: [Point-Free Episode #98](https://www.pointfree.co/episodes/ep98-ergonomic-state-management-part-1)
- 코드: [0098-ergonomic-state-management-pt1](https://github.com/pointfreeco/episode-code-samples/tree/main/0098-ergonomic-state-management-pt1) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-04-13
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:34 | Introduction |
| 1:45 | The architecture's surface area |
| 3:47 | Free functions |
| 8:38 | Reducer as a struct |
| 12:47 | Reducer methods |
| 19:32 | Updating the app's modules |
| 26:58 | Till next time |

---

## 이 편이 하려는 것

기능은 다 됐고 쓰기 편하게 다듬는다.

도입부가 지금까지를 정리하면서 한 가지를 짚는다. 이 라이브러리가 **200줄이 채 안 된다**는 점이다. 그 작은 코드로 합성·모듈화·테스트·부수효과·플랫폼 적응을 다 했다.

그리고 목적을 밝힌다. 더 널리 쓰이거나 **오픈소스로 공개하기 전에** 사용성을 손봐야 한다는 것이다. 실제로 이 무렵 TCA가 공개된다.

## 표면적

"The architecture's surface area" 섹션이 문제 제기다.

지금 아키텍처가 밖으로 내놓는 건 자유 함수들이다.

```swift
public func combine<Value, Action, Environment>(...)
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(...)
public func logging<Value, Action, Environment>(...)
```

전역 이름공간에 `combine`, `pullback`, `logging` 같은 흔한 단어가 놓인다. 라이브러리로 배포하면 쓰는 쪽 코드와 이름이 부딪히기 쉽다. `Reducer`가 `typealias`라 확장할 수도 없다.

## Reducer를 구조체로

```swift
public struct Reducer<Value, Action, Environment> {
  public init(_ reducer: @escaping (inout Value, Action, Environment) -> [Effect<Action>])
}
```

담고 있는 함수 모양은 그대로인데 `typealias`를 벗고 명목 타입이 된다. [Ep. 79](../04-side-effects/ep79-effectful-state-management-the-point.md)에서 `Effect`에 했던 것과 같은 수순이다. 타입이 되면 메서드를 붙일 수 있다.

## 자유 함수가 메서드로

`combine`은 정적 메서드가 된다.

```swift
public static func combine(_ reducers: Reducer...) -> Reducer
```

제네릭 파라미터가 사라졌다. `Reducer` 자신의 것을 쓰면 되니 다시 선언할 필요가 없다.

`pullback`은 인스턴스 메서드가 되면서 더 극적으로 줄어든다.

```swift
// 전 — 자유 함수, 제네릭 6개
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(
  _ reducer: ...
)

// 후 — 인스턴스 메서드, 제네릭 3개
public func pullback<GlobalValue, GlobalAction, GlobalEnvironment>(...)
```

지역 쪽 세 타입이 `Self`에서 나오니 전역 쪽만 남는다. [Ep. 91](../06-dependency-management/ep91-dependency-injection-made-composable.md)에서 환경 축이 붙으며 여섯까지 늘었던 게 절반으로 줄었다.

호출부도 달라진다. 함수를 감싸는 형태에서 점 문법으로 이어 붙이는 형태가 된다. 여러 변환을 연달아 적용할 때 읽기가 훨씬 낫다.

`logging`도 같은 방식으로 인스턴스 메서드가 된다. 고차 리듀서가 메서드로 표현되는 셈이다.

옛 자유 함수들은 지워지지 않고 **주석으로 남아 있다.** 저장소에서 전후를 나란히 볼 수 있다.

## 모듈 갱신

"Updating the app's modules" 섹션이 마지막 작업이다. API가 바뀌었으니 앱의 각 모듈이 새 형태를 쓰도록 고친다. [03 섹션](../03-modularity/00-overview.md)에서 나눠 둔 모듈들이 여기서도 작업 단위가 된다.

## 다음 편

리듀서 쪽은 정리됐고 이제 뷰 쪽이다. → [Ep. 99](ep99-ergonomic-state-management-part-2.md)

## 참고자료

이 편은 References가 없다. 외부 개념 없이 자기 API를 다듬는 편이라 그렇다.

## 확인 범위

- 영상이 유료라 논증의 세부와 실제 마이그레이션 과정은 확인하지 못했다
- `Reducer` 구조체화와 메서드 시그니처는 저장소 소스로 확인했다. `ComposableArchitecture.swift`가 151줄 → 220줄로 늘어나는데, 옛 자유 함수가 주석으로 남아 있는 분량이 포함돼 있다
