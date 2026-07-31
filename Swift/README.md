# Swift / SwiftUI

[study_list.md §1](../study_list.md#1-swift--swiftui) 묶음. Phase 0(언어 코어) · Phase 1a(SwiftUI 렌더링 모델).

Phase 1의 나머지 절반인 Concurrency는 [Concurrency/](../Concurrency/)에 있다. 실제 버그는 둘의 경계에서 나므로 같이 본다.

## 문서

| 문서 | 범위 | 상태 |
|---|---|---|
| [phase0-language-core.md](phase0-language-core.md) | §1-A 언어 코어 — 값 의미론·에러 설계·PAT·제네릭·resultBuilder·메모리 + 통과 기준 실습 | **Phase 0 완료.** 코드 실행 검증됨 + §7 확장 가능성을 실제 확장으로 확인 |
| [phase1-swiftui-rendering.md](phase1-swiftui-rendering.md) | §1-B 렌더링 모델 — body 재평가·무효화 범위·레이아웃 협상·identity·네비게이션·**UIKit 상호운용**·재계산 진단 절차 | **Phase 1a 완료.** 무효화 범위 + body 호출 횟수 런타임 검증. 레이아웃·Lazy는 타입체크까지. ⚠️ **UIKit 절만 컴파일 검증 없음** — macOS에 UIKit이 없다 |

## 코드

리포 루트에서 실행:

단독 실행:

```
swift Swift/code/phase0/phase0_demo.swift
swift -swift-version 6 Swift/code/phase0/existential_layout.swift
swift -swift-version 6 Swift/code/phase1/observation_demo.swift
swiftc -typecheck -swift-version 6 Swift/code/phase1/rendering_views.swift
```

SPM 타겟 (루트 `Package.swift`가 `code/phase0`를 가리킨다):

```
swift test --filter ComponentAPITests    # Phase 0 §7 컴포넌트 API 확장 검증 — 6건
swift run RenderingLab                   # Phase 1a §7 body 호출 횟수 실측
```

- [`code/phase0/`](code/phase0/) — 언어 코어 데모, existential 레이아웃 측정, 컴포넌트 API(`component_api.swift`) + 확장(`component_api_extensions.swift`)
- [`code/phase0Tests/`](code/phase0Tests/) — 확장 가능성 검증. **원본을 고치지 않고** 색·치수·외형 축을 하나씩 늘린다
- [`code/phase1/`](code/phase1/) — `observation_demo.swift`(무효화 범위, 실행됨) · `rendering_views.swift`(뷰 코드, 타입체크만) · [`RenderingLab/`](code/phase1/RenderingLab/)(body 호출 횟수 측정용 UI 호스트, 자동 구동)
