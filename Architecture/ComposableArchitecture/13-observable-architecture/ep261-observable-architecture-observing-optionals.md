# Ep. 261 — Observable Architecture: Observing Optionals

- 출처: [Point-Free Episode #261](https://www.pointfree.co/episodes/ep261-observable-architecture-observing-optionals)
- 코드: [0261-observable-architecture-pt3](https://github.com/pointfreeco/episode-code-samples/tree/main/0261-observable-architecture-pt3) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-12-11
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:29 | The @ObservableState macro |
| 10:14 | Making IfLetStore obsolete |
| 39:40 | Next time: observing enums |

---

## 이 편이 하려는 것

[Ep. 260](ep260-observable-architecture-structural-identity.md)에서 구조체 관찰이 되게는 만들었는데 **보일러플레이트가 엄청나다.** 그걸 매크로로 생성한다.

도입부가 상황을 정리한다. 아직 표면만 긁었고, 값 타입을 쓰면서도 뷰가 관련 있는 상태만 관찰하게 하는 건 **상태의 정체성** 덕이다. 통째로 교체된 것과 제자리에서 변경된 것을 구별하는 그 장치다.

## @ObservableState 매크로

Swift의 `@Observable`은 구조체에 붙지 않으니 **자체 매크로가 필요하다**는 게 도입부의 설명이다.

흥미로운 건 출처다. Swift 오픈소스 프로젝트의 `@Observable` 매크로를 가져다 쓴다. Apple이 만든 매크로 구현을 참고해 구조체용으로 고치는 셈이다. 언어 기능이 오픈소스라 가능한 접근이다.

## IfLetStore가 없어진다

10:14부터 이 편의 절반 이상을 쓴다.

`IfLetStore`는 옵셔널 상태를 다루던 뷰 헬퍼다. 상태가 `nil`이 아닐 때만 자식 뷰를 그리되, 그 과정에서 최소 관찰을 유지하려고 만든 것이었다.

관찰이 자동으로 되면 그런 장치가 필요 없다. **평범한 `if let` 문**으로 충분하다.

```
전: IfLetStore(store.scope(...)) { childStore in ... }
후: if let childStore = store.scope(...) { ... }
```

이 섹션의 성격이 여기서 드러난다. 새 기능을 더하는 게 아니라 **기존 개념을 지우는** 작업이다.

## 확인 범위

- 영상이 유료라 매크로의 실제 구현과 `IfLetStore` 제거 과정은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
