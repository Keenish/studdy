# Ep. 72 — Modular State Management: Reducers

- 출처: [Point-Free Episode #72](https://www.pointfree.co/episodes/ep72-modular-state-management-reducers)
- 코드: [episode-code-samples/0072-modular-state-management-reducers](https://github.com/pointfreeco/episode-code-samples/tree/main/0072-modular-state-management-reducers) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부·References만 확인했다. 코드는 공개 저장소의 실제 소스로 확인했다

| 시간 | 섹션 |
|---|---|
| 0:06 | Introduction |
| 2:50 | Recap |
| 7:18 | What does modularity mean? |
| 9:17 | Modularizing our reducers |
| 10:53 | Modularizing the Composable Architecture |
| 13:41 | Modularizing the favorite primes reducer |
| 16:13 | Modularizing the counter reducer |
| 17:05 | Modularizing the prime modal reducer |
| 26:03 | Till next time… |

---

## 이 편이 하려는 것

[02 섹션](../02-reducers-and-stores/00-overview.md)에서 리듀서를 쪼개고 붙이는 도구를 만들었다. 그런데 그건 파일 안에서의 분리였다. 이 편은 그걸 진짜 경계로 만든다.

도입부에서 지금까지의 성적을 정리한다. 상태를 값 타입으로 모델링하는 것과 일관된 변경은 해결됐고, 리듀서 합성으로 모듈화도 일부 진행됐다. 하지만 뷰는 여전히 앱 전체의 상태와 액션을 받는다.

## 모듈화가 뭘 뜻하는가

Swift에서 모듈화는 명확한 의미가 있다. 각 기능을 별도 모듈에 넣어 **독립적으로 빌드되게** 하되, 앱 전체에는 그대로 끼워 넣을 수 있는 상태다.

핵심은 컴파일러가 강제한다는 점이다. 파일을 나누는 것과 모듈을 나누는 것은 다르다. 모듈 밖에서 보이려면 `public`을 붙여야 하고, 안 붙인 건 애초에 접근이 안 된다. 경계가 규율이 아니라 타입 시스템의 문제가 된다.

References에 Swift 접근 제어 문서와 John Hughes의 1989년 논문 "Why Functional Programming Matters"가 걸려 있다. 함수형 프로그래밍의 강점으로 모듈성을 든 고전이다.

## 프레임워크로 쪼개기

코드 구조가 이 편에서 완전히 바뀐다. 02 섹션까지는 플레이그라운드 파일 하나였는데, 여기서 실제 Xcode 프로젝트에 프레임워크 여러 개로 나뉜다.

```
PrimeTime/
├── ComposableArchitecture/   ← 아키텍처 자체 (Store, combine, pullback, logging)
├── Counter/
├── FavoritePrimes/
├── PrimeModal/
└── PrimeTime/                ← 앱, 위 모듈들을 조립
```

각 모듈에 테스트 타깃이 하나씩 붙는다. 기능별로 독립 빌드·독립 테스트가 되는 구조다.

## 아키텍처 모듈의 공개 API

`ComposableArchitecture` 프레임워크가 밖으로 내놓는 건 다섯 개뿐이다.

```swift
public final class Store<Value, Action>: ObservableObject
public func combine<Value, Action>(...)
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(...)
public func logging<Value, Action>(...)
```

02 섹션에서 만든 것들이 그대로다. 새 개념이 추가된 게 아니라 `public`을 붙이고 경계 밖으로 꺼냈을 뿐이다.

여기서 이 아키텍처의 성질이 드러난다. 리듀서가 이미 지역 상태·지역 액션만 알도록 만들어져 있었으니, 모듈로 옮기는 데 구조를 바꿀 게 없었다. 합성 가능하게 설계한 것의 배당금이다.

## 남는 문제

리듀서는 모듈로 잘 떨어졌는데 뷰는 아니다. 뷰가 여전히 `Store<AppState, AppAction>`를 받는다.

`Counter` 모듈의 뷰가 앱 전체 상태 타입을 알아야 한다면, 그 모듈은 앱 없이 빌드될 수 없다. 모듈로 나눈 의미가 없어진다.

이걸 다음 두 편이 나눠 푼다. 상태 쪽은 [Ep. 73](ep73-modular-state-management-view-state.md), 액션 쪽은 [Ep. 74](ep74-modular-state-management-view-actions.md)다. 02 섹션에서 리듀서에 했던 것과 같은 순서다.

## 참고자료

- [Why Functional Programming Matters](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) — John Hughes, 1989. 모듈성을 함수형 프로그래밍의 강점으로 든 고전. 이 섹션 네 편 모두에 걸려 있다
- [Access Control](https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html) — Swift 접근 제어 문서. 모듈 경계가 언어 차원에서 어떻게 강제되는지
- [Package Resources](https://github.com/abertelrud/swift-evolution/blob/package-manager-resources/proposals/NNNN-package-manager-resources.md) — Anders Bertelrud, 2018-12. SwiftPM 리소스 지원 제안. 당시엔 아직 제안 단계였다
- [Composable Reducers](https://www.youtube.com/watch?v=QOIigosUNGU) — Brandon Williams, 2017 Functional Swift Conference. 무료
- [Elm](https://elm-lang.org) / [Redux](https://redux.js.org)

## 확인 범위

- 영상이 유료라 논증의 세부와 실제 분리 과정은 확인하지 못했다
- 모듈 구조와 공개 API는 저장소 소스로 확인했다. 저장소 코드는 이후 갱신됐을 수 있다
