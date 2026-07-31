# Ep. 91 — Dependency Injection Made Composable

- 출처: [Point-Free Episode #91](https://www.pointfree.co/episodes/ep91-dependency-injection-made-composable)
- 코드: [0091-modular-dependency-injection-pt1](https://github.com/pointfreeco/episode-code-samples/tree/main/0091-modular-dependency-injection-pt1) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-02-17
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:40 | Introduction |
| 2:17 | Effects recap |
| 8:31 | Environment recap |
| 11:19 | Current problems |
| 16:52 | Environment in the reducer |
| 23:34 | Environment in the store |
| 27:44 | Erasing the environment from the store |
| 31:58 | Till next time |

---

## 이 편이 하려는 것

[05 섹션](../05-testing/00-overview.md)에서 Environment로 의존성을 갈아 끼울 수 있게 됐다. 부수효과와 테스트 가능성이 공존한다는 걸 보였다.

도입부가 Environment의 장점을 다시 확인한다. 부수효과를 일으키는 것들을 한자리에 모아 두니 접근이 일관되고 테스트에서 바꿔 끼우기 쉽다.

그런데 지금 방식에 한계가 있다고 말한다. 그리고 해법을 이렇게 예고한다 — **리듀서 시그니처에 아주 작은 변경**을 가하면 훨씬 견고해진다.

## 무엇이 문제였나

[Ep. 83](../05-testing/ep83-testable-state-management-effects.md)의 방식은 전역 변수였다.

```swift
var Current = FavoritePrimesEnvironment.live
```

모듈마다 자기 `Current`가 있고, 리듀서는 그걸 직접 참조한다. 편하지만 대가가 있다.

"Current problems" 섹션이 이걸 다루는데 유료 구간이라 세부는 못 봤다. 다만 [Ep. 93](ep93-modular-dependency-injection-the-point.md) 도입부가 해결된 문제 셋을 명시하므로 역으로 알 수 있다.

- 모듈마다 환경이 따로 있으니 **조율하기 어렵고 정적 보장을 잃는다**
- 모듈당 환경이 하나뿐이라 **같은 화면을 다른 환경으로 재사용할 수 없다**
- 여러 기능이 **공통 의존성을 공유하기 어렵다**

전역 변수라 컴파일러가 도와주지 않는 게 공통 원인이다. 어떤 리듀서가 무엇에 의존하는지 시그니처에 안 드러난다.

## 해법 — 리듀서가 환경을 인자로 받는다

리듀서에 세 번째 축이 생긴다.

```swift
public typealias Reducer<Value, Action, Environment>
  = (inout Value, Action, Environment) -> [Effect<Action>]
```

전역 변수를 읽는 대신 **넘겨받는다.** 의존성이 타입에 드러나므로 컴파일러가 검사한다.

소스에는 검토했다 버린 다른 모양도 주석으로 남아 있다.

```swift
// (inout Value, Action) -> (Environment) -> [Effect<Action>]
```

환경을 커링해서 받는 형태다. 결국 인자 셋을 나란히 받는 쪽을 택했다.

## 합성 함수들이 따라 바뀐다

축이 하나 늘었으니 `combine`과 `pullback`도 그걸 다뤄야 한다. `pullback`이 특히 눈에 띈다.

```swift
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(
  _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
  value: WritableKeyPath<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>,
  environment: @escaping (GlobalEnvironment) -> LocalEnvironment
) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment>
```

제네릭 파라미터가 여섯이다. 상태·액션·환경이 각각 지역과 전역으로 짝을 이룬다.

환경 변환의 방향이 `(GlobalEnvironment) -> LocalEnvironment`인 게 자연스럽다. 큰 환경에서 이 기능이 필요한 것만 꺼내 주는 것이다. 상태 쪽과 같은 방향이다.

`logging` 같은 고차 리듀서도 환경을 통과시키도록 바뀐다.

## store에서 환경 지우기

문제가 하나 남는다. `Store`는 뷰가 쓰는 타입인데, 여기에 `Environment` 제네릭까지 붙으면 뷰마다 환경 타입을 알아야 한다. 모듈화에 역행한다.

그래서 store 안에서 환경 타입을 지운다.

```swift
public final class Store<Value, Action>: ObservableObject {
  private let environment: Any

  public init<Environment>(
    initialValue: Value,
    reducer: @escaping Reducer<Value, Action, Environment>,
    environment: Environment
  ) {
    self.reducer = { value, action, environment in
      reducer(&value, action, environment as! Environment)
    }
  }
}
```

이니셜라이저만 환경에 대해 제네릭이고, 저장할 때는 `Any`로 담는다. 실행 시점에 `as!`로 되돌린다.

`Store<Value, Action>`의 제네릭이 둘로 유지되니 뷰 쪽은 아무 변화가 없다. 대신 타입 안전성을 한 지점에서 포기한다. 이니셜라이저에서 타입이 맞춰졌으니 실제로는 안전하지만, 컴파일러가 아니라 사람이 보증하는 형태다.

## 다음 편

아키텍처는 바뀌었고 이제 앱의 프레임워크들과 테스트를 여기에 맞춰야 한다. → [Ep. 92](ep92-dependency-injection-made-modular.md)

## 참고자료

References가 세 편 모두 같다. Environment 계보와 이 시리즈의 앞부분이다.

- [Dependency Injection Made Easy](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy) — Point-Free #16. `Current` 패턴의 출처
- [Dependency Injection Made Comfortable](https://www.pointfree.co/episodes/ep18-dependency-injection-made-comfortable) — Point-Free #18
- [How to Control the World](https://vimeo.com/291588126) — Stephen Celis, NSSpain 2018. 무료
- [Effectful State Management: Synchronous Effects](https://www.pointfree.co/episodes/ep76-effectful-state-management-synchronous-effects) — [04 섹션](../04-side-effects/) 시작점
- [Testable State Management: Reducers](https://www.pointfree.co/episodes/ep82-testable-state-management-reducers) — [05 섹션](../05-testing/) 시작점

## 확인 범위

- 영상이 유료라 "Current problems"에서 든 구체적 사례와 논증은 확인하지 못했다. 위 문제 셋은 Ep. 93 도입부에서 역으로 읽어낸 것이다
- 시그니처와 `Store`의 환경 소거는 저장소 소스로 확인했다
- 이 섹션 세 편의 `ComposableArchitecture.swift`는 105줄로 모두 동일하다. 아키텍처 변경은 91편에서 끝나고 92·93은 그걸 적용하고 검증하는 편이다
