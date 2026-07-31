# Ep. 82 — Testable State Management: Reducers

- 출처: [Point-Free Episode #82](https://www.pointfree.co/episodes/ep82-testable-state-management-reducers)
- 코드: [0082-testable-state-management-reducers](https://github.com/pointfreeco/episode-code-samples/tree/main/0082-testable-state-management-reducers) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-11-25
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:28 | Recap |
| 6:48 | Testing the prime modal |
| 13:54 | Testing favorite primes |
| 19:18 | Testing the counter |
| 29:19 | Unhappy paths and integration tests |
| 34:03 | Next time: testing effects |

---

## 이 편이 하려는 것

[Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)이 남긴 다섯 문제 중 마지막이다. 도입부가 지금까지 푼 넷을 정리한다.

- 상태와 액션을 값 타입으로 모델링
- 변경을 합성 가능한 리듀서 함수로 표현
- 합성 가능한 store 타입으로 모듈 단위 관찰
- 부수효과를 모델링

그 위에서 이 아키텍처가 **매우 테스트하기 좋고, 준비 작업이 거의 없다**고 주장한다. 이 편은 그걸 리듀서 셋에 대해 실제로 보인다.

## 왜 준비가 필요 없는가

리듀서는 `(inout Value, Action) -> [Effect<Action>]`이다. 순수 함수다.

테스트에 필요한 게 이게 전부다. 초기 상태를 만들고, 액션을 넣고, 상태가 어떻게 바뀌었는지 본다. 목 객체도, 의존성 주입 컨테이너도, 뷰 계층을 띄우는 것도 필요 없다.

앞 섹션들이 이 조건을 만들어 놨다. 상태가 값 타입이니 비교할 수 있고, 변경이 리듀서 한 곳에 모여 있으니 어디를 검증할지 명확하다.

## 소수 모달 · 즐겨찾기 · 카운터

세 리듀서를 차례로 테스트한다. 각각 [03 섹션](../03-modularity/00-overview.md)에서 독립 모듈로 분리해 둔 것들이라, 모듈 안에서 앱을 몰라도 테스트가 된다. Ep. 75가 모듈화의 목적으로 든 것이 바로 이거였다.

## 통합 테스트

"Unhappy paths and integration tests" 섹션이 눈에 띈다.

작은 리듀서를 각각 테스트하는 것과, 그것들을 `combine`과 `pullback`으로 붙였을 때 제대로 도는지 확인하는 건 다른 일이다. [Ep. 83](ep83-testable-state-management-effects.md) 도입부도 이 편을 "리듀서에 대한 통합 테스트"라고 부르며, 작고 재사용 가능한 컴포넌트들이 **붙여 놨을 때도 계속 동작하는지**를 확인하는 것이라고 설명한다.

happy path만이 아니라 실패 경로도 다룬다.

## 남는 것

리듀서 자체는 순수해서 쉬웠는데, 리듀서가 반환하는 **효과**는 아직이다. 효과는 바깥세상과 얘기하니 그대로 실행하면 테스트가 아니라 실제 파일을 쓰고 실제 네트워크를 부른다.

→ [Ep. 83](ep83-testable-state-management-effects.md)

## 참고자료

이 편은 References가 셋뿐이다. 새 개념을 도입하지 않고 앞서 만든 것을 검증하는 편이라 그렇다.

- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams, 2017 Functional Swift Conference. 무료
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 실제 테스트 코드와 논증의 세부는 확인하지 못했다
- 이 편에서 `ComposableArchitecture.swift`는 바뀌지 않는다 (130줄, Ep. 81과 동일). 아키텍처를 고치지 않고 테스트만 쓰는 편이라는 뜻이다
