// Phase 0 §3의 `미측정 [중]` 항목을 닫는다 — existential 컨테이너 크기와 박싱 임계값.
// 실행: swift -swift-version 6 Swift/code/phase0/existential_layout.swift
//
// ⚠️ 여기서 재는 값은 **구현 세부**다. 컴파일러 버전에 따라 달라질 수 있으니
//    수치를 API 계약처럼 쓰면 안 된다. 남는 결론은 "큰 값은 힙으로 간다"다.
//
// 측정 방법을 두 번 틀렸다 (AI/phase-parallel-ai-verification.md 사례 13):
//  1) existential을 제네릭 파라미터로 넘겨 재려 했다 → **암묵적 열림**(SE-0352)으로
//     T가 동적 타입에 바인딩돼 컨테이너가 아니라 구체 타입을 재고 있었다. [3]에서 재현한다
//  2) 컨테이너 전체에서 sentinel 값을 찾아 인라인 여부를 판단했다 → 스택 잔여물에
//     걸려 실행마다 결과가 달라졌다. 단일 인스턴스의 주소 비교도 할당자 재사용에 걸린다
//  → 같은 값을 담은 두 컨테이너를 **동시에 살려두고** 첫 워드를 비교하는 방식으로 고쳤다
import Foundation

let word = MemoryLayout<UInt>.size

protocol Plain {}
protocol Second {}
protocol ClassOnly: AnyObject {}
protocol WithParent: Plain {}

struct W1: Plain { var a: UInt64 }
struct W2: Plain { var a, b: UInt64 }
struct W3: Plain { var a, b, c: UInt64 }
struct W4: Plain { var a, b, c, d: UInt64 }
struct W5: Plain { var a, b, c, d, e: UInt64 }

/// existential을 struct 프로퍼티로 담으면 제네릭 파라미터가 `Holder`(구체 타입)로
/// 바인딩되므로 암묵적 열림이 일어나지 않는다 → 컨테이너 바이트를 볼 수 있다.
struct Holder { var value: any Plain }

// ═══════════════════════════════════════════════════════════
// 1. 컨테이너 크기는 담는 값과 무관하게 고정이다
// ═══════════════════════════════════════════════════════════

func describeContainers() {
    print("[1] existential 컨테이너 크기 (1워드 = \(word)바이트)")
    let rows: [(String, Int)] = [
        ("any Plain", MemoryLayout<any Plain>.size),
        ("any Plain & Second", MemoryLayout<any Plain & Second>.size),
        ("any WithParent (상속 1단)", MemoryLayout<any WithParent>.size),
        ("any ClassOnly (AnyObject 제약)", MemoryLayout<any ClassOnly>.size),
        ("any Error", MemoryLayout<any Error>.size),
    ]
    for (label, size) in rows {
        print("  \(label.padding(toLength: 32, withPad: " ", startingAt: 0)) \(size)바이트 (\(size / word)워드)")
    }
    print("  → 프로토콜을 더 요구하면 witness table이 늘어 컨테이너가 커진다")
    print("  → AnyObject 제약이면 참조 1개라 훨씬 작다")
}

// ═══════════════════════════════════════════════════════════
// 2. 박싱 임계값
// ═══════════════════════════════════════════════════════════

/// 같은 값을 담은 두 컨테이너를 동시에 살려두고 첫 워드를 비교한다.
/// 인라인이면 페이로드라 같고, 박싱이면 서로 다른 힙 주소라 다르다.
func isBoxed(_ make: () -> any Plain) -> Bool {
    let a = Holder(value: make())
    let b = Holder(value: make())
    let wa = withUnsafeBytes(of: a) { $0.loadUnaligned(as: UInt64.self) }
    let wb = withUnsafeBytes(of: b) { $0.loadUnaligned(as: UInt64.self) }
    withExtendedLifetime((a, b)) {}      // 비교가 끝나기 전에 해제되면 주소가 재사용된다
    return wa != wb
}

func findThreshold() {
    // Swift 6에서 최상위 `let`은 @MainActor 격리라 nonisolated 함수에서 참조할 수 없다
    // (컴파일러가 잡아줬다). 그래서 함수 안에 둔다.
    let samples: [(String, Int, () -> any Plain)] = [
        ("W1", MemoryLayout<W1>.size, { W1(a: 7) }),
        ("W2", MemoryLayout<W2>.size, { W2(a: 7, b: 7) }),
        ("W3", MemoryLayout<W3>.size, { W3(a: 7, b: 7, c: 7) }),
        ("W4", MemoryLayout<W4>.size, { W4(a: 7, b: 7, c: 7, d: 7) }),
        ("W5", MemoryLayout<W5>.size, { W5(a: 7, b: 7, c: 7, d: 7, e: 7) }),
    ]
    print("[2] 값이 컨테이너 안에 들어가는가 (3회 반복해 안정성 확인)")
    var lastResult: [Bool] = []
    for trial in 1...3 {
        let results = samples.map { isBoxed($0.2) }
        let line = zip(samples, results)
            .map { "\($0.0.0)(\($0.0.1)B)=\($0.1 ? "힙" : "인라인")" }
            .joined(separator: "  ")
        print("  시도 \(trial): \(line)")
        lastResult = results
    }
    // 결론을 관측에서 뽑는다. 기대를 print에 박아넣으면 그게 틀려도 드러나지 않는다
    let inlineSizes = zip(samples, lastResult).filter { !$0.1 }.map { $0.0.1 }
    let boxedSizes = zip(samples, lastResult).filter { $0.1 }.map { $0.0.1 }
    if let maxInline = inlineSizes.max(), let minBoxed = boxedSizes.min() {
        let container = MemoryLayout<any Plain>.size
        print("  → 관측: \(maxInline)바이트까지 인라인, \(minBoxed)바이트부터 힙")
        print("     컨테이너 \(container) = 인라인 버퍼 \(maxInline) + 메타데이터·witness table \(container - maxInline)")
    }
}

// ═══════════════════════════════════════════════════════════
// 3. 측정 함정 — 암묵적 열림 (SE-0352)
// ═══════════════════════════════════════════════════════════

/// existential을 제네릭 파라미터로 받으면 열려서 `T`가 동적 타입이 된다.
func sizeSeenByGeneric<T>(_ value: T) -> Int { MemoryLayout<T>.size }

func showImplicitOpening() {
    print("[3] existential을 제네릭에 넘기면 열린다")
    let small: any Plain = W1(a: 7)
    let big: any Plain = W5(a: 7, b: 7, c: 7, d: 7, e: 7)
    print("  MemoryLayout<any Plain>.size        = \(MemoryLayout<any Plain>.size)바이트  ← 컨테이너 크기")
    print("  제네릭 <T>로 W1을 받아 재면          = \(sizeSeenByGeneric(small))바이트  ← 열려서 W1이 됐다")
    print("  제네릭 <T>로 W5를 받아 재면          = \(sizeSeenByGeneric(big))바이트  ← 열려서 W5가 됐다")
    print("  struct에 담아 재면                   = \(MemoryLayout<Holder>.size)바이트  ← 컨테이너 크기")
    print("  → 값마다 다른 크기가 나오면 컨테이너를 재고 있는 게 아니다")
}

describeContainers(); print()
findThreshold(); print()
showImplicitOpening()
