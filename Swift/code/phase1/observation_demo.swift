// Phase 1a 검증 — 무효화 범위를 런타임으로 확인
// 실행: swift -swift-version 6 Swift/code/phase1/observation_demo.swift
import Foundation
import Observation
import Combine
import Synchronization

// ─────────────────────────────────────────────
// 1. @Observable — 읽은 프로퍼티만 추적된다 (프로퍼티 단위)
// ─────────────────────────────────────────────
@Observable
final class NewModel {
    var title = "a"
    var unrelated = 0
}

func demo1() {
    print("[1] @Observable — 프로퍼티 단위 추적")
    let model = NewModel()
    let fired = Mutex(0)

    withObservationTracking {
        _ = model.title              // title만 읽는다. unrelated는 읽지 않음
    } onChange: {
        fired.withLock { $0 += 1 }
    }

    model.unrelated = 99             // 읽지 않은 프로퍼티
    print("  읽지 않은 프로퍼티 변경 → onChange 호출 횟수: \(fired.withLock { $0 })")

    model.title = "b"                // 읽은 프로퍼티
    print("  읽은 프로퍼티 변경   → onChange 호출 횟수: \(fired.withLock { $0 })")
}

// ─────────────────────────────────────────────
// 2. ObservableObject — 어떤 프로퍼티든 객체 전체가 알린다
// ─────────────────────────────────────────────
final class OldModel: ObservableObject {
    @Published var title = "a"
    @Published var unrelated = 0
}

func demo2() {
    print("[2] ObservableObject — 객체 단위 알림")
    let model = OldModel()
    let fired = Mutex(0)
    let token = model.objectWillChange.sink { _ in
        fired.withLock { $0 += 1 }
    }

    model.unrelated = 99             // title을 쓰는 뷰와 무관한 변경
    print("  무관한 프로퍼티 변경 → objectWillChange 발행 횟수: \(fired.withLock { $0 })")

    model.title = "b"
    print("  관련 프로퍼티 변경   → objectWillChange 발행 횟수: \(fired.withLock { $0 })")
    token.cancel()
}

// ─────────────────────────────────────────────
// 3. 추적은 '읽은 것'만 — 조건 분기로 안 읽으면 추적 안 된다
// ─────────────────────────────────────────────
@Observable
final class Toggleable {
    var showDetail = false
    var detail = "hidden"
}

func demo3() {
    print("[3] 조건 분기로 읽지 않은 프로퍼티")
    let model = Toggleable()
    let fired = Mutex(0)

    withObservationTracking {
        // showDetail이 false라서 detail에는 접근하지 않는다
        if model.showDetail { _ = model.detail }
    } onChange: {
        fired.withLock { $0 += 1 }
    }

    model.detail = "changed"
    print("  detail 변경 → onChange: \(fired.withLock { $0 })  (이번 추적에서 안 읽었으므로 0)")
    model.showDetail = true
    print("  showDetail 변경 → onChange: \(fired.withLock { $0 })")
}

// ─────────────────────────────────────────────
// 4. onChange는 1회성 — 매 갱신마다 다시 추적해야 한다
// ─────────────────────────────────────────────
func demo4() {
    print("[4] withObservationTracking은 one-shot")
    let model = NewModel()
    let fired = Mutex(0)

    withObservationTracking {
        _ = model.title
    } onChange: {
        fired.withLock { $0 += 1 }
    }

    model.title = "1"
    model.title = "2"
    model.title = "3"
    print("  3번 변경했지만 onChange 호출: \(fired.withLock { $0 })")
    print("  → SwiftUI는 body를 재평가할 때마다 추적을 다시 건다")
}

demo1(); print()
demo2(); print()
demo3(); print()
demo4()
