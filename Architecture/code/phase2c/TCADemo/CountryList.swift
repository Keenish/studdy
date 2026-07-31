// 기본 루프 — Reducer / Store / Effect.
//
// three_way.swift 의 `countryReducer` 와 로직이 같다. 달라진 것만 세면:
//   1. 자유 함수 → @Reducer 가 붙은 타입 (ep201~204)
//   2. env 인자 → @Dependency 프로퍼티 (ep205·206)
//   3. [Effect] 배열 반환 → .run/.none (ep195~200)
//   4. State 에 @ObservableState (ep259~266)
import ComposableArchitecture
import Foundation

@Reducer
struct CountryList {
    @ObservableState
    struct State: Equatable {
        var query = ""
        var countries: [Country] = []
        var isLoading = false
        var errorMessage: String?

        /// 파생 상태는 저장하지 않는다 — three_way.swift 의 버전 A와 같은 판단.
        var visible: [Country] {
            query.isEmpty ? countries : countries.filter { $0.name.contains(query) }
        }
    }

    /// 액션 이름은 "사용자가 UI에서 한 일"을 반영한다 (ep243의 원칙).
    /// `loadCountries` 가 아니라 `appeared`·`retryTapped` 인 이유.
    enum Action: Equatable {
        case appeared
        case queryChanged(String)
        case retryTapped
        case response(Result<[Country], LoadFailure>)
    }

    @Dependency(\.countryClient) var countryClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appeared, .retryTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        await send(.response(.success(try await countryClient.load())))
                    } catch {
                        await send(.response(.failure(.network)))
                    }
                }

            case let .queryChanged(text):
                state.query = text
                return .none

            case let .response(.success(countries)):
                state.isLoading = false
                // 비즈니스 규칙이 리듀서에 산다 — three_way.swift 와 같은 위치.
                let preferred = countryClient.preferredCode
                state.countries = countries.sorted { lhs, rhs in
                    if lhs.code == preferred { return true }
                    if rhs.code == preferred { return false }
                    return lhs.name < rhs.name
                }
                return .none

            case .response(.failure):
                state.isLoading = false
                state.errorMessage = "목록을 불러오지 못했어요."
                return .none
            }
        }
    }
}
