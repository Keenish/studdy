// Phase 3 §6-C 검증 — 모션을 토큰으로 만들고, 규칙이 실제로 지켜지는지 검사한다.
// 실행: swift -swift-version 6 DesignSystem/code/phase3/motion_tokens.swift
//
// 값은 이 실습을 위해 직접 정한 예제 세트다.
//
// 색 토큰과 다른 점: **모션은 틀려도 컴파일되고 테스트도 통과한다.** 0.3초가
// 0.8초가 돼도 아무것도 실패하지 않는다. 그래서 규칙을 코드로 적어 검사한다.
import Foundation

// ═══════════════════════════════════════════════════════════
// 1. 계층 — 색과 같은 3계층을 쓴다
// ═══════════════════════════════════════════════════════════

/// 계층 1 — Primitive. "얼마나 걸리는가"와 "어떤 곡선인가". 역할을 모른다.
fileprivate enum MotionPrimitive {
    // duration (초)
    static let d0 = 0.0
    static let d100 = 0.10
    static let d150 = 0.15
    static let d250 = 0.25
    static let d400 = 0.40

    // easing — cubic-bezier 제어점. CSS 토큰과 같은 표현을 쓴다.
    static let linear = Easing(0, 0, 1, 1)
    static let standard = Easing(0.2, 0, 0, 1)      // 들어오고 나가는 기본
    static let decelerate = Easing(0, 0, 0, 1)      // 등장 — 빨리 시작해 천천히 멈춤
    static let accelerate = Easing(0.3, 0, 1, 1)    // 퇴장 — 천천히 시작해 빨리 사라짐
}

struct Easing: Equatable {
    let x1, y1, x2, y2: Double
    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        (self.x1, self.y1, self.x2, self.y2) = (x1, y1, x2, y2)
    }
    var css: String { "cubic-bezier(\(x1), \(y1), \(x2), \(y2))" }
}

/// 계층 2 — Semantic. **역할**로 부른다. 화면 코드는 이 이름만 쓴다.
///
/// `0.25초`가 아니라 `.standard`라고 쓰는 이유는 색 토큰과 같다 —
/// 값을 한 곳에서 바꾸면 전부 따라오고, 호출부가 의도를 말한다.
struct MotionToken: Equatable {
    let name: String
    let duration: Double
    let easing: Easing

    /// 상태 전환 — 눌림·호버처럼 즉각 반응해야 하는 것
    static let stateChange = MotionToken(name: "state-change", duration: MotionPrimitive.d100, easing: MotionPrimitive.standard)
    /// 작은 요소의 등장/퇴장 — 툴팁·배지
    static let microEnter = MotionToken(name: "micro-enter", duration: MotionPrimitive.d150, easing: MotionPrimitive.decelerate)
    static let microExit  = MotionToken(name: "micro-exit",  duration: MotionPrimitive.d100, easing: MotionPrimitive.accelerate)
    /// 표준 전환 — 시트·다이얼로그
    static let surfaceEnter = MotionToken(name: "surface-enter", duration: MotionPrimitive.d250, easing: MotionPrimitive.decelerate)
    static let surfaceExit  = MotionToken(name: "surface-exit",  duration: MotionPrimitive.d150, easing: MotionPrimitive.accelerate)
    /// 화면 전환 — 페이지 push/pop
    static let pageEnter = MotionToken(name: "page-enter", duration: MotionPrimitive.d400, easing: MotionPrimitive.decelerate)
    static let pageExit  = MotionToken(name: "page-exit",  duration: MotionPrimitive.d250, easing: MotionPrimitive.accelerate)
    /// 무한 반복 — 스켈레톤 shimmer·로딩 점
    static let loop = MotionToken(name: "loop", duration: MotionPrimitive.d400, easing: MotionPrimitive.linear)

    static let all: [MotionToken] = [
        .stateChange, .microEnter, .microExit,
        .surfaceEnter, .surfaceExit, .pageEnter, .pageExit, .loop,
    ]

    /// 등장/퇴장 짝. 화면 전환 일관성 규칙의 검사 대상이다.
    static let pairs: [(enter: MotionToken, exit: MotionToken)] = [
        (.microEnter, .microExit), (.surfaceEnter, .surfaceExit), (.pageEnter, .pageExit),
    ]

    /// 반복 애니메이션은 reduce motion에서 **끄는 것**이 맞다. 나머지는 즉시 완료.
    var isLooping: Bool { self == .loop }
}

// ═══════════════════════════════════════════════════════════
// 2. reduce motion — "느리게"가 아니라 "즉시 완료"다
// ═══════════════════════════════════════════════════════════

/// 접근성 설정이 켜졌을 때의 해석. 두 가지를 구분한다.
///
/// - 일반 전환: duration을 0으로. **애니메이션을 건너뛰되 상태 변화는 일어난다**
/// - 무한 반복: 아예 실행하지 않는다. duration 0으로 두면 무한 루프가 CPU를 태운다
enum MotionResolution: Equatable {
    case animate(duration: Double, easing: Easing)
    case immediate
    case disabled

    static func resolve(_ token: MotionToken, reduceMotion: Bool) -> MotionResolution {
        guard reduceMotion else { return .animate(duration: token.duration, easing: token.easing) }
        return token.isLooping ? .disabled : .immediate
    }
}

// ═══════════════════════════════════════════════════════════
// 3. 규칙 검사 — 모션은 틀려도 컴파일된다. 그래서 여기서 센다.
// ═══════════════════════════════════════════════════════════

var failures = 0

// top-level `var` 는 @MainActor 로 격리된다(Swift 6). 이걸 건드리는 함수도
// 같은 격리에 있어야 한다 — Phase 1b §7 에서 본 진단이 여기서 그대로 났다.
@MainActor
func check(_ label: String, _ ok: Bool, _ detail: String = "") {
    print("    \(ok ? "✅" : "❌") \(label.padding(toLength: 46, withPad: " ", startingAt: 0))\(detail)")
    if !ok { failures += 1 }
}

@MainActor
func auditMotion() {
    print("[1] 토큰 목록")
    for t in MotionToken.all {
        let ms = Int(t.duration * 1000)
        print("    \(t.name.padding(toLength: 16, withPad: " ", startingAt: 0)) \(String(ms).padding(toLength: 6, withPad: " ", startingAt: 0))ms  \(t.easing.css)")
    }

    print()
    print("[2] 일관성 규칙")

    // 규칙 1 — 퇴장은 등장보다 빠르다.
    // 사라지는 것을 기다리게 하면 앱이 굼떠 보인다. 등장은 눈이 따라가야 하므로 여유가 필요하다.
    for (enter, exit) in MotionToken.pairs {
        check("퇴장 ≤ 등장: \(exit.name) ≤ \(enter.name)",
              exit.duration <= enter.duration,
              "\(Int(exit.duration * 1000))ms ≤ \(Int(enter.duration * 1000))ms")
    }

    // 규칙 2 — 등장은 감속, 퇴장은 가속 곡선을 쓴다.
    for (enter, exit) in MotionToken.pairs {
        check("등장=decelerate: \(enter.name)", enter.easing == MotionPrimitive.decelerate)
        check("퇴장=accelerate: \(exit.name)", exit.easing == MotionPrimitive.accelerate)
    }

    // 규칙 3 — 사람이 "즉각"으로 느끼는 상한. 상태 전환은 100ms를 넘지 않는다.
    check("상태 전환 ≤ 100ms", MotionToken.stateChange.duration <= 0.1,
          "\(Int(MotionToken.stateChange.duration * 1000))ms")

    // 규칙 4 — 어떤 전환도 400ms를 넘지 않는다. 넘으면 기다리는 느낌이 된다.
    let tooLong = MotionToken.all.filter { $0.duration > 0.4 }
    check("모든 토큰 ≤ 400ms", tooLong.isEmpty, tooLong.map(\.name).joined(separator: ", "))

    // 규칙 5 — duration은 Primitive에 정의된 값만 쓴다(임의값 금지).
    let allowed = [MotionPrimitive.d0, MotionPrimitive.d100, MotionPrimitive.d150,
                   MotionPrimitive.d250, MotionPrimitive.d400]
    let offScale = MotionToken.all.filter { !allowed.contains($0.duration) }
    check("스케일 밖 duration 없음", offScale.isEmpty, offScale.map(\.name).joined(separator: ", "))

    print()
    print("[3] reduce motion 해석")
    for t in MotionToken.all {
        let r = MotionResolution.resolve(t, reduceMotion: true)
        let text: String
        switch r {
        case .animate(let d, _): text = "animate(\(d))"
        case .immediate: text = "immediate"
        case .disabled: text = "disabled"
        }
        print("    \(t.name.padding(toLength: 16, withPad: " ", startingAt: 0)) → \(text)")
    }

    // 규칙 6 — reduce motion에서 애니메이션이 남아 있으면 안 된다.
    let leftover = MotionToken.all.filter {
        if case .animate = MotionResolution.resolve($0, reduceMotion: true) { return true }
        return false
    }
    check("reduce motion 시 animate 잔존 0", leftover.isEmpty, leftover.map(\.name).joined(separator: ", "))

    // 규칙 7 — 무한 반복은 immediate가 아니라 disabled여야 한다.
    // immediate(0초)로 두면 무한 루프가 그대로 돌면서 CPU만 태운다.
    check("무한 반복은 disabled", MotionResolution.resolve(.loop, reduceMotion: true) == .disabled)

    // 규칙 8 — 설정이 꺼져 있으면 원래 값이 그대로 나온다(양성 대조).
    // 이게 없으면 resolve가 항상 immediate를 반환해도 위 검사들이 전부 통과한다.
    let normal = MotionResolution.resolve(.pageEnter, reduceMotion: false)
    check("reduce motion 꺼짐 → 원래 값 (양성 대조)",
          normal == .animate(duration: MotionPrimitive.d400, easing: MotionPrimitive.decelerate))
}

auditMotion()

print()
if failures == 0 {
    print("🎉 규칙 검사 전부 통과")
} else {
    print("💥 위반 \(failures)건")
    exit(1)
}
