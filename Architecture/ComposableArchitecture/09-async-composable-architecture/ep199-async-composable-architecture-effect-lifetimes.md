# Ep. 199 — Async Composable Architecture: Effect Lifetimes

- 출처: [Point-Free Episode #199](https://www.pointfree.co/episodes/ep199-async-composable-architecture-effect-lifetimes)
- 코드: [0199-tca-concurrency-pt5](https://github.com/pointfreeco/episode-code-samples/tree/main/0199-tca-concurrency-pt5) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-08-01
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:42 | The problem |
| 7:21 | View store tasks |
| 22:08 | Task cancellation |
| 31:13 | Testing |
| 37:05 | Conclusion |

---

## 이 편이 하려는 것

효과의 수명을 **뷰의 수명에 묶는다.** 뷰가 사라지면 돌던 작업이 자동으로 취소되고 정리된다.

[Ep. 67의 4.3](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)이 부수효과 문제로 든 것 중 하나가 "취소할 방법이 없다"였다. [04 섹션](../04-side-effects/00-overview.md)에서 취소 자체는 만들었지만, 그건 명시적으로 취소 액션을 보내야 하는 방식이었다. 이 편은 그걸 뷰 생명주기에 자동으로 연결한다.

## 문제 — async deinit이 없다

도입부가 걸림돌부터 밝힌다. Swift에는 **비동기 `deinit`이 없다.** 객체가 사라질 때 비동기 정리 작업을 기다릴 방법이 언어에 없다는 뜻이다.

그래서 다른 길을 택한다. **액션에서 `Task`를 돌려받는** 방식이다. 그 `Task`가 효과의 수명을 대표하므로, 특정 효과가 끝나기를 기다릴 수도 있고 취소할 수도 있다.

## SwiftUI의 .task와 연결

돌려받은 `Task`를 SwiftUI의 `.task` modifier에 물린다. `.task`는 뷰가 나타날 때 작업을 시작하고 사라질 때 취소한다. 그 취소가 그대로 효과에 전달된다.

"View store tasks" 섹션(7:21~22:08)이 이 연결이다. [07 섹션](../07-adaptation/00-overview.md)에서 만든 `ViewStore`에 그 기능이 붙는 것으로 보인다.

프레임워크가 이미 제공하는 수명 관리에 얹는 방식이라, 아키텍처가 따로 생명주기를 추적할 필요가 없다.

## 취소와 테스트

"Task cancellation"(22:08)과 "Testing"(31:13)이 나머지를 채운다.

에피소드 설명이 테스트도 강화된다고 밝힌다. 효과의 수명이 값으로 표현되면 테스트가 "이 효과가 끝났다"를 명시적으로 기다릴 수 있다. [Ep. 195](ep195-async-composable-architecture-the-problem.md)에서 문제였던 임의 대기(`XCTWaiter`로 0.1초 기다리기)가 필요 없어지는 방향이다.

## 참고자료

- [Collection: Concurrency](https://www.pointfree.co/collections/concurrency) — Brandon Williams & Stephen Celis

## 확인 범위

- 영상이 유료라 실제 API 시그니처와 취소 전파 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 샘플의 라이브러리 복사본이 이 섹션 여섯 편에서 동일해 코드로 대조하지 못했다
