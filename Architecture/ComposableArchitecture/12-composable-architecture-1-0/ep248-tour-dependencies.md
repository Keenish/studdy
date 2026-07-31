# Ep. 248 — Tour of the Composable Architecture 1.0: Dependencies

- 출처: [Point-Free Episode #248](https://www.pointfree.co/episodes/ep248-tour-of-the-composable-architecture-1-0-dependencies)
- 코드: [0248-tca-tour-pt6](https://github.com/pointfreeco/episode-code-samples/tree/main/0248-tca-tour-pt6) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-09-04
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:27 | The speech client dependency |
| 23:07 | Testing the record meeting feature |
| 30:46 | Other ways of ending meetings |
| 41:29 | Speech recognition |
| 51:01 | Next time: Transcription |

---

## 이 편이 하려는 것

[Ep. 247](ep247-tour-domain-modeling.md)에서 시작한 녹음 화면에 음성 인식을 붙인다. 앱에서 가장 복잡한 의존성이다.

## 통제되지 않은 의존성이 프리뷰를 막는다

도입부의 사례가 이 섹션에서 가장 실용적이다.

음성 인식 권한 상태를 조회하는 `await`가 **영영 재개되지 않는다.** 프리뷰 환경에는 권한을 처리할 주체가 없기 때문이다. 그러면 그 뒤 코드가 실행되지 않고, 프리뷰에서 기능을 다듬는 게 불가능해진다.

원하는 해법도 도입부에 나온다. 의존성에게 **사용자 권한 요청은 신경 쓰지 말고 허가된 것으로 치자**고 말할 수 있으면 된다는 것이다.

이게 [Ep. 208](../10-reducer-protocol/ep208-reducer-protocol-in-practice.md)의 `previewValue`가 존재하는 이유다. [Ep. 233](../11-navigation/ep233-composable-stacks-multiple-destinations.md) 도입부도 같은 문제를 짚었는데, 여기서는 실제 시스템 프레임워크로 그게 얼마나 심각한지 보인다.

프리뷰가 안 되는 게 사소한 불편처럼 보이지만, 반복 속도가 떨어지면 개발 방식 자체가 바뀐다. [Ep. 75](../03-modularity/ep75-modular-state-management-the-point.md)의 Playground Driven Development 이래 이 시리즈가 계속 신경 써 온 부분이다.

## 미팅을 끝내는 다른 방법들 (30:46)

엣지 케이스를 다루는 섹션이다. 녹음 중 미팅이 끝나는 경로가 여러 개라는 뜻으로 보인다 — 시간이 다 되거나, 사용자가 중단하거나, 화면을 벗어나거나.

[Ep. 236](../11-navigation/ep236-composable-stacks-effect-cancellation.md)에서 다룬 효과 취소가 실제로 필요해지는 상황이다. 녹음이라는 긴 효과가 여러 경로로 끝날 수 있으니 그 처리가 정확해야 한다.

## 확인 범위

- 영상이 유료라 speech client의 실제 인터페이스와 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
