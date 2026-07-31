# Ep. 205 — Reducer Protocol: Dependencies, Part 1

- 출처: [Point-Free Episode #205](https://www.pointfree.co/episodes/ep205-reducer-protocol-dependencies-part-1)
- 코드: [0205-reducer-protocol-pt5](https://github.com/pointfreeco/episode-code-samples/tree/main/0205-reducer-protocol-pt5) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-09-19
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:05 | SwiftUI's Environment |
| 2:57 | EnvironmentValues |
| 9:02 | Theorizing a TCA Environment |
| 14:57 | DependencyKey, DependencyValues |
| 22:28 | @Dependency |
| 35:23 | Next time: Overriding dependencies |

---

## 이 편이 하려는 것

[Ep. 201](ep201-reducer-protocol-the-problem.md)의 문제 넷째, 의존성을 푼다.

도입부가 상황을 먼저 정리한다. `ReducerProtocol`로 옮기면서 **리듀서에서 environment 개념이 이미 완전히 사라졌다.** [06 섹션](../06-dependency-management/00-overview.md)에서 리듀서의 세 번째 인자로 넣었던 그 환경이다.

그럼 의존성을 어떻게 받나. SwiftUI의 방식을 가져온다.

## SwiftUI의 Environment를 본뜬다

앞의 세 섹션(2:05~14:57)이 SwiftUI의 `Environment`와 `EnvironmentValues`를 뜯어보고 TCA용을 구상하는 데 쓰인다.

SwiftUI에서는 뷰가 `@Environment(\.colorScheme)`처럼 필요한 것만 꺼내 쓴다. 중간 뷰들이 그걸 알거나 전달할 필요가 없다. 부모가 `.environment(...)`로 심어 두면 아래로 흐른다.

이게 [Ep. 201](ep201-reducer-protocol-the-problem.md)의 문제를 정확히 겨눈다. 말단 기능에 의존성 하나를 추가하면 위 계층의 모든 `Environment` 구조체와 이니셜라이저를 고쳐야 했던 문제다. 암묵적으로 흐르면 중간 계층이 몰라도 된다.

## 세 조각

```
DependencyKey    — 의존성 하나를 등록하는 키
DependencyValues — 키로 값을 꺼내는 저장소
@Dependency      — 리듀서에서 꺼내 쓰는 프로퍼티 래퍼
```

SwiftUI의 `EnvironmentKey`·`EnvironmentValues`·`@Environment`와 일대일로 대응한다.

## 얻는 것

도입부가 이점 셋을 든다.

- 부모가 쓰지도 않는 의존성을 들고 다니지 않아도 된다
- 모듈로 나눌 때 `public` 이니셜라이저를 만들 필요가 없어진다
- 의존성 **하나만** 갈아 끼우는 게 가능해진다

두 번째가 [03 섹션](../03-modularity/00-overview.md)의 모듈화와 맞물린다. 환경 구조체를 모듈 경계 밖으로 노출하려면 `public` 이니셜라이저가 필요했는데, 그 부담이 사라진다.

## 06 섹션과의 관계

방향이 되돌아간 것처럼 보이는 지점이라 짚어 둘 만하다.

[Ep. 93](../06-dependency-management/ep93-modular-dependency-injection-the-point.md)은 전역 `var Current`를 걷어내고 명시적 인자로 바꾼 편이었다. 이유는 정적 보장이었다. 그런데 여기서는 다시 **암묵적으로 흐르는** 방식을 택한다.

같은 것으로 되돌아간 건 아니다. 06이 문제 삼은 건 프로세스에 하나뿐인 전역 변수였고, 여기서는 키 기반 저장소라 범위를 좁혀 덮어쓸 수 있다. 그 덮어쓰기가 [Ep. 206](ep206-reducer-protocol-dependencies-part-2.md)의 주제다.

## 하위 호환

도입부가 두 가지를 밝힌다. 이 변화가 완전히 하위 호환되고, Swift 5.7이 아직 아닌 곳을 위한 5.6 근사치도 제공한다는 것이다. 이미 널리 쓰이는 라이브러리라 이런 배려가 붙는다.

## 확인 범위

- 영상이 유료라 세 타입의 실제 정의와 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부에서 읽어낸 것이다
