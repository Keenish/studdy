# Ep. 206 — Reducer Protocol: Dependencies, Part 2

- 출처: [Point-Free Episode #206](https://www.pointfree.co/episodes/ep206-reducer-protocol-dependencies-part-2)
- 코드: [0206-reducer-protocol-pt6](https://github.com/pointfreeco/episode-code-samples/tree/main/0206-reducer-protocol-pt6) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-09-26
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:30 | Introduction |
| 1:13 | Overriding dependencies |
| 16:36 | Override order and performance |
| 32:34 | Next time: testing |

---

## 이 편이 하려는 것

[Ep. 205](ep205-reducer-protocol-dependencies-part-1.md)에서 만든 의존성 체계에 아직 두 가지가 빠져 있다. 에피소드 설명이 짚는다.

- **통제 수단이 없다** — 특정 리듀서에만 다른 의존성을 주는 방법
- **인터페이스와 구현의 분리가 불분명하다**

이 둘을 갖추면 이전보다 훨씬 나은 것이 된다고 말한다.

## 덮어쓰기

[Ep. 205](ep205-reducer-protocol-dependencies-part-1.md)에서 의존성이 암묵적으로 흐르게 만들었다. 편해졌지만 그대로 두면 [06 섹션](../06-dependency-management/00-overview.md)이 전역 변수를 걷어낸 이유로 되돌아간다. 프로세스 전체에 하나뿐이면 같은 화면을 다른 설정으로 띄울 수 없다.

그래서 **특정 리듀서에만** 다른 의존성을 주는 장치를 만든다.

도입부가 쓰임새 둘을 든다.

- **온보딩** — 그 흐름 안에서만 다른 환경으로 동작하게 한다
- **프리뷰** — 리팩터링 과정에서 잃었던, 프리뷰에 원하는 의존성을 주는 능력을 되찾는다

프리뷰 쪽이 실용적이다. Xcode 프리뷰에서 실제 API를 부르면 안 되니 스텁을 꽂아야 하는데, 환경을 걷어내면서 그 통로가 막혔던 것이다.

이걸로 [Ep. 93](../06-dependency-management/ep93-modular-dependency-injection-the-point.md)이 전역 방식의 문제로 든 셋(환경 조율, 화면 재사용, 의존성 공유)이 새 체계에서도 유지된다. 흐름은 암묵적이되 범위는 통제된다.

## 덮어쓰기 순서와 성능

두 번째 섹션(16:36~32:34)이 절반을 차지한다.

의존성이 계층을 따라 흐르고 중간에서 덮어쓸 수 있으면 **어느 것이 이기는지** 규칙이 필요하다. 리듀서 트리에서 부모가 덮어쓴 것과 자식이 덮어쓴 것이 만나는 경우다.

성능도 같이 다룬다. 값을 꺼낼 때마다 계층을 거슬러 올라가야 한다면 비용이 든다. [Ep. 201](ep201-reducer-protocol-the-problem.md)이 스택 프레임 문제를 지적한 섹션이라 여기서도 성능을 그냥 넘기지 않는다.

## 확인 범위

- 영상이 유료라 덮어쓰기 API의 실제 형태와 순서 규칙은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
