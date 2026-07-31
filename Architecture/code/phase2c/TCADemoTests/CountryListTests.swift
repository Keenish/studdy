// TestStore — 라이브러리 실물. three_way.swift 의 손코딩 TestStore 와 같은 일을 한다.
// 무엇이 공짜로 따라오는지 보려고 같은 시나리오를 그대로 옮겼다.
import ComposableArchitecture
import Testing

@testable import TCADemo

@MainActor
struct CountryListTests {
    /// three_way.swift 의 [C-2] 와 같은 시나리오.
    /// 대기(Task.sleep) 없이 끝나는 것도 같다.
    @Test
    func 기본_루프_성공() async {
        let store = TestStore(initialState: CountryList.State()) {
            CountryList()
        } withDependencies: {
            $0.countryClient.load = { stubbedCountries }
        }

        await store.send(.appeared) { $0.isLoading = true }

        // 액션은 클라이언트가 준 그대로(정렬 전), 상태는 리듀서가 정렬한 뒤.
        // 이 둘이 다르다는 게 "변경이 리듀서에서만 일어난다"의 증거다.
        await store.receive(.response(.success(stubbedCountries))) {
            $0.isLoading = false
            $0.countries = sortedStubbedCountries
        }
    }

    @Test
    func 실패_경로() async {
        let store = TestStore(initialState: CountryList.State()) {
            CountryList()
        } withDependencies: {
            $0.countryClient.load = { throw LoadFailure.network }
        }

        await store.send(.appeared) { $0.isLoading = true }
        await store.receive(.response(.failure(.network))) {
            $0.isLoading = false
            $0.errorMessage = "목록을 불러오지 못했어요."
        }
    }

    @Test
    func 검색어는_효과를_내지_않는다() async {
        let store = TestStore(
            initialState: CountryList.State(countries: sortedStubbedCountries)
        ) {
            CountryList()
        }

        await store.send(.queryChanged("국")) { $0.query = "국" }
        // 파생 상태라 기대에 적지 않는다. 적으려 하면 오히려 실패한다.
        // "국"은 대한민국·미국·영국 셋에 걸린다 — 일본만 빠진다.
        #expect(store.state.visible.map(\.code) == ["KR", "US", "GB"])
    }

    /// ep207 — 의존성 기본값이 "호출되면 실패"다.
    /// withDependencies 로 덮지 않으면 테스트가 통과하지 못한다는 걸 실제로 확인한다.
    @Test
    func 의존성을_빠뜨리면_테스트가_실패한다() async {
        await withKnownIssue {
            let store = TestStore(initialState: CountryList.State()) {
                CountryList()
            }
            // load 를 덮지 않았다 → testValue = unimplemented 가 호출된다.
            await store.send(.appeared) { $0.isLoading = true }
            await store.receive(.response(.success([]))) { $0.isLoading = false }
        }
    }
}
