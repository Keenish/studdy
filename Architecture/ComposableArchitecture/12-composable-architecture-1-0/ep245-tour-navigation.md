# Ep. 245 — Tour of the Composable Architecture 1.0: Navigation

- 출처: [Point-Free Episode #245](https://www.pointfree.co/episodes/ep245-tour-of-the-composable-architecture-1-0-navigation)
- 코드: [0245-tca-tour-pt3](https://github.com/pointfreeco/episode-code-samples/tree/main/0245-tca-tour-pt3) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-08-14
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:51 | Adding a standup |
| 18:44 | Scrumdinger retrospective |
| 25:56 | Testing the standups list |
| 37:53 | Viewing and editing a standup |
| 48:35 | Next time: Navigating to the detail |

---

## 이 편이 하려는 것

[Ep. 244](ep244-tour-introducing-standups.md)에서 만든 폼과 목록 기능을 붙인다. "추가"를 누르면 시트로 폼이 뜨는 흐름이다.

[11 섹션](../11-navigation/00-overview.md)에서 만든 내비게이션 도구가 실제로 쓰이는 첫 자리다. 그 섹션이 트리 기반(시트·알럿)을 다뤘으니 여기서 그 방식이 나온다.

## Scrumdinger 회고 (18:44)

이 섹션이 이 편에서 가장 눈에 띈다.

Apple 원본과 대조하는 자리로 보인다. 같은 기능을 두 방식으로 짜 놓고 비교하는 건 [Ep. 85](../05-testing/ep85-testable-state-management-the-point.md) 이래 이 시리즈가 반복해 온 논증 방식이다. 다만 이번 상대는 Apple이 공식 튜토리얼로 내놓은 코드다.

## 값 타입과 스냅샷 비교

도입부가 다시 강조하는 대목이다. 값 타입이라 액션 전후의 상태를 **스냅샷으로 비교**할 수 있다.

[Ep. 243](ep243-tour-the-basics.md)에서 `_printChanges()`로 소개된 성질이 여기서 테스트의 근거가 된다. 목록 테스트(25:56)에 12분을 쓰는 게 그 결과다.

## 편집까지

37:53부터 기존 항목을 보고 편집하는 흐름을 만든다. 추가와 편집이 같은 폼을 공유하는 구조라, [03 섹션](../03-modularity/00-overview.md)에서 말한 기능 재사용이 실제로 드러나는 지점이다.

## 확인 범위

- 영상이 유료라 실제 구현과 Scrumdinger 회고의 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
