# Ep. 75 — Modular State Management: The Point

- 출처: [Point-Free Episode #75](https://www.pointfree.co/episodes/ep75-modular-state-management-the-point)
- 코드: [episode-code-samples/0075-modular-state-management-wtp](https://github.com/pointfreeco/episode-code-samples/tree/main/0075-modular-state-management-wtp) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2019-10-07
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:24 | What's the point? |
| 4:01 | The favorite primes app |
| 6:24 | The prime modal app |
| 7:45 | The counter app |
| 13:25 | Fixing the root app |
| 18:07 | Conclusion |

---

## 이 편이 하려는 것

세 편에 걸친 모듈화의 결산이다. 도입부에서 지금까지를 이렇게 정리한다.

- 모듈화란 Swift 모듈 안에 코드를 격리하는 것이라고 정의했다
- 리듀서를 각자의 프레임워크로 분리해 모듈성을 보였다
- 뷰는 store 합성 두 가지로 모듈화했다. 하나는 상태 부분집합에, 하나는 액션 부분집합에 집중하는 것

그 결과 각 화면이 앱 전체 사정과 무관하게 돌아간다.

## 결산의 방식이 특이하다

섹션 제목을 보면 이 편이 뭘 하는지 알 수 있다.

- The favorite primes app
- The prime modal app
- The counter app

**화면 하나하나를 각각 독립된 앱처럼 띄운다.** 모듈화가 됐다는 걸 말로 주장하지 않고 실제로 실행해서 보여주는 방식이다. 즐겨찾기 화면만, 소수 모달만, 카운터만 따로 돌린다.

References가 이 방식을 뒷받침한다. Playground Driven Development 관련 자료가 세 개나 걸려 있다 — Point-Free 21편, Brandon Williams의 FrenchKit 2017 강연, 그리고 Kickstarter에서의 실제 적용 사례다. 플레이그라운드로 화면 하나를 미니 앱처럼 띄워 빠르게 반복하는 개발 방식이고, 실제로 저장소의 각 편에 `PrimeTime.playground`가 들어 있다.

이게 모듈화의 실질적 보상이다. 앱 전체를 빌드하고 그 화면까지 네비게이션해서 확인하는 대신, 그 화면만 몇 초 만에 띄운다.

## 무엇을 위한 모듈화였나

에피소드 설명이 목적을 분명히 한다. 각 화면이 격리된 미니 앱으로 동작하면 **앱 전체 구조를 몰라도 그 화면을 테스트할 수 있다.** 이게 모듈형 상태 관리의 핵심 목표라고 못 박는다.

테스트가 목표로 언급되는 게 눈에 띈다. 실제 테스트 작성은 [`05-testing`](../05-testing/) 섹션이지만, 그게 가능한 조건을 여기서 갖추는 셈이다.

## 루트 앱 손보기

"Fixing the root app" 섹션이 따로 있다. 각 모듈이 독립하고 나면 그것들을 조립하는 쪽에 일이 남는다는 뜻이다.

모듈은 자기 상태와 액션만 아니까, 앱 쪽에서 전역 상태에서 각 화면 상태를 뽑아내고 지역 액션을 전역 액션으로 감싸는 배선을 해야 한다. 복잡함이 사라진 게 아니라 한곳에 모인 것이다. 그 한곳이 앱 타깃이고, 나머지 모듈은 깨끗해진다.

## 이 시점의 프로젝트 구조

```
PrimeTime/
├── ComposableArchitecture/   Store, combine, pullback, logging
├── Counter/                  CounterAction, CounterViewAction, CounterView
├── FavoritePrimes/
├── PrimeModal/
├── PrimeTime/                앱 — 위를 조립
└── PrimeTime.playground      화면별 미니 앱 실행
```

각 모듈에 테스트 타깃이 하나씩 붙어 있다. 이 편에서는 `Package.swift`도 추가돼서 SwiftPM으로도 다룰 수 있게 된다.

## 남는 것

02·03 섹션으로 [Ep. 67](../01-swiftui-and-state-management/ep67-swiftui-and-state-management-part-3.md)의 숙제 넷 중 둘이 끝났다. 상태 변경의 조직화와 큰 앱의 분해다.

아직 손대지 않은 게 둘 남는다. 부수효과와 테스트다.

- [`04-side-effects`](../04-side-effects/)
- [`05-testing`](../05-testing/)

## 참고자료

이 편은 Playground Driven Development 자료가 특징적이다.

- [Playground Driven Development](https://www.pointfree.co/episodes/ep21-playground-driven-development) — Point-Free #21. 화면을 미니 앱처럼 띄워 반복하는 방식
- [Playground Driven Development](https://www.youtube.com/watch?v=DrdxSNG-_DE) — Brandon Williams, FrenchKit 2017. 이 방식을 쓰려면 코드베이스가 어떤 상태여야 하는지에 대한 강연. 무료
- [Playground Driven Development at Kickstarter](https://talk.objc.io/episodes/S01E51) — 스토리보드를 플레이그라운드로 대체한 실제 사례
- [Why Functional Programming Matters](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) — John Hughes, 1989
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — 무료 강연
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 결산의 내용과 각 화면을 띄워 보이는 시연은 확인하지 못했다
- 프로젝트 구조와 모듈 구성은 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
