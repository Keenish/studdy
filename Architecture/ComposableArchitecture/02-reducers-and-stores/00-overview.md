# 02 · Reducers and Stores — 네 편 흐름

Point-Free [Reducers and Stores](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores) 섹션(Ep. 68~71)을 한 흐름으로 읽기 위한 문서.

- 정리일: 2026-07-30
- 근거: 네 편 모두 **영상은 유료 회원 전용**이라 섹션 제목과 도입부만 확인했다. 다만 **코드는 [공개 저장소](https://github.com/pointfreeco/episode-code-samples)(MIT)의 실제 소스로 확인**했다. 그래서 시그니처와 구조는 근거가 있고, 논증의 세부와 화면에서 짠 순서는 확인하지 못했다

관련 문서

- [ep68 — Reducers](ep68-composable-state-management-reducers.md) · 리듀서의 모양을 정하고 store를 만든다
- [ep69 — State Pullbacks](ep69-composable-state-management-state-pullbacks.md) · 리듀서가 상태의 일부만 보게 만든다
- [ep70 — Action Pullbacks](ep70-composable-state-management-action-pullbacks.md) · 액션에도 같은 일을 한다
- [ep71 — Higher-Order Reducers](ep71-composable-state-management-higher-order-reducers.md) · 리듀서를 감싸 기능을 얹는다

---

## 이 섹션이 하는 일

[01 섹션](../01-swiftui-and-state-management/00-overview.md)이 문제를 모았다면 여기서부터 답을 만든다.

Ep. 67이 남긴 네 가지 숙제 중 이 섹션이 가져가는 건 두 개다. 상태 변경의 조직화, 그리고 큰 앱의 분해. 부수효과와 테스트는 뒤 섹션 몫이다.

전체 구성은 단순하다. 먼저 변경을 함수 하나에 모으고(68), 그 함수가 너무 커지니 쪼갰다 다시 붙이는 도구를 만들고(69, 70), 마지막으로 그 도구를 응용해 앱 전체를 가로지르는 기능을 붙인다(71).

## 네 편이 쌓이는 순서

### Ep. 68 — 변경을 한곳에 모으다

리듀서는 상태와 액션을 받아 상태를 바꾸는 함수다. 뷰 곳곳에 흩어져 있던 변경을 여기로 모으면 Ep. 67의 4.2가 풀린다.

함수 모양을 두 후보에서 고른다.

- `(State, Action) -> State` — 새 상태를 반환
- `(inout State, Action) -> Void` — 기존 상태를 직접 변경

후자를 택한다. 큰 자료구조를 복사 없이 바꿀 수 있어서다. 표준 라이브러리 `reduce`에도 두 변형이 있다는 걸 근거로 들고, `inout` 리듀서의 효율에 대한 Chris Eidhof의 논의를 참고했다고 밝힌다.

리듀서를 앱 곳곳에 직접 넘기는 대신 store가 감싸 들고, 쓰는 쪽에는 변경 메서드만 노출한다.

Redux와 Elm이 이 방식을 퍼뜨렸다는 계보를 밝히고 시작한다.

### Ep. 69 — 상태를 좁히다

리듀서 하나에 모으고 나면 그게 앱 전체를 떠안는다. 화면이 스물 몇 개인 앱이면 스위치문이 감당 못 하게 커진다.

그래서 쪼갰다 붙이는 도구를 만든다.

- combine — 리듀서 여러 개를 하나로 묶는다
- pullback — 지역 상태만 아는 작은 리듀서를 전역 상태에서 도는 리듀서로 끌어올린다. 연결은 key path로 한다

이름이 map이 아니라 pullback인 이유는 방향 때문이다. 리듀서는 상태를 소비하는 쪽이라 상태 타입에 대해 반변이고, 값이 흐르는 방향(전역 → 지역)과 리듀서가 승격되는 방향(지역 → 전역)이 반대다. 쓰기까지 해야 하니 `WritableKeyPath`가 필요하다.

### Ep. 70 — 액션도 좁히다

상태는 좁혔는데 액션은 그대로다. 카운터 리듀서가 `counter` 상태만 건드리면서도 즐겨찾기 액션까지 받고 있다. 한쪽만 캡슐화된 상태다.

액션에도 같은 걸 하려는데 여기서 막힌다. Swift에 enum용 key path가 없다. 구조체는 `\.counter`로 가리킬 수 있지만 enum 케이스에는 그런 문법이 없고, 이 비대칭 때문에 보일러플레이트를 손으로 써야 한다.

보완책이 enum property다. 케이스마다 값을 꺼내고 넣는 접근자를 만들어 구조체 비슷한 사용감을 낸다. 이건 Episode #52에서 다룬 내용이고, 그 보일러플레이트를 자동 생성하는 CLI를 Episode #55에서 만들었다고 밝힌다.

여기까지 오면 화면별 리듀서를 그 화면의 상태와 액션만 아는 상태로 짜고, pullback 두 번과 combine으로 앱 리듀서를 조립할 수 있다.

### Ep. 71 — 리듀서를 감싸다

앞의 두 편이 리듀서를 나란히 붙이는 합성이었다면 이 편은 방향이 다르다. 리듀서를 받아 리듀서를 반환하는 함수로 없던 기능을 얹는다.

예제는 두 개, 활동 기록과 로깅이다. 앱 전체를 가로지르는 기능을 화면마다 코드를 심지 않고 붙일 수 있다는 게 요지다.

활동 기록이 예제인 게 우연이 아니다. Ep. 67의 4.2에서 문제 제기의 근거로 쓰인 게 바로 이 기능이었다. 당시엔 삭제가 두 곳에 있어 기록 코드를 중복해 넣어야 했고 한쪽을 빠뜨려 버그가 났다. 고차 리듀서로 감싸면 지나가는 액션을 한자리에서 볼 수 있으니 중복이 사라진다. 문제를 제기한 편과 해결하는 편이 정확히 대응한다.

## 네 편을 한 줄로

변경을 함수 하나로 모으고, 그 함수를 상태와 액션 양쪽으로 쪼갰다 다시 붙일 수 있게 만들면, 화면별로 독립해 짜면서도 앱 하나로 조립할 수 있다.

## 01 섹션의 숙제와 대조

| Ep. 67 | 한계 | 이 섹션에서 |
|---|---|---|
| 4.2 | 상태 변경이 흩어져 있다 | 리듀서 하나로 모음 (68) + 고차 리듀서로 교차 기능 처리 (71) |
| 4.4 | 상태 관리가 합성되지 않는다 | combine과 pullback (69, 70) |
| 4.3 | 부수효과 이야기가 없다 | 아직 — [`04-side-effects`](../04-side-effects/) |
| 4.5 | 테스트할 수 없다 | 아직 — [`05-testing`](../05-testing/) |

4.4는 이 섹션에서 도구가 나오지만 모듈 분리까지 가는 건 [`03-modularity`](../03-modularity/)다.

## 영상 없이 볼 수 있는 것

네 편 다 유료지만, 에피소드 페이지의 References는 열려 있고 거기 걸린 자료 대부분이 무료다. 특히 두 개가 유용하다.

- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams, 2017 Functional Swift Conference. 이 시리즈의 핵심 아이디어를 다룬 강연이다. 네 편의 내용을 압축해서 볼 수 있는 가장 가까운 무료 자료
- [episode-code-samples](https://github.com/pointfreeco/episode-code-samples) — 편별 플레이그라운드. 68 → 69 → 70 → 71 순으로 `Contents.swift`를 비교하면 리듀서와 pullback이 어떻게 변해 가는지 그대로 보인다

배경 개념은 Point-Free의 다른 편들에 흩어져 있다. [#14 Contravariance](https://www.pointfree.co/episodes/ep14-contravariance)가 pullback의 원형이고, [#51 Structs 🤝 Enums](https://www.pointfree.co/episodes/ep51-structs-enums)와 [#52 Enum Properties](https://www.pointfree.co/episodes/ep52-enum-properties)가 Ep. 70이 막히는 이유를 설명한다.

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 68](ep68-composable-state-management-reducers.md) — 리듀서 모양과 store
3. [Ep. 69](ep69-composable-state-management-state-pullbacks.md) → [Ep. 70](ep70-composable-state-management-action-pullbacks.md) — 상태와 액션은 짝이니 붙여서 본다
4. [Ep. 71](ep71-composable-state-management-higher-order-reducers.md)

## 이 정리의 근거와 한계

01 섹션(Ep. 65~67)은 무료 영상이라 트랜스크립트 전체를 근거로 정리했다. 이 섹션은 네 편 모두 영상이 유료 회원 전용이라 사정이 다르다.

확인한 것

- 섹션 제목과 타임스탬프, 도입부, 에피소드 설명
- 코드 전체 — [episode-code-samples](https://github.com/pointfreeco/episode-code-samples) 저장소(MIT)에 편별 플레이그라운드가 공개돼 있다. 각 편의 시그니처·타입·조립 방식은 여기서 확인했다

확인하지 못한 것

- 논증의 세부, 대안을 검토하고 버리는 과정, 화면에서 실제로 짠 순서
- Ep. 71의 "What's the point?" 결산 내용

저장소 코드는 이후 Swift·SwiftUI 변화에 맞춰 갱신됐을 수 있어 2019년 영상 시점과 정확히 같다는 보장은 없다. 실제로 Ep. 68의 `Store`가 저장소에서는 `ObservableObject`/`@Published`인데 당시 영상은 `BindableObject`였을 것이다.
