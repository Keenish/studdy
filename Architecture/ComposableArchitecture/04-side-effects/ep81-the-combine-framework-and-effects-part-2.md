# Ep. 81 — The Combine Framework and Effects: Part 2

- 출처: [Point-Free Episode #81](https://www.pointfree.co/episodes/ep81-the-combine-framework-and-effects-part-2)
- 코드: [0081-combine-and-effects-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0081-combine-and-effects-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-11-18
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다.** 코드도 저장소 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:27 | Effect as a Combine publisher |
| 8:31 | Pulling back reducers with publishers |
| 15:57 | Finishing the architecture refactor |
| 19:43 | Refactoring synchronous effects |
| 26:54 | Refactoring asynchronous effects |
| 35:12 | What's the point? |

---

## 이 편이 하려는 것

[Ep. 80](ep80-the-combine-framework-and-effects-part-1.md)에서 `Effect`와 Combine이 같은 것을 가리킨다는 걸 확인했다. 이 편은 실제로 갈아 끼운다.

## Effect를 Publisher로

`Effect`가 콜백을 감싸던 걸 그만두고 Combine 퍼블리셔를 감싼다.

```swift
public struct Effect<Output>: Publisher {
  public typealias Failure = Never
  // 내부에 AnyPublisher<Output, Never>를 들고, receive(subscriber:)를 위임
}
```

`Failure`가 `Never`로 고정된 게 설계 결정이다. **효과는 실패할 수 없다.** 에러가 날 수 있는 일이라면 그 에러를 액션 안에 담아야 한다. 실패도 리듀서가 처리할 하나의 사건으로 다루겠다는 뜻이다.

리듀서 시그니처는 겉보기에 그대로다.

```swift
public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]
```

`Effect`의 속이 완전히 바뀌었는데 이 줄은 변하지 않았다. 이게 이 편 결론의 근거가 된다.

## pullback에서 걸리는 것

지역 효과를 전역으로 끌어올릴 때 퍼블리셔의 `map`을 쓰면 된다. 그런데 `map`의 결과 타입은 `Publishers.Map<...>`이지 `Effect`가 아니다.

그래서 확장을 하나 만든다. `Failure == Never`인 모든 퍼블리셔에 `eraseToEffect()`를 붙여, `AnyPublisher`로 지운 뒤 `Effect`로 감싼다. Combine의 `eraseToAnyPublisher()`와 같은 발상이다.

## store가 효과를 실행하는 법

store가 구독을 관리하게 된다.

```swift
private var effectCancellables: Set<AnyCancellable> = []
```

액션을 보내면 리듀서가 돌려준 효과마다 `sink`를 걸고, 값이 나오면 그 액션을 다시 `send`한다. 구독이 끝나면 해당 cancellable을 집합에서 뺀다.

여기서 경쟁 조건이 하나 있다. 퍼블리셔가 **즉시 완료되면** cancellable이 집합에 들어가기도 전에 완료 핸들러가 먼저 돈다. 그러면 넣은 적 없는 걸 빼려 하거나, 뺀 뒤에 넣어 영영 남게 된다. `didComplete` 플래그로 이 순서를 정리한다.

동기 효과가 흔한 아키텍처라 실제로 부딪히는 문제다.

## 두 가지 헬퍼

**동기 작업**

```swift
Effect.sync(work:)  // Deferred { Just(work()) }.eraseToEffect()
```

`Deferred`가 핵심이다. Ep. 80에서 짚은 `Future`의 성급함 문제를 여기서 막는다. 구독 전에는 `work`가 실행되지 않는다.

**결과가 필요 없는 작업**

```swift
Effect.fireAndForget(work:)  // Deferred { work(); return Empty(completeImmediately: true) }.eraseToEffect()
```

`Empty`는 값 없이 즉시 완료되는 퍼블리셔다. Ep. 76의 `() -> Void`에 해당하는 자리를 Combine 어휘로 다시 쓴 셈이다.

**네트워크**

`URLSession.shared.dataTaskPublisher(for:)`에 `map`으로 데이터만 꺼내고, `decode`로 모델을 만들고, `replaceError(with: nil)`로 에러를 `nil`로 바꾼 뒤 `eraseToEffect()`를 부른다. 마지막 단계가 `Failure == Never` 제약을 맞추는 부분이다.

## 결론

두 가지를 말한다.

**얻은 것** — 초점이 좁고 변환 가능한 추상을 만들어 두면 큰 리팩터링에 열려 있게 된다. `Effect`의 구현을 통째로 갈아 끼웠는데 리듀서 시그니처는 그대로였고, 그 위에 쌓인 코드도 대부분 그대로였다.

**한계** — Swift의 타입 시스템으로는 효과를 일반화해 표현할 수 없다. 그래서 사용자가 RxSwift 같은 다른 리액티브 라이브러리를 끼워 넣을 방법이 없다. Combine으로 고정된다.

두 번째가 솔직한 대목이다. 합성 가능하게 만들었다고 해서 모든 축에서 자유로워지는 건 아니라는 인정이다.

## 참고자료

- [Combine](https://developer.apple.com/documentation/combine) — Apple 공식 문서
- [Deferred Publishers 트윗](https://twitter.com/_lksz_/status/1183773360494383104) — `Deferred` 해법의 출처
- [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) / [RxSwift](https://github.com/ReactiveX/RxSwift) — 결론에서 언급되는 대안들
- [Reactive Streams](https://www.reactive-streams.org)

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했고, 코드도 저장소 소스로 확인했다. 영상 자체는 보지 않았다
