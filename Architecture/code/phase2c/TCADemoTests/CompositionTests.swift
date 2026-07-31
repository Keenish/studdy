// Scope · forEach · ifLet — 손코딩 코어에는 없던 것들.
// 각각이 실제로 무엇을 대신해 주는지 테스트로 확인한다.
import ComposableArchitecture
import Testing

@testable import TCADemo

@MainActor
struct CompositionTests {
    /// Scope — 자식 액션이 부모를 거쳐 자식 리듀서에 닿고,
    /// 부모가 같은 액션을 가로채 자기 일도 한다.
    @Test
    func Scope는_자식_액션을_부모가_가로챌_수_있게_한다() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.countryClient.load = { stubbedCountries }
        }

        await store.send(.list(.appeared)) { $0.list.isLoading = true }
        await store.receive(.list(.response(.success(stubbedCountries)))) {
            $0.list.isLoading = false
            $0.list.countries = sortedStubbedCountries
            // 부모만 아는 일 — 자식은 favorites 의 존재를 모른다.
            $0.favorites = IdentifiedArray(
                uniqueElements: sortedStubbedCountries.map { FavoriteRow.State(country: $0) }
            )
        }
    }

    /// forEach — 원소 하나에 보낸 액션이 그 원소에만 닿는다.
    @Test
    func forEach는_원소별로_리듀서를_돌린다() async {
        let store = TestStore(
            initialState: AppFeature.State(
                favorites: IdentifiedArray(
                    uniqueElements: sortedStubbedCountries.map { FavoriteRow.State(country: $0) }
                )
            )
        ) {
            AppFeature()
        }

        await store.send(.favorites(.element(id: "US", action: .pinToggled))) {
            $0.favorites[id: "US"]?.isPinned = true
        }
        #expect(store.state.favorites[id: "KR"]?.isPinned == false)
    }

    /// ifLet — 자식이 dismiss 를 부르면 부모의 옵셔널이 비워진다.
    /// 부모는 "닫기" 액션을 따로 정의하지 않았다.
    @Test
    func ifLet은_자식의_dismiss로_상태를_비운다() async {
        let korea = sortedStubbedCountries[0]
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.countryTapped(korea)) {
            $0.detail = CountryDetail.State(country: korea)
        }
        await store.send(.detail(.presented(.noteChanged("메모")))) {
            $0.detail?.note = "메모"
        }
        await store.send(.detail(.presented(.closeTapped)))
        await store.receive(\.detail.dismiss) {
            $0.detail = nil
        }
    }

    /// 전수성을 끄면 관심 있는 것만 적을 수 있다 (ep225에서 도입).
    /// 위 테스트와 같은 흐름인데 기대를 하나도 안 적었다.
    @Test
    func 비전수_모드는_기대를_생략할_수_있다() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.countryClient.load = { stubbedCountries }
        }
        store.exhaustivity = .off

        await store.send(.list(.appeared))
        // 키패스 방식 — 값을 안 적고 "어느 case 가 오는지"만 적는다.
        await store.receive(\.list.response.success)

        // 최종 상태만 확인한다.
        #expect(store.state.favorites.count == 4)
        #expect(store.state.list.countries.first?.code == "KR")
    }
}
