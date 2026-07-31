# Ep. 246 — Tour of the Composable Architecture 1.0: Stacks

- 출처: [Point-Free Episode #246](https://www.pointfree.co/episodes/ep246-tour-of-the-composable-architecture-1-0-stacks)
- 코드: [0246-tca-tour-pt4](https://github.com/pointfreeco/episode-code-samples/tree/main/0246-tca-tour-pt4) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:56 | Navigating to the detail |
| 38:14 | Testing the edit flow |
| 51:48 | Confirming standup deletion |
| 1:01:42 | Next time: enum presentation state |

---

## 이 편이 하려는 것

목록에서 상세 화면으로 들어가는 드릴다운을 만든다. [Ep. 245](ep245-tour-navigation.md)가 트리 기반(시트)이었다면 여기는 **스택 기반**이다.

도입부가 두 방식을 다시 대조한다.

- **트리 기반** — 옵셔널을 쓴다. 기능이 기능을 품는다
- **스택 기반** — 평평한 배열을 쓴다. 파고들면 값을 붙이고 나오면 뺀다

이 편에서 스택을 고른 이유도 밝힌다. 트리 기반은 다른 곳에서 이미 보였기 때문이다. [11 섹션](../11-navigation/00-overview.md)의 두 아크가 여기서 실제 앱에 나뉘어 적용된다.

## 딥링크

에피소드 설명이 다루는 것으로 화면 다양성 지원, **딥링크**, 통합 테스트를 든다.

딥링크가 스택 기반의 대표적 이점이다. 상태가 배열이라 "목록 → 상세 → 편집"에 해당하는 값들을 한 번에 채워 넣으면 그 지점으로 바로 갈 수 있다. [Ep. 232](../11-navigation/ep232-composable-stacks-multiple-layers.md)에서 프로그래밍 방식 조작으로 언급된 것이 실제 앱에서 이렇게 쓰인다.

## 시간 배분

편집 흐름 테스트에 13분(38:14), 삭제 확인에 10분(51:48)을 쓴다. 1시간 2분 중 절반 가까이가 테스트와 엣지 케이스다.

투어 섹션인데도 테스트 비중이 높은 게 이 섹션의 일관된 특징이다.

## 다음 편 예고

"enum presentation state"가 [Ep. 247](ep247-tour-domain-modeling.md)이다. 상세 화면에 편집·삭제 알럿 등 여러 목적지가 붙으면서 옵셔널 여럿이 되고, 그 문제를 다룬다.

## 확인 범위

- 영상이 유료라 실제 구현과 딥링크 처리는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
