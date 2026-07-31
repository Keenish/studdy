# Ep. 265 — Observable Architecture: Observing Bindings

- 출처: [Point-Free Episode #265](https://www.pointfree.co/episodes/ep265-observable-architecture-observing-bindings)
- 코드: [0265-observable-architecture-pt7](https://github.com/pointfreeco/episode-code-samples/tree/main/0265-observable-architecture-pt7) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-01-22
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:32 | Simpler bindings in theory |
| 8:08 | Simpler bindings made a reality |
| 18:03 | Next time: The point |

---

## 이 편이 하려는 것

바인딩을 다시 짠다. 19분으로 이 섹션에서 가장 짧은데 내용은 오래된 빚을 갚는 것이다.

도입부의 표현이 솔직하다. 바인딩은 **첫날부터 껄끄러웠다**는 것이다. UI 컴포넌트마다 전용 액션을 만들어야 해서 리듀서가 장황해졌다.

그리고 Observation이 마침내 **처음부터 하고 싶었던 방식**을 가능하게 했다고 말한다.

## 왜 껄끄러웠나

SwiftUI의 `TextField`·`Toggle`·`Slider`는 `Binding<T>`를 요구한다. 그런데 이 아키텍처에서 상태를 바꾸는 유일한 길은 액션을 보내는 것이다.

바인딩이 값을 직접 쓰게 두면 [Ep. 67의 4.2](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)가 지적한 지점으로 돌아간다. 당시 흩어진 변경 일곱 군데를 셀 때 둘이 바인딩 안에 숨은 변경이었다.

그래서 [Ep. 99](../08-ergonomics/ep99-ergonomic-state-management-part-2.md)에서 바인딩 헬퍼를 만들었고, 이후에도 필드마다 액션 케이스를 두는 방식이 남았다. 껄끄러움의 정체가 그것이다.

## 무엇이 달라지나

에피소드 설명이 두 가지를 든다.

- store 상태를 **직접 관찰**한다
- view store를 **제거**한다

그러면 개념이 줄고 바인딩이 단순해진다. `ViewStore`라는 중간 층이 없으니 바인딩을 만들 자리가 하나로 정리되는 셈이다.

이론(1:32)과 실제(8:08)로 나눠 진행하는 구성이다.

## 확인 범위

- 영상이 유료라 새 바인딩 API의 실제 형태는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
