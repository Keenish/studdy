# Ep. 270 — Shared State: The Solution, Part 2

- 출처: [Point-Free Episode #270](https://www.pointfree.co/episodes/ep270-shared-state-the-solution-part-2)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-03-11
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:41 | Adding another step to the flow |
| 13:21 | Adding another step |
| 24:44 | One final touch |
| 40:44 | Next time: Testing |

---

## 이 편이 하려는 것

[Ep. 269](ep269-shared-state-the-solution-part-1.md)에서 시작한 회원가입 흐름을 완성한다. `@Shared` 프로퍼티 래퍼가 실제로 어떻게 쓰이는지 보이는 편이다.

에피소드 설명이 목적을 밝힌다. 라이브러리에 **최근 추가된 능력들**을 보이면서, 공유 상태 관리가 얼마나 단순해질 수 있는지 시연한다.

## 곁들여 나오는 것 — @Reducer 매크로

도입부가 짚는 대목이 이 컬렉션의 흐름과 이어진다.

`@Reducer` 매크로가 **기능 enum을 모델링하는 데 필요한 보일러플레이트를 전부 생성**해 준다는 것이다. 내비게이션 스택에 특히 유용하다고 언급한다.

[11 섹션](../11-navigation/00-overview.md)에서 `StackState`와 목적지 enum을 만들 때 손으로 써야 했던 것들이 매크로로 정리된 셈이다. [Ep. 229](../11-navigation/ep229-composable-navigation-correctness.md)가 "enum이 옳지만 다루기 불편하다"고 했던 문제가 여기서 상당 부분 해소된다.

## 흐름을 쌓아 가며

단계를 하나씩 더한다(0:41, 13:21). 회원가입처럼 화면이 이어지는 흐름에서 각 단계가 같은 데이터를 조금씩 채워 나가는 모습이다.

이게 `@Shared`의 값이 드러나는 자리다. 예전 방식이라면 각 단계의 상태를 부모가 들고 있다가 내려 주고 올려받는 배선이 필요했다.

## 확인 범위

- 영상이 유료라 실제 코드는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
