# Ep. 268 — Shared State: The Problem

- 출처: [Point-Free Episode #268](https://www.pointfree.co/episodes/ep268-shared-state-the-problem)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-02-26
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:47 | The problem of shared state |
| 16:44 | Sharing state with value types |
| 24:53 | Shared state using dependencies |
| 46:20 | Next time: The solution |

---

## 이 편이 하려는 것

도입부가 이 주제의 위상을 밝힌다. **"여러 기능이 상태를 어떻게 공유하나"가 TCA 사용자에게서 가장 흔한 질문 중 하나**라는 것이다.

역설처럼 보이는 지점을 먼저 정리한다. 이 아키텍처는 단일 진실 공급원(single source of truth)을 갖는데, 정작 앱은 독립적인 기능들로 쪼개지고 각 기능은 자기 몫의 상태 조각만 본다.

그 격리가 의도된 것이라는 점도 짚는다. [03 섹션](../03-modularity/00-overview.md)에서 모듈 경계를 만든 이유가 바로 그것이었다. 그런데 여러 기능이 같은 상태를 필요로 하는 순간 마찰이 생긴다.

## 기존 방법 두 가지

**값 타입으로 공유** (16:44) — 각 기능이 자기 사본을 갖고, 부모가 변경을 동기화한다. 값 타입 원칙은 지켜지지만 동기화 코드를 손으로 써야 한다.

**의존성으로 공유** (24:53) — [10 섹션](../10-reducer-protocol/00-overview.md)의 `@Dependency`를 쓴다. 상태가 아니라 의존성으로 취급하는 방식인데 보일러플레이트가 늘고, 상태가 아니라서 [05 섹션](../05-testing/00-overview.md)이 세운 전수 테스트의 대상에서 벗어난다.

둘 다 대가가 있다.

## 예고

다음 편들이 Swift의 관찰 도구를 활용한 해법을 내놓는다고 예고한다. 그리고 두 가지를 약속한다.

- **완전히 테스트 가능**할 것
- 자동 영속화(user defaults, 파일 저장)를 지원할 것

SwiftUI의 `@AppStorage`와 비슷하되 아키텍처에 직접 녹아든 형태라고 설명한다.

## 확인 범위

- 영상이 유료라 두 기존 방법의 구체적 코드와 한계 논증은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
