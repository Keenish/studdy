# Phase 2-A — 경량 단방향 MVVM

[study_list.md](../study_list.md) §2-A의 정리.

- **범위**: 단방향 상태 흐름 · ViewModel 생명주기와 소유 관계 · 테스트 경계 · 흔한 실패
- **코드**: [`Architecture/code/phase2/`](code/phase2/) — 리포 루트에서 `swift -swift-version 6 Architecture/code/phase2/mvvm_vs_clean.swift`
- **근거**: 아래 인용은 전부 **이 저장소의 실행되는 코드**다. 문서에 붙인 출력도 실제 출력이다

선행: [Phase 1a](../Swift/phase1-swiftui-rendering.md)(무효화 범위), [Phase 1b](../Concurrency/phase1-concurrency.md)(actor·취소).

---

## MVVM이 무너지는 세 지점

MVVM은 규율이 약한 패턴이다. 강제하는 게 거의 없어서 아래 셋이 반복해서 생긴다. 이 문서는 각각을 어떻게 막는지를 본다.

- **ViewModel이 God object가 된다** — 화면 상태 + 비즈니스 규칙 + 네트워크 + 내비게이션이 한 클래스에 쌓인다
- **상태 변경 경로를 추적할 수 없다** — 어디서 무엇이 바뀌었는지 모르면 상태 머신을 테스트할 수 없다
- **View에 로직이 새어나간다** — 뷰가 조건을 계산하기 시작하면 그 로직은 테스트 밖으로 나간다

---

## 1. 단방향을 타입으로 강제한다

### 형태

```
View ──sendAction(.retryTapped)──▶ ViewModel
                                     │  (Action 처리)
                                     ▼
                                 State 갱신  ◀── Tasker (async: 네트워크)
                                     │
                                     ▼
                         View 자동 리렌더 (@Observable)
```

`@Observable` ViewModel + `State` struct + `Action` enum + `Tasker` 조합. 외부 라이브러리가 없다.

### 구현

[`code/phase2/mvvm_vs_clean.swift`](code/phase2/mvvm_vs_clean.swift):

```swift
@MainActor
@Observable
final class MVVMCountryViewModel {
    struct State {
        var query = ""
        var countries: [CountryDTO] = []
        var isLoading = false
        var errorMessage: String?

        /// 표시용 파생 값. 정렬 규칙이 ViewModel 안에 있다.
        var visible: [CountryDTO] { ... }
    }

    enum Action {
        case appeared
        case queryChanged(String)
        case retryTapped
    }

    private(set) var state = State()

    func sendAction(_ action: Action) {
        switch action {
        case .appeared, .retryTapped: load()
        case let .queryChanged(text): state.query = text
        }
    }
}
```

### 여기서 실제로 일을 하는 것

- **`private(set) var state`** — View는 읽을 수만 있다. 쓰기 경로가 `sendAction` 하나로 좁혀진다. 규율을 문서가 아니라 **접근 제어로** 강제한다
- **`State`를 struct로** — 상태 전체가 하나의 값이다. 스냅샷을 찍어 비교할 수 있고, [Phase 1a §2](../Swift/phase1-swiftui-rendering.md#2-무효화-범위는-래퍼마다-다르다)의 무효화 범위가 프로퍼티 단위로 잡힌다
- **`Action`을 enum으로** — 화면이 받을 수 있는 입력이 전수 나열된다. 새 상호작용을 추가하면 `switch`가 컴파일 에러로 알려준다
- **파생 상태를 State 안의 계산 프로퍼티로** — `visible`이 View가 아니라 State에 있다. View에 로직이 새는 걸 막는 자리다

### `@MainActor`가 붙는 이유

- 상태 변이가 전부 메인 액터에서 일어나야 뷰 갱신과 경쟁하지 않는다
- Swift 6에서는 이게 선택이 아니다. `@Observable` 상태를 뷰가 읽는 순간 격리가 요구된다
- 대가: ViewModel의 모든 메서드가 메인 액터에 묶인다. 무거운 계산은 `nonisolated` 함수나 다른 액터로 빼야 한다

---

## 2. async를 상태 변이와 분리한다

### 문제

ViewModel 안에서 `Task { }`를 직접 만들면 세 가지가 곧 엉킨다.

- 중복 탭으로 같은 요청이 두 번 나간다
- 화면을 벗어났는데 작업이 살아 있다
- 어떤 작업이 돌고 있는지 알 방법이 없다

### Tasker — key로 수명을 관리한다

```swift
@MainActor
final class Tasker {
    private var tasks: [String: Task<Void, Never>] = [:]

    /// 같은 key 작업이 돌고 있으면 취소하고 대체한다(중복 탭 방지).
    func run(_ key: String, _ operation: @escaping @MainActor @Sendable () async -> Void) {
        tasks[key]?.cancel()
        tasks[key] = Task { @MainActor [weak self] in
            await operation()
            self?.tasks[key] = nil
        }
    }
}
```

- key 하나로 "이 화면의 목록 조회"를 식별한다. 중복 탭은 이전 작업을 **취소하고 대체**한다
- 화면 이탈 시 일괄 취소도 같은 dictionary 하나로 된다
- 클로저가 `@MainActor`라 작업 완료 후 상태 변이가 메인에서 이어진다

### 중복 요청 처리는 두 갈래다 — 대체냐 합류냐

[Phase 1b §4](../Concurrency/phase1-concurrency.md#4-actor와-reentrancy)의 single-flight와 비교하면 선택이 보인다.

| | Tasker (대체) | single-flight (합류) |
|---|---|---|
| 같은 요청이 또 오면 | 이전 것을 취소하고 새로 시작 | 진행 중인 것에 붙어 결과를 공유 |
| 맞는 상황 | 사용자 입력. 마지막 의도가 유효하다 | 캐시·토큰 갱신. 결과가 같으면 한 번만 하면 된다 |
| 잘못 쓰면 | 매 입력마다 요청을 버려 응답이 안 온다 | 취소하고 싶은데 옛 요청이 계속 산다 |

같은 "중복 방지"라는 말로 뭉뚱그리면 안 된다. **입력이면 대체, 조회면 합류**가 기본이다.

### 취소를 실패로 취급하지 않는다

```swift
} catch is CancellationError {
    state.isLoading = false                          // 조용히 정리
} catch {
    state.errorMessage = "목록을 불러오지 못했어요."   // 사용자에게 알림
}
```

취소는 사용자가 의도한 것이거나 화면 이탈이다. 여기서 에러 토스트를 띄우면 정상 동작이 오류로 보인다. [Phase 1b §3](../Concurrency/phase1-concurrency.md#3-취소는-협조적이다)의 협조적 취소가 UI에 닿는 자리다.

---

## 3. 일회성 이벤트를 상태로 표현한다

토스트·알럿·화면 전환처럼 "한 번만 일어나야 하는 것"은 상태와 잘 안 맞는다. 상태는 지속되고 이벤트는 소비되기 때문이다.

```swift
var pendingMessage: String?          // 표시 대기 중인 메시지(one-shot)

case .messagePresented:
    state.pendingMessage = nil       // View가 띄운 뒤 소비를 알린다
```

- 이벤트를 **소비 가능한 상태**로 바꾼다. `nil`이 아니면 표시 대기, 표시 후 View가 `.messagePresented`를 보내 비운다
- 소비를 View가 알려주므로 단방향이 유지된다. ViewModel이 View를 호출하지 않는다
- 대안은 별도 이벤트 스트림(`AsyncStream`)이지만 상태 하나로 되는 일에 채널을 추가할 이유는 적다

`[중]` 실습 코드는 `errorMessage`를 재시도로 덮어쓰는 데서 멈췄다. 위 소비 프로토콜까지는 구현하지 않았다.

---

## 4. 내비게이션을 ViewModel에 넣지 않는다

```swift
private let onFinished: () -> Void

init(transport: CountryTransport, onFinished: @escaping () -> Void) { ... }
```

- ViewModel은 "끝났다"만 알린다. **어디로 갈지는 모른다**
- 부모(라우터/코디네이터)가 클로저를 꽂아 결정한다. 같은 화면을 다른 흐름에서 다른 목적지로 재사용할 수 있다
- 테스트에서는 클로저가 불렸는지만 보면 된다. 내비게이션 스택을 흉내낼 필요가 없다

대가도 있다. 클로저를 프로퍼티로 들고 있으면 [Phase 0 §6](../Swift/phase0-language-core.md#6-참조-순환)의 순환 참조 후보가 되고, [Phase 1a §3](../Swift/phase1-swiftui-rendering.md#3-재평가를-끊는-세-가지-방법)에서 본 것처럼 `Equatable`을 만들 수 없다.

`[중]` 이 절은 패턴 서술이다. 실습 코드의 ViewModel에는 내비게이션 클로저가 없다.

---

## 5. 확인 — 같은 화면을 이 패턴으로

국가 선택 화면(목록 조회 · 검색 · 로딩/실패/재시도)을 만들어 돌렸다.

```swift
vm.sendAction(.appeared)
await vm.waitForLoad()
vm.sendAction(.retryTapped)
vm.sendAction(.queryChanged("국"))
```

```
[A] 경량 단방향 MVVM
  로딩 시작: isLoading=true
  첫 시도 실패: error=목록을 불러오지 못했어요.
  재시도 성공: ["KR", "US", "GB", "JP"]
  '국' 필터: ["KR", "US", "GB"]
```

### 여기서 나온 발견 — async 상태를 검증하려면 완료를 기다릴 수단이 필요하다

`sendAction`은 즉시 반환하고 실제 작업은 `Tasker`가 돌린다. 테스트에서 결과를 보려면 완료를 기다려야 하는데, `Tasker`에는 그 창구가 없다. 실습 코드에서 하나 추가했다.

```swift
/// 테스트에서 완료를 기다리기 위한 창구. 실제 코드에는 없다.
func wait(_ key: String) async { await tasks[key]?.value }
```

- 이게 경량 MVVM이 지불하는 비용이다. 단방향 구조는 얻었지만 **비동기 완료 시점을 테스트가 알 방법을 직접 만들어야 한다**
- TCA의 `TestStore`가 해결하는 문제가 정확히 이것이다. 액션을 보내고 이펙트가 끝날 때까지 결정론적으로 기다린다
- §2-D 비교에서 "테스트 용이성" 축의 실질 내용이 여기다. 문법 편의가 아니라 **결정론을 누가 제공하는가**의 차이

---

## 6. God object를 막는 방어선

커지는 신호와 처방:

| 신호 | 처방 |
|---|---|
| `Action` 케이스가 15개를 넘는다 | 화면을 쪼갠다. 한 화면에 두 개의 관심사가 있을 가능성 |
| `State`에 서로 무관한 필드 묶음이 보인다 | 하위 State struct로 분리 → 나중에 하위 뷰로 승격 |
| ViewModel이 DTO 필드명을 안다 | Domain 레이어가 필요하다 ([§2-B](phase2-clean-layered.md)) |
| 정렬·필터·검증 규칙이 State 계산 프로퍼티에 쌓인다 | UseCase로 내린다 |
| `Tasker` key가 5개를 넘는다 | 한 화면이 너무 많은 외부 작업을 조율하고 있다 |

세 번째 신호가 실습 코드에 이미 있다. `MVVMCountryViewModel.State.visible`이 `country_name`·`country_code`를 직접 읽는다 — **서버가 필드명을 바꾸면 화면 로직이 깨진다.** 정렬 규칙(한국 우선)도 여기 얹혀 있다. 둘 다 [§2-B](phase2-clean-layered.md)에서 Domain으로 내리는 대상이다.

---

## 7. 이 패턴을 언제 고르나

[§2-D](phase2d-comparison.md)에서 같은 화면을 세 가지로 만들어 비교한 결과가 판단 근거다.

| 조건 | 판단 |
|---|---|
| 상태 전이가 단순하고 화면 수가 적다 | 순수 SwiftUI MV로 충분하다. 이 패턴도 과하다 |
| 명시적 상태 머신이 여럿이고 회귀 테스트가 필요하다 | **경량 단방향 MVVM.** 라이브러리 무게 0으로 전이를 추적 가능하게 만든다 |
| 전수 상태 검증·이펙트 결정론이 요구된다 | TCA. §5에서 본 "완료를 기다릴 수단"을 직접 만들지 않아도 된다 ([§2-C](phase2c-tca.md)) |

**되돌리기 비용이 큰 결정이다.** 이 패러다임은 모든 화면 코드의 모양을 규정하므로, 나중에 바꾸면 이미 짠 화면을 재작성해야 한다. 아키텍처 결정은 되돌리기 비싼 것부터 확정한다.

---

## 8. 스스로 물어볼 것

- `private(set) var state`가 막는 것은 무엇인가. 없으면 어떤 코드가 가능해지는가 (§1)
- 파생 상태를 View가 아니라 State에 두는 이유 (§1)
- 중복 요청에서 대체와 합류를 어떻게 고르는가 (§2)
- 취소를 실패로 처리하면 사용자에게 무엇이 보이는가 (§2)
- 일회성 이벤트를 상태로 표현하면서 단방향을 유지하는 방법 (§3)
- ViewModel이 내비게이션을 모르게 하면 테스트가 어떻게 쉬워지는가 (§4)
- 이 패턴에서 비동기 결과를 테스트하려면 무엇이 추가로 필요한가 (§5)
- ViewModel이 커지고 있다는 신호 세 가지 (§6)

---

## 9. 검증 기록

### 환경

```
swift-driver version: 1.148.6 Apple Swift version 6.3.3
Target: arm64-apple-macosx26.0
```

### 실행한 것

| 대상 | 명령 | 결과 |
|---|---|---|
| §5 같은 화면 구현 (A·B 동시) | `swift -swift-version 6 Architecture/code/phase2/mvvm_vs_clean.swift` | 실행, 경고 0. 출력을 그대로 인용 |

### 확인하지 못한 것

| 주장 | 상태 |
|---|---|
| §6 God object 임계값(Action 15개, Tasker key 5개) | **경험 규칙 [저]**. 측정된 기준이 아니라 판단 촉발점으로만 쓸 것 |
| 실제 앱 규모에서 이 패턴의 유지보수 비용 | **미검증 [저]**. 화면 하나짜리 실습이다 |
| §3 일회성 이벤트 소비 프로토콜 | **미구현 [중]**. 패턴만 서술했고 실습 코드에는 없다 |
| §4 내비게이션 클로저 | **미구현 [중]**. 같음 |
| TCA와의 컴파일 시간·러닝커브 비교 | [§2-C](phase2c-tca.md)에서 실물로 측정했다 |

---

## 참고 자료

- 📚 [objc.io — App Architecture](https://www.objc.io/books/app-architecture/) — MVVM을 포함한 패턴별 같은 앱 구현 비교. §2-D 비교 축의 원형
- 🎬 [Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/) — `@Observable` ViewModel의 갱신 범위

다음은 [§2-B — Clean / Layered](phase2-clean-layered.md). 이 문서의 §6에서 "Domain이 필요하다"고 미룬 것들을 거기서 다룬다.
