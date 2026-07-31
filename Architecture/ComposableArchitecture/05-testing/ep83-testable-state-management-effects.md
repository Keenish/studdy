# Ep. 83 — Testable State Management: Effects

- 출처: [Point-Free Episode #83](https://www.pointfree.co/episodes/ep83-testable-state-management-effects)
- 코드: [0083-testable-state-management-effects](https://github.com/pointfreeco/episode-code-samples/tree/main/0083-testable-state-management-effects) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-12-02
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:44 | Testing effects |
| 2:36 | Recap: the environment |
| 7:44 | Controlling the favorite primes save effect |
| 17:06 | Controlling the favorite primes load effect |
| 24:19 | Testing the favorite primes save effect |
| 31:31 | Testing the favorite primes load effect |
| 37:51 | Controlling the counter effect |
| 42:25 | Testing the counter effects |
| 48:51 | Next time: test ergonomics |

---

## 이 편이 하려는 것

[Ep. 82](ep82-testable-state-management-reducers.md)에서 리듀서는 순수 함수라 쉽게 테스트됐다. 문제는 리듀서가 반환하는 효과다.

에피소드 설명이 문제를 정확히 말한다. 부수효과는 앱에서 가장 테스트하기 어렵다. 바깥세상과 얘기하고, 일을 처리하느라 여기저기 흩어지는 경향이 있다. 그런데 **아주 적은 작업으로 넓은 커버리지를 얻을 수 있고**, 그건 과거에 다룬 단순한 기법 덕이라고 예고한다.

그 기법이 Environment다.

## Environment

섹션 제목이 "Recap: the environment"인 게 힌트다. 새로 만드는 게 아니라 Point-Free가 오래전부터 써 온 패턴을 가져온다.

발상은 단순하다. 바깥세상과 얘기하는 함수들을 구조체 하나에 모으고, 그걸 전역 변수로 두되 테스트에서 갈아 끼운다.

```swift
struct FileClient {
  var load: (String) -> Effect<Data?>
  var save: (String, Data) -> Effect<Never>
}

struct FavoritePrimesEnvironment {
  var fileClient: FileClient
}

extension FavoritePrimesEnvironment {
  static let live = FavoritePrimesEnvironment(fileClient: .live)
  static let mock = FavoritePrimesEnvironment(...)
}

var Current = FavoritePrimesEnvironment.live
```

리듀서 안에서는 `Current.fileClient.save(...)`처럼 쓴다. 테스트에서는 `Current = .mock`으로 바꾸면 실제 디스크를 건드리지 않는다.

프로토콜이 아니라 **함수를 담은 구조체**인 게 특징이다. 목을 만들려고 클래스를 상속하거나 프로토콜을 구현할 필요 없이, 클로저만 바꿔 끼우면 된다.

`save`의 반환 타입이 `Effect<Never>`인 것도 눈여겨볼 만하다. 저장은 액션을 만들어 내지 않으니 절대 값을 방출하지 않는 효과다. 타입으로 그 성질이 드러난다.

## 통제와 테스트를 나눠서

섹션 구성이 규칙적이다.

- Controlling the ... effect
- Testing the ... effect

**통제**가 먼저다. 효과가 Environment를 거치도록 코드를 고치는 단계다. 그다음에야 **테스트**가 가능해진다. 저장·불러오기·카운터 효과 각각에 대해 이 두 단계를 반복한다.

리팩터링이 먼저고 테스트가 따라온다는 순서 자체가 이 편의 메시지다. 테스트가 안 되는 코드는 대개 의존성이 하드코딩돼 있고, 그걸 값으로 바꾸는 게 선행 작업이다.

## 참고자료

이 편은 Environment 계보가 References의 절반이다.

- [Dependency Injection Made Easy](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy) — Point-Free #16. Environment 개념의 도입
- [Dependency Injection Made Comfortable](https://www.pointfree.co/episodes/ep18-dependency-injection-made-comfortable) — Point-Free #18. 테스트 데이터 구성까지
- [How to Control the World](https://vimeo.com/291588126) — Stephen Celis, NSSpain 2018. Environment 방식 의존성 주입 강연. 무료
- [Structure and Interpretation of Swift Programs](https://www.youtube.com/watch?v=V-YvI83QdMs) — Colin Barrett, Functional Swift 2015. Environment 개념을 처음 소개한 강연. 무료
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 실제 테스트 코드와 논증의 세부는 확인하지 못했다
- Environment 구조는 저장소의 `FavoritePrimes.swift`로 확인했다. 이 편에서 87줄 → 189줄로 늘어난다
- `ComposableArchitecture.swift`는 이 편에서도 130줄로 그대로다. 테스트를 위해 아키텍처 자체를 고치지는 않았다
