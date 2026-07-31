# Ep. 247 — Tour of the Composable Architecture 1.0: Domain Modeling

- 출처: [Point-Free Episode #247](https://www.pointfree.co/episodes/ep247-tour-of-the-composable-architecture-1-0-correctness)
- 코드: [0247-tca-tour-pt5](https://github.com/pointfreeco/episode-code-samples/tree/main/0247-tca-tour-pt5) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-08-28
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:04 | Enum presentation state |
| 8:08 | Delete alert integration |
| 22:20 | Recording a meeting |
| 34:36 | Next time: Dependencies |

---

## 이 편이 하려는 것

[Ep. 229](../11-navigation/ep229-composable-navigation-correctness.md)의 논증을 실제 앱에서 반복한다. 그런데 숫자가 더 세다.

도입부가 제시하는 수치다.

| 목적지 수 | 표현 가능한 상태 | 유효한 상태 | 무효 비율 |
|---|---|---|---|
| 4개 | 16 | 5 | 약 70% |
| 5개 | 32 | 6 | **90% 초과** |

옵셔널을 하나 더할 때마다 표현 가능한 상태가 두 배가 되는데 유효한 건 하나만 는다. 목적지가 늘수록 상태 공간의 대부분이 말이 안 되는 조합으로 채워진다.

도입부의 진단이 명확하다. 여러 내비게이션 목적지를 여러 옵셔널로 표현하는 건 옳은 방식이 아니고, enum이 **여럿 중 하나를 배타적으로 고르는 상황에 딱 맞는 도구**라는 것이다.

## 이 섹션에서 반복되는 원칙

Point-Free가 오래 밀어 온 "불가능한 상태를 표현 불가능하게 만들라"가 여기서 가장 구체적인 숫자로 나온다.

같은 발상이 이 컬렉션 전체에 흩어져 있다.

- [02 섹션](../02-reducers-and-stores/00-overview.md) — 액션을 enum으로
- [Ep. 229](../11-navigation/ep229-composable-navigation-correctness.md) — 내비게이션 목적지를 enum으로 (16 중 5)
- 이 편 — 같은 논증, 실제 앱, 더 큰 수치

## 가장 복잡한 화면과 의존성

22:20부터 **미팅 녹음** 화면을 시작한다. 에피소드 설명이 이를 앱에서 **가장 복잡한 화면이자 가장 복잡한 의존성**이라고 부른다.

음성 인식이 걸리는데, 권한 요청·실시간 스트리밍·시스템 프레임워크 연동이 한꺼번에 들어온다. 이게 [Ep. 248](ep248-tour-dependencies.md)로 이어진다.

Scrumdinger를 예제로 고른 이유가 여기서 드러난다. 목록·폼 같은 평범한 화면만 있는 게 아니라 이런 난이도의 기능이 들어 있다.

## 확인 범위

- 영상이 유료라 enum 전환의 실제 코드와 알럿 통합은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 상태 수 통계는 도입부에 명시된 것이다
