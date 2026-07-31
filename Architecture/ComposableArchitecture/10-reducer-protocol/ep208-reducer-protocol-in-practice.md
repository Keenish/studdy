# Ep. 208 — Reducer Protocol in Practice

- 출처: [Point-Free Episode #208](https://www.pointfree.co/episodes/ep208-reducer-protocol-in-practice)
- 코드: [0208-reducer-protocol-in-practice](https://github.com/pointfreeco/episode-code-samples/tree/main/0208-reducer-protocol-in-practice) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다**

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:00 | Recursive case study |
| 11:22 | Preview dependencies |
| 17:19 | ifCaseLet |
| 20:03 | isowords |
| 44:42 | Conclusion |

---

## 이 편이 하려는 것

일곱 편에 걸친 작업의 결산이다. [Ep. 200](../09-async-composable-architecture/ep200-async-composable-architecture-in-practice.md)과 같은 방식으로, 예제와 실제 출시작 isowords를 옮기며 전후를 비교한다.

## 재귀 리듀서 (1:00)

상태가 자기 자신을 품는 기능이다. 전에는 `recurse`라는 헬퍼 함수를 만들고 **암묵적 언래핑 옵셔널**로 재귀 고리를 묶어야 했다.

프로토콜 체계에서는 그럴 필요가 없다. `body`가 지연 평가되므로 `Self()`를 그 안에서 그냥 참조하면 된다. `View`의 `body`가 재귀적 구조를 자연스럽게 표현하는 것과 같다.

억지스러운 우회가 사라진 사례라 첫 예제로 고른 것으로 보인다.

## 성능 (스택 프레임)

[Ep. 201](ep201-reducer-protocol-the-problem.md)이 지적한 다섯째 문제의 답이다. 스택 추적을 비교한 수치가 나온다.

| 버전 | 앱 스택 프레임 |
|---|---|
| 0.39 | 269 |
| 이전 (프로토콜 직전) | 113 |
| 프로토콜 (인라인 후) | **31** |

0.39 대비 거의 10분의 1이다. 이스케이핑 클로저가 인라인되지 않던 것이 프로토콜 준수로 바뀌면서 최적화가 걸린 결과다.

## 프리뷰 의존성 (11:22)

`previewValue` 등록이 새로 생긴다. Xcode 프리뷰에서 실제 API 대신 스텁 데이터로 기능을 돌릴 수 있다.

음성 인식 데모가 예시인데, Speech 프레임워크 자리에 로렘 입숨을 내보내는 에뮬레이터를 꽂는다. [Ep. 206](ep206-reducer-protocol-dependencies-part-2.md)이 되찾겠다고 한 프리뷰 능력이 이런 모습이다.

의존성 등록이 세 갈래가 되는 셈이다 — 실제(`liveValue`), 테스트(`testValue`), 프리뷰(`previewValue`).

## ifCaseLet (17:19)

enum 상태를 다루는 합성 연산자다.

기존에 `ifLet`이 옵셔널 상태를, `forEach`가 컬렉션을 다뤘다면 `ifCaseLet`은 enum의 특정 케이스를 다룬다. 상태가 여러 모드 중 하나인 기능(로딩/성공/실패 같은)을 표현할 때 쓴다.

[02 섹션](../02-reducers-and-stores/00-overview.md)에서 Swift에 enum key path가 없어 enum property를 손으로 만들던 문제가 있었는데, 그 계열의 도구가 연산자로 정리된 것이다.

## isowords (20:03)

실제 출시작을 옮긴다. 이 편에서 가장 긴 구간(24분)이다.

## 결론 (44:42)

이 섹션이 이미 널리 쓰이는 라이브러리를 고치는 작업이라, 결론이 마이그레이션 이야기로 채워진다.

- **100% 하위 호환**이다
- 점진적으로 도입할 수 있다
- 업그레이드 가이드를 제공한다
- Swift 5.6에서도 우아하게 낮춰 동작한다
- 기존 앱이 당장 옮겨야 할 압박은 없다

[Ep. 200](../09-async-composable-architecture/ep200-async-composable-architecture-in-practice.md)의 결론이 "얼마나 좋아졌나"였다면 여기는 "얼마나 안전하게 옮길 수 있나"에 무게가 실린다. 라이브러리가 성숙했다는 신호이기도 하다.

## 이 편에서 정리된 API

- `ReducerProtocol` — 클로저 기반 리듀서를 대체
- `Reduce` — 로직 하나짜리 리듀서를 만드는 빌더
- `@Dependency` — 의존성 선언
- `DependencyKey` / `TestDependencyKey` — 등록용 프로토콜
- `DependencyValues` 확장 — 전역 등록 패턴
- `.ifLet()` / `.forEach()` / `.ifCaseLet()` — 합성 연산자

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
