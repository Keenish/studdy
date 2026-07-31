# iOS 학습 계획

원본 키워드 6개를 주제별 학습 항목으로 쪼개고, **의존성 순서**(선수지식 → 후속)로 배열한 로드맵.
기간은 명시하지 않는다. 각 Phase는 **통과 기준**으로만 판단한다.

각 섹션 끝에 **참고 자료**(엄선된 것만)가 있고, 공부하다 발견한 즉석 링크는 맨 아래 [링크 수집함](#링크-수집함-inbox)에 던져둔다.
외부 링크는 2026-07-30에 HTTP 응답으로 실재 확인(55개 중 51개 직접 200). Dropbox·Uber 도메인은 자동 접근을 차단(403/406)하지만 **브라우저에서는 열린다** — Uber 글은 내용까지 확인했고, Dropbox 글은 접근 가능한 미러를 [§5-G](#5-g-출처)에 함께 달았다.

## 원본 키워드 → 섹션 매핑

| 키워드 | 섹션 | Phase |
|---|---|---|
| Swift, SwiftUI | [§1](#1-swift--swiftui) | 0, 1 |
| TCA, MVVM, Clean architecture 등 아키텍처 | [§2](#2-아키텍처--mvvm--clean--tca) | 2 |
| Swift Concurrency | [§3](#3-swift-concurrency) | 1 |
| AI 활용 개발, 디자인 시스템 적용 등 적극 활용 및 비판적 검증 | [§4](#4-ai-활용-개발--비판적-검증) | 병행 |
| 레거시 → 최신 아키텍처로 대규모 리팩토링 | [§5](#5-레거시--최신-아키텍처-대규모-리팩토링) | 4 (읽기 전용) |
| 공통 컴포넌트, 디자인 시스템 설계 | [§6](#6-공통-컴포넌트--디자인-시스템-설계) | 3 |

---

## 로드맵 (의존성 순서)

```
Phase 0 ── 언어 코어 (§1 전반부)
   │        value/reference semantics · 프로토콜 · 제네릭 · result builder
   │  통과 기준: 제네릭 + PAT로 공통 컴포넌트 시그니처를 직접 설계할 수 있다
   ▼
Phase 1 ── SwiftUI 렌더링 모델 (§1 후반부) + Swift Concurrency (§3)
   │        body 재평가 · 상태 무효화 범위 · 레이아웃 협상 │ async/await · actor · Sendable
   │  통과 기준: 불필요한 body 재계산을 Instruments로 찾아 고칠 수 있다
   │            + Swift 6 strict concurrency 경고를 우회 없이 해소할 수 있다
   ▼
Phase 2 ── 아키텍처 비교 (§2)
   │        MVVM → Clean 경계 → TCA
   │  통과 기준: 같은 화면 하나를 3가지로 구현하고 트레이드오프를 수치로 말할 수 있다
   ▼
Phase 3 ── 디자인 시스템 · 공통 컴포넌트 설계 (§6)
   │        토큰 계층 · 컴포넌트 API · 접근성 · 스냅샷 테스트
   │  통과 기준: variant enum 폭발 없이 확장 가능한 컴포넌트 API를 설계·문서화할 수 있다
   ▼
Phase 4 ── 대규모 리팩토링 (§5) ─ 읽기 전용 트랙, 실습 없음
            공개된 회사 사례를 읽고 의사결정 근거를 갖춘다
            통과 기준: "지금 이 코드베이스를 재작성해야 하나?"에 사례를 근거로 답할 수 있다

전 구간 병행 ── AI 활용 개발 + 비판적 검증 (§4)
                각 Phase의 산출물을 AI로 가속하고, 그 결과를 반드시 검증한다
```

**왜 이 순서인가**

- Phase 0이 먼저인 이유: SwiftUI의 `@State` 무효화, `@ViewBuilder`, 컴포넌트 제네릭 API는 전부 언어 기능 위에 얹힌 것. 언어를 건너뛰면 "왜 이렇게 쓰는지" 없이 관용구만 외운다.
- Concurrency를 Phase 1에 SwiftUI와 **같이** 두는 이유: `@MainActor`와 View 갱신은 분리해서 배우기 어렵다. 실제 버그도 둘의 경계에서 난다.
- 아키텍처가 Phase 2인 이유: 상태 무효화 범위를 모르면 "MVVM이 왜 느린지 / TCA 상태 합성이 왜 필요한지"를 판단할 근거가 없다.
- 리팩토링이 마지막인 이유: 이행의 **목표 지점**(Phase 2~3)을 모르면 사례를 읽어도 "무엇으로 옮겼는지"가 안 읽힌다.
- 리팩토링만 실습이 없는 이유: 대규모 리팩토링은 **규모·조직·기간이 조건**이라 개인 실습으로 재현되지 않는다. 축소판 실습은 오히려 "쉽다"는 잘못된 감각을 남긴다. 대신 남이 지불한 비용을 읽는다.

---

## 1. Swift / SwiftUI

### 1-A. 언어 코어 (Phase 0)

> 📄 학습 문서: [Swift/phase0-language-core.md](Swift/phase0-language-core.md) — 아래 항목 전부 + 통과 기준 실습(Button 96조합 해체). 코드는 Swift 6.3.3에서 실행 검증됨

- value/reference semantics, copy-on-write, `struct` vs `class` 선택 기준
- 옵셔널 처리 관용구, `Result`, `throws` / typed throws, 에러 전파 설계
- 프로토콜: associated type(PAT), `some` vs `any`, existential 비용, 프로토콜 지향 설계의 한계
- 제네릭: 제약 조건, 조건부 준수(`extension Array where Element: ...`), opaque type
- `@resultBuilder` 동작 원리 — `@ViewBuilder`가 왜 그렇게 생겼는지
- 메모리: `weak`/`unowned`, 클로저 캡처 리스트, 순환 참조 실제 사례

### 1-B. SwiftUI (Phase 1)

> 📄 학습 문서: [Swift/phase1-swiftui-rendering.md](Swift/phase1-swiftui-rendering.md) — 무효화 범위는 런타임 검증, 재계산 진단 절차 포함

- **렌더링 모델**: View는 값 타입 · body가 재평가되는 조건 · diffing과 `Identifiable`
- **상태**: `@State` / `@Binding` / `@Observable`(Observation) / `@Environment` — 각각의 무효화 **범위** 차이
- **레이아웃**: 부모→자식 제안 크기 협상 3단계, `Layout` 프로토콜 직접 구현, `alignmentGuide`, `GeometryReader` 남용 문제
- **성능**: Instruments SwiftUI 템플릿으로 body 과다 호출 추적, `Equatable` View, `LazyVStack` 재사용, 대형 리스트 스크롤 히칭
- **네비게이션**: `NavigationStack` + path 기반 라우팅, 딥링크 복원
- **UIKit 상호운용**: `UIViewRepresentable` / `UIHostingController` 경계, 제스처·포커스 충돌

### 참고 자료

**먼저 볼 것 (1개만 고른다면)**
- 🎬 [Demystify SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10022/) (WWDC21) — Identity / Lifetime / Dependencies. **이 트랙에서 가장 중요한 1편.** body 재평가와 상태 무효화를 이해하는 출발점

**공식 문서**
- 📘 [The Swift Programming Language](https://docs.swift.org/swift-book/) — Phase 0 언어 코어의 기준 문서
- 📄 [Swift Evolution 대시보드](https://www.swift.org/swift-evolution/) — "이 기능이 왜 이렇게 생겼나"의 원출처(제안서 본문에 대안·트레이드오프가 적혀 있다)
- 📄 [Observation 프레임워크](https://developer.apple.com/documentation/observation)

**WWDC — 렌더링 모델·성능·레이아웃**
- 🎬 [Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/) (WWDC23) — body 과다 호출 진단. 통과 기준에 직결
- 🎬 [Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/) (WWDC23) — `ObservableObject` → `@Observable` 마이그레이션과 무효화 범위 차이
- 🎬 [Compose custom layouts with SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10056/) (WWDC22) — `Layout` 프로토콜·Grid

**책**
- 📕 [Thinking in SwiftUI](https://www.objc.io/books/thinking-in-swiftui/) (Chris Eidhof·Florian Kugler) — 저자들이 "API 레퍼런스가 아니라 **직관을 기르는 책**"이라고 명시. Phase 1 목표와 정확히 일치
- 📕 [Advanced Swift](https://www.objc.io/books/advanced-swift/) — Phase 0용. 값 의미론·제네릭·메모리
- 📚 [objc.io 책 목록](https://www.objc.io/books/) — App Architecture 등 §2에서도 쓸 것들

## 2. 아키텍처 — MVVM / Clean / TCA

### 2-A. MVVM

> 📄 학습 문서: [Architecture/phase2-mvvm.md](Architecture/phase2-mvvm.md) — 단방향 상태 흐름·Tasker·God object 방어선. 코드는 실행 검증됨

- 단방향 상태 흐름으로 정리하는 법(경량 store 패턴)
- ViewModel 생명주기, View와의 소유 관계, 테스트 경계 설정
- 흔한 실패: ViewModel이 God object 되기, View 로직 누수

### 2-B. Clean / Layered

> 📄 학습 문서: [Architecture/phase2-clean-layered.md](Architecture/phase2-clean-layered.md) — 6레이어·경계 강제 스크립트·DTO 매핑 위치를 실물로 정리

- Entity – UseCase – Repository 경계, 각 레이어가 아는 것/모르는 것
- DTO ↔ Domain 매핑 위치 결정(Repository vs UseCase)
- 의존성 역전 실제 적용, 프로토콜 추상화가 과할 때의 신호

### 2-C. TCA

> 📄 학습 문서: [Architecture/phase2c-tca.md](Architecture/phase2c-tca.md) — TCA 1.26.1 실물로 같은 화면 재구현. `swift test` 8건 통과, 빌드 시간·API 표면·의존성 실측
> 🎬 영상 정리: [Architecture/ComposableArchitecture/](Architecture/ComposableArchitecture/) — Point-Free 컬렉션 14섹션 84편 완료

- `Reducer` / `Store` / `Effect` 기본 루프
- 상태 합성: `Scope`, `ifLet`, `forEach` — 큰 화면을 어떻게 쪼개는지
- 의존성 주입: `@Dependency`, 테스트용 대체 구현
- `TestStore` 기반 결정론적 테스트 — TCA의 최대 강점
- **비용도 같이 학습**: 빌드 시간, 러닝커브, 화면당 보일러플레이트, 팀 온보딩

### 2-D. 비교 & 모듈화

> 📄 학습 문서: [Architecture/phase2d-comparison.md](Architecture/phase2d-comparison.md) — 3자 구현 비교(수치)와 모듈화 실물 대조. 측정 불가한 축은 수치를 만들지 않고 명시

- 비교 축을 수치로: 테스트 용이성 / 온보딩 비용 / 컴파일 시간 / 화면당 코드량
- Tuist · SPM 멀티모듈, 순환 의존 차단, 피처 모듈 독립 실행(샘플 앱)
- 실습: **같은 화면 하나**를 MVVM / Clean+MVVM / TCA 3가지로 구현해 직접 비교

### 참고 자료

**TCA**
- 💻 [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) — 저장소. README와 함께 `Examples/` 디렉터리를 볼 것
- 🎬 [Point-Free: Composable Architecture 컬렉션](https://www.pointfree.co/collections/composable-architecture) — 설계 의도를 저자가 직접 유도해 나가는 영상. **유료지만 "왜 이 구조인가"는 여기가 원출처**
- 저장소 문서에 RIBs 등 타 패턴과의 **우선순위·트레이드오프 비교**가 있다 — 비교 축(2-D)을 세울 때 활용

**RIBs (Uber)**
- 💻 [uber/RIBs](https://github.com/uber/RIBs) — VIPER 변형, 크로스플랫폼. 2017년 오픈소스로 공개된 프레임워크 이름
  - 용어 주의: 2016년 라이더 앱 글은 **"Riblets"**로 표기한다 (Router·Interactor·Builder + Component). 같은 계보의 초기 명칭
- 📄 [Engineering the Architecture Behind Uber's New Rider App](https://www.uber.com/us/en/blog/new-rider-app-architecture/) — **[§5 사례 2와 교차]** 같은 사건을 아키텍처 관점에서 본 글
- 📄 [Architecting Uber's New Driver App in RIBs](https://www.uber.com/us/en/blog/driver-app-ribs-architecture/) — 두 번째 시도. 앞선 실패를 반영한 판단이 보인다

**읽는 법**: 아키텍처 자료는 **장점만 적혀 있다**. 각 자료를 볼 때 "이 구조가 무엇을 포기했는지"를 따로 메모할 것 — 2-D 비교 축의 재료가 된다. 채택 회사의 회고(§5)와 붙여 읽으면 균형이 잡힌다.

## 3. Swift Concurrency

> 📄 학습 문서: [Concurrency/phase1-concurrency.md](Concurrency/phase1-concurrency.md) — 데모 6개를 `-swift-version 6`(strict concurrency complete)에서 실행 검증

- **기초**: async/await 실행 모델(스레드 ≠ Task), suspension point의 의미
- **구조적 동시성**: `async let`, `TaskGroup`, Task 트리, 취소 전파와 `Task.isCancelled` / `checkCancellation()`
- **격리**: `actor`, actor reentrancy 함정(await 전후 상태 불변 아님), `@MainActor`, `nonisolated`, global actor
- **Sendable**: Swift 6 strict concurrency 마이그레이션, `@unchecked Sendable`을 언제 써도 되는지(그리고 대개 안 되는 이유)
- **AsyncSequence**: `AsyncStream` / `AsyncThrowingStream`, `URLSession.bytes`로 SSE 파싱, backpressure·버퍼링 정책
- **브리징**: `withCheckedContinuation` / `withTaskCancellationHandler`로 콜백 API 감싸기
- **Combine → Concurrency** 전환 판단 기준(무엇을 남기고 무엇을 옮길지)
- **실전 패턴**: single-flight(중복 요청 합치기), debounce, 재시도, 토큰 갱신 직렬화

### 참고 자료

WWDC 세션이 많은데, **연도순이 아니라 아래 순서로** 보는 게 낫다. 2021년 세션이 기초를 세우고, 2025년 세션이 그동안 바뀐 권장 사항을 덮어쓴다.

**1단계 — 기초 (WWDC21, 이 4편이 한 세트)**
1. 🎬 [Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/) — suspension point의 의미
2. 🎬 [Explore structured concurrency in Swift](https://developer.apple.com/videos/play/wwdc2021/10134/) — `async let`·`TaskGroup`·Task 트리·취소
3. 🎬 [Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/) — actor와 reentrancy
4. 🎬 [Swift concurrency: Behind the scenes](https://developer.apple.com/videos/play/wwdc2021/10254/) — 스레드 ≠ Task를 몸으로 이해하게 되는 편. **가장 어렵고 가장 값어치 있다**

**2단계 — 심화**
- 🎬 [Beyond the basics of structured concurrency](https://developer.apple.com/videos/play/wwdc2023/10170/) (WWDC23) — 취소 처리기와 본문 사이의 공유 상태 보호
- 🎬 [Discover concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019/) (WWDC21) · [Explore concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/266/) (WWDC25) — **Phase 1에서 SwiftUI와 Concurrency를 같이 두는 이유가 이 두 편에 있다**

**3단계 — Swift 6 / 현재 권장 사항 (여기가 통과 기준)**
- 📘 [Swift Concurrency Migration Guide (공식)](https://www.swift.org/migration/) — `minimal → targeted → complete` 단계적 이행 전략. **strict concurrency 경고를 우회 없이 해소하는 방법의 기준 문서**
- 💻 [swiftlang/swift-migration-guide](https://github.com/swiftlang/swift-migration-guide) — 위 가이드의 소스, 실행 가능한 예제 포함
- 🎬 [Migrate your app to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/) (WWDC24)
- 🎬 [Embracing Swift concurrency](https://developer.apple.com/videos/play/wwdc2025/268/) (WWDC25) — `@concurrent`·`nonisolated` 등 **최신 권장 패턴. 2021년 세션의 관용구를 일부 대체하므로 반드시 마지막에**
- 🎬 [Code-along: Elevate an app with Swift concurrency](https://developer.apple.com/videos/play/wwdc2025/270/) (WWDC25) — 따라 치는 형식
- 📄 [Swift 6: What's New and How to Migrate](https://www.avanderlee.com/concurrency/swift-6-migrating-xcode-projects-packages/) (Antoine van der Lee) — 실무 이행 절차 요약

**주의**: 2021~2023년 자료의 관용구 중 일부는 현재 권장이 아니다. 오래된 블로그 글에서 `@unchecked Sendable`이나 `DispatchQueue` 혼용을 봤다면 3단계 자료로 대조할 것.

## 4. AI 활용 개발 + 비판적 검증

*Phase 0~4 전 구간에 병행. 별도 단계가 아니라 작업 방식.*

> 📄 학습 문서: [AI/phase-parallel-ai-verification.md](AI/phase-parallel-ai-verification.md) — Phase 0~4에서 실제로 틀렸던 사례 + 탐지 수단별 커버리지. 링크 검사기 `AI/code/check_links.py` 포함

### 4-A. 활용

- 컨텍스트 설계: `CLAUDE.md` 계층, 스펙 문서 참조 구조, SoT 명시
- 태스크 분해와 병렬화, 서브에이전트를 쓸 지점과 안 쓸 지점
- 자동화 대상: 디자인 토큰 → 코드 파이프라인, 스펙 → 테스트 케이스, 코드리뷰 보조, 기계적 마이그레이션

### 4-B. 비판적 검증 (더 중요)

- **"그럴듯한 오답" 패턴 식별**: 존재하지 않는 API, 낡은 iOS 버전 가정, 근거 없는 확언, 실행되지 않은 코드에 대한 "동작 확인" 주장
- **검증 루프**: 생성 코드는 테스트/빌드/실행 출력으로만 인정. 파일 경로·명령 출력 등 구체적 근거 요구
- **근거 추적 습관**: 스펙(SoT) vs 구현 vs 파생 요약 — 세 층의 drift를 감지 (이 워크스페이스가 이미 그 구조)
- **한계 구분**: AI가 잘하는 것(기계적 치환, 보일러플레이트, 탐색) vs 못하는 것(모듈 경계 설계, 성능 트레이드오프 판단, 제품 의사결정)

### 참고 자료

- 📘 [Best practices for Claude Code (공식 문서)](https://code.claude.com/docs/en/best-practices) — `CLAUDE.md`·컨텍스트 설계·워크플로의 기준 문서
- 📄 [Claude Code best practices (Anthropic Engineering)](https://www.anthropic.com/engineering/claude-code-best-practices) — 내부 팀에서 검증된 패턴
- 📄 [How Claude Code is used in practice](https://www.anthropic.com/research/claude-code-expertise) — 실제 사용 양상 리서치. "다들 어떻게 쓰나"의 근거 자료
- 📚 [Anthropic Engineering 블로그](https://www.anthropic.com/engineering) — 에이전트 설계·컨텍스트 엔지니어링 글이 계속 올라온다

**근거 3층 구조가 그 자체로 교재다**: 스펙(SoT) → 구현 코드 → 파생 요약. 각 층에 **신뢰도 라벨**과 **"언제 기준인가"**를 붙이면 4-B의 "근거 추적"이 문서 구조로 나타난다. 실제로 어떻게 생기는지는 [§4 문서](AI/phase-parallel-ai-verification.md#4-근거-3층과-drift)에 있다.

**비판적 검증은 링크로 배울 수 없는 부분이 크다.** 위 자료는 활용법(4-A) 쪽에 치우쳐 있다. 검증 감각은 직접 틀린 출력을 잡아본 기록에서 나오므로, 겪은 사례를 아래 [링크 수집함](#링크-수집함-inbox)에 메모로 남길 것.

## 5. 레거시 → 최신 아키텍처 대규모 리팩토링

> **읽기 전용 트랙 — 실습하지 않는다.** 대규모 리팩토링은 규모·조직·기간이 조건이라 개인 실습으로 재현되지 않는다. 공개된 회사 사례를 읽고 **의사결정 근거와 어휘**를 갖추는 것이 목표.
>
> 아래 사례의 수치·기간은 각 회사 공식 엔지니어링 블로그 및 언론 보도 기준. **6건 전부 원문 대조 완료 (2026-07-31)** — 그 과정에서 내 요약 4건을 정정했다. 원문 링크는 [§5-G](#5-g-출처)에 있다.
>
> 📄 학습 문서: [Refactoring/phase4-large-scale-refactoring.md](Refactoring/phase4-large-scale-refactoring.md) — 아래 사례에서 판단 절차를 뽑아 실제 코드베이스에 적용한 결과. 재검증 내역과 정정 4건은 [§8](Refactoring/phase4-large-scale-refactoring.md#나머지-5건-원문-재검증-2026-07-31)

### 5-A. 회사 사례 6건

읽는 순서는 이 순서를 권장한다. **실패 → 성공 → 절반의 성공**으로 배열해, 뒤로 갈수록 판단이 미묘해진다.

| # | 사례 | 무엇을 | 기간 | 규모 | 결과 |
|---|---|---|---|---|---|
| 1 | **Netscape 6** (2000, Spolsky 글) | 브라우저 처음부터 재작성 | 4.0 → 6.0 사이 **약 3년 공백** | — | ❌ 그 기간 시장을 IE에 내줌. "처음부터 재작성"의 고전적 실패 사례 |
| 2 | **Uber Helix** (2016) | 라이더 앱 전면 재작성 (Obj-C → Swift, RIBs 도입) | **2015년 말** CEO가 파티에서 날짜 발표 → 2016년 중반 착수 → **11/2 공개 출시, 계획대로 완주** (9/16 사내 테스트·10/16 전사 베타는 크리스마스 앱스토어 동결에서 역산한 일정) | iOS·Android **각 100+ 엔지니어**, 플랫폼당 100만 줄+ | ⚠️ **날짜는 지켰는데** 대가가 큼 (아래 참조) |
| 3 | **Airbnb React Native** (2016–2018) | 크로스플랫폼 전환 | **약 2년** 후 철수 발표 | **220 화면**, JS **12만 줄** | ❌ 네이티브로 복귀. 단 설문에선 63%가 "다시 선택하겠다", 74%가 "신규 프로젝트엔 고려" |
| 4 | **Dropbox C++ 코드 공유** (2013–2019) | iOS/Android 로직을 C++로 공유 (Djinni 등 자체 도구) | **약 6년** 운영 후 철수 | — | ❌ 결론: "**두 번 쓰는 비용 < 공유를 유지하는 비용**". Swift/Kotlin 네이티브로 회귀 |
| 5 | **LinkedIn Operation InVersion** (2011) | 모놀리스(Leo) 모듈화 | **전사 기능 개발 2개월 전면 중단** | 엔지니어링 조직 전체 | ✅ 성공. **IPO 6개월 후** 감행 — 조직적 결단의 대표 사례. 지금은 하루 3회 배포 |
| 6 | **Shopify React Native** (2019–2023) | 전 모바일 앱 전환 | 6주 실험 → 2020 공식 선언 → **2023년 말 완료 (약 5년)** | 전 모바일 앱 | ✅ 성공. P75 화면 로드 500ms 미만, crash-free **99.9%+**. 단 스탠스는 "**100% RN은 anti-goal**" |

### 5-B. 사례별 핵심 교훈

**1. Netscape — "재작성"과 "리팩토링"은 다른 일이다**
코드가 더러워 보이는 건 대부분 **버그가 하나씩 고쳐진 흔적**이다(`"Old code has been used. It has been tested. Lots of bugs have been found, and they've been fixed."`). 재작성은 그 축적된 지식을 버리는 것. 재작성이 좌초한 흔적이 버전 번호에 남아 있다 — **`"There never was a version 5.0."`**

→ 이 글은 반박문(“Joel is Wrong”류)과 **같이** 읽을 것. 반박의 기준은 명확하다: Joel이 말한 건 **같은 세대 도구로 같은 문제를 다시 푸는 재작성**이고, 기술 세대 자체가 바뀌었다면(예: 직접 관리하던 계층을 클라우드가 흡수) 판단이 달라진다. 무조건 금지가 아니라 조건부 판단의 문제.

**2. Uber Helix — 데드라인이 먼저 정해진 재작성의 실제 비용**
- **바이너리 크기**: Swift 앱이 Obj-C 대비 몇 배로 커져, 신·구 앱 동시 번들이 Apple의 100MB OTA 한도를 넘김 → **신규 사용자 유입이 막힘**. 고성장 서비스에 치명적.
- **점진 전환 실패**: 결국 구 앱을 통째로 갈아치우는 "YOLO" 전략. 롤백 여지 없음.
- **출시 직후**: 결제 기능 오류율 **15% 상승**, 2.5시간 내 긴급 클라이언트 릴리스.
- **사람**: 번아웃과 출시 후 퇴사자 발생.
- **후속 영향**: 드라이버 앱 재작성은 **훨씬 점진적·유연한 데드라인**으로 전환. Kotlin 도입은 Swift 조기 채택 비용 때문에 크게 지연.
- → 교훈: **경영진이 날짜를 먼저 발표한 재작성**은 기술 판단이 아니다. 그리고 언어·아키텍처·UX를 동시에 바꾸면 실패 원인을 분리할 수 없다.

**3. Airbnb — 부분 도입의 숨은 비용**
원문 표현이 정확하다 — **"두 플랫폼 대신 세 플랫폼을 지원하게 됐다"**(`we wound up supporting code on three platforms instead of two`). 브리징 인프라 자체가 세 번째 플랫폼이다. 그 비용(빌드, 디버깅, 브릿지, 채용·교육)이 절감분을 잠식했다. 기술이 나빠서가 아니라 **하이브리드 상태의 유지비** 때문에 철수.
→ 교훈: 이행 중간 상태는 "임시"가 아니라 **수년간 유지될 상태**다. 그 비용을 계산에 넣어야 한다.

**4. Dropbox — 비표준을 택한 대가**
플랫폼 기본값을 벗어나면 없던 도구를 직접 만들어야 한다(Djinni, 백그라운드 실행 프레임워크, JSON 직렬화, non-null 포인터…). 그 유지보수가 중복 작성보다 비쌌다. 콜백 지옥과 디버깅 난이도도 문제.
→ 교훈: **DRY는 무료가 아니다.** 중복 제거 비용이 중복 유지 비용보다 클 수 있다.

**5. LinkedIn — 성공한 케이스의 조건**
성공 요인이 기술이 아니다. ① **Kevin Scott(당시 VP of Engineering)**이 직접 주도, ② **기능 개발 전면 중단을 조직이 승인**, ③ 2개월이라는 명확한 한계, ④ 문제가 이미 명백했음 — 배포가 **2주에 한 번**뿐이었고 프로덕션 장애가 잦았다.
→ 교훈: 대규모 리팩토링의 성공 변수는 **경영진 합의와 명시적 기간 상한**이다. 몰래 조금씩 하는 건 다른 종류의 작업이다.

**6. Shopify — 성공했는데도 "100%는 안티골"**
성공 사례도 5년이 걸렸고, 초기엔 속도를 우선해 일관성을 희생 → 팀마다 같은 문제를 재발명 → **2024년에야 공통 기반 추출**. 남은 어려움: RN 버전 업그레이드마다 상당한 작업, 서드파티 의존 증가, 디버깅 불편.
→ 교훈: 목표는 "전부 이행"이 아니라 **경계 설정**. 하드웨어 집약 기능(스캔·AI·위젯)은 네이티브로 남긴다.

### 5-C. 주의점 (사례에서 반복되는 것)

1. **재작성(rewrite) ≠ 점진 이행(migration)** — 사례 1·2는 재작성, 5·6은 점진 이행. 성공률이 갈린다.
2. **"기간이 먼저 정해진" 리팩토링은 위험 신호** — Uber는 파티에서 발표된 날짜가 기술 계획을 지배했다. 주의: Uber는 **날짜를 지켰다.** 실패의 형태가 "지연"이 아니라 "완주했는데 대가를 치름"이었다는 게 이 사례의 요점이다.
3. **중간 상태의 유지비를 계산했는가** — Airbnb 실패의 실질 원인. 두 세계 병존은 수년간 지속된다.
4. **한 번에 하나만 바꿔라** — 언어 + 아키텍처 + UX 동시 변경(Uber)은 원인 분리를 불가능하게 한다.
5. **되돌릴 경로가 있는가** — Uber는 바이너리 크기 때문에 점진 롤아웃을 못 하고 전면 교체로 내몰렸다.
6. **기능 개발과의 충돌을 조직이 인지했는가** — LinkedIn은 명시적으로 멈췄다. 안 멈추면 리팩토링이 항상 후순위로 밀린다.
7. **안전망 없는 리팩토링은 리팩토링이 아니다** — 특성화 테스트(characterization test)로 현재 동작을 먼저 고정.
8. **DRY·최신 기술 자체가 목적이 되면 실패** — Dropbox의 교훈.
9. **사람 비용** — 번아웃·퇴사는 회고에 잘 안 적히지만 실재한다(Uber).

### 5-D. 장점 (제대로 됐을 때 얻는 것)

- **배포 독립성** — 모놀리스 모듈화의 1차 목표(LinkedIn: 2주마다 터지던 배포 장애 해소)
- **기능 개발 속도** — Shopify: 플랫폼별 중복 구현 제거, 엔지니어가 웹/모바일을 넘나듦
- **플랫폼 투자의 배가 효과** — Uber: 아키텍처가 하나면 한 조직의 코드가 다른 조직에서 재사용됨(RIBs를 드라이버 앱에도 적용)
- **측정 가능한 품질** — Shopify: P75 500ms 미만, crash-free 99.9%+
- **테스트 가능성 확보** — 경계가 생기면 비로소 단위 테스트가 가능해짐
- **채용·온보딩** — 표준 아키텍처는 신규 인력 투입 비용을 낮춘다 (Dropbox가 비표준 스택에서 겪은 문제의 역)

### 5-E. 기간 감각과 추정

| 범위 | 관측된 기간 | 사례 |
|---|---|---|
| 단일 앱 전면 재작성(무리한 데드라인) | 4~5개월 | Uber Helix — 대가가 컸음 |
| 모놀리스 모듈화 (전면 집중) | 2개월 | LinkedIn — 전사 기능 개발 중단 전제 |
| 크로스플랫폼 전환 시도 후 철수 판단 | 2년 | Airbnb |
| 조직 전체 스택 이행 (점진, 성공) | 약 5년 | Shopify |
| 잘못된 전략을 유지한 기간 | 약 6년 | Dropbox |
| 처음부터 재작성의 시장 공백 | 약 3년 | Netscape |

**읽어낼 것**: 성공 사례는 "**2개월 전면 집중**"이거나 "**5년 점진**"이다. 그 사이 어중간한 기간(6개월~1년 반)에 전면 재작성을 시도한 쪽이 대체로 실패했다. — *이건 6개 사례에서 관측한 패턴일 뿐, 통계적 근거는 아니다.*

### 5-F. 개념 어휘 (사례를 논하기 위한 최소 도구)

실습은 하지 않지만, 사례를 읽고 설명하려면 아래 용어는 알아야 한다.

- **Strangler Fig** — 신규 코드만 새 구조로, 구 구조물을 서서히 감싸 대체 (Shopify형)
- **Branch by Abstraction** — 추상화를 먼저 넣고 구현을 뒤에서 교체
- **Characterization test** — 현재 동작을 있는 그대로 고정하는 테스트 (안전망)
- **Feature flag 병행 운영** — 신/구 동시 존재 + 롤백 경로
- **모듈 추출 순서** — 리프에 가까운 것부터: Design System → Core/Network → Feature
- **iOS 구체 이행 축** — UIKit → SwiftUI (`UIHostingController` 경계), Combine/RxSwift → Concurrency, 싱글톤 → DI, 거대 ViewController 분해

### 5-G. 출처

- Joel Spolsky, [Things You Should Never Do, Part I](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/) (2000) — 반론도 함께: [Joel is Wrong, and it costs you a fortune](https://medium.com/cyberark-engineering/joel-is-wrong-and-it-costs-you-a-fortune-105924be8f01)
- The Pragmatic Engineer, [Uber's Crazy YOLO App Rewrite, From the Front Seat](https://blog.pragmaticengineer.com/uber-app-rewrite-yolo/)
- Uber Engineering, [Engineering the Architecture Behind Uber's New Rider App](https://www.uber.com/us/en/blog/new-rider-app-architecture/) · [Rewrite, Update, or Migrate: Next Generation of Uber's Driver App](https://www.uber.com/blog/rewrite-uber-carbon-app/)
- Gabriel Peal (Airbnb), [Sunsetting React Native](https://medium.com/airbnb-engineering/sunsetting-react-native-1868ba28e30a) (2018, 5부 시리즈)
- Dropbox, [The (not so) hidden cost of sharing code between iOS and Android](https://dropbox.tech/mobile/the-not-so-hidden-cost-of-sharing-code-between-ios-and-android) (2019) — *원문은 자동 접근 차단(403). 브라우저로 열리며, 요약 미러: [InfoQ](https://www.infoq.com/news/2019/11/mobile-share-code-costs/) · [The Register](https://www.theregister.com/2019/08/16/dropbox_gives_up_on_sharing_c_code_between_ios_and_android/)*
- Bloomberg, [Inside Operation InVersion, the Code Freeze That Saved LinkedIn](https://www.bloomberg.com/news/articles/2013-04-10/inside-operation-inversion-the-code-freeze-that-saved-linkedin) · [IT Revolution 케이스 스터디](https://itrevolution.com/articles/case-study-linkedins-2011-operation-inversion-through-the-lens-of-slowify-simplify-and-amplify/)
- Shopify, [React Native is the Future of Mobile at Shopify](https://shopify.engineering/react-native-future-mobile-shopify) (2020) · [Five years of React Native at Shopify](https://shopify.engineering/five-years-of-react-native-at-shopify) (2025)

## 6. 공통 컴포넌트 · 디자인 시스템 설계

### 6-A. 토큰

> 📄 학습 문서: [DesignSystem/phase3-design-system.md](DesignSystem/phase3-design-system.md) — 토큰 3계층 · 대비비 실측 감사 · 조합 폭발의 두 답 · 버전 정책

- 계층: primitive → semantic → component 토큰 (왜 3층인지)
- 다크모드 / 테마 스위칭, Figma 변수 ↔ 코드 동기화 파이프라인
- 타이포그래피 스케일, 간격 스케일, 색 역할 정의

### 6-B. 컴포넌트 API 설계

- 조합(composition) vs 설정(configuration) — **variant enum 폭발 방지**
- Slot 패턴(`@ViewBuilder` 파라미터), 스타일 프로토콜(`ButtonStyle` 식 확장 지점)
- 기본값 정책, 필수/옵션 파라미터 경계
- 승격 기준: 언제 공통 컴포넌트가 되는가(사용 2회? 3회?), 예외 허용 방식

### 6-C. 품질

- **접근성**: Dynamic Type 대응 레이아웃, VoiceOver 라벨/트레잇, 색 대비, reduce motion
- **모션**: 토큰화된 duration/easing, 화면 전환 일관성
- 스냅샷 테스트, 카탈로그/데모 앱, 컴포넌트 문서화
- 버전 정책과 breaking change 관리

### 참고 자료

**토큰 (표준)**
- 📘 [Design Tokens Format Module](https://www.designtokens.org/tr/drafts/format/) — W3C DTCG 표준. `$value`·`$type`·`$description` 필수 속성과 토큰 타입(color, dimension, fontFamily, fontWeight, duration, cubicBezier) 정의. **2025-10-28에 첫 안정 버전(2025.10) 발표** — 6-A의 기준으로 삼을 것
- 📄 [첫 안정 버전 발표문](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/) · 🏠 [designtokens.org](https://www.designtokens.org/) · 💻 [DTCG 저장소](https://github.com/design-tokens/community-group)
- 📄 [Style Dictionary — DTCG 지원](https://styledictionary.com/info/dtcg/) — 토큰 → 플랫폼별 코드 변환 도구. 6-A 파이프라인의 실물

**컴포넌트 API 설계 — Nathan Curtis (EightShapes)**
이 사람 글이 6-B의 핵심이다. 디자인 시스템을 **API로 다루는** 관점.
- 📄 [Crafting Component API, Together](https://medium.com/eightshapes-llc/crafting-ui-component-api-together-81946d140371) — anatomy / properties / layout 3축으로 API를 정리. **variant enum 폭발 문제의 정면 해법**
- 📄 [Subcomponents](https://medium.com/eightshapes-llc/subcomponents-753ce9f6600a) — "통제를 내려놓고 부품을 제공한다" = slot 패턴의 설계 논리
- 📄 [Component Specifications](https://medium.com/eightshapes-llc/component-specifications-1492ca4c94c) — 스펙에 무엇을 담고 어디에 두는가. 컴포넌트 스펙 문서를 평가할 잣대
- 📄 [Principles of Design Systems](https://eightshapes.com/articles/principles-of-designing-systems/)

**플랫폼 가이드라인·접근성**
- 📘 [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) — 특히 Accessibility·Typography·Layout 항목
- 📘 [Apple Accessibility for Developers](https://developer.apple.com/accessibility/) — Dynamic Type·VoiceOver의 기준

**품질**
- 💻 [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) — 6-C 스냅샷 테스트의 사실상 표준

---

## 진행 체크리스트

- [x] **Phase 0** 언어 코어 — 제네릭 + PAT로 공통 컴포넌트 시그니처 설계 ([문서](Swift/phase0-language-core.md) · [§7 실습](Swift/phase0-language-core.md#7-통과-기준-실습--button-96조합-해체)). Button 96조합을 축 분해하고, **확장 가능성 주장을 실제 확장으로 확인** — 축 3개 추가에 기존 코드 0줄 수정(git 판정), 테스트 6건. 렌더 정확성은 `fileprivate` 제약으로 검증 불가 → Phase 3 스냅샷으로 넘김
- [x] **Phase 1a** SwiftUI 렌더링 모델 — body 재계산 추적·수정 ([문서](Swift/phase1-swiftui-rendering.md) · [§7 실측](Swift/phase1-swiftui-rendering.md#절차를-실제로-돌렸다-2026-07-31)). UI 호스트를 만들어 과잉 무효화를 찾고 고치고 다시 쟀다 — 부모 body 10회 → 잎 뷰 10회로 서브트리 축소. **행 body 는 0회**라 통념과 달랐다. ⚠️ Instruments SwiftUI 템플릿은 이 환경(macOS·SPM)에서 데이터를 내지 않아 `OSSignposter`로 우회했다 (두 측정 일치)
- [x] **Phase 1b** Concurrency — Swift 6 strict concurrency 경고 우회 없이 해소 ([문서](Concurrency/phase1-concurrency.md) · [§7 이행 실습](Concurrency/phase1-concurrency.md#이행을-실제로-해봤다-2026-07-31)). Swift 5 모듈을 올려 진단 6건을 우회 없이 해소, `verify_migration.sh` 8건 통과. **진단은 파도로 온다**(타입체커 4 → SIL 2)는 것과 **`-typecheck`이 SIL 진단을 0건 잡는다**는 걸 확인. 대규모 이행의 난이도와 런타임 정합성(TSan)은 미검증
- [x] **Phase 2** 아키텍처 — 같은 화면 3가지 구현 + 트레이드오프 수치화 ([§2-A](Architecture/phase2-mvvm.md)·[§2-B](Architecture/phase2-clean-layered.md)·[§2-D](Architecture/phase2d-comparison.md)). **TCA 실물까지 붙여 컴파일 시간·러닝커브·lock-in을 닫았다** ([§2-C](Architecture/phase2c-tca.md)) — 증분 빌드 9.51s vs 1.15s, API 표면 22개 vs 9개. 팀 온보딩 비용만 원리적으로 측정 불가로 남는다
- [x] **Phase 3** 디자인 시스템 — 확장 가능한 컴포넌트 API 설계·문서화 ([문서](DesignSystem/phase3-design-system.md)). 감사에서 찾은 항목을 **내 컴포넌트에서 닫았다** — 대비비를 회귀 가드로([§4](DesignSystem/phase3-design-system.md#실제로-닫은-것-2026-07-31)), 스냅샷을 붙이고 토큰을 깨뜨려 회귀 검출을 실증([§5](DesignSystem/phase3-design-system.md#붙였다-2026-07-31)). 버전 정책까지 붙여 §6-C를 닫았다. ⚠️ Dynamic Type은 컴파일되는 코드를 썼으나 **macOS에 Dynamic Type이 없어 스케일 동작은 검증되지 않음** — 남은 하나는 플랫폼 한계다
- [x] **Phase 4** 리팩토링 (읽기 전용) — 사례 6건 완독, "재작성 vs 점진 이행" 판단 근거 확보 ([문서](Refactoring/phase4-large-scale-refactoring.md)). 판단 절차 + 실제 적용 + **원문 재검증 완료** — 확인 14건, [정정 4건](Refactoring/phase4-large-scale-refactoring.md#나머지-5건-원문-재검증-2026-07-31)
  - [x] 1 Netscape (+반론) · [x] 2 Uber Helix · [x] 3 Airbnb · [x] 4 Dropbox *(원문 403 — InfoQ 미러 경유)* · [x] 5 LinkedIn *(Bloomberg 유료 — IT Revolution 경유)* · [x] 6 Shopify
- [x] **병행** AI 활용 + 검증 — 각 Phase 산출물에 검증 루프 적용 ([문서](AI/phase-parallel-ai-verification.md)). Phase 0~4 전 구간에서 사례 누적, 탐지 수단 표·체크리스트에 반영. 새로 드러난 종류: **관측 장치가 죽어 있는 것**(0이 "없다"인지 "못 쟀다"인지) · **검사 도구가 통과시킨 미통과**(`-typecheck`) · **요약의 각색**. *진행형 트랙이라 완료가 아니라 "이번 사이클 반영 완료"다*

---

## 다음 사이클 (2026-07-31~)

Phase 0~4가 전부 닫히면서 **"다음에 뭘 하나"가 문서에 없어졌다.** 로드맵을 새로 만들 필요는 없다 — 위 6개 트랙을 진행하며 **§1~§6에 적어놓고 문서로 옮기지 않은 항목**과 **각 문서가 스스로 남긴 미검증 항목**이 그대로 다음 할 일이다.

원칙: 새 주제를 늘리지 않는다. **이미 약속한 것을 닫는다.**

### 2-1. 커버리지 구멍 — 항목은 있는데 문서가 없다

리포 전수 grep으로 확인한 것들(2026-07-31). 실행·타 레포 없이 문서 작업만으로 닫힌다.

- [x] **§1-B UIKit 상호운용** → [Swift/phase1-swiftui-rendering.md](Swift/phase1-swiftui-rendering.md#uikit-상호운용). `UIViewRepresentable`/`UIHostingController` 경계, 제스처·포커스 충돌. ⚠️ macOS에 UIKit이 없어 **컴파일 검증 불가** — 전부 신뢰도 라벨로 처리
- [x] **§3 Combine → Concurrency 전환 판단 기준** → [Concurrency/phase1-concurrency.md](Concurrency/phase1-concurrency.md#combine을-어디까지-옮기나). 무엇을 남기고 무엇을 옮길지의 결정 절차
- [x] **§6-C 버전 정책·breaking change 관리** → [DesignSystem/phase3-design-system.md](DesignSystem/phase3-design-system.md#버전-정책과-breaking-change)
- [x] **§4-A 자동화 대상 4종** → [AI/phase-parallel-ai-verification.md](AI/phase-parallel-ai-verification.md#자동화한-것과-안-한-것). 토큰→코드 파이프라인 · 스펙→테스트 케이스 · 코드리뷰 보조 · 기계적 마이그레이션
- [ ] **§6-A 다크모드 / 테마 스위칭** — 문서 언급 0건. 예제 토큰 세트에 라이트/다크 두 벌을 넣고 스냅샷으로 고정하는 데까지 갈 수 있다
- [ ] **§6-C 모션 토큰화**(duration/easing, 화면 전환 일관성) — 목차 한 줄만 있고 본문 없음. reduce motion 분기까지 같이 다룰 것

### 2-2. 있는 내용의 재정리

- [x] **§2 탐지 수단 표 재귀납** — 10건 시점 표에 사례 15·18이 누락돼 있었다. 24건 기준으로 다시 만들고 [행 매핑을 기계로 검증](AI/phase-parallel-ai-verification.md#표를-다시-만들면서-나온-것)
- [x] **미검증 대장 통합** → [AI/phase-parallel-ai-verification.md](AI/phase-parallel-ai-verification.md#미검증-대장--저장소-전체). 문서 6곳에 흩어진 "확인하지 못한 것"을 한 표로
- [x] **§6-B 슬롯 패턴** → [DesignSystem/phase3-design-system.md §3](DesignSystem/phase3-design-system.md#슬롯-패턴--통제를-내려놓는-지점). 한 줄 언급뿐이었다

### 2-2b. 저장소 자체 정비 (2026-07-31)

문서 내용이 아니라 **저장소를 다시 열었을 때 길을 잃지 않게** 하는 작업.

- [x] **재현 진입점** — 검증 명령이 README 6곳에 흩어져 있었다. [`verify_all.sh`](verify_all.sh) 하나로 13개를 돌린다
- [x] **작업 규칙 문서** — 라벨 규칙·`-typecheck` 금지·수치 중복 금지가 문서 곳곳에 흩어져 있었다. [`CLAUDE.md`](CLAUDE.md)에 모았다
- [x] **읽는 순서** — 루트 [README](README.md)에 증거 규칙·재현·의존성 순서를 앞에 놓았다. 문서 간 "다음은 …" 사슬도 §2-A→§2-B→§2-C→§2-D→Phase 3으로 이었다

### 2-3. 실행 환경이 필요해 열어두는 것

지금 환경에서 닫을 수 없다. **닫힌 척하지 않기 위해** 목록으로만 유지한다. 근거는 각 문서의 검증 기록 절, 전체 목록은 [미검증 대장](AI/phase-parallel-ai-verification.md#미검증-대장--저장소-전체).

- iOS 시뮬레이터/실기기: Dynamic Type 스케일 · Instruments SwiftUI 템플릿 · macOS↔iOS 결과 이식성 · Phase 0 §7 실기기 · TCA 프리뷰
- 추가 측정: TSan 런타임 검증 · `.equatable()` 효과 · 스냅샷 기계 간 재현성 · 화면 수 대비 빌드 시간 선형성
- 원리적 불가: 팀 온보딩 비용 · 오류 발견율

---

## 링크 수집함 (inbox)

공부하다 발견한 링크를 **분류·검증하지 말고 그냥 여기 던진다.** 흐름 끊는 게 더 손해다.

**형식**

```
- [ ] YYYY-MM-DD §N 제목 — URL
      왜 담았나 / 무엇을 기대하는가 (한 줄)
```

**운영 규칙**

1. **던질 때는 판단하지 않는다** — 좋은 자료인지는 읽어봐야 안다.
2. **읽고 쓸모 있었으면** 해당 섹션 `참고 자료`로 **옮긴다** (한 줄 평 붙여서). 여기서는 지운다.
3. **읽고 별로였으면 지운다** — "언젠가 볼 것"으로 남기지 않는다.
4. **미독 항목이 20개를 넘으면 전부 버린다.** 20개가 쌓였다는 건 수집이 학습을 대체하고 있다는 신호다. 진짜 필요한 건 다시 찾게 된다.
5. 섹션 번호를 모르면 `§?`로 둔다.

### 미분류

<!-- 아래에 추가. 예시 형식:
- [ ] 2026-08-03 §3 Swift Concurrency의 actor reentrancy 사례 — <URL>
      await 전후로 상태가 바뀌는 실제 버그를 본 적이 없어서, 구체 예시가 필요했다
-->

*(비어 있음)*

### AI 검증 사례 기록

§4-B는 링크로 배우기 어려운 영역이다. **AI가 틀렸던 순간과 그걸 어떻게 잡았는지**를 여기 남긴다. 이게 쌓이면 그 자체로 4-B의 체크리스트가 된다.

```
- YYYY-MM-DD [징후] 무엇이 그럴듯했나 → [실제] 무엇이 틀렸나 → [탐지] 어떻게 잡았나
```

<!-- 예시:
- 2026-08-05 [징후] 존재하는 것처럼 쓰인 SwiftUI 모디파이어 → [실제] iOS 26에 없는 API
             → [탐지] 빌드 실패. 그 전에 공식 문서 대조로 잡을 수 있었다
-->

기록 위치를 [AI/phase-parallel-ai-verification.md §1](AI/phase-parallel-ai-verification.md#1-실제로-틀렸던-것들)로 옮겼다.
여기와 그쪽에 같은 내용을 두면 두 사본이 어긋난다 — 그 자체가 §4-B가 경계하는 drift다.

유형별 분포와 건수는 문서 §1·§2가 SoT다. 여기 옮겨 적으면 바로 낡는다(실제로 한 번 낡았다).

변하지 않는 결론만 남긴다.

- **컴파일이 가장 많이 잡는다.** 가장 값싼 수단이라 먼저 돌린다
- **자동 수단이 전부 통과했는데 결과가 틀린 사례가 있다.** 검사 방법 자체의 결함은 출력을 읽어야만 잡힌다
- 그래서 위임되지 않는 일이 둘이다 — **출력을 읽는 일**과 **원본과 대조하는 일**
