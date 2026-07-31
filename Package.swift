// swift-tools-version: 6.0
//
// 학습용 빌드 타겟. 레포 규칙(README.md "코드가 있는 문서는 같은 폴더 하위 code/에 둔다")을
// 깨지 않으려고 Sources/ 를 새로 만들지 않고, 각 타겟의 path 를 기존 묶음 폴더로 지정한다.
//
//   swift build                 — 전체 빌드
//   swift test                  — 전체 테스트
//   swift test --filter TCADemo — §2-C 만
import PackageDescription

let package = Package(
    name: "StuddyLab",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TCADemo", targets: ["TCADemo"]),
        .library(name: "ComponentAPI", targets: ["ComponentAPI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.0.0"
        ),
        // Phase 3 §5 — "스냅샷 테스트는 0개"를 닫는다.
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.17.0"
        ),
    ],
    targets: [
        // §2-C — 실물 TCA 라이브러리로 같은 화면을 구현한다.
        // 손으로 만든 최소 재현(Architecture/code/phase2/three_way.swift)과 대조하는 것이 목적.
        .target(
            name: "TCADemo",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Architecture/code/phase2c/TCADemo"
        ),
        .testTarget(
            name: "TCADemoTests",
            dependencies: ["TCADemo"],
            path: "Architecture/code/phase2c/TCADemoTests"
        ),

        // Phase 0 §7 — Button 96조합 해체.
        // component_api.swift 는 원래 `swiftc -typecheck` 로만 확인하던 파일이다.
        // 확장 가능성 주장("색 +1 선언 / Variant +1 타입, 기존 코드 수정 없음")을
        // 실제로 확장해서 검증하려고 타겟으로 승격했다.
        //
        // 같은 폴더의 두 파일은 top-level 코드라 라이브러리에 들어갈 수 없어 제외한다
        // (단독 실행 스크립트로 남는다).
        .target(
            name: "ComponentAPI",
            path: "Swift/code/phase0",
            exclude: ["phase0_demo.swift", "existential_layout.swift"]
        ),
        .testTarget(
            name: "ComponentAPITests",
            dependencies: ["ComponentAPI"],
            path: "Swift/code/phase0Tests"
        ),

        // Phase 3 §4·§5 — 접근성 감사를 회귀 가드로 바꾸고 스냅샷 테스트를 붙인다.
        // 대상 컴포넌트는 ComponentAPI (Phase 0 §7 에서 설계한 것). 실제 디자인 시스템
        // 대상은 Phase 0 §7 의 ComponentAPI — 내가 설계한 컴포넌트다.
        .testTarget(
            name: "DesignSystemTests",
            dependencies: [
                "ComponentAPI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "DesignSystem/code/phase3Tests",
            exclude: ["__Snapshots__"]
        ),

        // Phase 1a §7 — body 재계산 진단 절차를 실제로 돌리기 위한 UI 호스트.
        // 문서의 절차가 오래 "계획"으로만 있던 이유가 호스트 부재였다.
        .executableTarget(
            name: "RenderingLab",
            path: "Swift/code/phase1/RenderingLab"
        ),
    ]
)
