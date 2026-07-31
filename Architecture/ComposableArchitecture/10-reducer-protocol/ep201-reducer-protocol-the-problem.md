# Ep. 201 — Reducer Protocol: The Problem

- 출처: [Point-Free Episode #201](https://www.pointfree.co/episodes/ep201-reducer-protocol-the-problem)
- 코드: [0201-reducer-protocol-pt1](https://github.com/pointfreeco/episode-code-samples/tree/main/0201-reducer-protocol-pt1) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다.** 이 섹션에서 201과 208만 그렇다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:50 | Structure |
| 10:22 | Compiler strain |
| 13:23 | Readability, composition and correctness |
| 28:01 | Dependencies |
| 36:46 | Performance and stack size |
| 38:38 | Next time: the solution |

---

## 이 편이 하려는 것

[09 섹션](../09-async-composable-architecture/00-overview.md)에서 동시성을 정리했으니 이제 리듀서 자체의 사용성을 본다. 이번에도 해법 없이 문제만 늘어놓는다.

대상은 [Ep. 98](../08-ergonomics/ep98-ergonomic-state-management-part-1.md)에서 만든 `Reducer` 구조체다. 파일 수준에 전역 변수로 리듀서를 선언하고 클로저를 중첩해 조립하는 방식이 한계에 부딪혔다.

## 문제 다섯

### 구조 (2:50)

`Reducer<State, Action, Environment>` 변수가 파일 수준에 놓인다. 이름공간이 없다.

- 타입 파라미터 나열이 길어서 여러 줄을 차지하기도 한다
- 헬퍼 함수를 부르려면 `inout` 상태와 환경을 매번 손으로 넘겨야 한다

기능 하나를 이루는 상태·액션·로직이 흩어져 있고 묶어 주는 장치가 없다.

### 컴파일러 부담 (10:22)

이게 실무에서 가장 아픈 부분이다.

- 이스케이핑 클로저가 타입 추론을 압박해 Xcode 자동완성이 깨진다
- 복잡한 리듀서에서는 사용하지 않는 변수 경고가 사라진다
- 제네릭 체인이 길어 에러 메시지가 알아볼 수 없고 엉뚱한 줄을 가리킨다

기능이 커질수록 편집기가 도움을 못 준다는 뜻이다.

### 가독성·합성·정확성 (13:23)

`.optional()`과 `.forEach()` 같은 연산자는 **조합 순서를 지켜야** 런타임 버그가 안 난다. 그런데 그 순서를 API가 강제하지 못한다. 문서와 런타임 경고에 의존한다.

`.pullback()`도 문맥이 모호하면 제네릭 타입을 명시해야 한다.

타입 시스템이 잡아 줘야 할 걸 사람이 기억하고 있는 상태다.

### 의존성 (28:01)

[06 섹션](../06-dependency-management/00-overview.md)에서 만든 환경 방식의 한계다.

말단 기능에 의존성을 **하나 추가하면** 그 위 계층의 모든 `Environment` 구조체를 고쳐야 한다.

- 각 환경의 이니셜라이저 수정
- `failing`·`noop` 같은 정적 인스턴스 수정
- pullback 변환 수정

모듈로 나뉜 코드베이스에서는 컴파일 에러가 연쇄한다. 06 섹션이 전역 변수를 걷어내고 얻은 정적 보장이, 이번엔 변경 비용으로 돌아온 셈이다.

### 성능과 스택 크기 (36:46)

이스케이핑 클로저는 Swift가 최적화하지 못한다. 단순한 액션 하나에 스택 프레임이 **약 100개** 쌓인다.

프로토콜 준수는 인라인될 수 있는데 깊게 중첩된 클로저는 안 된다. [Ep. 208](ep208-reducer-protocol-in-practice.md)에서 이 수치가 얼마나 줄어드는지 확인할 수 있다.

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
