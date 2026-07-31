# Ep. 249 — Tour of the Composable Architecture 1.0: Persistence

- 출처: [Point-Free Episode #249](https://www.pointfree.co/episodes/ep249-tour-of-the-composable-architecture-1-0-persistence)
- 코드: [0249-tca-tour-pt7](https://github.com/pointfreeco/episode-code-samples/tree/main/0249-tca-tour-pt7) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-09-11
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:30 | Speech recognition client |
| 21:06 | Data persistence |
| 33:48 | Data manager dependency |
| 54:55 | Outro |

---

## 이 편이 하려는 것

투어의 마지막 편이다. 앱을 껐다 켜도 데이터가 남도록 영속화를 붙인다.

에피소드 설명이 이 편의 논점을 밝힌다. 영속화 의존성을 추가하는 것이 **프리뷰와 테스트를 얼마나 망가뜨릴 수 있는지**, 그리고 그걸 통제했을 때의 이점이 전부 무엇인지를 보인다.

[Ep. 248](ep248-tour-dependencies.md)의 음성 인식과 같은 구조의 문제다. 통제되지 않은 의존성이 개발 흐름을 막는다.

## 왜 영속화가 위험한가

테스트가 실제 파일 시스템을 건드리면 여러 문제가 한꺼번에 생긴다.

- 테스트끼리 상태를 공유하게 되어 실행 순서에 따라 결과가 달라진다
- 테스트를 돌릴 때마다 남은 파일을 지워야 한다
- 프리뷰가 실제 데이터를 읽거나 덮어쓴다

[Ep. 83](../05-testing/ep83-testable-state-management-effects.md)에서 `FileClient`를 만들며 다뤘던 문제인데, 그때는 즐겨찾기 배열 하나였고 여기서는 앱 전체 데이터다.

## 리듀서를 단순하게 유지하기

도입부에서 짚는 원칙이 이 컬렉션 전체를 요약한다. 로직을 효과 안에 정리하면 **리듀서는 단순한 함수로, 상태는 단순한 값 타입으로** 유지된다는 것이다.

[Ep. 76](../04-side-effects/ep76-effectful-state-management-synchronous-effects.md)에서 "리듀서를 순수하게 유지하려고 효과를 값으로 반환한다"고 결정한 것이, 일곱 섹션을 지나 실제 앱에서 이렇게 표현된다.

## 마무리

54:55의 Outro가 투어 전체의 마무리다. 카운터로 시작해([Ep. 243](ep243-tour-the-basics.md)) Scrumdinger 규모의 앱을 완성하기까지 일곱 편이 걸렸다.

## 확인 범위

- 영상이 유료라 data manager 의존성의 실제 구현과 Outro 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
