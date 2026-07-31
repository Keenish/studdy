# Ep. 243 — Tour of the Composable Architecture 1.0: The Basics

- 출처: [Point-Free Episode #243](https://www.pointfree.co/episodes/ep243-tour-of-the-composable-architecture-1-0-the-basics)
- 코드: [0243-tca-tour-pt1](https://github.com/pointfreeco/episode-code-samples/tree/main/0243-tca-tour-pt1) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다.** 이 섹션에서 243만 그렇다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 3:00 | Soft landing into TCA |
| 20:26 | Effects |
| 30:11 | Testing |
| 56:16 | Next time: Scrumdinger |

---

## 이 편이 하려는 것

TCA 1.0의 입문 편이다. 앞선 열한 개 섹션이 **왜 그렇게 만들었는지**를 다뤘다면, 여기서는 **완성된 것을 어떻게 쓰는지**를 처음부터 보인다.

소재는 익숙한 카운터다. 증감으로 시작해 네트워크 요청(숫자 사실 API)과 매초 도는 타이머를 붙인다. [01 섹션](../01-swiftui-and-state-management/00-overview.md)의 예제와 닮았는데, 그때는 문제를 드러내려고 만들었고 여기서는 도구가 어떻게 다루는지 보이려고 만든다.

시간 배분이 특징적이다. 57분 중 **26분이 테스트**다.

## 등장하는 API

| 분류 | API |
|---|---|
| 코어 | `Reducer` 프로토콜(`State`·`Action`), `Store`·`StoreOf`, `WithViewStore`, `Effect` |
| 의존성 | `@Dependency`, `DependencyKey`, `DependencyValues` 확장 |
| 테스트 | `TestStore`, `Clock`(continuous·immediate·test) |
| 효과 제어 | `CancelID`로 취소 |

[10 섹션](../10-reducer-protocol/00-overview.md)에서 만든 것들이 그대로 쓰인다. `@Dependency`, `DependencyKey`, `DependencyValues`가 전부 거기서 나온 이름이다.

## 짚고 넘어가는 것들

**값 타입의 배당금** — 값 타입은 의미론이 잘 정의돼 있어서 `_printChanges()` 같은 도구가 상태 변화의 diff를 보여줄 수 있다. [Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md)에서 상태를 구조체로 만든 결정이 여기서 디버깅 도구로 돌아온다.

**액션 이름 짓기** — 액션은 **사용자가 UI에서 한 일**을 반영해야지 비즈니스 로직의 결과여서는 안 된다. `decrementButtonTapped`이 예다. 그래야 기능이 바뀌어도 설명이 안정적으로 유지된다.

이건 [Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md) 코드에서 이미 확인된 관례다. 당시 액션 케이스가 `decrTapped`, `saveFavoritePrimeTapped`처럼 붙어 있었는데, 그게 우연이 아니라 원칙이었음이 여기서 명시된다.

**전수 검증** — 값 타입 기반이라 상태 전체를 빠짐없이 단언할 수 있다. 참조 타입으로는 불가능하고, 예상 못 한 상태 변화가 자동으로 잡힌다. [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 바닐라 SwiftUI로는 안 된다고 논증한 바로 그 지점이다.

**의존성 통제** — 네트워크와 타이머는 테스트 가능한 인터페이스 뒤로 추상화해야 하고, **실제 구현이 테스트에서 의도치 않게 도는 일이 없어야** 한다. [Ep. 207](../10-reducer-protocol/ep207-reducer-protocol-testing.md)의 unimplemented 의존성이 그 장치다.

**클럭** — 테스트 클럭을 쓰면 실제로 기다리지 않는다. 테스트가 60배 이상 빨라지면서 결정적이고 검증 가능한 상태를 유지한다.

[Ep. 197](../09-async-composable-architecture/ep197-async-composable-architecture-schedulers.md)이 Combine `Scheduler`를 감싸는 과도기 선택을 했던 그 문제가, 여기서는 `Clock`으로 정리돼 있다. 그 편의 예고가 실현된 모습이다.

## 다음 편

Apple의 Scrumdinger 샘플을 TCA로 다시 만든다. → [Ep. 244](ep244-tour-introducing-standups.md)

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
