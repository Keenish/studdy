# Ep. 260 — Observable Architecture: Structural Identity

- 출처: [Point-Free Episode #260](https://www.pointfree.co/episodes/ep260-observable-architecture-structural-identity)
- 코드: [0260-observable-architecture-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0260-observable-architecture-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-12-04
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:04 | Observing structs naively |
| 19:05 | Observing structs with identity |
| 41:36 | Next time: Observing optionality |

---

## 이 편이 하려는 것

[Ep. 259](ep259-observable-architecture-sneak-peek.md)가 결과를 보였으니 이제 구현이다.

도입부가 이 섹션의 성격을 밝힌다. 사용법 시연이 아니라 **Apple의 Observation을 라이브러리에 통합하는 고급 기법**을 다룬다는 것이다. 그리고 이 시리즈에 대해 한 마디를 덧붙인다 — 라이브러리 설계에 들어간 거의 모든 결정이 이 영상 시리즈에 문서화돼 있다는 것이다.

## 근본적 불일치

에피소드 설명이 문제를 정확히 짚는다.

- 이 아키텍처는 상태를 **값 타입**으로 모델링한다
- `@Observable` 매크로는 **값 타입을 지원하지 않는다**

[Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md)에서 상태를 구조체로 만든 결정이 이 아키텍처의 근간이다. 전수 테스트도, `_printChanges()` 같은 도구도, 스냅샷 비교도 전부 값 타입이라 가능했다. 그걸 포기할 수는 없다.

## 접근 방식

먼저 **순진하게** 통합해 보고, 거기서 Apple의 도구와 어떻게 갈라져야 하는지 찾는다. 섹션 구성이 그대로다.

- 1:04 — 순진하게 구조체 관찰하기
- 19:05 — 정체성(identity)을 부여해 관찰하기

문제를 먼저 드러내고 해법을 요구하는 이 시리즈의 방식이 여기서도 반복된다.

## 정체성이 열쇠

제목의 "Structural Identity"가 핵심 개념이다. [Ep. 261](ep261-observable-architecture-observing-optionals.md) 도입부가 이를 설명한다.

값 타입은 참조 타입과 달리 동일성을 판단할 기준이 없다. 그래서 상태가 **통째로 교체된 것**인지 **제자리에서 변경된 것**인지를 구별할 장치가 필요하다. 그 구별이 있어야 뷰가 관련 있는 상태만 관찰할 수 있다.

SwiftUI 자체가 뷰에 대해 쓰는 구조적 정체성 개념을 상태에 적용하는 셈이다.

## 확인 범위

- 영상이 유료라 실제 구현과 정체성 부여 방식은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명, 그리고 다음 편 도입부의 설명에서 읽어낸 것이다
