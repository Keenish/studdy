# Ep. 264 — Observable Architecture: Observing Navigation

- 출처: [Point-Free Episode #264](https://www.pointfree.co/episodes/ep264-observable-architecture-observing-navigation)
- 코드: [0264-observable-architecture-pt6](https://github.com/pointfreeco/episode-code-samples/tree/main/0264-observable-architecture-pt6) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-01-15
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:20 | Navigation: a recap and rethink |
| 9:38 | Scoping store bindings |
| 20:38 | Next time: Observing bindings |

---

## 이 편이 하려는 것

[11 섹션](../11-navigation/00-overview.md)에서 16편에 걸쳐 만든 내비게이션 도구를 다시 본다.

도입부의 문장이 이 섹션 전체를 요약한다. 그 헬퍼들을 **전부 그만 쓰고 평범한 SwiftUI view modifier를 쓰면 된다**는 것이다. 전부 Swift의 관찰 도구 덕이라고 덧붙인다.

대상은 시트·팝오버·전체화면 커버·스택용으로 만든 전용 modifier 묶음이다.

## 16편이 지워진다

이 섹션에서 가장 극적인 대목이다.

[11 섹션](../11-navigation/00-overview.md)은 이 컬렉션에서 가장 큰 섹션이었다. 16편, 약 13시간. 그 결과물의 상당 부분이 여기서 불필요해진다.

다만 **전부 없어지는 건 아니다.** 그 섹션이 실제로 만든 것은 두 층이었다.

- **도메인 모델링** — 옵셔널·enum으로 목적지를 표현하는 방식, `PresentationState`, `StackState`, 부모·자식 통신 규약
- **뷰 층 헬퍼** — 그 상태를 SwiftUI에 연결하는 전용 modifier들

없어지는 건 두 번째다. 첫 번째는 그대로 남는다. [Ep. 229](../11-navigation/ep229-composable-navigation-correctness.md)의 enum 논증이나 [Ep. 247](../12-composable-architecture-1-0/ep247-tour-domain-modeling.md)의 수치는 관찰과 무관하게 유효하다.

관찰이 해결한 건 **최소 관찰을 손으로 하던 부분**이고, 그게 뷰 층 헬퍼들이 존재하던 이유였다.

## Store 바인딩 스코핑 (9:38)

절반을 여기 쓴다. 전용 modifier 대신 평범한 SwiftUI modifier를 쓰려면 store에서 바인딩을 뽑아내는 방법이 필요하다.

SwiftUI의 `.sheet(item:)` 같은 API는 `Binding`을 요구한다. store 상태를 그 형태로 내주되 쓰기는 액션으로 가게 만드는 작업으로 보인다. 이게 [Ep. 265](ep265-observable-architecture-observing-bindings.md)의 바인딩 이야기로 이어진다.

## 확인 범위

- 영상이 유료라 실제 스코핑 API는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- "16편이 지워진다"는 서술에서 어느 부분이 남고 어느 부분이 사라지는지는 제가 두 섹션의 구성을 비교해 정리한 것이다. 영상에서 그렇게 구분했는지는 확인하지 못했다
