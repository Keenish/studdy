# Phase 1b — Swift Concurrency

[study_list.md](../study_list.md) §3의 정리.

- **통과 기준**: Swift 6 strict concurrency 경고를 우회 없이 해소할 수 있다 → [§7](#7-통과-기준--sendable과-swift-6-이행)
- **코드**: 이 문서의 데모는 전부 `-swift-version 6`으로 컴파일·실행했다. 경고 0. 인용한 출력은 실제 실행 결과다
- **전체 소스**: [`Concurrency/code/phase1/`](code/phase1/) — 리포 루트에서 `swift -swift-version 6 Concurrency/code/phase1/concurrency_demo.swift`
- **이행 실습**: [`Concurrency/code/phase1b/`](code/phase1b/) — Swift 5 모듈을 우회 없이 Swift 6로 올린다. `bash Concurrency/code/phase1b/verify_migration.sh` ([§7](#이행을-실제로-해봤다-2026-07-31))

같이 볼 것: [Phase 1a — SwiftUI 렌더링 모델](../Swift/phase1-swiftui-rendering.md). 실제 버그는 `@MainActor`와 뷰 갱신의 경계에서 난다.

---

## 왜 SwiftUI와 같은 Phase에 두는가

따로 배우기 어렵다. 화면 갱신은 메인 액터에서 일어나고, 데이터는 다른 액터에서 온다. 둘의 경계가 곧 버그 위치다.

- 로딩 중 화면이 멈춘다 → 어디서 메인을 붙잡고 있나
- "Publishing changes from background thread" → 격리를 어긴 것
- Swift 6로 올리니 경고가 수백 개 → 경계를 명시하지 않고 써왔다는 뜻

---

## 1. Task는 스레드가 아니다

### 이런 데서 물린다

- `DispatchQueue`의 감각으로 `Task`를 쓰다가 "왜 이 스레드가 아니지"에서 막힌다
- `await` 앞뒤가 같은 스레드라고 가정한 코드를 쓴다

### 확인

```swift
var observed: Set<UInt64> = [threadID()]
for _ in 0..<20 {
    try? await Task.sleep(for: .milliseconds(1))
    observed.insert(threadID())
}
```

```
20회 suspend/resume 중 관측된 스레드 수: 2
```

- `await`는 "이 스레드를 붙잡는다"가 아니라 **"여기서 놓아준다"**는 뜻이다
- 재개 스레드는 보장되지 않는다. 위 결과가 2였지만 1일 수도 3일 수도 있다. 보장이 없다는 게 요점이다
- 그래서 스레드에 묶인 것(스레드 로컬, 락 재진입, UIKit 접근)을 `await` 앞뒤로 가정하면 깨진다
- 붙잡고 싶은 건 스레드가 아니라 **액터**다. `@MainActor`가 그 도구다

---

## 2. 구조적 동시성

### 이런 데서 물린다

- `await`를 줄줄이 쓰고 "비동기니까 빠르겠지"라고 생각한다
- 하위 작업이 언제 끝나고 언제 취소되는지 추적이 안 된다

### 확인 — `await` 나열은 순차 실행이다

```swift
_ = await work(100)          // 순차
_ = await work(100)

async let a = work(100)      // 겹쳐 실행
async let b = work(100)
_ = await (a, b)
```

```
순차:    211ms
async let: 110ms
```

(타이밍은 실행마다 조금씩 다르다. 비율이 요점이다.)

- `await` 한 줄은 "여기서 기다린다"다. 병렬로 만들려면 `async let`이나 `TaskGroup`으로 **명시**해야 한다
- 개수가 컴파일 타임에 정해지면 `async let`, 런타임에 정해지면 `TaskGroup`

### Task 트리

- `async let`과 `TaskGroup`이 만든 자식은 부모보다 오래 살 수 없다. 스코프를 벗어나면 기다리거나 취소된다
- `Task { }`는 이 트리에서 **떨어져 나간다**(비구조적). 수명을 직접 관리해야 하고, 부모 취소가 자동으로 전파되지 않는다
- 기본은 구조적. `Task { }`는 동기 코드에서 비동기로 진입하는 경계에서만 쓴다

---

## 3. 취소는 협조적이다

### 이런 데서 물린다

- `cancel()`을 불렀는데 작업이 계속 돈다
- 화면을 벗어났는데 네트워크 요청이 살아 있다

### 확인 — 확인하지 않으면 멈추지 않는다

```swift
let ignoring = Task {
    var done = 0
    for _ in 1...5 {
        for _ in 0..<2_000_000 { done += 1 }   // suspension point가 없다
    }
    return "완주(취소 무시), isCancelled=\(Task.isCancelled)"
}
ignoring.cancel()
```

```
완주(취소 무시), isCancelled=true
```

`isCancelled`가 `true`인데도 끝까지 돌았다. `cancel()`은 **플래그를 세우는 것**이고 강제 중단이 아니다.

### 확인 — 협조하는 쪽

```swift
try Task.checkCancellation()
try await Task.sleep(for: .milliseconds(20))
```

```
취소로 종료: CancellationError
```

- `Task.sleep`, `URLSession`의 async API 같은 표준 suspension point는 취소를 확인해준다
- 긴 계산 루프에는 `try Task.checkCancellation()`을 직접 넣는다
- 취소를 에러로 던지지 않고 부분 결과를 반환하는 설계도 가능하다. `Task.isCancelled`를 보고 정하면 된다

### 확인 — 그룹은 형제에게 전파한다

```
그룹: 자식 실패 → 형제 취소 후 종료 (CancellationError)
```

`withThrowingTaskGroup`에서 자식 하나가 던지면 나머지에게 취소가 전파되고 그룹이 정리된 뒤 에러가 올라온다.

---

## 4. actor와 reentrancy

이 절이 Phase 1b에서 실무에 가장 자주 걸린다.

### 이런 데서 물린다

- actor로 캐시를 감쌌는데 같은 요청이 여러 번 나간다
- "actor니까 한 번에 하나만 실행된다"고 믿는다

### actor가 보장하는 것과 안 하는 것

- 보장: 같은 시점에 **하나의 실행만** actor 안에 있다. 데이터 경쟁이 없다
- 보장하지 않음: `await`를 만나면 actor를 **놓아준다**. 그 사이 다른 호출이 들어온다
- 그래서 `await` 앞에서 검사한 것이 뒤에서도 참이라는 보장이 없다. 이게 reentrancy다

### 확인 — check-then-act가 깨진다

```swift
actor NaiveLoader {
    private var cache: [String: String] = [:]

    func value(for key: String) async -> String {
        if let cached = cache[key] { return cached }
        // ↓ 이 await에서 actor를 놓아준다. 다른 호출이 위 검사를 똑같이 통과한다
        let fetched = await fetch(key)
        cache[key] = fetched
        return fetched
    }
}
```

동시에 5번 호출하면:

```
캐시 검사가 있는데도 fetch 횟수: 5  (동시 호출 5건)
```

캐시 코드가 아무 일도 하지 않았다.

### 확인 — 진행 중인 Task를 공유한다 (single-flight)

값을 캐시하는 대신 **작업을 캐시**한다.

```swift
actor SingleFlightLoader {
    private var cache: [String: String] = [:]
    private var inFlight: [String: Task<String, Never>] = [:]

    func value(for key: String) async -> String {
        if let cached = cache[key] { return cached }
        if let running = inFlight[key] { return await running.value }   // 합류

        let task = Task { await self.fetch(key) }
        inFlight[key] = task
        let fetched = await task.value
        cache[key] = fetched
        inFlight[key] = nil
        return fetched
    }
}
```

```
single-flight 적용 후 fetch 횟수: 1
```

- `inFlight`에 Task를 넣는 것까지가 **suspension 없이** 끝나기 때문에 중간에 끼어들 틈이 없다
- 토큰 갱신 직렬화도 같은 패턴이다. 동시에 401을 받은 요청들이 갱신 Task 하나에 합류한다
- 일반 규칙: actor 안에서 `await` 앞뒤로 상태 가정을 하지 않는다. 해야 한다면 그 상태를 **await 이전에 확정**해둔다

---

## 5. AsyncSequence와 버퍼링

### 이런 데서 물린다

- 스트림에서 값이 빠지는데 원인을 모른다
- SSE를 파싱하는데 이벤트가 누락된다

### 확인 — 정책에 따라 조용히 버려진다

```swift
let (stream, c) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .bufferingNewest(1))
for i in 1...5 { c.yield(i) }
c.finish()
```

```
.unbounded          → [1, 2, 3, 4, 5]
.bufferingNewest(1) → [5]   (나머지는 버려짐)
```

- 생산이 소비보다 빠를 때 무슨 일이 일어나는지가 **정책으로 결정**된다. 에러도 로그도 없다
- 이벤트 누락이 치명적이면 `.unbounded`, 최신 상태만 의미 있으면 `.bufferingNewest(1)`
- `.unbounded`는 메모리 상한이 없다. 생산이 계속 빠르면 그쪽이 문제가 된다
- `URLSession.bytes`로 SSE를 읽는 파이프라인이 §3의 취소와 이 절의 버퍼링을 동시에 만나는 자리다

---

## 6. 콜백 API 브리징

기존 completion handler를 그대로 두고 async 경계만 만든다.

```swift
func modernFetch() async -> String {
    await withCheckedContinuation { continuation in
        legacyFetch { continuation.resume(returning: $0) }
    }
}
```

```
콜백 → async 변환 결과: legacy-ok
```

- `resume`은 **정확히 한 번** 불려야 한다. 두 번 부르면 크래시, 안 부르면 영구 대기
- `withCheckedContinuation`은 이 위반을 런타임에 잡아준다. 릴리스 성능이 중요해지면 `withUnsafeContinuation`으로 바꾸지만 기본은 checked
- 취소를 전달해야 하면 `withTaskCancellationHandler`와 조합한다. 콜백 API 쪽에 취소 수단이 없으면 취소는 "무시"가 된다는 걸 알고 써야 한다

---

## Combine을 어디까지 옮기나

§6이 "콜백을 async로 감싸는 법"이었다면 여기는 그 앞의 질문이다 — **감쌀지 말지.** study_list §3의 "무엇을 남기고 무엇을 옮길지"에 답하는 절이다.

> ⚠️ 이 절은 **결정 절차**이지 이행 실습이 아니다. 이 저장소에 Combine 코드는 없고, 실제 Combine 파이프라인을 옮겨 본 기록도 없다. 근거는 앞 절들에서 관측한 Concurrency 쪽 성질과 Combine의 문서화된 계약이다. 라벨은 절 끝에.

### 먼저 — 옮길 이유가 하나 사라졌다

Combine을 쓰는 가장 흔한 이유는 원래 **`ObservableObject` + `@Published`** 였다. 뷰 갱신을 위해 Combine을 import했지 스트림 처리가 필요해서가 아니었다.

Observation(`@Observable`)이 그 자리를 대체했다. [Phase 1a §2](../Swift/phase1-swiftui-rendering.md#2-무효화-범위는-래퍼마다-다르다)에서 확인한 무효화 범위 차이가 그 이유다 — `@Published`는 객체 단위로 알리고, `@Observable`은 **읽은 프로퍼티 단위**로 알린다.

**그래서 "Combine → Concurrency 이행"의 상당 부분은 실은 "Combine → Observation" 이행이다.** 둘을 구분하지 않으면 async/await로 옮길 수 없는 것을 옮기려 들게 된다.

### 축은 하나다 — 소비자가 몇인가

| 모양 | 옮긴다 | 무엇으로 |
|---|---|---|
| 1회 요청 → 1회 응답 | **옮긴다** | `async` 함수. `Future`·`Deferred`가 하던 일 |
| 뷰 상태 알림 | **옮긴다** | `@Observable`. Combine이 아니라 Observation |
| 시간에 따른 값 · **소비자 1** | **옮긴다** | `AsyncStream` / `AsyncSequence` ([§5](#5-asyncsequence와-버퍼링)) |
| 시간에 따른 값 · **소비자 N** | **남긴다** | Combine의 브로드캐스트가 공짜다. `AsyncStream`은 소비자 하나가 기본이라 직접 멀티캐스트를 만들어야 한다 |
| `combineLatest`·`zip`·`merge` 조합 | **경우에 따라** | 조합 대상이 요청-응답이면 `async let`([§2](#2-구조적-동시성))이 더 짧다. 진짜 스트림 조합이면 Combine이 아직 짧다 |
| `debounce`·`throttle` | **경우에 따라** | SwiftUI 안이면 `.task(id:)` + 취소로 대체된다. 그 밖이면 직접 구현 비용을 잰다 |

**소비자가 둘 이상인 순간 이행 비용이 급격히 오른다.** Combine에서 `share()`·`multicast()`가 한 줄인 것이 Concurrency에서는 직접 짜야 하는 구조물이다. 여기가 실질적인 경계선이다.

### 옮겨서 얻는 것 — 앞 절들이 그대로 근거다

- **취소가 구조적으로 전파된다** ([§3](#3-취소는-협조적이다)). Combine에서 `AnyCancellable`을 어디에 보관했는지가 곧 수명인데, Task 트리는 부모가 죽으면 자식이 죽는다
- **격리를 컴파일러가 검사한다** ([§7](#7-통과-기준--sendable과-swift-6-이행)). Combine 파이프라인에서 `receive(on:)`을 빼먹은 것은 런타임에 드러나지만, actor 경계는 컴파일에 드러난다
- **직선 코드가 된다.** `sink` 안의 클로저 중첩이 사라지면 [사례 4](../AI/phase-parallel-ai-verification.md#4--언어-모드에-따라-나타나는-오류) 같은 격리 문제도 눈에 보인다
- **에러가 타입에 남는다.** Combine의 `Failure` 타입은 연산자를 거치며 `Error`로 뭉개지기 쉽다

### 옮겨서 잃는 것

- **브로드캐스트** (위 표)
- **동기적 현재값.** `CurrentValueSubject.value`는 지금 당장 읽힌다. `AsyncStream`에는 대응물이 없다 — 최신값이 필요하면 actor에 따로 들고 있어야 한다
- **연산자 생태계.** 15년치 관용구가 표준 라이브러리에 없다
- **backpressure 표현.** Combine은 `Demand`로 소비 속도를 위로 알린다. `AsyncStream`은 [버퍼링 정책](#5-asyncsequence와-버퍼링)으로 **조용히 버리는** 쪽을 고른다. 이건 대체가 아니라 다른 모델이다

### 그래서 절차

1. **분류부터 한다.** 위 표의 여섯 모양 중 어디인지. 코드를 열기 전에 세어 본다
2. **`@Published`만 쓰는 파일은 Combine 사용이 아니다.** Observation으로 옮기고 `import Combine`을 지운다. 여기서 대부분이 정리된다
3. **경계에서 만난다.** 전부 옮기지 않고 섞어 쓸 수 있다 — `publisher.values`로 `AsyncSequence`가 되고, 반대 방향은 `AsyncStream`을 감싸는 `Subject` 하나면 된다. §6의 브리징과 같은 발상이다
4. **남은 것은 남긴다.** 브로드캐스트·복잡한 연산자 조합은 옮기는 순간 직접 구현 부채가 된다

4번이 [§5 리팩토링](../Refactoring/phase4-large-scale-refactoring.md)의 결론과 같다 — **"한 번에 하나만 바꿔라."** 언어 모델 이행(Swift 6)과 반응형 프레임워크 이행(Combine 제거)을 동시에 하면 진단이 어느 쪽에서 온 것인지 분리되지 않는다. [§7의 실습](#이행을-실제로-해봤다-2026-07-31)에서 진단이 파도로 온 것을 봤는데, 두 이행을 겹치면 그 파도가 두 겹이 된다.

### 신뢰도

| 주장 | 상태 |
|---|---|
| `@Observable`이 `@Published`의 대체가 된다 | **확인함** — 무효화 범위 차이를 [Phase 1a §2](../Swift/phase1-swiftui-rendering.md#2-무효화-범위는-래퍼마다-다르다)에서 실측 |
| `AsyncStream`이 단일 소비자 기본, 버퍼링이 조용히 버린다 | **확인함** — [§5](#5-asyncsequence와-버퍼링)에서 실행 출력으로 |
| 취소가 구조적으로 전파된다 | **확인함** — [§3](#3-취소는-협조적이다) |
| 멀티캐스트 직접 구현 비용이 크다 | **미검증 [중]**. 짜 보지 않았다. "한 줄이 아니다" 이상은 말할 수 없다 |
| `publisher.values` 브리징이 취소·버퍼링에서 기대대로 동작 | **미검증 [저]**. Combine을 이 저장소에 들이지 않았다 |
| 실제 Combine 코드베이스 이행 난이도 | **미검증 [저]**. [Phase 1b의 Swift 6 이행](#이행을-실제로-해봤다-2026-07-31)과 같은 한계다 — 파일 하나짜리 실습조차 없다 |

---

## 7. 통과 기준 — Sendable과 Swift 6 이행

### 단계적으로 올린다

공식 가이드가 제시하는 순서다. 한 번에 `complete`로 가지 않는다.

| 단계 | 의미 |
|---|---|
| `minimal` | 명시적으로 표시한 것만 검사 |
| `targeted` | 모듈 단위로 점진 적용 |
| `complete` | 전부 검사. Swift 6 언어 모드가 이것 |

이 문서의 코드는 `-swift-version 6`으로 컴파일했다. `complete`에서 경고 0이다.

### 경고 유형별 처방

| 경고 | 원인 | 처방 |
|---|---|---|
| 전역 가변 상태가 안전하지 않다 | `var` 전역/static | `let`으로 바꾸거나, `actor`로 감싸거나, `Mutex`로 보호 |
| 비Sendable 타입이 경계를 넘는다 | class를 다른 격리로 넘김 | 값 타입으로 바꾸거나, 넘기지 않고 필요한 값만 추출 |
| 메인 액터 격리 위반 | UI 인접 타입에 표시가 없다 | 그 타입에 `@MainActor` |
| 프로토콜 준수가 격리를 넘는다 | 격리된 타입이 nonisolated 요구사항 구현 | 해당 멤버에 `nonisolated` |
| 캡처가 Sendable하지 않다 | 클로저가 가변 상태 캡처 | 캡처를 값으로, 또는 보호된 저장소로 |

### 실제로 겪은 두 가지

**프로토콜 준수 격리 —** Phase 1a에서 뷰를 `Equatable`로 만들다 막혔다. `View`는 Swift 6에서 `@MainActor`라 그 안의 `static func ==`도 격리되고, nonisolated 요구사항을 만족하지 못한다.

```
error: conformance of 'ExpensiveRow' to protocol 'Equatable'
       crosses into main actor-isolated code and can cause data races
note: main actor-isolated operator function '==' cannot satisfy nonisolated requirement
```

`nonisolated static func ==`로 해결했다. 자세한 맥락은 [Phase 1a §3](../Swift/phase1-swiftui-rendering.md#3-재평가를-끊는-세-가지-방법).

**공유 카운터 —** 데모에서 콜백 호출 횟수를 세야 했다. `var`를 클로저에서 캡처하면 `complete`에서 걸린다. `@unchecked Sendable`로 덮지 않고 `Mutex`를 썼다.

```swift
import Synchronization

let fired = Mutex(0)
... onChange: {
    fired.withLock { $0 += 1 }
}
print(fired.withLock { $0 })
```

### 우회 수단과 정당한 사용 조건

경고를 "없애는" 방법은 있다. 통과 기준은 **우회 없이** 해소하는 것이므로, 아래는 언제 정당한지까지 알고 써야 한다.

- **`@unchecked Sendable`** — "내가 직접 동기화했다"는 선언. 락으로 모든 접근을 보호한 타입에만 정당하다. 대부분의 경우 그 락이 없거나 일부 경로가 빠져 있다
- **`nonisolated(unsafe)`** — 단일 스레드에서만 접근한다는 주장. 테스트 코드나 초기화 1회 상수에 한정
- **`@preconcurrency import`** — 아직 이행되지 않은 의존성 때문에 나는 경고를 미룬다. 내 코드 문제를 덮는 데 쓰면 안 된다

세 가지 모두 **컴파일러의 검사를 끄는 것**이지 문제를 고치는 게 아니다. 쓸 때는 이유를 주석으로 남긴다.

### 이행을 실제로 해봤다 (2026-07-31)

위 표는 공식 가이드 요약이었다. 실제로 이행해 보려고 **Swift 5 시절 관용구로 쓴 작은 피처 모듈**을 만들고([`code/phase1b/legacy_service.swift`](code/phase1b/legacy_service.swift)) Swift 6로 올렸다. 전역 토큰 · 싱글턴 캐시 · 콜백 재시도 · 화면 상태 클래스 — 억지 예제가 아니라 흔한 모양이다.

```
bash Concurrency/code/phase1b/verify_migration.sh     # 8건 검사 전부 통과
```

스크립트가 "우회하지 않았다"까지 강제한다 — `@unchecked Sendable`·`nonisolated(unsafe)`·`@preconcurrency`를 `grep`으로 세서 0이 아니면 실패시킨다.

#### 진단은 파도로 온다

가장 중요한 발견이다. **첫 컴파일이 일의 전부를 보여주지 않는다.**

| 파도 | 건수 | 낸 주체 | 내용 |
|---|---|---|---|
| 1차 | **4** | 타입체커 | 전역 `var` · `static var` · 비Sendable 싱글턴 · 준수 격리 |
| 2차 | **2** | SIL 패스 | `#SendingClosureRisksDataRace` × 2 |

1차 4건이 남아 있는 동안 2차는 **보이지 않는다.** 타입 검사가 실패하면 SIL 생성이 아예 돌지 않기 때문이다. 1차를 눌러 놓은 표본([`wave2_probe.swift`](code/phase1b/wave2_probe.swift))으로 확인했다.

이행 규모를 첫 컴파일의 에러 수로 추정하면 **과소평가한다.**

#### `-typecheck`으로는 절반을 못 잡는다

2차 진단은 SIL 패스가 낸다. 그래서 타입 검사에서 멈추는 명령은 **하나도 잡지 못한다.**

| 명령 | 2차 진단 검출 |
|---|---|
| `swiftc -typecheck -swift-version 6` | **0건** |
| `swiftc -c -swift-version 6` | 2건 |

`-typecheck`이 통과했다고 strict concurrency를 만족하는 게 아니다. 검증에는 **실제 컴파일(`-c`)이나 `swift build`/`swift run`**을 써야 한다.

> 이 문서 §1~6 데모는 `swift <파일>`로 **실행**해서 확인했으므로 영향이 없다(실행은 전체 컴파일을 거친다). 영향이 있는 건 `-typecheck`으로만 확인한 다른 문서다 — [Phase 1a](../Swift/phase1-swiftui-rendering.md)의 `rendering_views.swift`를 `-c`로 다시 돌려봤고 **추가 진단은 없었다**.

`-parse-as-library`도 결과를 바꾼다. 없이 컴파일하면 파일이 top-level 코드로 취급돼 전역 `var`가 암묵적으로 `@MainActor`가 되고, 진단 문구와 위치가 달라진다.

#### 처방 표의 실제 진단 문구

위 표를 이번에 실제로 나온 진단으로 채운다.

| 유형 | 실제 진단 | 쓴 처방 (우회 아님) |
|---|---|---|
| 전역 `var` | `var 'currentAccessToken' is not concurrency-safe because it is nonisolated global shared mutable state` | `actor TokenStore` |
| `static var` | 같은 `#MutableGlobalVariable` | `Mutex(0)` — 잠깐 잠그고 끝나는 접근이라 actor 는 과하다 |
| 비Sendable 싱글턴 | `static property 'shared' is not concurrency-safe because non-'Sendable' type 'ImageCache' may have shared mutable state` | `class` → `actor` |
| 준수 격리 | `conformance of 'FeedSummary' to protocol 'Summarizable' crosses into main actor-isolated code` | `: @MainActor Summarizable` |
| 비Sendable 전달 | `passing closure as a 'sending' parameter risks causing data races` | 참조 대신 메시지를 보낸다 (`await cache.insert(...)`) |

`Mutex`와 `actor`를 갈라 쓴 이유가 실습에서 분명해졌다. `Analytics.track`을 actor 로 만들면 `async`가 되어 **호출부가 전부 오염된다.** 잠금 구간이 짧고 대기가 없으면 `Mutex`가 맞다.

#### 옛 규칙 하나가 더 이상 맞지 않았다

"클로저가 `var`를 캡처하면 위반"은 **이제 조건부다.**

```swift
func retrying(times: Int, _ body: @escaping @Sendable () -> Bool) {
    var attempts = 0
    Task.detached {
        while attempts < times { attempts += 1; if body() { break } }
    }
}
```

이 코드는 Swift 6 complete 에서 **그대로 통과한다.** region isolation 이 `attempts`가 클로저 밖에서 접근되지 않는다는 걸 증명하기 때문이다. 이행본에서도 이 함수만 손대지 않았다.

바꿔 말하면 — **위반 목록을 외우지 말고 컴파일러에게 물어야 한다.** 나는 이 파일을 쓰면서 위반이라고 예상한 5곳 중 1곳이 틀렸다.

### 옛 자료 주의

2021~2023년 세션의 관용구 일부는 현재 권장이 아니다. `@unchecked Sendable`이나 `DispatchQueue` 혼용이 보이면 WWDC25 세션과 공식 마이그레이션 가이드로 대조한다.

---

### 컴파일 통과가 런타임 안전을 뜻하는가 (2026-07-31)

문서가 오래 "컴파일만 확인했다. 실행해 데이터 레이스가 없음을 보인 게 아니다"로 남겨둔 항목이다. Swift 6 complete가 컴파일 타임에 증명한다고 하지만, **그 증명이 실제로 맞는지는 다른 질문**이다.

[`tsan_driver.swift`](code/phase1b/tsan_driver.swift)로 이행본의 다섯 축을 전부 동시에 두드렸다.

```
swiftc -swift-version 6 -sanitize=thread -O \
  -o /tmp/tsan_run migrated_service.swift tsan_driver.swift && /tmp/tsan_run
```

```
완료 — analytics 80건 · cache 64건
ThreadSanitizer 보고: 0건
```

**0건이다.** 그런데 이 저장소에서 0은 그냥 믿지 않는다 ([사례 17·19·22](../AI/phase-parallel-ai-verification.md#1-실제로-틀렸던-것들)).

**양성 대조 — TSan이 살아 있는지 먼저 확인했다.**

```swift
final class Box: @unchecked Sendable { var v = 0 }
// 8개 큐에서 같은 프로퍼티를 10,000번씩 증가시킨다
```

```
WARNING: ThreadSanitizer: data race   → 1건 검출
```

같은 플래그, 같은 환경에서 **일부러 심은 레이스는 잡힌다.** 그러므로 이행본의 0은 "검사가 안 돌았음"이 아니라 "관측된 레이스가 없음"이다.

### 그래도 이게 증명은 아니다

- **TSan은 실행된 경로에서 관측된 레이스만 잡는다.** 안 돈 코드는 검사되지 않는다. 그래서 드라이버가 다섯 축을 전부 두드리게 짰지만, 그것도 내가 생각한 경로일 뿐이다
- 이행본에 **우회가 0건**이라 애초에 TSan이 새로 잡을 여지가 좁았다. `@unchecked Sendable`이나 `nonisolated(unsafe)`가 섞인 코드베이스라면 여기가 진짜 시험대다
- 즉 이 결과는 **"컴파일러의 증명을 런타임이 반박하지 않았다"**까지다. 강한 결론은 아니고, 우회를 쓴 코드에서는 이 검사가 훨씬 중요해진다

### 부수적으로 나온 것 — region isolation 검사기의 한계

드라이버를 쓰다가 컴파일이 막혔다.

```
error: pattern that the region-based isolation checker does not understand
       how to check. Please file a bug
```

`withTaskGroup`의 `group.addTask { @MainActor in ... }` 형태다. **컴파일러가 스스로 버그 신고를 요청하는 진단**이라, 코드가 틀린 게 아니라 검사기가 못 따라가는 경우다. 격리를 클로저 속성이 아니라 호출 지점(`await MainActor.run { }`)에 두면 통과하고 의미는 같다.

Swift 6 이행에서 만나는 진단이 전부 "내 코드가 틀렸다"는 뜻은 아니라는 표본이다.

---

## 8. 스스로 물어볼 것

- `await` 전후로 같은 스레드라고 가정하면 무엇이 깨지는가 (§1)
- `await` 여러 줄과 `async let`의 차이를 시간으로 설명할 수 있는가 (§2)
- `Task { }`가 구조적 동시성에서 벗어난다는 게 실무에서 어떤 문제가 되는가 (§2)
- `cancel()`을 불렀는데 안 멈추는 코드의 조건은 (§3)
- actor가 데이터 경쟁을 막아주는데도 중복 요청이 나가는 이유는 (§4)
- single-flight에서 `inFlight`에 Task를 넣는 시점이 왜 중요한가 (§4)
- 스트림에서 값이 사라졌을 때 먼저 볼 것은 (§5)
- `@unchecked Sendable`이 정당한 조건을 말할 수 있는가 (§7)

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
| §1~6 데모 6개 | `swift -swift-version 6 Concurrency/code/phase1/concurrency_demo.swift` | 전부 실행, 경고 0. 출력을 그대로 인용 |
| §7 `Mutex` 사용 | `swift -swift-version 6 Swift/code/phase1/observation_demo.swift` | 실행 확인 |
| §7 이행 실습 (2026-07-31) | `bash Concurrency/code/phase1b/verify_migration.sh` | **8건 검사 전부 통과** |
| §7 1차 진단 | `swiftc -c -swift-version 6 -parse-as-library legacy_service.swift` | error 4건 (타입체커) |
| §7 2차 진단 | 같은 명령 @ `wave2_probe.swift` | error 2건 (SIL 패스) |
| §7 `-typecheck` 한계 | `swiftc -typecheck ... wave2_probe.swift` | **0건 — 2차를 전부 놓친다** |
| §7 이행본 | `swiftc -c -swift-version 6 ... migrated_service.swift` | error 0, 우회 수단 0회 |
| Phase 1a 코드 재검증 | `swiftc -c -swift-version 6 ... rendering_views.swift` | 추가 진단 없음 |

`-swift-version 6`은 strict concurrency `complete`에 해당한다. 즉 이 문서의 코드는 통과 기준을 코드로 만족한다.

**단, 검증 명령이 중요하다.** `-typecheck`은 SIL 패스가 내는 region isolation 진단을 놓친다 ([§7](#-typecheck으로는-절반을-못-잡는다)). 위 §1~6 데모는 `swift <파일>`로 **실행**했으므로 전체 컴파일을 거쳤고, 이 함정에 걸리지 않는다.

### 확인하지 못한 것

| 주장 | 상태 |
|---|---|
| 재개 스레드 수(2)의 일반성 | **환경 의존 [중]**. 코어 수·부하에 따라 달라진다. "보장이 없다"만 근거 있는 주장 |
| §2 타이밍 수치 | **실행마다 변동 [중]**. 절대값이 아니라 비율만 의미 있다 |
| ~~§7 이행 절차~~ | **해소 (2026-07-31)** — 작은 모듈로 직접 이행했다. 진단이 파도로 온다는 것과 `-typecheck`의 한계가 거기서 나왔다 |
| **대규모** 이행의 시간·난이도 | **여전히 미검증 [저]**. 파일 하나(90줄)짜리 실습이다. 수백 파일에서 의존성이 얽힐 때의 순서 문제·`@preconcurrency import`가 실제로 필요해지는 지점은 겪지 않았다 |
| ~~이행본이 런타임에도 옳은지~~ | **부분 해소 (2026-07-31)** — TSan 아래서 다섯 축을 동시에 돌려 **보고 0건**, 양성 대조로 검사기가 살아 있음을 확인 ([§7](#컴파일-통과가-런타임-안전을-뜻하는가-2026-07-31)). 단 TSan은 **실행된 경로만** 본다. 우회가 0건인 코드라 원래 여지가 좁았다는 것도 감안해야 한다 |
| **Combine 전환 절 전체** | 이 저장소에 **Combine 코드가 없다.** 결정 절차는 앞 절들의 관측에서 세웠고, Combine 쪽 주장은 문서 기반이다. 항목별 라벨은 [해당 절](#신뢰도)에 |
| `.unbounded`의 메모리 위험 | **미측정 [중]**. 정성 서술 |
| `withUnsafeContinuation`의 성능 이득 | **미측정 [저]** |

reentrancy(§4)·취소(§3)·버퍼링(§5)은 런타임 근거가 있다. §7의 이행은 **컴파일 근거**가 있다(진단 문구·건수를 실제로 받아 적었다). 이행 결과가 런타임에도 옳은지는 별도 문제이고 확인하지 않았다.

---

## 참고 자료

[study_list.md §3](../study_list.md#3-swift-concurrency)의 순서를 따른다. 연도순이 아니라 아래 순서로 보는 편이 낫다.

**기초 (WWDC21, 4편 한 세트)**
- 🎬 [Meet async/await](https://developer.apple.com/videos/play/wwdc2021/10132/) · [Explore structured concurrency](https://developer.apple.com/videos/play/wwdc2021/10134/) · [Protect mutable state with actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
- 🎬 [Swift concurrency: Behind the scenes](https://developer.apple.com/videos/play/wwdc2021/10254/) — §1의 원출처. 어렵고 값어치 있다

**SwiftUI와의 경계**
- 🎬 [Discover concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019/) · [Explore concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/266/)

**현재 권장 사항 (§7의 기준)**
- 📘 [Swift Concurrency Migration Guide](https://www.swift.org/migration/) — `minimal → targeted → complete`
- 🎬 [Embracing Swift concurrency](https://developer.apple.com/videos/play/wwdc2025/268/) — 2021년 관용구를 일부 대체한다. 마지막에 본다
- 🎬 [Migrate your app to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/)

다음은 **Phase 2** — 아키텍처 비교. §4의 single-flight와 격리 경계가 Repository 계층 설계에서 다시 나온다.
