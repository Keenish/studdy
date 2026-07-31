// §2-C — 실물 TCA로 구현하는 같은 화면.
//
// 대조 대상: Architecture/code/phase2/three_way.swift 의 버전 C.
// 그쪽은 ep68~71·83~84를 손으로 재현한 최소 코어이고, 이쪽은 라이브러리다.
// 도메인을 한 글자도 바꾸지 않아야 "무엇이 라이브러리 덕분인가"가 분리된다.
import Foundation

/// three_way.swift 의 Country 와 같다. IdentifiedArray 에 넣으려고 Identifiable 만 추가했다.
struct Country: Equatable, Identifiable, Sendable {
    let code: String
    let name: String

    var id: String { code }
}

enum LoadFailure: Error, Equatable {
    case network
}

let stubbedCountries = [
    Country(code: "KR", name: "대한민국"),
    Country(code: "JP", name: "일본"),
    Country(code: "US", name: "미국"),
    Country(code: "GB", name: "영국"),
]

/// 리듀서가 정렬한 뒤의 기대값 (선호 국가 최상단 + 이름순).
let sortedStubbedCountries = [
    Country(code: "KR", name: "대한민국"),
    Country(code: "US", name: "미국"),
    Country(code: "GB", name: "영국"),
    Country(code: "JP", name: "일본"),
]
