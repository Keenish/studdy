# Ep. 80 — The Combine Framework and Effects: Part 1

- 출처: [Point-Free Episode #80](https://www.pointfree.co/episodes/ep80-the-combine-framework-and-effects-part-1)
- 코드: [0080-combine-and-effects-pt1](https://github.com/pointfreeco/episode-code-samples/tree/main/0080-combine-and-effects-pt1) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-11-11
- 근거: **무료 영상이라 트랜스크립트 전문이 열린다.** 이 섹션에서 80·81편만 그렇다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 2:18 | The Effect type: a quick recap |
| 5:15 | The Combine-Effect Correspondence |
| 5:54 | Publishers |
| 10:22 | Subscribers |
| 16:18 | Eagerness vs. laziness |
| 19:14 | Subjects |
| 23:48 | Next time: refactoring the architecture |

---

## 이 편이 하려는 것

네 편에 걸쳐 `Effect` 타입을 직접 만들었다. 그런데 Apple이 같은 문제를 푸는 프레임워크를 이미 내놨다. 이 편은 코드를 고치지 않고 **둘을 대조만 한다.** 실제 교체는 다음 편이다.

저장소를 봐도 이 편에는 `PrimeTime` 프로젝트가 없고 `Combine.playground` 하나뿐이다. 탐색만 하는 편이라는 뜻이다.

## 지금까지의 Effect

도입부가 부수효과를 한 줄로 정의한다. 부수효과란 **작업 단위를 감싼 값을 반환하는 것**이고, 그 값을 실행하는 건 store다.

```swift
public struct Effect<A> {
  public let run: (@escaping (A) -> Void) -> Void
  public func map<B>(_ f: @escaping (A) -> B) -> Effect<B>
}
```

두 가지 성질이 중요하다.

- **게으르다** — `run`을 부르기 전에는 아무 일도 안 일어난다
- **변환된다** — `map`으로 만들어 낼 액션을 바꿀 수 있다

## 대응 관계

Combine의 개념들이 하나씩 짝을 이룬다.

| Effect | Combine |
|---|---|
| `Effect<A>` 자체 | `Publisher` — 임의의 시점에 값을 전달하는 것 |
| `run`을 호출하는 행위 | `Subscriber` — 구독해서 값을 받는 것 |

`Publisher`는 연관 타입이 있는 프로토콜이라 그대로는 쓰기 어렵다. 그래서 `Future`나 `AnyPublisher` 같은 구체 타입을 쓴다. `Future<Int, Never>`는 콜백을 받는 초기화 방식이 `Effect`와 거의 같은 모양이다.

### Subscriber 쪽은 더 복잡하다

`Effect`는 콜백 하나였는데 Combine의 `Subscriber`는 이벤트를 셋 받는다.

- `receiveSubscription` — 연결이 맺어지며 `Subscription` 객체를 받는다
- `receiveValue` — 값이 오고, `Demand`(더 받을지)를 반환한다
- `receiveCompletion` — 끝났음을 알린다. 성공이든 실패든

`sink`가 이걸 간편하게 만들어 준다. 값과 완료 클로저만 받고 `Demand`는 무제한으로 가정한다. 반환값은 `AnyCancellable`이고, 이걸 붙들고 있어야 구독이 유지된다.

## 문제 — Future는 성급하다

이 편에서 가장 실질적인 발견이다.

`Future`는 **만들어지는 순간 실행된다.** 구독할 때가 아니다. 이게 이 아키텍처에서 심각한 이유는, 리듀서가 효과를 반환하기만 하고 실행은 store가 해야 하기 때문이다. `Future`를 그냥 쓰면 리듀서가 상태를 계산하는 도중에 부수효과가 터진다. 리듀서의 순수성이 깨진다.

해법은 `Deferred`다. `Future`를 클로저로 감싸 구독 시점까지 실행을 미룬다. 그러면 `Effect`와 같은 게으른 의미가 회복된다.

References에 이 해법의 출처가 남아 있다. 2019년 10월 트윗 한 건과, 게으름을 다룬 자료들 — Wikipedia의 Lazy Evaluation, John Hughes의 1989년 논문, 그리고 André Staltz의 "Promises Are Not Neutral Enough"다. 마지막 글이 특히 이 대목과 맞는데, 성급한 추상(Promise)이 왜 문제인지를 다룬다.

## Subject

`Future`는 값을 하나만 낸다. 여러 개를 명령적으로 보내려면 `PassthroughSubject`나 `CurrentValueSubject`를 쓴다. `.send()`를 불러 값을 흘려보내는 방식이라 Combine 밖의 코드를 스트림으로 끌어들일 때 쓰인다.

`Effect`의 콜백 방식보다 덜 우아하다고 평가한다.

## 다음 편

대조는 끝났고 이제 실제로 갈아 끼운다. → [Ep. 81](ep81-the-combine-framework-and-effects-part-2.md)

## 참고자료

- [Combine](https://developer.apple.com/documentation/combine) — Apple 공식 문서
- [Promises Are Not Neutral Enough](https://staltz.com/promises-are-not-neutral-enough.html) — André Staltz, 2018-02. 성급한 추상의 문제. `Future` 대목의 배경
- [Lazy Evaluation](https://en.wikipedia.org/wiki/Lazy_evaluation) / [Why Functional Programming Matters](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) — 게으름의 이론적 배경
- [Deferred Publishers 트윗](https://twitter.com/_lksz_/status/1183773360494383104) — 2019-10-19. `Deferred` 해법의 출처
- [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) / [RxSwift](https://github.com/ReactiveX/RxSwift) — 같은 일을 하는 대안들
- [Reactive Streams](https://www.reactive-streams.org) — Combine 설계의 바탕

## 확인 범위

- 무료 영상이라 트랜스크립트를 근거로 정리했다. 영상 자체는 보지 않았다
