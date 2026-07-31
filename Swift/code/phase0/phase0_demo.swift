// Phase 0 검증 스크립트 — swift phase0_demo.swift
import Foundation

// ─────────────────────────────────────────────
// 1. 값 의미론이 struct 안의 class 참조로 깨지는 순간
// ─────────────────────────────────────────────
final class Box { var value = 0 }
struct Leaky { var box = Box(); var count = 0 }

func demo1() {
    print("[1] 값 의미론 붕괴")
    var a = Leaky()
    let b = a          // 복사한 셈
    a.count = 99
    a.box.value = 99   // box는 참조 → b와 공유됨
    print("  a.count=\(a.count) b.count=\(b.count)      (독립)")
    print("  a.box.value=\(a.box.value) b.box.value=\(b.box.value)  (공유 — 값 의미론 아님)")
}

// ─────────────────────────────────────────────
// 2. Array의 COW를 버퍼 주소로 확인
// ─────────────────────────────────────────────
func bufferAddress(_ a: [Int]) -> UInt {
    a.withUnsafeBufferPointer { UInt(bitPattern: $0.baseAddress) }
}

func demo2() {
    print("[2] Array copy-on-write")
    let arr1 = [1, 2, 3]
    var arr2 = arr1
    let sameBefore = bufferAddress(arr1) == bufferAddress(arr2)
    arr2.append(4)
    let sameAfter = bufferAddress(arr1) == bufferAddress(arr2)
    print("  대입 직후 버퍼 공유: \(sameBefore)")
    print("  변경 직후 버퍼 공유: \(sameAfter)   (쓰기 시점에 복사)")
}

// ─────────────────────────────────────────────
// 3. COW 직접 구현 — isKnownUniquelyReferenced
// ─────────────────────────────────────────────
final class Storage { var data: [Int]; init(_ d: [Int]) { data = d } }

struct MyBuffer {
    private var storage: Storage
    private(set) var copyHappened = false
    init(_ d: [Int]) { storage = Storage(d) }
    var data: [Int] { storage.data }

    mutating func append(_ x: Int) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(storage.data)   // 공유 중일 때만 복사
            copyHappened = true
        }
        storage.data.append(x)
    }
}

func demo3() {
    print("[3] 직접 만든 COW")
    var only = MyBuffer([1, 2])
    only.append(3)
    print("  유일 참조일 때 복사 발생: \(only.copyHappened)")
    var shared = MyBuffer([1, 2])
    let holder = shared          // 공유 발생
    shared.append(3)
    print("  공유 중일 때 복사 발생: \(shared.copyHappened)")
    print("  원본 보존: \(holder.data) / 변경본: \(shared.data)")
}

// ─────────────────────────────────────────────
// 4. typed throws · try? · Result
// ─────────────────────────────────────────────
enum LoadError: Error, Equatable { case notFound, decode(field: String) }

func load(_ id: Int) throws(LoadError) -> String {
    guard id > 0 else { throw .notFound }          // 문맥으로 타입 추론
    guard id != 13 else { throw .decode(field: "title") }
    return "item-\(id)"
}

// Result { try ... } 는 Failure == any Error 로 고정 → typed throws가 흐르지 않는다.
// 실패 타입을 유지하려면 do/catch로 직접 감싼다.
func loadResult(_ id: Int) -> Result<String, LoadError> {
    do { return .success(try load(id)) }
    catch { return .failure(error) }      // error의 정적 타입이 LoadError
}

func demo4() {
    print("[4] typed throws / try? / Result")
    do {
        _ = try load(0)
    } catch {
        // error의 정적 타입이 LoadError — as? 캐스팅 불필요
        print("  catch에서 바로 패턴 매칭: \(error == .notFound)")
    }
    let swallowed: String? = try? load(0)
    print("  try? 는 에러 종류를 버린다: \(swallowed as Any)")
    let ok: String? = try? load(7)
    print("  성공 시엔 평탄화된 Optional: \(ok as Any)")

    let r = loadResult(13)
    switch r {
    case .success(let v): print("  Result 성공: \(v)")
    case .failure(let e): print("  Result 실패 보존: \(e)")
    }
}

// ─────────────────────────────────────────────
// 5. PAT · some vs any · 프로토콜 extension의 정적 디스패치
// ─────────────────────────────────────────────
protocol Container<Item> {          // Item = primary associated type
    associatedtype Item
    var items: [Item] { get }
    mutating func add(_ item: Item)
}

struct Bag<Item>: Container {
    var items: [Item] = []
    mutating func add(_ item: Item) { items.append(item) }
}

func makeBag() -> some Container<Int> { Bag<Int>() }   // primary associated type은 위치 인자

protocol Greeter {
    func hello()                    // 프로토콜 요구사항
}
extension Greeter {
    func hello() { print("  default hello") }
    func bye()   { print("  default bye")   }   // 요구사항 아님 — extension에만 존재
}
struct Korean: Greeter {
    func hello() { print("  안녕") }
    func bye()   { print("  안녕히") }
}

func demo5() {
    print("[5] PAT / some vs any / 정적 디스패치 함정")
    let boxed: any Container<Int> = Bag<Int>()      // primary associated type 덕에 제약 표기 가능
    print("  existential 사용 가능: \(boxed.items)")

    let g: any Greeter = Korean()
    print("  요구사항 hello() →", terminator: " ")
    g.hello()                                       // witness table 경유 → 동적
    print("  비요구사항 bye()  →", terminator: " ")
    g.bye()                                         // 정적 디스패치 → default가 호출됨
}

// ─────────────────────────────────────────────
// 6. 제네릭 제약 · 조건부 준수 · opaque type
// ─────────────────────────────────────────────
protocol CSSToken { var raw: String { get } }
struct ClassToken: CSSToken { let raw: String }

extension Array: CSSToken where Element: CSSToken {   // 조건부 준수
    var raw: String { map(\.raw).joined(separator: " ") }
}

func render(_ token: some CSSToken) -> String { token.raw }   // some = 파라미터 위치 제네릭

func chipTokens(active: Bool) -> some Collection<String> {    // opaque return
    active ? ["chip", "chip--active-brand"] : ["chip"]
}

func demo6() {
    print("[6] 제약 / 조건부 준수 / opaque")
    let tokens = [ClassToken(raw: "chip"), ClassToken(raw: "chip--md")]
    print("  [ClassToken]도 CSSToken이 된다: \"\(render(tokens))\"")
    print("  opaque 반환: \(Array(chipTokens(active: true)))")
}

// ─────────────────────────────────────────────
// 7. @resultBuilder — @ViewBuilder의 정체
// ─────────────────────────────────────────────
@resultBuilder
enum ClassListBuilder {
    static func buildExpression(_ s: String) -> [String] { [s] }
    static func buildPartialBlock(first: [String]) -> [String] { first }
    static func buildPartialBlock(accumulated: [String], next: [String]) -> [String] { accumulated + next }
    static func buildOptional(_ c: [String]?) -> [String] { c ?? [] }            // if (else 없음)
    static func buildEither(first c: [String]) -> [String] { c }                 // if/else 앞가지
    static func buildEither(second c: [String]) -> [String] { c }                // if/else 뒷가지
    static func buildArray(_ parts: [[String]]) -> [String] { parts.flatMap { $0 } }  // for
    static func buildFinalResult(_ c: [String]) -> String { c.joined(separator: " ") }
}

func classes(@ClassListBuilder _ build: () -> String) -> String { build() }

func demo7() {
    print("[7] @resultBuilder로 Chip 클래스 조립")
    let isActive = true
    let size = "md"
    let result = classes {
        "chip"
        if isActive { "chip--active-brand" }              // buildOptional
        if size == "md" { "chip--md" } else { "chip--sm" } // buildEither
        for i in 0..<2 { "data-idx-\(i)" }                // buildArray
    }
    print("  \(result)")
}

// ─────────────────────────────────────────────
// 8. 순환 참조 — deinit으로 증명
// ─────────────────────────────────────────────
final class Node {
    let name: String
    var onDone: (() -> Void)?
    init(name: String) { self.name = name }
    deinit { print("  deinit \(name)") }
}

func demo8() {
    print("[8] 순환 참조")
    do {
        let n = Node(name: "strong")
        n.onDone = { print("  \(n.name) 실행") }   // 클로저가 n을 강하게 캡처
        n.onDone?()
    }
    print("  스코프 종료 — strong의 deinit이 위에 없으면 누수")
    do {
        let n = Node(name: "weak")
        n.onDone = { [weak n] in print("  \(n?.name ?? "해제됨") 실행") }
        n.onDone?()
    }
    print("  스코프 종료 — weak의 deinit이 위에 있으면 정상 해제")
}

demo1(); print()
demo2(); print()
demo3(); print()
demo4(); print()
demo5(); print()
demo6(); print()
demo7(); print()
demo8()
