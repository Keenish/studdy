# 10 · Reducer Protocol — 여덟 편 흐름

Point-Free [Reducer Protocol](https://www.pointfree.co/collections/composable-architecture/reducer-protocol) 섹션(Ep. 201~208)을 한 흐름으로 읽기 위한 문서. 이 컬렉션에서 가장 긴 섹션이다.

- 정리일: 2026-07-30
- 근거: 202~207은 영상이 유료라 섹션 제목·도입부·References만 확인했다. **201과 208은 무료라 트랜스크립트 전문을 근거로 정리했다**

관련 문서

- [ep201 — The Problem](ep201-reducer-protocol-the-problem.md) · 구조체 기반 리듀서의 한계 다섯 (무료)
- [ep202 — The Solution](ep202-reducer-protocol-the-solution.md) · 프로토콜과 연산자 타입
- [ep203 — Composition 1](ep203-reducer-protocol-composition-part-1.md) · result builder
- [ep204 — Composition 2](ep204-reducer-protocol-composition-part-2.md) · SwiftUI의 `body` 스타일 통합
- [ep205 — Dependencies 1](ep205-reducer-protocol-dependencies-part-1.md) · `@Dependency` 도입
- [ep206 — Dependencies 2](ep206-reducer-protocol-dependencies-part-2.md) · 범위를 좁힌 덮어쓰기
- [ep207 — Testing](ep207-reducer-protocol-testing.md) · 테스트 패턴을 라이브러리에 심기
- [ep208 — In Practice](ep208-reducer-protocol-in-practice.md) · 실물 적용과 마이그레이션 (무료)

---

## 이 섹션이 하는 일

섹션 설명이 목표 셋을 든다. 리듀서 타입 앞에 프로토콜을 두면 컴파일러의 타입 검사 능력이 크게 좋아지고, 기능을 합성하는 새 방법이 생기고, 의존성 관리가 크게 단순해진다.

대상은 [Ep. 98](../08-ergonomics/ep98-ergonomic-state-management-part-1.md)에서 만든 `Reducer` 구조체다. 파일 수준 전역 변수로 리듀서를 선언하고 클로저를 중첩해 조립하던 방식이 한계에 부딪혔다.

## Ep. 201의 문제 다섯과 그것이 닫히는 곳

이 섹션 전체가 이 대응으로 읽힌다.

| Ep. 201의 문제 | 증상 | 닫히는 곳 |
|---|---|---|
| 구조 | 리듀서가 파일 수준 전역 변수, 이름공간 없음 | 202 — 기능마다 타입 하나 |
| 컴파일러 부담 | 이스케이핑 클로저가 추론을 압박, 자동완성 깨짐 | 202 — 구체 타입 |
| 가독성·정확성 | `.optional()`·`.forEach()` 조합 순서를 API가 강제 못 함 | 203 — result builder |
| 의존성 | 말단에 하나 추가하면 위 계층 환경을 전부 수정 | 205·206 — `@Dependency` |
| 성능 | 단순 액션에 스택 프레임 약 100개 | 202·208 — 인라인 가능 |

## 여덟 편이 쌓이는 순서

### Ep. 201 — 문제 (무료)

다섯을 늘어놓는다. 그중 실무에 가장 아픈 건 컴파일러 쪽이다. 이스케이핑 클로저가 타입 추론을 압박해 자동완성이 깨지고, 에러 메시지가 엉뚱한 줄을 가리키고, 사용하지 않는 변수 경고가 사라진다.

의존성 문제도 구체적이다. 말단 기능에 의존성 **하나**를 추가하면 위 계층의 모든 `Environment` 구조체와 이니셜라이저, `failing`/`noop` 정적 인스턴스, pullback 변환을 전부 고쳐야 한다. [06 섹션](../06-dependency-management/00-overview.md)이 전역 변수를 걷어내고 얻은 정적 보장이 이번엔 변경 비용으로 돌아온 셈이다.

### Ep. 202 — 프로토콜

201의 문제들이 대부분 "리듀서가 값(클로저)이라서" 생겼다. 클로저라 이름공간에 안 담기고, 추론이 압박받고, 인라인이 안 된다.

리듀서를 타입으로 만들면 셋이 한꺼번에 풀린다. 깊게 중첩된 이스케이핑 클로저 대신 프로토콜을 준수하는 구체 타입으로 만든다.

`pullback`·`combine`·`optional`·`forEach`도 메서드에서 **타입**이 된다. Combine에서 `map`이 `Publishers.Map`을 만드는 것과 같은 구조다.

### Ep. 203 — result builder

도입부가 솔직하다. 202의 결과물이 이상적이지 않다고 스스로 말한다. 프로토콜의 이점은 분명한데 합성 모양이 지저분하다.

Swift 5.7의 result builder로 다시 짠다. 노리는 것 중 **정확성 보장의 강제**가 201의 셋째 문제와 직접 연결된다. 조합 순서를 문서와 런타임 경고에 의존하던 걸 타입으로 제한한다.

당시 Swift에 가변 제네릭이 없어 리듀서 N개 합성에 오버로드를 잔뜩 만들어야 했는데, SE-0348의 `buildPartialBlock`이 그 우회로다.

### Ep. 204 — SwiftUI에서 빌려오기

202 이후 리듀서 정의 방식이 둘로 갈렸다. 말단은 로직을 직접 담고 복잡한 기능은 합성한다. 도입부가 든 증상이 구체적인데, `VoiceMemos` 리듀서가 합성된 리듀서를 만들어 놓고 **오직 `reduce`를 부르기 위해서만** 쓴다.

SwiftUI의 `View`가 이미 답이다. `body`에서 조립하되 원시 뷰는 그리기 로직을 직접 갖는다. 하나의 프로토콜이 두 스타일을 받는다. 리듀서도 같게 만든다.

Swift 5.7의 primary associated types(SE-0346)가 여기서 결정적이다. `some ReducerProtocol<State, Action>` 문법이 없으면 긴 `where` 제약을 매번 써야 한다. References가 이 기능이 사용성 있는 합성을 가능하게 했다고 밝힌다.

### Ep. 205 — @Dependency

프로토콜로 옮기면서 리듀서에서 environment 개념이 **이미 완전히 사라졌다.** 그럼 의존성을 어떻게 받나.

SwiftUI의 `Environment`를 본뜬다.

```
DependencyKey    ← EnvironmentKey
DependencyValues ← EnvironmentValues
@Dependency      ← @Environment
```

중간 계층이 몰라도 아래로 흐르니, 말단에 하나 추가할 때 위를 전부 고치던 문제가 사라진다. 모듈화할 때 `public` 이니셜라이저가 필요 없어지는 것도 이점이다.

### Ep. 206 — 범위를 좁힌 덮어쓰기

205의 방식은 편하지만 그대로 두면 06 섹션이 전역 변수를 걷어낸 이유로 되돌아간다. 그래서 **특정 리듀서에만** 다른 의존성을 주는 장치를 만든다.

쓰임새로 온보딩과 프리뷰를 든다. 프리뷰 쪽이 실용적인데, 환경을 걷어내면서 막혔던 통로를 되찾는 작업이다.

절반을 덮어쓰기 순서와 성능에 쓴다. 계층을 따라 흐르고 중간에서 덮어쓸 수 있으면 어느 것이 이기는지 규칙이 필요하다.

### Ep. 207 — 테스트

에피소드 설명의 표현이 요지다. **테스트 패턴을 라이브러리에 직접 codify**해서 테스트를 즉시 더 강하고 빠짐없게 만든다.

핵심은 "Unimplemented dependencies"다. 테스트에서 의존성의 기본값을 **호출되면 실패하는 것**으로 둔다. 그러면 테스트가 지정하지 않은 의존성을 코드가 건드리는 순간 깨진다. [05 섹션](../05-testing/00-overview.md)에서 `.mock`을 손으로 만들고 빠뜨려도 모르던 것과 대비된다.

### Ep. 208 — 실물 (무료)

성능 수치가 나온다.

| 버전 | 앱 스택 프레임 |
|---|---|
| 0.39 | 269 |
| 프로토콜 직전 | 113 |
| 프로토콜 | **31** |

0.39 대비 거의 10분의 1이다. 201의 다섯째 문제가 숫자로 닫힌다.

재귀 리듀서 예제도 좋다. 전에는 헬퍼 함수와 암묵적 언래핑 옵셔널로 고리를 묶어야 했는데, `body`가 지연 평가되므로 `Self()`를 그냥 참조하면 된다.

결론은 마이그레이션 이야기다 — 100% 하위 호환, 점진적 도입 가능, 업그레이드 가이드 제공, Swift 5.6 우아한 낮춤, 당장 옮길 압박 없음. 이미 널리 쓰이는 라이브러리를 고치는 작업이라 [Ep. 200](../09-async-composable-architecture/ep200-async-composable-architecture-in-practice.md)보다 안전성에 무게가 실린다.

## 이 섹션은 Swift 5.7 위에 서 있다

앞 섹션들과 다른 점이다. 해법이 언어 기능에 크게 기댄다.

- result builder — 합성 (203)
- `buildPartialBlock`, SE-0348 — 가변 제네릭 부재 우회 (203)
- primary associated types, SE-0346 — `some ReducerProtocol<State, Action>` (204)

Point-Free가 Swift Evolution 제안을 근거로 걸어 두는 게 이 섹션에 유독 많다. 언어가 자라면서 가능해진 설계라는 뜻이다.

## 09·10을 함께 보면

두 섹션이 성격이 같다. 이미 공개된 라이브러리를 크게 고치는 작업이고, 각각 무료 편 둘(문제 편·실물 편)로 열고 닫는다.

| | 09 Async | 10 Reducer Protocol |
|---|---|---|
| 대상 | Combine 기반 `Effect` | 구조체 기반 `Reducer` |
| 계기 | 언어에 동시성이 들어옴 | Swift 5.7 기능들 |
| 무료 편 | 195 문제 · 200 실물 | 201 문제 · 208 실물 |
| 검증 방식 | 기존 테스트가 그대로 통과 | 스택 프레임 269 → 31 |

## 읽는 순서

1. 이 문서로 흐름을 잡는다
2. [Ep. 201](ep201-reducer-protocol-the-problem.md) 원문 — **무료다.** 문제 다섯이 이후 일곱 편의 목차다
3. [Ep. 202](ep202-reducer-protocol-the-solution.md) → [203](ep203-reducer-protocol-composition-part-1.md) → [204](ep204-reducer-protocol-composition-part-2.md) — 프로토콜과 합성
4. [Ep. 205](ep205-reducer-protocol-dependencies-part-1.md) → [206](ep206-reducer-protocol-dependencies-part-2.md) → [207](ep207-reducer-protocol-testing.md) — 의존성과 테스트
5. [Ep. 208](ep208-reducer-protocol-in-practice.md) 원문 — **무료다.** 수치와 마이그레이션 안내

시간이 없으면 201과 208 원문만 봐도 이 섹션의 값은 대부분 얻는다.

## 확인 범위

확인한 것

- 201·208: 트랜스크립트 전문. 스택 프레임 수치와 API 목록 포함
- 202~207: 섹션 제목과 타임스탬프, 도입부, 에피소드 설명, References

확인하지 못한 것

- 202~207의 실제 시그니처와 구현. `ReducerProtocol` 정의, 연산자 타입들, result builder, `DependencyKey`·`@Dependency`의 실체가 모두 여기 해당한다

09 섹션과 마찬가지로 코드 diff로 대조하지 못했다. 다만 무료 두 편이 최종 API 목록과 사용 예를 담고 있어 결과물은 확인된다.
