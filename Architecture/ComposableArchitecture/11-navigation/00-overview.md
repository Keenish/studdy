# 11 · Navigation — 열여섯 편 흐름

Point-Free [Navigation](https://www.pointfree.co/collections/composable-architecture/navigation) 섹션(Ep. 222~237)을 한 흐름으로 읽기 위한 문서. **이 컬렉션에서 가장 큰 섹션이다** — 16편, 약 13시간으로 01~08 섹션을 합친 규모다.

- 정리일: 2026-07-30
- 근거: **열여섯 편 모두 유료 회원 전용이다.** 섹션 제목·타임스탬프·도입부·에피소드 설명만 확인했다. 코드로 대조하지 못했다

## 두 아크

제목이 갈리는 지점이 그대로 경계다.

**전반 · Composable Navigation (222~230)** — 트리 기반. 기능이 기능을 품는 구조

- [ep222 — Tabs](ep222-composable-navigation-tabs.md) · 시작, delegate 패턴
- [ep223 — Alerts & Dialogs](ep223-composable-navigation-alerts-dialogs.md) · 가장 단순한 형태부터
- [ep224 — Sheets](ep224-composable-navigation-sheets.md) · 안에 온전한 기능이 들어간다
- [ep225 — Effect Cancellation](ep225-composable-navigation-effect-cancellation.md) · 닫힐 때 효과 정리, 비전수 테스트
- [ep226 — Unification](ep226-composable-navigation-unification.md) · 셋을 하나로, 팝오버·커버가 거의 공짜로
- [ep227 — Links](ep227-composable-navigation-links.md) · 드릴다운 (iOS 16 미만)
- [ep228 — Destinations](ep228-composable-navigation-destinations.md) · 드릴다운 (iOS 16+)
- [ep229 — Correctness](ep229-composable-navigation-correctness.md) · 옵셔널 여럿을 enum 하나로
- [ep230 — Stack vs Heap](ep230-composable-navigation-stack-vs-heap.md) · 성능을 도구에 심기

**후반 · Composable Stacks (231~237)** — 스택 기반. 평평한 배열로 화면을 쌓는 구조

- [ep231 — vs Trees](ep231-composable-stacks-vs-trees.md) · 두 모델의 대조
- [ep232 — Multiple Layers](ep232-composable-stacks-multiple-layers.md) · 여러 겹 드릴다운
- [ep233 — Multiple Destinations](ep233-composable-stacks-multiple-destinations.md) · 종류가 다른 화면 섞기
- [ep234 — Action Ergonomics](ep234-composable-stacks-action-ergonomics.md) · `NavigationStackStore`
- [ep235 — State Ergonomics](ep235-composable-stacks-state-ergonomics.md) · `StackState`
- [ep236 — Effect Cancellation](ep236-composable-stacks-effect-cancellation.md) · 스택판 효과 정리
- [ep237 — Testing](ep237-composable-stacks-testing.md) · 테스트로 도구를 검증

---

## 왜 이제서야 다루는가

[Ep. 222](ep222-composable-navigation-tabs.md) 도입부가 이 주제를 Point-Free가 **가장 오래 기다려온 것**이라고 부르면서, 선행 작업 두 가지가 필요했다고 밝힌다.

- **라이브러리 현대화** — async/await([09](../09-async-composable-architecture/00-overview.md)), 리듀서 프로토콜과 result builder([10](../10-reducer-protocol/00-overview.md)), 별도 라이브러리로 분리된 의존성 관리
- **SwiftUI 내비게이션 자체의 정리** — iOS 16의 `navigationDestination`, `NavigationStack`을 다룬 별도 시리즈

두 번째에서 나온 표현이 이 섹션의 열쇠다. SwiftUI 내비게이션의 **"대통일 이론"** — 알럿, 시트, 드릴다운이 전부 비슷한 API 모양을 공유한다는 관찰이다. 그래서 형태별로 하나씩 만들다가 [Ep. 226](ep226-composable-navigation-unification.md)에서 통합할 수 있었다.

## 실제 주제는 내비게이션이 아니다

제목만 보면 화면 전환 이야기 같은데 시간 배분이 다른 말을 한다. [Ep. 222](ep222-composable-navigation-tabs.md)는 제목이 탭이지만 기능 합성, 테스트, delegate 패턴에 대부분을 쓴다.

에피소드 설명들이 반복하는 단어가 **기능 간 통신**이다. [Ep. 228](ep228-composable-navigation-destinations.md)의 표현으로는 부모와 자식 도메인이 서로 소통할 아주 단순한 방법을 얻는 것이다.

내비게이션은 그 통신이 가장 첨예해지는 자리라서 소재가 됐다고 읽는 편이 맞다.

## 전반 아크가 쌓이는 순서

단순한 형태에서 복잡한 형태로 간다.

**알럿** ([223](ep223-composable-navigation-alerts-dialogs.md)) — 가장 단순하다. 뜨고, 닫히고, 선택적으로 액션을 낸다. 자기 내부 로직이 없다. `Reducer.alert` 연산자가 dismiss 액션과 상태 비우기를 감춘다.

**시트** ([224](ep224-composable-navigation-sheets.md)) — 결정적으로 다르다. 안에 온전한 기능이 들어가므로 부모와 자식이 진짜로 통신해야 한다.

**동작 얹기** ([225](ep225-composable-navigation-effect-cancellation.md)) — 시트가 닫힐 때 그 안에서 시작된 효과가 허공으로 사라지는 문제, 자식이 스스로 닫는 방법, 그리고 비전수 테스트.

**통합** ([226](ep226-composable-navigation-unification.md)) — 알럿·다이얼로그·시트가 사실상 같은 구조라 하나로 묶는다. 그러자 팝오버가 6분, 커버가 2분에 붙는다. 추상을 제대로 잡으면 그 위에서 얻는 게 늘어난다는 이 시리즈의 반복 논증이다.

**드릴다운** ([227](ep227-composable-navigation-links.md)·[228](ep228-composable-navigation-destinations.md)) — iOS 16 미만과 이상을 나눠 다룬다.

**정확성** ([229](ep229-composable-navigation-correctness.md)) — 여섯 형태를 다 지원하니 이번엔 여러 화면으로 동시에 이동한 상태가 표현 가능해진다. 옵셔널 넷이면 16가지 상태 중 유효한 건 5가지뿐이다. enum 하나로 바꾼다.

**효율** ([230](ep230-composable-navigation-stack-vs-heap.md)) — 기능이 중첩되며 루트 상태가 부푸는 우려를 다룬다. 컬렉션과 대부분의 문자열이 힙에 있다는 게 답의 절반이고, 나머지는 프로퍼티 래퍼로 도구에 효율을 심는다.

## 후반 아크 — 왜 스택이 따로 필요한가

[Ep. 231](ep231-composable-stacks-vs-trees.md)의 대조가 핵심이다.

| | 트리 기반 | 스택 기반 |
|---|---|---|
| 모델 | 기능이 기능을 품는다 | 평평한 배열 |
| 상태 | 중첩 구조 | 컬렉션 |
| 맞는 곳 | 모달·알럿, 깊이가 정해진 경우 | 깊이가 정해지지 않은 드릴다운 |
| 프로그래밍 조작 | 어렵다 | 자연스럽다 (딥링크, 루트로 돌아가기) |

둘 다 필요하고, 그래서 섹션이 두 아크로 나뉜다.

후반부의 진행이 인상적이다. 처음엔 기존 도구를 스택에 맞춰 쓰다가([232](ep232-composable-stacks-multiple-layers.md)·[233](ep233-composable-stacks-multiple-destinations.md)), 부족함을 인정하고 전용 도구를 만든다([234](ep234-composable-stacks-action-ergonomics.md)·[235](ep235-composable-stacks-state-ergonomics.md)). 그리고 트리 쪽에서 했던 효과 취소를 반복한 뒤([236](ep236-composable-stacks-effect-cancellation.md)) 테스트로 마무리한다([237](ep237-composable-stacks-testing.md)).

## 같은 순서의 네 번째 반복

액션과 상태를 짝지어 처리하는 습관이 여기서도 나온다. [Ep. 234](ep234-composable-stacks-action-ergonomics.md)가 액션, [Ep. 235](ep235-composable-stacks-state-ergonomics.md)가 상태다.

| 대상 | 상태 | 액션 |
|---|---|---|
| 리듀서 | [Ep. 69](../02-reducers-and-stores/ep69-composable-state-management-state-pullbacks.md) | [Ep. 70](../02-reducers-and-stores/ep70-composable-state-management-action-pullbacks.md) |
| Store | [Ep. 73](../03-modularity/ep73-modular-state-management-view-state.md) | [Ep. 74](../03-modularity/ep74-modular-state-management-view-actions.md) |
| ViewStore | [Ep. 95](../07-adaptation/ep95-adaptive-state-management-state.md) | [Ep. 96](../07-adaptation/ep96-adaptive-state-management-actions.md) |
| 스택 | Ep. 235 | Ep. 234 |

[Ep. 96](../07-adaptation/ep96-adaptive-state-management-actions.md) 도입부가 밝힌 원칙 그대로다 — 짝을 이루는 개념 중 한쪽에서 쓸모를 찾으면 즉시 다른 쪽도 본다.

## 두 아크의 대칭

전반과 후반이 같은 순서를 밟는다는 것도 이 섹션을 읽는 데 도움이 된다.

| | 트리 | 스택 |
|---|---|---|
| 기본 구현 | 223~224 | 231~233 |
| 전용 도구 | 226 통합 | 234·235 |
| 효과 취소·자식 닫기 | 225 | 236 |
| 정확성 (enum) | 229 | 233 |
| 테스트 | 225 비전수 | 237 |

## 이전 섹션들이 여기서 값을 한다

- [10 섹션](../10-reducer-protocol/00-overview.md)의 `@Dependency`·`previewValue` — [Ep. 233](ep233-composable-stacks-multiple-destinations.md) 도입부가 모듈 분리 시 프리뷰가 막히는 실무 문제를 짚으며 이게 왜 필요했는지 재확인한다
- [09 섹션](../09-async-composable-architecture/00-overview.md)의 `.task` — [Ep. 225](ep225-composable-navigation-effect-cancellation.md)가 그것으로 커버되지 않는 빈틈(버튼 탭으로 시작된 효과)을 메운다
- [02 섹션](../02-reducers-and-stores/00-overview.md)의 enum 액션 모델링 — [Ep. 229](ep229-composable-navigation-correctness.md)에서 같은 발상이 상태 쪽에 적용된다

## 읽는 순서

16편이라 통째로 보기 부담스럽다. 목적에 따라 갈라 읽는 게 낫다.

**개념만 잡고 싶다면** — [Ep. 231](ep231-composable-stacks-vs-trees.md)의 트리 vs 스택 대조와 [Ep. 229](ep229-composable-navigation-correctness.md)의 enum 논증. 이 둘이 섹션 전체의 사고방식을 담는다.

**트리 쪽을 쓸 거라면** — 222 → 223 → 224 → 225 → 226 → 229. 227·228은 드릴다운이 필요할 때, 230은 성능이 걱정될 때.

**스택 쪽을 쓸 거라면** — 231 → 234 → 235 → 236 → 237. 232·233은 중간 과정이라 결과 도구를 먼저 봐도 된다.

## 확인 범위

확인한 것

- 열여섯 편의 섹션 제목과 타임스탬프, 도입부, 에피소드 설명

확인하지 못한 것

- 모든 실제 API와 구현. `Reducer.alert`, 통합된 표시 도구, `NavigationStackStore`, `StackState`, `StackAction`이 전부 여기 해당한다
- 코드 대조를 하지 못했다. 이 시기 샘플은 라이브러리 저장소 자체를 담고 있어 편별 diff로 추적하기 어렵다

**이 섹션은 이 컬렉션에서 근거가 가장 얇다.** 무료 편이 하나도 없어서다. 각 문서의 서술은 섹션 제목의 흐름, 도입부에 드러난 문제의식, 시간 배분, 그리고 앞뒤 편의 회고에서 읽어낸 것이다. 실제 API를 쓸 때는 [TCA 공식 문서](https://pointfreeco.github.io/swift-composable-architecture/)로 확인해야 한다.
