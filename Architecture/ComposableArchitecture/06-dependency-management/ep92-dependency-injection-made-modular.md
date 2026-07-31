# Ep. 92 — Dependency Injection Made Modular

- 출처: [Point-Free Episode #92](https://www.pointfree.co/episodes/ep92-dependency-injection-made-modular)
- 코드: [0092-modular-dependency-injection-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0092-modular-dependency-injection-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-02-24
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:54 | Using the architecture's environment |
| 10:46 | Tuplizing the environment |
| 19:50 | Testing with the environment |
| 31:55 | Next time: what's the point? |

---

## 이 편이 하려는 것

[Ep. 91](ep91-dependency-injection-made-composable.md)에서 리듀서가 환경을 인자로 받도록 아키텍처를 고쳤다. 이제 앱을 거기에 맞춘다.

도입부가 순서를 밝힌다. 앱이 모듈로 나뉘어 있으니 **의존성이 단순한 모듈부터 시작해 메인 타깃 쪽으로 올라간다.** 그리고 이미 Environment 기법을 쓰고 있었으니 옮기는 게 어렵지 않다고 말한다.

[03 섹션](../03-modularity/00-overview.md)에서 만든 모듈 경계가 여기서 작업 순서를 정해 주는 셈이다.

## 전역 변수를 걷어내기

"Using the architecture's environment" 섹션이 본 작업이다. 각 모듈의 `var Current`를 없애고, 리듀서가 인자로 받은 환경을 쓰도록 바꾼다.

바뀌는 건 참조 방식이다. `Current.fileClient.save(...)`가 리듀서에 넘어온 환경을 통하는 형태가 된다. 의존성이 시그니처에 드러나므로 어떤 리듀서가 무엇을 필요로 하는지 타입만 봐도 알 수 있다.

## 환경을 튜플로

"Tuplizing the environment"가 이 편에서 가장 눈에 띄는 대목이다.

문제는 이렇다. 앱 전체 환경은 각 모듈이 필요로 하는 것들을 다 담아야 한다. 그런데 모듈이 늘 때마다 앱 환경 구조체에 필드를 추가하고 이름을 정하는 일이 반복된다.

튜플을 쓰면 그 의식이 사라진다. 여러 환경을 그냥 나란히 묶으면 되고, [Ep. 91](ep91-dependency-injection-made-composable.md)의 `pullback`이 받는 `(GlobalEnvironment) -> LocalEnvironment` 변환은 튜플 요소를 꺼내는 것으로 충분하다.

구조체를 만들지 않아도 되니 가볍다는 게 요지로 보인다. 도입부에서 이 접근을 "modular, lightweight"라고 부른다.

## 테스트

"Testing with the environment" 섹션이 3분의 1을 차지한다.

[Ep. 83](../05-testing/ep83-testable-state-management-effects.md)에서는 `Current = .mock`으로 전역을 바꿔치기했다. 이제는 환경을 **인자로 넘긴다.** 테스트마다 원하는 환경을 만들어 주면 되니 전역 상태를 건드릴 일이 없다.

차이가 큰 부분이다. 전역을 바꾸는 방식은 테스트끼리 간섭할 여지가 있고, 되돌리는 걸 잊으면 다른 테스트가 영향을 받는다. 인자로 넘기면 그런 문제가 구조적으로 없어진다.

## 다음 편

적용은 끝났고 이제 결산이다. → [Ep. 93](ep93-modular-dependency-injection-the-point.md)

## 참고자료

- [Dependency Injection Made Easy](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy) — Point-Free #16
- [Dependency Injection Made Comfortable](https://www.pointfree.co/episodes/ep18-dependency-injection-made-comfortable) — Point-Free #18
- [How to Control the World](https://vimeo.com/291588126) — Stephen Celis, NSSpain 2018. 무료
- [Effectful State Management: Synchronous Effects](https://www.pointfree.co/episodes/ep76-effectful-state-management-synchronous-effects)
- [Testable State Management: Reducers](https://www.pointfree.co/episodes/ep82-testable-state-management-reducers)

## 확인 범위

- 영상이 유료라 실제 마이그레이션 과정과 튜플 방식의 구체적 코드는 확인하지 못했다. 위 내용은 섹션 제목과 도입부에서 읽어낸 것이다
- `ComposableArchitecture.swift`는 이 편에서도 105줄로 Ep. 91과 동일하다. 아키텍처는 그대로 두고 앱 쪽만 고치는 편이다
