// 의존성 — three_way.swift 의 `CountryEnvironment` 와 같은 모양(함수를 담은 구조체)이지만,
// 인자로 넘기는 대신 @Dependency 로 암묵적으로 흐른다 (ep205·206).
//
// 필드 구성을 CountryEnvironment 와 동일하게 둔 이유: 달라진 게 "전달 방식"뿐임을 드러내려고.
import ComposableArchitecture
import Foundation

struct CountryClient: Sendable {
    var load: @Sendable () async throws -> [Country]
    var preferredCode: String = "KR"
}

extension CountryClient: DependencyKey {
    /// 실서비스. 여기선 네트워크 대신 지연만 흉내 낸다.
    static let liveValue = CountryClient(
        load: {
            try await Task.sleep(for: .milliseconds(10))
            return stubbedCountries
        }
    )

    /// ep207의 핵심 — 테스트 기본값은 "호출되면 실패".
    /// 빠뜨린 의존성이 조용히 통과하지 않고 드러난다.
    static let testValue = CountryClient(
        load: unimplemented("CountryClient.load", placeholder: [])
    )

    /// ep248이 실물로 보여준 자리 — 프리뷰가 영영 멈추지 않도록 즉시 값을 준다.
    static let previewValue = CountryClient(
        load: { stubbedCountries }
    )
}

extension DependencyValues {
    var countryClient: CountryClient {
        get { self[CountryClient.self] }
        set { self[CountryClient.self] = newValue }
    }
}
