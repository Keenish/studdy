# Ep. 273 — Shared State: User Defaults, Part 1

- 출처: [Point-Free Episode #273](https://www.pointfree.co/episodes/ep273-shared-state-ubiquity-persistence)
- 코드: [0273-shared-state-pt6](https://github.com/pointfreeco/episode-code-samples/tree/main/0273-shared-state-pt6) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-04-01
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:16 | Ubiquitous shared state |
| 18:56 | Persistence to user defaults |
| 40:21 | Next time: External changes |

---

## 이 편이 하려는 것

공유 문제와 테스트를 해결했으니 이제 **영속화**다. [Ep. 268](ep268-shared-state-the-problem.md)이 예고했던 두 번째 약속이다.

user defaults부터 시작한다. 에피소드 설명이 이를 **Apple 플랫폼에서 가장 단순한 형태의 영속화**라고 부른다. 더 복잡한 방식([Ep. 275](ep275-shared-state-file-storage-part-1.md)의 파일 저장)의 토대가 된다.

## 전제가 바뀌었다는 확인

도입부가 이 섹션이 지금 가능해진 이유를 짚는다.

참조 타입은 **예전에 뷰 무효화와 잘 어울리지 않았는데** Swift의 관찰 도구가 그 문제를 해결했다는 것이다. [13 섹션](../13-observable-architecture/00-overview.md)의 작업이 없었다면 `@Shared` 자체가 성립하지 않았다.

`TestStore`도 전후 상태 비교를 담아내도록 개선돼 테스트가 쉬워졌다고 언급한다. [Ep. 271](ep271-shared-state-testing-part-1.md)~[272](ep272-shared-state-testing-part-2.md)의 성과다.

## 편재하는 상태 (2:16)

이 편의 개념적 전환점이다.

지금까지 `@Shared`는 부모가 자식에게 **넘겨주는** 상태를 표현했다. 회원가입 흐름이 그랬다. 그런데 설정값 같은 것은 앱 전체가 즉시 접근해야 하고, 그걸 모든 경로로 손수 전달하는 건 말이 안 된다.

명시적 전달 없이 앱 어디서나 쓸 수 있게 만드는 것이 이 섹션이다.

[10 섹션](../10-reducer-protocol/00-overview.md)의 `@Dependency`가 의존성에 대해 한 일과 같은 성격이다. 중간 계층이 몰라도 흐르게 하는 것. 다만 이번 대상은 의존성이 아니라 **상태**라서, 변경도 되고 관찰도 되고 테스트에서 검증도 돼야 한다.

## user defaults 영속화 (18:56)

`@Shared`에 영속화 전략을 붙인다. [Ep. 268](ep268-shared-state-the-problem.md)이 예고한 대로 SwiftUI의 `@AppStorage`와 비슷하되 아키텍처에 녹아든 형태다.

## 확인 범위

- 영상이 유료라 실제 API와 영속화 전략의 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 페이지 제목은 "User Defaults, Part 1"인데 URL 슬러그는 `ep273-shared-state-ubiquity-persistence`다. 제작 중 제목이 바뀐 것으로 보인다
