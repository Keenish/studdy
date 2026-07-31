# Ep. 266 — Observable Architecture: The Point

- 출처: [Point-Free Episode #266](https://www.pointfree.co/episodes/ep266-observable-architecture-the-point)
- 코드: [0266-observable-architecture-pt8](https://github.com/pointfreeco/episode-code-samples/tree/main/0266-observable-architecture-pt8) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-01-29
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:00 | Measuring observation improvements |
| 12:54 | Throwback: Todos |
| 25:23 | Outro |

---

## 이 편이 하려는 것

여덟 편의 결산이다. 도입부가 성과를 셋으로 정리한다.

- 뷰가 더 효율적이 됐다
- 라이브러리로 만든 기능에서 보일러플레이트가 사라졌다
- 기능 구현에 필요했던 **여러 개념이 더 이상 필요 없어졌다**

세 번째가 이 섹션의 성격이다. 더한 게 아니라 지운 것이 성과다.

## 숫자로 확인한다

이 편이 주장 대신 측정을 택한다.

도입부가 밝히는 방식이 인상적이다. TCA 기능을 **시뮬레이터에서 실제로 돌리는 통합 테스트 스위트**를 갖고 있어서, 그걸로 구체적 개선을 잰다는 것이다.

측정 대상 셋이 나온다.

- store 생성
- scope 연산
- 뷰 재계산

[07 섹션](../07-adaptation/00-overview.md)이 `View.init`/`body` 호출 횟수를 실측하고 [Ep. 208](../10-reducer-protocol/ep208-reducer-protocol-in-practice.md)이 스택 프레임을 세었듯이, 이 시리즈는 성능 주장을 할 때 숫자를 낸다.

## Todos 회고 (12:54)

**Todos 앱**을 새 도구로 마이그레이션한다.

이게 상징적이다. Todos는 TCA 초기부터 있던 기본 예제다. 가장 오래된 코드를 가장 새 도구로 옮겨 보이는 것으로, 전후 대비가 가장 잘 드러나는 선택이다.

[Ep. 200](../09-async-composable-architecture/ep200-async-composable-architecture-in-practice.md)이 isowords로, [Ep. 208](../10-reducer-protocol/ep208-reducer-protocol-in-practice.md)이 같은 앱으로 했던 것과 같은 방식이다. 이 시리즈는 결산 편마다 실물로 보인다.

## 확인 범위

- 영상이 유료라 실제 측정 수치와 Todos 마이그레이션 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- 앞의 결산 편들(Ep. 200, 208)은 무료라 구체적 수치를 확인할 수 있었는데 이 편은 그렇지 않다
