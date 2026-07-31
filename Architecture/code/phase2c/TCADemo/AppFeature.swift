// 상태 합성 — Scope · forEach · ifLet 을 한 화면에 모아 놓고 셋의 역할 차이를 본다.
//
// 손으로 만든 코어에는 이게 아예 없었다. three_way.swift 는 화면 하나짜리라
// pullback 도 combine 도 쓸 일이 없었고, 그래서 "합성이 왜 필요한가"가 안 보였다.
// 여기서 처음으로 부모-자식이 생긴다.
import ComposableArchitecture
import Foundation

// MARK: - 자식 1 · 즐겨찾기 행 (forEach 대상)

@Reducer
struct FavoriteRow {
    @ObservableState
    struct State: Equatable, Identifiable {
        let country: Country
        var isPinned = false

        var id: String { country.code }
    }

    enum Action: Equatable {
        case pinToggled
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .pinToggled:
                state.isPinned.toggle()
                return .none
            }
        }
    }
}

// MARK: - 자식 2 · 상세 (ifLet 대상)

@Reducer
struct CountryDetail {
    @ObservableState
    struct State: Equatable {
        let country: Country
        var note = ""
    }

    enum Action: Equatable {
        case noteChanged(String)
        case closeTapped
    }

    /// 부모에게 "닫아 달라"고 말하는 통로. ep222의 delegate 패턴.
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .noteChanged(text):
                state.note = text
                return .none

            case .closeTapped:
                return .run { _ in await dismiss() }
            }
        }
    }
}

// MARK: - 부모

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var list = CountryList.State()
        var favorites: IdentifiedArrayOf<FavoriteRow.State> = []
        /// ep229·247 — 목적지를 옵셔널 여럿이 아니라 하나로 둔다.
        @Presents var detail: CountryDetail.State?
    }

    /// Equatable 을 빼면 `store.receive(.list(...))` 가 컴파일되지 않는다.
    /// 라이브러리는 키패스 방식(`store.receive(\.list.response.success)`)을 기본으로 두고,
    /// 값 비교는 Equatable 을 붙였을 때만 열어 준다.
    enum Action: Equatable {
        case list(CountryList.Action)
        case favorites(IdentifiedActionOf<FavoriteRow>)
        case detail(PresentationAction<CountryDetail.Action>)
        case countryTapped(Country)
    }

    var body: some ReducerOf<Self> {
        // Scope — 자식 도메인 하나를 부모 도메인의 한 조각에 끼운다.
        // ep69·70의 pullback 이 그대로 이 자리에 있다.
        Scope(state: \.list, action: \.list) {
            CountryList()
        }

        Reduce { state, action in
            switch action {
            case .list(.response(.success)):
                // 목록이 로드되면 즐겨찾기 행을 만든다.
                // 자식 액션을 부모가 가로채는 자리 — 부모만 아는 조율이 여기 산다.
                //
                // ⚠️ 액션에 실린 페이로드가 아니라 `state.list.countries` 를 읽는다.
                //    body 안의 리듀서는 적힌 순서대로 돈다 — Scope 가 먼저 끝나 있으므로
                //    이 시점의 자식 상태는 이미 정렬됐다. 페이로드를 쓰면 정렬 전 순서가
                //    새어 들어와 목록과 즐겨찾기의 순서가 어긋난다 (실제로 테스트가 잡았다).
                state.favorites = IdentifiedArray(
                    uniqueElements: state.list.countries.map { FavoriteRow.State(country: $0) }
                )
                return .none

            case let .countryTapped(country):
                state.detail = CountryDetail.State(country: country)
                return .none

            case .list, .favorites, .detail:
                return .none
            }
        }
        // forEach — 같은 자식 리듀서를 컬렉션의 각 원소에 돌린다.
        // 원소가 사라진 뒤 그 원소의 효과를 자동으로 취소해 주는 게 손코딩과의 결정적 차이.
        .forEach(\.favorites, action: \.favorites) {
            FavoriteRow()
        }
        // ifLet — 옵셔널 자식. nil 이 되는 순간 자식 효과가 취소된다 (ep225).
        .ifLet(\.$detail, action: \.detail) {
            CountryDetail()
        }
    }
}
