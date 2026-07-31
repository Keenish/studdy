# Ep. 275 — Shared State: File Storage, Part 1

- 출처: [Point-Free Episode #275](https://www.pointfree.co/episodes/ep275-shared-state-file-storage-part-1)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:42 | Persistence to file storage |
| 11:25 | Debouncing persistence |
| 15:20 | Saving on willResignActive |
| 19:27 | Observing external writes to file system |
| 26:50 | Fixing feedback loop |
| 29:58 | Next time: Testable file storage |

---

## 이 편이 하려는 것

세 번째 영속화 전략이다. 도입부가 지금까지의 전략을 정리한다.

| 전략 | 용도 |
|---|---|
| in-memory | 영속화 없음. 순수한 공유만 |
| user defaults | 불리언·정수·문자열 같은 단순 타입 |
| **file storage** | 복잡한 데이터. `Codable` + JSON |

user defaults의 한계가 분명하다. 단순 타입만 다룬다. 그래서 복잡한 데이터는 파일 시스템으로 간다.

에피소드 설명이 난이도를 인정한다. 이게 **제대로 하기 까다로워서** 엣지 케이스를 전부 다루는 데 시간을 들인다는 것이다.

## 엣지 케이스가 이 편의 본론

섹션 제목이 그대로 목록이다.

**디바운싱** (11:25) — 상태가 바뀔 때마다 파일을 쓰면 디스크 I/O가 폭주한다. 타이핑 한 글자마다 저장하는 상황을 생각하면 된다. 일정 시간 모았다가 쓴다.

**willResignActive에 저장** (15:20) — 디바운싱을 하면 아직 안 쓴 변경이 남아 있을 수 있다. 앱이 백그라운드로 갈 때 강제로 비워야 데이터를 잃지 않는다. 디바운싱이 만든 문제를 디바운싱과 짝지어 해결하는 셈이다.

**외부 쓰기 관찰** (19:27) — [Ep. 274](ep274-shared-state-user-defaults-part-2.md)에서 user defaults에 했던 것과 같다. 다른 프로세스나 확장이 파일을 고칠 수 있다.

**피드백 루프 수정** (26:50) — 앞의 두 가지를 합치면 생기는 문제다. 상태가 바뀌면 파일에 쓰고, 파일이 바뀌면 상태에 반영한다. 그러면 내가 쓴 것이 다시 나에게 돌아와 무한히 순환할 수 있다.

이 넷이 나열된 순서가 좋다. 기능을 붙이면 그것이 다음 문제를 만들고, 그걸 또 해결한다.

## 왜 이렇게까지 하나

라이브러리가 대신 감당하기 때문이다. 쓰는 쪽이 `.fileStorage` 전략을 고르기만 하면 디바운싱도, 백그라운드 저장도, 외부 변경 감지도 따라온다.

[Ep. 249](../12-composable-architecture-1-0/ep249-tour-persistence.md)에서 영속화를 손으로 붙일 때 겪던 일들이 여기서 전략 하나로 정리된다.

## 확인 범위

- 영상이 유료라 실제 구현과 각 엣지 케이스의 해법은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
