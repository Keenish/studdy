# 14 · Sharing and Persisting State — 아홉 편 흐름

Point-Free [Sharing and Persisting State](https://www.pointfree.co/collections/composable-architecture/sharing-and-persisting-state) 섹션(Ep. 268~276)을 한 흐름으로 읽기 위한 문서. 이 컬렉션의 마지막 섹션이다.

- 정리일: 2026-07-30
- 근거: **아홉 편 모두 유료 회원 전용이다.** 섹션 제목·타임스탬프·도입부·에피소드 설명만 확인했다

관련 문서

- [ep268 — The Problem](ep268-shared-state-the-problem.md) · 기존 두 방법의 한계
- [ep269 — The Solution 1](ep269-shared-state-the-solution-part-1.md) · 참조 타입을 그냥 넣어 본다
- [ep270 — The Solution 2](ep270-shared-state-the-solution-part-2.md) · `@Shared`로 흐름 완성
- [ep271 — Testing 1](ep271-shared-state-testing-part-1.md) · 참조 타입은 복사가 안 된다
- [ep272 — Testing 2](ep272-shared-state-testing-part-2.md) · 값 타입처럼 전수 테스트하기
- [ep273 — User Defaults 1](ep273-shared-state-user-defaults-part-1.md) · 편재하는 상태와 영속화
- [ep274 — User Defaults 2](ep274-shared-state-user-defaults-part-2.md) · 외부 변경 감지
- [ep275 — File Storage 1](ep275-shared-state-file-storage-part-1.md) · 엣지 케이스 넷
- [ep276 — File Storage 2](ep276-shared-state-file-storage-part-2.md) · 테스트와 파생 상태

---

## 이 섹션이 하는 일

섹션 설명이 문제의 성격을 밝힌다. 공유 상태는 이 아키텍처에서 다루기 어려운 문제인데, **도메인을 참조 타입이 아니라 값 타입으로 모델링하는 것을 선호**하기 때문이다.

해법도 그 문장에 담겨 있다. 참조 타입을 **통제된 방식으로** 도입하되 이점은 지키고 단점은 최소화한다. 거기에 가벼운 영속화까지 얹는다.

[Ep. 268](ep268-shared-state-the-problem.md) 도입부가 이 주제의 위상을 말한다. **"여러 기능이 상태를 어떻게 공유하나"가 TCA 사용자에게서 가장 흔한 질문 중 하나**라는 것이다.

## 역설처럼 보이는 지점

이 아키텍처는 단일 진실 공급원을 갖는데, 정작 앱은 독립적인 기능들로 쪼개지고 각 기능은 자기 몫의 조각만 본다.

그 격리는 의도된 것이다. [03 섹션](../03-modularity/00-overview.md)이 모듈 경계를 만든 이유가 그것이었다. 그런데 여러 기능이 같은 상태를 필요로 하는 순간 마찰이 생긴다.

## 기존 두 방법의 한계 (Ep. 268)

| 방법 | 대가 |
|---|---|
| 값 타입으로 공유 | 각 기능이 사본을 갖고 부모가 동기화. 배선 코드를 손으로 |
| 의존성으로 공유 | 보일러플레이트가 늘고, 상태가 아니라서 전수 테스트 대상 밖 |

## 이 섹션이 근본 원칙을 건드린다

[Ep. 269](ep269-shared-state-the-solution-part-1.md) 도입부의 질문이 파격이다. **처음부터 참조 타입을 기능 상태에 그냥 집어넣었으면 어땠을까?**

값 타입은 [Ep. 68](../02-reducers-and-stores/ep68-composable-state-management-reducers.md)에서 `AppState`를 구조체로 만든 이래 한 번도 흔들린 적 없는 원칙이었다.

- 전수 테스트가 가능한 이유
- 스냅샷 비교와 `_printChanges()`의 근거
- [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 바닐라 SwiftUI로 안 된다고 논증한 이유

그 원칙에 정면으로 부딪히는 시도다.

가능해진 이유가 하나 있다. [Ep. 273](ep273-shared-state-user-defaults-part-1.md) 도입부가 밝히듯, 참조 타입은 예전에 **뷰 무효화와 잘 어울리지 않았는데** Swift의 관찰 도구가 그 문제를 풀었다. [13 섹션](../13-observable-architecture/00-overview.md)이 이 섹션의 전제 조건인 셈이다.

## 아홉 편의 구성

세 덩어리로 나뉜다.

**268~270 · 해법 만들기** — 참조를 넣어 보고, 사용성을 다듬어 `@Shared` 프로퍼티 래퍼를 얻고, 회원가입 흐름으로 검증한다. 여러 화면이 한 데이터를 조금씩 채워 나가는 흐름이라 공유 상태의 대표 사례다.

**271~272 · 테스트 복구** — `@Shared`가 공유는 잘 푸는데 테스트를 깨뜨린다. [Ep. 271](ep271-shared-state-testing-part-1.md) 도입부의 진단이 명료하다. 참조 타입은 **데이터와 동작이 뒤섞인 덩어리**라 테스트하기 악명 높고, **복사할 수 없어서** 상태 변경 단언이 복잡해진다.

전후 스냅샷 비교가 전수 검증의 기반이었는데 사본을 뜰 수 없으니 "이전 상태"가 존재하지 않는다. 두 편을 들여 복구하고, [Ep. 272](ep272-shared-state-testing-part-2.md)에서 참조 타입 기능을 **값 타입인 것처럼 빠짐없이** 테스트하는 데 이른다.

**273~276 · 영속화** — 전략 세 가지가 쌓인다.

| 전략 | 용도 | 편 |
|---|---|---|
| in-memory | 영속화 없이 공유만 | 269~272 |
| user defaults | 불리언·정수·문자열 | 273~274 |
| file storage | `Codable` + JSON, 복잡한 데이터 | 275~276 |

## 편재하는 상태라는 전환 (Ep. 273)

이 섹션의 개념적 분기점이다.

`@Shared`는 처음에 부모가 자식에게 **넘겨주는** 상태였다. 그런데 설정값 같은 것은 앱 전체가 즉시 접근해야 하고, 모든 경로로 손수 전달하는 건 말이 안 된다.

[10 섹션](../10-reducer-protocol/00-overview.md)의 `@Dependency`가 의존성에 대해 한 일과 같은 성격이다. 중간 계층이 몰라도 흐르게 하는 것. 다만 대상이 의존성이 아니라 **상태**라서 변경도 되고 관찰도 되고 테스트에서 검증도 돼야 한다.

## 엣지 케이스를 대신 감당한다 (Ep. 275)

이 섹션에서 실무적으로 가장 값진 부분이다. 파일 저장의 섹션 제목이 그대로 문제 목록이다.

- **디바운싱** — 상태가 바뀔 때마다 쓰면 디스크 I/O가 폭주한다
- **willResignActive에 저장** — 디바운싱하면 안 쓴 변경이 남는다. 백그라운드 전환 시 비워야 데이터를 안 잃는다
- **외부 쓰기 관찰** — 다른 프로세스나 확장이 파일을 고칠 수 있다
- **피드백 루프 수정** — 위 둘을 합치면 내가 쓴 것이 나에게 돌아와 순환한다

기능을 붙이면 그것이 다음 문제를 만들고, 그걸 또 해결하는 순서다. 쓰는 쪽은 `.fileStorage` 전략을 고르기만 하면 이 전부가 따라온다.

## 파생 상태 — 세 번째 반복 (Ep. 276)

큰 것에서 작은 것을 떼어 내되 연결은 유지한다는 발상이 또 나온다.

| 대상 | 도구 |
|---|---|
| 리듀서 | `pullback` ([Ep. 69](../02-reducers-and-stores/ep69-composable-state-management-state-pullbacks.md)) |
| store | `view` / `scope` ([Ep. 73](../03-modularity/ep73-modular-state-management-view-state.md)) |
| 공유 상태 | 파생 (Ep. 276) |

## 이 섹션이 지키는 기준

[05 섹션](../05-testing/00-overview.md) 이래 일관된 기준이 여기서도 작동한다. [Ep. 196](../09-async-composable-architecture/ep196-async-composable-architecture-tasks.md) 도입부의 표현으로는 **테스트 가능성을 해치는 기능은 절대 넣지 않으려 한다**는 것이다.

그래서 `@Shared`를 만든 뒤 곧바로 두 편을 테스트 복구에 쓴다. [Ep. 268](ep268-shared-state-the-problem.md)의 예고에서 "완전히 테스트 가능할 것"을 먼저 약속한 것도 같은 맥락이다.

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 268](ep268-shared-state-the-problem.md) — 문제 정의. 왜 기존 방법으로 부족한지
3. [Ep. 269](ep269-shared-state-the-solution-part-1.md)~[270](ep270-shared-state-the-solution-part-2.md) — `@Shared`
4. 필요에 따라 — 테스트가 궁금하면 271·272, 영속화가 필요하면 273~276

**실무에서 쓸 거라면** 275의 엣지 케이스 목록을 먼저 보는 것도 방법이다. 직접 영속화를 짤 때 무엇을 놓치기 쉬운지가 그대로 나와 있다.

## 확인 범위

확인한 것

- 아홉 편의 섹션 제목과 타임스탬프, 도입부, 에피소드 설명

확인하지 못한 것

- 모든 실제 API와 구현. `@Shared`의 정의, `PersistenceKey` 프로토콜, 영속화 전략들, 파생 상태 API가 전부 여기 해당한다

**[11 섹션](../11-navigation/00-overview.md)과 함께 근거가 얇은 편이다.** 무료 편이 하나도 없다. 실제 API를 쓸 때는 [TCA 공식 문서](https://pointfreeco.github.io/swift-composable-architecture/)로 확인해야 한다.

이 섹션 이후로도 시리즈는 이어진다. Ep. 277부터 이 도구들을 SyncUps 앱에 적용하는 편들이 나오는데, 이 컬렉션의 섹션 목록에는 포함돼 있지 않다.
