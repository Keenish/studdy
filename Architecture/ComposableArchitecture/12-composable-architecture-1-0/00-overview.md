# 12 · A tour of the Composable Architecture 1.0 — 일곱 편 흐름

Point-Free [A tour of the Composable Architecture 1.0](https://www.pointfree.co/collections/composable-architecture/composable-architecture-1-0) 섹션(Ep. 243~249)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 244~249는 영상이 유료라 섹션 제목·도입부만 확인했다. **243은 무료라 트랜스크립트 전문을 근거로 정리했다**

관련 문서

- [ep243 — The Basics](ep243-tour-the-basics.md) · 카운터로 코어 API를 훑는다 (무료)
- [ep244 — Introducing Standups](ep244-tour-introducing-standups.md) · Scrumdinger를 TCA로 다시 만든다
- [ep245 — Navigation](ep245-tour-navigation.md) · 시트로 폼 붙이기 (트리 기반)
- [ep246 — Stacks](ep246-tour-stacks.md) · 상세로 드릴다운, 딥링크 (스택 기반)
- [ep247 — Domain Modeling](ep247-tour-domain-modeling.md) · 옵셔널 여럿을 enum으로
- [ep248 — Dependencies](ep248-tour-dependencies.md) · 음성 인식, 가장 복잡한 의존성
- [ep249 — Persistence](ep249-tour-persistence.md) · 영속화로 마무리

---

## 이 섹션의 성격

앞의 열한 개 섹션과 방향이 반대다.

- **01~11** — 왜 이렇게 만들었는가. 문제를 드러내고 하나씩 해결한다
- **12** — 완성된 것을 어떻게 쓰는가. 처음부터 앱 하나를 만든다

섹션 설명이 이를 밝힌다. 여러 달에 걸쳐 원칙부터 개념을 발전시킨 끝에 오픈소스로 공개했고, 이 컬렉션은 작은 앱을 **이해 가능한 단위로 쪼개고 촘촘한 테스트를 붙이는** 과정을 안내한다.

그러니 TCA를 처음 배운다면 **여기부터 시작해도 된다.** 01~11은 설계 근거를 알고 싶을 때 돌아가면 된다.

## Scrumdinger를 고른 이유

[Ep. 244](ep244-tour-introducing-standups.md)부터 Apple의 Scrumdinger를 TCA로 다시 만든다. TCA 버전은 **Standups**라고 부른다.

비교 대상으로 이보다 나은 선택이 드물다.

- Apple이 직접 만든 공식 SwiftUI 튜토리얼이라 "SwiftUI다운 방식"의 기준점이 된다
- 이미 존재하는 앱이라 요구사항을 새로 만들 필요가 없다
- 목록·폼·상세·녹음·영속화까지 실제 앱의 요소를 고루 담는다
- 음성 인식처럼 **정말 어려운 것**이 들어 있다

[Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 바닐라 SwiftUI로 짠 예제와 대조했던 방식의 확장판이고, 이번 상대는 Apple의 공식 샘플이다. [Ep. 245](ep245-tour-navigation.md)에 "Scrumdinger 회고" 섹션이 따로 있다.

## 일곱 편이 쌓이는 순서

### Ep. 243 — 코어 훑기 (무료)

카운터에 네트워크 요청과 타이머를 붙이며 코어 API를 한 바퀴 돈다. 57분 중 **26분이 테스트**다.

등장하는 API가 대부분 [10 섹션](../10-reducer-protocol/00-overview.md)에서 나온 것들이다 — `Reducer` 프로토콜, `@Dependency`, `DependencyKey`, `TestStore`.

짚고 넘어가는 원칙 둘이 중요하다.

- **액션 이름은 사용자가 UI에서 한 일**을 반영한다(`decrementButtonTapped`). 비즈니스 로직의 결과가 아니다. 그래야 기능이 바뀌어도 설명이 안정적이다
- **테스트 클럭**으로 실제 대기를 없앤다. 60배 이상 빨라지면서 결정적이다. [Ep. 197](../09-async-composable-architecture/ep197-async-composable-architecture-schedulers.md)이 과도기 절충으로 남겼던 문제가 `Clock`으로 정리돼 있다

### Ep. 244 — 폼부터

Scrumdinger 투어 후 Standups를 시작한다. 첫 기능이 폼인 게 자연스럽다. 다른 화면에 의존하지 않는 말단이라 독립적으로 만들고 테스트할 수 있고, 목록과 상세가 이걸 조립해 쓴다.

### Ep. 245 · 246 — 두 가지 내비게이션

[11 섹션](../11-navigation/00-overview.md)의 두 아크가 실제 앱에 나뉘어 적용된다.

| | Ep. 245 | Ep. 246 |
|---|---|---|
| 방식 | 트리 기반 (시트) | 스택 기반 (드릴다운) |
| 대상 | 추가·편집 폼 | 상세 화면 |
| 얻는 것 | 옵셔널 상태로 표시 제어 | 딥링크, 프로그래밍 방식 조작 |

Ep. 246이 스택을 고른 이유를 밝히는데, 트리 기반은 다른 곳에서 이미 보였기 때문이다.

### Ep. 247 — 숫자로 말하는 도메인 모델링

[Ep. 229](../11-navigation/ep229-composable-navigation-correctness.md)의 논증을 실제 앱에서 반복하는데 수치가 더 세다.

| 목적지 수 | 표현 가능 | 유효 | 무효 비율 |
|---|---|---|---|
| 4개 | 16 | 5 | 약 70% |
| 5개 | 32 | 6 | **90% 초과** |

옵셔널을 하나 더할 때마다 상태 공간은 두 배가 되는데 유효한 건 하나만 는다. enum이 여럿 중 하나를 배타적으로 고르는 상황에 맞는 도구라는 결론이다.

### Ep. 248 · 249 — 통제되지 않은 의존성

두 편이 같은 구조의 문제를 다른 대상으로 다룬다.

**음성 인식** (248) — 권한 조회 `await`가 프리뷰에서 **영영 재개되지 않는다.** 그 뒤 코드가 실행되지 않으니 프리뷰로 기능을 다듬을 수 없다. 원하는 건 의존성에게 "권한은 허가된 것으로 치자"고 말하는 것이고, 그게 [Ep. 208](../10-reducer-protocol/ep208-reducer-protocol-in-practice.md)의 `previewValue`가 있는 이유다.

**영속화** (249) — 테스트가 실제 파일 시스템을 건드리면 테스트끼리 상태를 공유하고, 실행 순서에 결과가 달라지고, 프리뷰가 실제 데이터를 덮어쓴다.

## 이 섹션이 확인해 주는 것

앞선 섹션들의 결정이 실제 앱에서 어떻게 값을 하는지가 한자리에 모인다.

| 앞 섹션의 결정 | 이 섹션에서 |
|---|---|
| [Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md) 상태를 값 타입으로 | 243 — `_printChanges()` diff, 전수 검증 |
| [Ep. 76](../04-side-effects/ep76-effectful-state-management-synchronous-effects.md) 효과를 값으로 반환 | 249 — 리듀서는 단순 함수, 상태는 단순 값으로 유지 |
| [Ep. 207](../10-reducer-protocol/ep207-reducer-protocol-testing.md) 통제되지 않은 의존성 차단 | 248·249 — 프리뷰와 테스트가 막히는 실제 사례 |
| [Ep. 229](../11-navigation/ep229-composable-navigation-correctness.md) enum으로 정확성 | 247 — 같은 논증, 더 큰 수치 |

## 읽는 순서

**TCA를 처음 본다면** — 여기부터 시작한다. 243 원문(무료)을 먼저 보고, 244~249를 순서대로.

**앞 섹션을 이미 읽었다면** — 243은 복습이니 건너뛰어도 된다. 247의 수치와 248의 프리뷰 사례가 새로 얻을 것이다.

**실무에서 막힌 게 있다면** — 문제별로 골라 본다. 내비게이션은 245·246, 상태 모델링은 247, 의존성은 248·249.

## 확인 범위

확인한 것

- 243: 트랜스크립트 전문. API 목록과 원칙 포함
- 244~249: 섹션 제목과 타임스탬프, 도입부, 에피소드 설명

확인하지 못한 것

- 244~249의 실제 구현 코드, Ep. 245의 Scrumdinger 회고 내용, Ep. 249의 Outro

이 섹션은 코드 대조를 하지 않았다. 샘플이 라이브러리를 의존성으로 쓰는 앱 프로젝트라 편별 diff가 앞 섹션들처럼 의미 있게 나오지 않는다. 대신 실제로 만들어 볼 수 있는 완성된 앱이므로, [저장소](https://github.com/pointfreeco/episode-code-samples)를 직접 열어 보는 편이 낫다.
