# Ep. 263 — Observable Architecture: Observing Collections

- 출처: [Point-Free Episode #263](https://www.pointfree.co/episodes/ep263-observable-architecture-observing-collections)
- 코드: [0263-observable-architecture-pt5](https://github.com/pointfreeco/episode-code-samples/tree/main/0263-observable-architecture-pt5) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-01-08
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:07 | Getting rid of ForEachStore |
| 6:41 | Array scope |
| 19:35 | Minimal observation of collections |
| 29:26 | New ForEach super powers |
| 52:10 | Next time: Observable navigation |

---

## 이 편이 하려는 것

컬렉션 차례다. `ForEachStore`를 없애고 평범한 SwiftUI `ForEach`를 쓴다.

도입부가 지금까지의 전과를 센다. Swift 5.9의 Observation 덕에 **뷰 헬퍼 넷**이 사라졌다 — `WithViewStore`, `IfLetStore`, `SwitchStore`, `CaseLet`. 그러면서도 뷰에서 건드린 상태만 최소로 관찰하는 성질은 유지된다.

`ForEachStore`가 하던 일도 설명한다. 컬렉션 store를 개별 요소의 store로 변환해 목록을 분해하는 것이다. 그것 역시 평범한 `ForEach`로 대체할 수 있다는 판단이다.

## 컬렉션이 까다로운 이유

옵셔널이나 enum과 달리 컬렉션은 요소가 여러 개다.

목록의 한 항목만 바뀌었을 때 그 항목의 행만 다시 그려야지 목록 전체를 그리면 안 된다. 최소 관찰의 난이도가 한 단계 높다. 19:35의 "Minimal observation of collections"가 그 작업이고, 이 편이 53분으로 이 섹션에서 가장 긴 이유이기도 하다.

## ForEach의 새 능력 (29:26)

23분을 쓰는 이 편의 최대 구간이다.

단순히 `ForEachStore`를 걷어내는 데 그치지 않고, 평범한 `ForEach`를 쓰면서 전보다 나은 것을 얻는 것으로 보인다. SwiftUI 기본 뷰를 쓰면 그 생태계의 기능(스와이프 삭제, 이동, 애니메이션 등)이 자연스럽게 따라온다.

전용 래퍼를 쓰면 그 프레임워크 기능과의 통합이 늘 한 겹 어긋나기 마련인데, 그 문제가 사라지는 셈이다.

## 확인 범위

- 영상이 유료라 실제 구현과 "새 능력"의 내용은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명과 시간 배분에서 읽어낸 것이다
