// Phase 2 실습 — 같은 화면을 두 아키텍처로 구현해 비교한다.
// 화면: 국가 선택 (목록 조회 · 검색 필터 · 로딩/실패/재시도)
// 실행: swift -swift-version 6 Architecture/code/phase2/mvvm_vs_clean.swift
//
import Foundation
import Synchronization

// ═══════════════════════════════════════════════════════════
// 공통 — 서버와 가짜 전송
// ═══════════════════════════════════════════════════════════

/// 서버가 주는 모양. 필드명·타입이 서버 소유다.
struct CountryDTO: Codable, Sendable {
    let country_code: String
    let country_name: String
    let dial_code: String?
}

/// 전송 계층. 두 버전이 공유한다.
protocol CountryTransport: Sendable {
    func fetch() async throws -> [CountryDTO]
}

struct FakeTransport: CountryTransport {
    let failFirstCall: Bool
    private let callCount = Counter()

    init(failFirstCall: Bool = false) { self.failFirstCall = failFirstCall }

    func fetch() async throws -> [CountryDTO] {
        let n = callCount.increment()
        try await Task.sleep(for: .milliseconds(10))
        if failFirstCall && n == 1 { throw URLError(.timedOut) }
        return [
            CountryDTO(country_code: "KR", country_name: "대한민국", dial_code: "+82"),
            CountryDTO(country_code: "JP", country_name: "일본", dial_code: "+81"),
            CountryDTO(country_code: "US", country_name: "미국", dial_code: "+1"),
            CountryDTO(country_code: "GB", country_name: "영국", dial_code: nil),
        ]
    }
}

/// Swift 6에서 공유 카운터를 우회 없이 다루는 방법 (Phase 1b §7)
final class Counter: Sendable {
    private let box = Mutex(0)
    func increment() -> Int { box.withLock { $0 += 1; return $0 } }
}

// ═══════════════════════════════════════════════════════════
// 공통 — Tasker (key 로 Task 수명을 관리하는 최소 구현)
// ═══════════════════════════════════════════════════════════

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

    /// 테스트에서 완료를 기다리기 위한 창구.
    /// 실제 코드에는 없다 — 단방향 MVVM의 async를 검증하려면 이런 수단이 필요하다는 것 자체가 발견이다.
    func wait(_ key: String) async {
        await tasks[key]?.value
    }
}

// ═══════════════════════════════════════════════════════════
// 버전 A — 경량 단방향 MVVM (Domain 레이어 없음)
//   ViewModel이 전송 결과(DTO)를 직접 다룬다.
// ═══════════════════════════════════════════════════════════
// <A>

@MainActor
@Observable
final class MVVMCountryViewModel {
    struct State {
        var query = ""
        var countries: [CountryDTO] = []
        var isLoading = false
        var errorMessage: String?

        /// 표시용 파생 값. 정렬 규칙(한국 우선)이 ViewModel 안에 있다.
        var visible: [CountryDTO] {
            let filtered = query.isEmpty
                ? countries
                : countries.filter { $0.country_name.contains(query) }
            return filtered.sorted { lhs, rhs in
                if lhs.country_code == "KR" { return true }
                if rhs.country_code == "KR" { return false }
                return lhs.country_name < rhs.country_name
            }
        }
    }

    enum Action {
        case appeared
        case queryChanged(String)
        case retryTapped
    }

    private(set) var state = State()
    private let transport: CountryTransport
    private let tasker = Tasker()

    init(transport: CountryTransport) { self.transport = transport }

    func sendAction(_ action: Action) {
        switch action {
        case .appeared, .retryTapped:
            load()
        case let .queryChanged(text):
            state.query = text
        }
    }

    private func load() {
        state.isLoading = true
        state.errorMessage = nil
        tasker.run("load") { [weak self] in
            guard let self else { return }
            do {
                self.state.countries = try await self.transport.fetch()
                self.state.isLoading = false
            } catch is CancellationError {
                self.state.isLoading = false
            } catch {
                self.state.isLoading = false
                self.state.errorMessage = "목록을 불러오지 못했어요."
            }
        }
    }

    func waitForLoad() async { await tasker.wait("load") }
}

// </A>

// ═══════════════════════════════════════════════════════════
// 버전 B — Clean + MVVM (Entity / UseCase / Repository 분리)
// ═══════════════════════════════════════════════════════════
// <B>

// ── Entity: 앱이 쓰는 모양. 서버 필드명을 모른다.
struct Country: Equatable, Sendable, Identifiable {
    let code: String
    let name: String
    let dialCode: String?
    var id: String { code }
}

// ── Repository: 포트. DTO는 이 경계 밖으로 나가지 않는다.
protocol CountryRepository: Sendable {
    func countries() async throws -> [Country]
}

struct LiveCountryRepository: CountryRepository {
    let transport: CountryTransport

    func countries() async throws -> [Country] {
        try await transport.fetch().map(Self.map)   // 매핑 위치 = Repository
    }

    /// DTO → Entity. 서버 필드명이 바뀌면 이 함수 하나만 고친다.
    private static func map(_ dto: CountryDTO) -> Country {
        Country(code: dto.country_code, name: dto.country_name, dialCode: dto.dial_code)
    }
}

struct StubCountryRepository: CountryRepository {
    let stubbed: [Country]
    func countries() async throws -> [Country] { stubbed }
}

// ── UseCase: 비즈니스 규칙. 화면도 서버도 모른다.
protocol FetchCountries: Sendable {
    func callAsFunction() async throws -> [Country]
}

struct FetchCountriesUseCase: FetchCountries {
    let repository: CountryRepository
    let preferredCode: String

    /// 규칙: 선호 국가를 최상단에 고정하고 나머지는 이름순.
    func callAsFunction() async throws -> [Country] {
        try await repository.countries().sorted { lhs, rhs in
            if lhs.code == preferredCode { return true }
            if rhs.code == preferredCode { return false }
            return lhs.name < rhs.name
        }
    }
}

@MainActor
@Observable
final class CleanCountryViewModel {
    struct State {
        var query = ""
        var countries: [Country] = []
        var isLoading = false
        var errorMessage: String?

        /// 표시 관심사만 남는다. 정렬은 UseCase가 이미 했다.
        var visible: [Country] {
            query.isEmpty ? countries : countries.filter { $0.name.contains(query) }
        }
    }

    enum Action {
        case appeared
        case queryChanged(String)
        case retryTapped
    }

    private(set) var state = State()
    private let fetchCountries: any FetchCountries
    private let tasker = Tasker()

    init(fetchCountries: any FetchCountries) { self.fetchCountries = fetchCountries }

    func sendAction(_ action: Action) {
        switch action {
        case .appeared, .retryTapped:
            load()
        case let .queryChanged(text):
            state.query = text
        }
    }

    private func load() {
        state.isLoading = true
        state.errorMessage = nil
        tasker.run("load") { [weak self] in
            guard let self else { return }
            do {
                self.state.countries = try await self.fetchCountries()
                self.state.isLoading = false
            } catch is CancellationError {
                self.state.isLoading = false
            } catch {
                self.state.isLoading = false
                self.state.errorMessage = "목록을 불러오지 못했어요."
            }
        }
    }

    func waitForLoad() async { await tasker.wait("load") }
}

// </B>

// ═══════════════════════════════════════════════════════════
// 같은 시나리오를 두 버전에 돌린다
// ═══════════════════════════════════════════════════════════

@MainActor
func runMVVM() async {
    print("[A] 경량 단방향 MVVM")
    let vm = MVVMCountryViewModel(transport: FakeTransport(failFirstCall: true))

    vm.sendAction(.appeared)
    print("  로딩 시작: isLoading=\(vm.state.isLoading)")
    await vm.waitForLoad()
    print("  첫 시도 실패: error=\(vm.state.errorMessage ?? "nil")")

    vm.sendAction(.retryTapped)
    await vm.waitForLoad()
    print("  재시도 성공: \(vm.state.visible.map(\.country_code))")

    vm.sendAction(.queryChanged("국"))
    print("  '국' 필터: \(vm.state.visible.map(\.country_code))")
}

@MainActor
func runClean() async {
    print("[B] Clean + MVVM")
    let repository = LiveCountryRepository(transport: FakeTransport(failFirstCall: true))
    let useCase = FetchCountriesUseCase(repository: repository, preferredCode: "KR")
    let vm = CleanCountryViewModel(fetchCountries: useCase)

    vm.sendAction(.appeared)
    print("  로딩 시작: isLoading=\(vm.state.isLoading)")
    await vm.waitForLoad()
    print("  첫 시도 실패: error=\(vm.state.errorMessage ?? "nil")")

    vm.sendAction(.retryTapped)
    await vm.waitForLoad()
    print("  재시도 성공: \(vm.state.visible.map(\.code))")

    vm.sendAction(.queryChanged("국"))
    print("  '국' 필터: \(vm.state.visible.map(\.code))")
}

/// B는 ViewModel을 서버 없이 검증할 수 있다. A는 전송 프로토콜을 흉내내야 한다.
@MainActor
func runTestSeam() async {
    print("[C] 테스트 이음새")

    let stub = StubCountryRepository(stubbed: [
        Country(code: "US", name: "미국", dialCode: "+1"),
        Country(code: "KR", name: "대한민국", dialCode: "+82"),
    ])
    let useCase = FetchCountriesUseCase(repository: stub, preferredCode: "KR")

    // UseCase만 단독 검증 — ViewModel도 네트워크도 필요 없다
    let sorted = try? await useCase()
    print("  UseCase 단독 검증(KR 최상단): \(sorted?.map(\.code) ?? [])")

    // ViewModel 검증 — UseCase를 갈아끼운다
    let vm = CleanCountryViewModel(fetchCountries: useCase)
    vm.sendAction(.appeared)
    await vm.waitForLoad()
    print("  ViewModel 검증(스텁 주입): \(vm.state.visible.map(\.code))")
}

await runMVVM(); print()
await runClean(); print()
await runTestSeam()
