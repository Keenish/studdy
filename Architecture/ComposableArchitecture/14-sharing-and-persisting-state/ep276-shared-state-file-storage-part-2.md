# Ep. 276 — Shared State: File Storage, Part 2

- 출처: [Point-Free Episode #276](https://www.pointfree.co/episodes/ep276-shared-state-file-storage-part-2)
- 코드: [0276-shared-state-pt9](https://github.com/pointfreeco/episode-code-samples/tree/main/0276-shared-state-pt9) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-04-22
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:04 | Making file storage testable |
| 6:34 | Derived shared state |
| 32:40 | Conclusion |

---

## 이 편이 하려는 것

섹션의 마지막 편이다. 두 가지를 다룬다 — 파일 저장의 테스트 가능성, 그리고 파생된 공유 상태.

## 파일 시스템이 왜 테스트를 어렵게 하나

도입부의 표현이 정확하다. 파일 시스템은 **크고, 전역적이고, 가변인 데이터 덩어리**다.

그러니 테스트 격리가 깨진다. 테스트가 실제 파일을 쓰면 다음 테스트가 그걸 읽고, 실행 순서에 따라 결과가 달라진다. [Ep. 249](../12-composable-architecture-1-0/ep249-tour-persistence.md)가 영속화를 붙일 때 경고한 문제 그대로다.

## fileStorage의 이점

도입부가 `.fileStorage`가 `.appStorage`보다 나은 점을 든다.

- 크고 복잡한 데이터를 다룬다
- **디바운싱이 내장**돼 있다
- **외부 변경 감지**가 내장돼 있다

[Ep. 275](ep275-shared-state-file-storage-part-1.md)에서 하나씩 해결한 엣지 케이스들이 전략 안에 들어가 있다는 뜻이다. 쓰는 쪽은 전략만 고르면 된다.

## 파생된 공유 상태 (6:34)

이 편의 절반 이상(26분)을 쓰는 대목이다.

에피소드 설명이 이를 **더 큰 상태 컬렉션에서 더 작은 공유 상태를 끌어내는 것**이라고 표현한다.

예를 들면 이렇다. 항목 목록 전체가 공유 상태로 있고, 각 항목의 상세 화면은 그중 자기 항목 하나만 공유받는다. 상세 화면이 그 항목을 고치면 목록에도 반영돼야 한다.

이건 이 컬렉션이 계속 해 온 일의 연장이다.

| 대상 | 좁히는 도구 |
|---|---|
| 리듀서 | `pullback` ([Ep. 69](../02-reducers-and-stores/ep69-composable-state-management-state-pullbacks.md)) |
| store | `view` / `scope` ([Ep. 73](../03-modularity/ep73-modular-state-management-view-state.md)) |
| 공유 상태 | 파생 (이 편) |

큰 것에서 작은 것을 떼어 내되 연결은 유지한다는 발상이 세 번째로 반복된다.

## 마무리

32:40의 Conclusion이 이 섹션의 결산이다. 그리고 이 컬렉션에서 제가 정리한 마지막 편이기도 하다.

다음 편(Ep. 277)부터는 이 도구들을 SyncUps 앱에 실제로 적용하는 시리즈로 이어진다.

## 확인 범위

- 영상이 유료라 실제 구현과 결론 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
