# 06 · Dependency Management — 세 편 흐름

Point-Free [Dependency Management](https://www.pointfree.co/collections/composable-architecture/dependency-management) 섹션(Ep. 91~93)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 세 편 모두 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT) 소스로 확인했다

관련 문서

- [ep91 — Made Composable](ep91-dependency-injection-made-composable.md) · 리듀서가 환경을 인자로 받는다
- [ep92 — Made Modular](ep92-dependency-injection-made-modular.md) · 앱의 모듈과 테스트를 거기에 맞춘다
- [ep93 — The Point](ep93-modular-dependency-injection-the-point.md) · 전역 환경으로는 안 되던 문제 셋을 짚는다

---

## 이 섹션이 하는 일

섹션 설명이 문제를 정확히 말한다. 이제 효과를 실행할 수 있고 그 효과가 시스템과 어떻게 상호작용하는지 테스트도 되지만, **효과에 의존성을 건네는 방식이 이상적이지 않다.**

[05 섹션](../05-testing/00-overview.md)에서 도입한 Environment는 전역 변수였다.

```swift
var Current = FavoritePrimesEnvironment.live
```

편하지만 전역이라 컴파일러가 도와주지 않는다. 어떤 리듀서가 무엇에 의존하는지 시그니처에 드러나지 않고, 프로세스에 하나뿐이라 같은 화면을 다른 환경으로 띄울 수도 없다.

이 섹션은 그 전역을 걷어내고 **환경을 리듀서 인자로** 만든다.

## 세 편이 쌓이는 순서

### Ep. 91 — 리듀서에 세 번째 축

도입부가 해법을 "리듀서 시그니처에 아주 작은 변경"이라고 예고하는데, 실제로 인자 하나가 는다.

```swift
public typealias Reducer<Value, Action, Environment>
  = (inout Value, Action, Environment) -> [Effect<Action>]
```

전역 변수를 읽는 대신 넘겨받는다. 의존성이 타입에 드러나므로 컴파일러가 검사한다.

축이 늘었으니 합성 함수들도 따라 바뀐다. `pullback`이 제네릭 파라미터 여섯 개짜리가 된다.

```swift
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(
  _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
  value: WritableKeyPath<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>,
  environment: @escaping (GlobalEnvironment) -> LocalEnvironment
) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment>
```

상태·액션·환경이 각각 지역과 전역으로 짝을 이룬다. 환경 변환은 `(Global) -> Local` 방향이라 상태 쪽과 같다. 큰 환경에서 이 기능이 필요한 것만 꺼내 준다.

한 가지 타협이 있다. `Store`에까지 `Environment` 제네릭이 붙으면 뷰가 환경 타입을 알아야 해서 모듈화에 역행한다. 그래서 store 안에서 타입을 지운다.

```swift
private let environment: Any
// 이니셜라이저만 Environment에 제네릭이고, 실행 시 as!로 되돌린다
```

`Store<Value, Action>`의 제네릭이 둘로 유지되니 뷰 쪽은 변화가 없다. 대신 타입 안전성을 한 지점에서 사람이 보증하는 형태가 된다.

소스에 검토했다 버린 모양도 주석으로 남아 있다 — `(inout Value, Action) -> (Environment) -> [Effect<Action>]`. 환경을 커링해서 받는 형태인데, 결국 인자 셋을 나란히 받는 쪽을 택했다.

### Ep. 92 — 앱을 옮기다

아키텍처가 바뀌었으니 앱의 모듈들과 테스트를 맞춘다. 의존성이 단순한 모듈부터 시작해 메인 타깃 쪽으로 올라간다. [03 섹션](../03-modularity/00-overview.md)에서 만든 모듈 경계가 여기서 작업 순서를 정해 준다.

눈에 띄는 건 "Tuplizing the environment"다. 모듈이 늘 때마다 앱 환경 구조체에 필드를 추가하고 이름을 정하는 게 반복 작업인데, 튜플로 묶으면 그 의식이 사라진다. `pullback`이 요구하는 `(Global) -> Local` 변환은 튜플 요소를 꺼내는 것으로 충분하다.

테스트도 달라진다. 예전엔 `Current = .mock`으로 전역을 바꿔치기했는데, 이제 환경을 인자로 넘긴다. 테스트끼리 간섭할 여지가 구조적으로 없어진다.

### Ep. 93 — 무엇이 해결됐나

도입부가 해결된 문제 셋을 명시한다. 섹션 구성이 그대로 그 셋이다.

| 문제 | 전역 환경에서 | 인자로 받으면 |
|---|---|---|
| 환경이 여러 개 | 조율이 어렵고 정적 보장이 없다. 하나 빠뜨려도 컴파일이 된다 | `pullback`이 변환을 요구하므로 안 맞추면 컴파일이 안 된다 |
| 지역 의존성 | 프로세스에 하나뿐이라 같은 화면을 다른 환경으로 못 띄운다 | 인스턴스마다 다른 환경을 줄 수 있다 |
| 의존성 공유 | 여러 모듈이 같은 인스턴스를 쓴다는 보장이 없다 | 앱 환경 하나를 여러 지역 환경으로 나눠 준다 |

세 번째에 시간이 가장 많이 배정돼 있다(18분). 가장 까다로운 문제였던 것으로 보인다.

## 이 섹션이 인정하는 대가

Ep. 93 도입부가 덧붙인다. 이 해법은 **Composable Architecture를 채택했기 때문에** 가능했다.

전역 `Current` 패턴은 어떤 코드베이스에도 얹을 수 있는 가벼운 기법이다. 반면 여기서 얻은 것들은 리듀서와 `pullback`이라는 구조를 이미 갖고 있어야 성립한다.

[Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 "테스트 가능성을 원하면 어차피 층을 올려야 한다"고 논증한 것과 같은 성격이다. 이 시리즈는 이런 대가를 감추지 않는 편이다.

## 01~05와의 관계

[Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)의 숙제 다섯은 [05 섹션](../05-testing/00-overview.md)에서 이미 다 닫혔다. 이 섹션부터는 성격이 다르다. **완성된 아키텍처의 약한 부분을 다시 손보는** 작업이다.

여기서 손보는 건 05 섹션이 도입한 Environment다. 그때는 테스트를 가능하게 만드는 게 목적이라 전역 변수로 충분했는데, 실제로 써 보니 모듈 여러 개를 조율할 때 부족했다.

앞으로의 섹션들도 대체로 이런 성격이다. 07 Adaptation, 08 Ergonomics처럼 다듬는 편이거나, 10 Reducer Protocol, 13 Observable Architecture처럼 Swift·SwiftUI의 변화에 맞춰 다시 짓는 편이다.

## 에피소드 번호가 건너뛴다

05 섹션이 Ep. 85로 끝나는데 이 섹션은 Ep. 91부터다. 86~90은 이 컬렉션에 속하지 않는 다른 주제의 에피소드들이다. Point-Free는 여러 시리즈를 번갈아 내보내므로 컬렉션 안에서 번호가 연속하지 않는다.

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 91](ep91-dependency-injection-made-composable.md) — 시그니처 변화. 이 섹션의 핵심은 여기 다 있다
3. [Ep. 93](ep93-modular-dependency-injection-the-point.md) — 왜 그렇게 했는지. 91을 보고 바로 봐도 된다
4. [Ep. 92](ep92-dependency-injection-made-modular.md) — 실제 마이그레이션. 순서상 중간이지만 적용 편이라 나중에 봐도 무방하다

## 확인 범위

확인한 것

- 섹션 제목과 타임스탬프, 도입부, 에피소드 설명, References
- `Reducer`·`combine`·`pullback`·`logging`·`Store`의 시그니처 변화 (저장소 소스)
- Ep. 93이 해결했다고 밝힌 문제 셋 (에피소드 설명·도입부에 명시)

확인하지 못한 것

- Ep. 91 "Current problems"에서 든 구체적 사례
- Ep. 92의 튜플 방식 실제 코드와 마이그레이션 과정
- Ep. 93의 각 문제에 대한 시연과 결론 세부

세 편의 `ComposableArchitecture.swift`는 105줄로 전부 동일하다. 아키텍처 변경은 Ep. 91에서 끝나고 92·93은 적용하고 검증하는 편이라는 뜻이다.
