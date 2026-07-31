# Ep. 97 — Adaptive State Management: The Point

- 출처: [Point-Free Episode #97](https://www.pointfree.co/episodes/ep97-adaptive-state-management-the-point)
- 코드: [0097-adaptive-state-management-pt4](https://github.com/pointfreeco/episode-code-samples/tree/main/0097-adaptive-state-management-pt4) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-04-06
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:54 | Cross-platform SwiftUI views |
| 7:10 | Dedicated platform SwiftUI views |
| 20:10 | Cross-platform playgrounds |
| 25:37 | Conclusion |

---

## 이 편이 하려는 것

세 편에 걸친 작업의 결산이다. 그런데 도입부가 먼저 비용을 인정하고 시작한다.

`ViewStore`는 복잡도를 더한다. 뷰마다 상태 구조체와 액션 enum을 새로 만들어야 한다. 그럼에도 앱이 커지면 실제로 값을 한다는 게 주장이고, 그걸 증명하려고 **macOS 앱을 만든다.**

논증 방식이 [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)와 비슷하다. 말로 주장하지 않고 실제로 해 보인다.

## 증명의 구조

비즈니스 로직은 플랫폼과 무관하게 일반적으로 짜 두고, `ViewStore`로 각 플랫폼에 맞게 적응시킨다. iOS·watchOS·macOS·tvOS가 같은 리듀서를 공유하되 보는 상태와 보낼 수 있는 액션은 서로 다르게 만든다.

`ViewStore`가 성능 문제를 풀려고 도입된 장치인데, 그 장치가 **플랫폼 적응의 통로**가 된다는 게 이 섹션 이름의 이유다.

## macOS 버전이 다른 점

도입부가 구체적인 차이 둘을 든다.

- 소수 판별에 모달 대신 **팝오버**를 쓴다. 팝오버는 iPhone에서 지원되지 않으므로 플랫폼별로 갈리는 지점이다
- **더블탭 제스처를 뺀다.** Mac에서는 흔한 동작이 아니다

작지만 논점을 잘 보여주는 예다. 같은 기능인데 플랫폼마다 상호작용이 다르고, 그러면 뷰가 보낼 수 있는 액션 집합도 달라진다. [Ep. 96](ep96-adaptive-state-management-actions.md)에서 액션까지 좁힌 이유가 여기서 드러난다.

## 두 갈래 전략

섹션 구성이 선택지를 나눈다.

- **Cross-platform SwiftUI views** (2:54) — 하나의 뷰가 여러 플랫폼을 다룬다
- **Dedicated platform SwiftUI views** (7:10) — 플랫폼마다 뷰를 따로 쓴다. 시간 배분이 더 길다(7:10~20:10)

둘 다 보여주는 게 맞는 접근이다. 차이가 작으면 조건 분기로 충분하고, 크면 뷰를 나누는 게 낫다. 어느 쪽이든 **리듀서와 상태는 공유**된다는 게 요지다.

## 플레이그라운드

"Cross-platform playgrounds" 섹션이 있다. [Ep. 75](../03-modularity/ep75-modular-state-management-the-point.md)에서 화면을 미니 앱으로 띄워 보이던 방식이 여기서 플랫폼 축으로 확장된다.

이 시리즈가 결산 편마다 플레이그라운드로 돌려 보이는 패턴이 반복된다.

## 참고자료

이 편도 References가 없다. 페이지에 연결된 건 앞뒤 에피소드와 샘플 코드 저장소뿐이다.

## 확인 범위

- 영상이 유료라 macOS 앱의 실제 구현과 결론의 세부는 확인하지 못했다
- `ComposableArchitecture.swift`는 151줄로 [Ep. 96](ep96-adaptive-state-management-actions.md)과 **동일하다.** 아키텍처를 더 고치지 않고 이미 만든 것으로 macOS 앱을 짜는 편이라는 뜻이고, 이 편의 주장을 뒷받침하는 사실이다
