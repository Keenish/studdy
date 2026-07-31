# Ep. 94 — Adaptive State Management: Performance

- 출처: [Point-Free Episode #94](https://www.pointfree.co/episodes/ep94-adaptive-state-management-performance)
- 코드: [0094-adaptive-state-management-pt1](https://github.com/pointfreeco/episode-code-samples/tree/main/0094-adaptive-state-management-pt1) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2020-03-16
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:42 | Introduction |
| 2:06 | Fixing a couple memory leaks |
| 9:11 | View.init/body: tracking |
| 14:56 | View.init/body: analysis |
| 17:44 | View.init/body: stress test |
| 19:47 | Next time: the solution |

---

## 이 편이 하려는 것

성능 개선으로 시작하는데 목적지가 다른 곳이다.

도입부가 이 연결을 밝힌다. 아키텍처에 **순진하게 짠 부분이 하나** 있어서 그걸 고치려는 건데, 그 작업이 아키텍처를 여러 상황에 적응시키는 좋은 길이 된다는 것이다. iOS·macOS·tvOS·watchOS에 같은 비즈니스 로직을 공유하는 게 목표다.

성능 문제를 풀다가 플랫폼 적응성까지 얻는 구조라, 섹션 이름이 Performance가 아니라 Adaptation인 이유가 여기 있다.

## 메모리 누수 잡기

먼저 누수 두 건을 고친다. 저장소 diff로 확인되는 변화가 셋이다.

**효과 구독의 완료 핸들러**

```swift
receiveCompletion: { [weak self, weak effectCancellable] _ in
```

기존에는 `self`만 약하게 잡았는데 `effectCancellable`까지 약하게 잡는다. [Ep. 81](../04-side-effects/ep81-the-combine-framework-and-effects-part-2.md)에서 만든 cancellable 관리 코드가 자기 자신을 붙들고 있던 셈이다.

**효과의 값 수신**

```swift
// 전
receiveValue: self.send
// 후
receiveValue: { [weak self] in self?.send($0) }
```

메서드 참조 `self.send`를 그대로 넘기면 `self`를 강하게 붙든다. 짧고 깔끔해 보이는 표기가 누수의 원인이었다. 도입부에서 말한 "순진한 것 하나"가 이런 종류로 보인다.

**지역 store 구독**

```swift
localStore.viewCancellable = self.$value
  .map(toLocalValue)
//  .removeDuplicates()      ← 주석으로만 존재
  .sink { [weak localStore] newValue in
    localStore?.value = newValue
  }
```

변환을 `sink` 안이 아니라 `map`으로 앞당겼다. 그리고 `.removeDuplicates()`가 **주석으로 남아 있다.** 다음 편의 해법을 미리 적어 둔 자리다.

## 뷰가 몇 번 그려지는가

나머지 시간은 전부 이 측정에 쓴다. `View.init`과 `body`가 얼마나 자주 불리는지 추적하고(tracking), 분석하고(analysis), 스트레스 테스트까지 한다.

문제의 구조는 [Ep. 95](ep95-adaptive-state-management-state.md) 도입부가 정리해 준다. 뷰 안의 store 하나가 **그 뷰에 필요한 상태뿐 아니라 자식들의 상태까지 전부** 들고 있다. 그러니 앱 어디서든 상태가 바뀌면 관련 없는 뷰까지 다시 그려진다.

[03 섹션](../03-modularity/00-overview.md)의 `Store.view`가 지역 store를 만들어 주긴 하는데, 그건 전역 store에 연결된 창이라 전역 변경이 그대로 흘러든다. 값이 실제로 달라졌는지는 보지 않는다.

## 다음 편

해법을 예고만 하고 끝난다. 위 주석에 남은 `.removeDuplicates()`가 그 방향이다. → [Ep. 95](ep95-adaptive-state-management-state.md)

## 참고자료

이 섹션은 References가 거의 없다. 새 이론을 들여오는 게 아니라 실측하고 고치는 편들이라 그렇다. 이 편에 하나 있다.

- [Gathering Information About Memory Use](https://developer.apple.com/documentation/xcode/improving_your_app_s_performance/reducing_your_app_s_memory_use/gathering_information_about_memory_use) — Apple. Xcode 메모리 그래프 디버거로 누수를 찾는 방법

## 확인 범위

- 영상이 유료라 측정 방법과 스트레스 테스트 결과는 확인하지 못했다
- 누수 수정 세 건은 저장소 소스 diff로 확인했다. `ComposableArchitecture.swift`가 105줄 → 107줄로 늘어난다
