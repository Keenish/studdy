# Ep. 93 — Modular Dependency Injection: The Point

- 출처: [Point-Free Episode #93](https://www.pointfree.co/episodes/ep93-modular-dependency-injection-the-point)
- 코드: [0093-modular-dependency-injection-pt3](https://github.com/pointfreeco/episode-code-samples/tree/main/0093-modular-dependency-injection-pt3) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-03-02
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:32 | Multiple environments |
| 13:52 | Local dependencies |
| 23:55 | Sharing dependencies |
| 41:54 | Conclusion |

---

## 이 편이 하려는 것

두 편에 걸친 리팩터링이 실제로 뭘 해결했는지 확인한다. 섹션 구성이 곧 답이다. 문제 셋을 하나씩 짚는다.

이 편이 이 섹션에서 근거가 가장 좋다. 도입부가 **해결된 문제 셋을 명시**하기 때문에, 유료 구간이어도 무엇을 다루는지는 분명하다.

## 전역 환경으로는 안 되던 것 셋

### 1. 환경이 여러 개일 때 (2:32)

모듈마다 자기 환경이 따로 있으면 그것들을 조율하기 어렵고 **정적 보장을 잃는다.**

전역 변수 방식에서는 각 모듈이 자기 `Current`를 들고 있었다. 앱을 조립할 때 그것들을 전부 제대로 설정했는지 컴파일러가 확인해 주지 않는다. 하나를 빠뜨리면 실행 중에야 알게 된다.

환경이 리듀서 인자가 되면 이 문제가 사라진다. `pullback`이 `(GlobalEnvironment) -> LocalEnvironment` 변환을 요구하므로, 앱 환경에서 각 모듈 환경을 어떻게 뽑을지 명시하지 않으면 컴파일이 안 된다.

### 2. 지역 의존성 (13:52)

모듈당 환경이 하나뿐이면 **같은 화면을 다른 환경으로 재사용할 수 없다.**

전역 변수는 프로세스에 하나다. 같은 카운터 화면을 두 개 띄우면서 하나는 실제 API를, 하나는 목을 쓰게 하는 게 불가능하다.

인자로 받으면 인스턴스마다 다른 환경을 줄 수 있다. 화면을 여러 벌 띄우거나, 같은 기능을 다른 설정으로 재사용하는 게 가능해진다.

### 3. 의존성 공유 (23:55)

여러 기능이 **공통 의존성을 공유하기 어렵다.**

날짜 생성기나 API 클라이언트처럼 여러 모듈이 함께 쓰는 게 있는데, 모듈마다 자기 환경에 따로 담으면 같은 인스턴스를 쓴다는 보장이 없다.

앱 환경에서 각 모듈 환경으로 가는 변환을 명시하는 구조라면, 하나의 공통 의존성을 여러 지역 환경으로 나눠 주는 게 자연스럽다.

시간 배분이 이 섹션에 가장 많다(23:55~41:54, 18분). 셋 중 가장 다루기 까다로운 문제였던 것으로 보인다.

## 대가

도입부가 한 가지를 덧붙인다. 이 해법은 **Composable Architecture를 채택했기 때문에** 가능했다.

솔직한 대목이다. 전역 `Current` 패턴은 어떤 코드베이스에도 얹을 수 있는 가벼운 기법이지만, 여기서 얻은 것들은 리듀서와 `pullback`이라는 구조를 이미 갖고 있어야 성립한다. 아키텍처를 안 쓰면 이 이점도 없다.

[Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 "테스트 가능성을 원하면 어차피 층을 올려야 한다"고 논증한 것과 같은 성격의 이야기다.

## 참고자료

- [Dependency Injection Made Easy](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy) — Point-Free #16. 전역 `Current` 패턴의 출처. 이 섹션은 그 패턴의 한계를 다루므로 대조해 읽으면 좋다
- [Dependency Injection Made Comfortable](https://www.pointfree.co/episodes/ep18-dependency-injection-made-comfortable) — Point-Free #18
- [How to Control the World](https://vimeo.com/291588126) — Stephen Celis, NSSpain 2018. 무료
- [Effectful State Management: Synchronous Effects](https://www.pointfree.co/episodes/ep76-effectful-state-management-synchronous-effects)
- [Testable State Management: Reducers](https://www.pointfree.co/episodes/ep82-testable-state-management-reducers)

## 확인 범위

- 영상이 유료라 각 문제의 구체적 시연과 결론의 세부는 확인하지 못했다
- 해결된 문제 셋은 에피소드 설명과 도입부에 명시돼 있어 근거가 있다. 각 문제에 대한 위 설명은 시그니처 변화로부터 추론한 것이므로 영상의 논증과 다를 수 있다
- `ComposableArchitecture.swift`는 105줄로 Ep. 91·92와 동일하다
