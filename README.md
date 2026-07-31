# studdy

iOS 학습 정리 저장소. 로드맵은 [study_list.md](study_list.md), 정리 문서는 study_list의 **묶음(§1~§6)별 폴더**에 넣는다.

## 폴더 구조

| 폴더 | study_list 묶음 | Phase | 상태 |
|---|---|---|---|
| [Swift/](Swift/) | [§1 Swift / SwiftUI](study_list.md#1-swift--swiftui) | 0, 1a | **Phase 0·1a 완료** — 컴포넌트 API 확장 검증 + body 호출 횟수 실측 |
| [Architecture/](Architecture/) | [§2 아키텍처 — MVVM / Clean / TCA](study_list.md#2-아키텍처--mvvm--clean--tca) | 2 | **Phase 2 완료** — §2-A~2-D + TCA 실물 실측, 영상 84편 |
| [Concurrency/](Concurrency/) | [§3 Swift Concurrency](study_list.md#3-swift-concurrency) | 1b | **Phase 1b 완료** — 데모 6개 + Swift 5 모듈을 우회 없이 이행 |
| [AI/](AI/) | [§4 AI 활용 개발 + 비판적 검증](study_list.md#4-ai-활용-개발--비판적-검증) | 전 구간 병행 | 문서 완료 — Phase 0~4 사례 반영, 계속 누적 |
| [Refactoring/](Refactoring/) | [§5 레거시 → 최신 아키텍처 대규모 리팩토링](study_list.md#5-레거시--최신-아키텍처-대규모-리팩토링) | 4 (읽기 전용) | **Phase 4 완료** — 사례 6건 원문 검증, 정정 4건 |
| [DesignSystem/](DesignSystem/) | [§6 공통 컴포넌트 · 디자인 시스템 설계](study_list.md#6-공통-컴포넌트--디자인-시스템-설계) | 3 | **Phase 3 완료** — 접근성 회귀 가드 + 스냅샷 테스트 |

각 폴더의 `README.md`가 그 묶음의 인덱스다. 진행 체크리스트는 [study_list.md 진행 체크리스트](study_list.md#진행-체크리스트).

**Phase 0~4가 전부 닫혔다.** 다음에 무엇을 하는지는 [다음 사이클](study_list.md#다음-사이클-2026-07-31)에 있다 — 새 주제를 늘리지 않고 **이미 약속했는데 안 닫힌 것**만 다룬다. 저장소 전체에서 무엇이 미검증인지는 [미검증 대장](AI/phase-parallel-ai-verification.md#미검증-대장--저장소-전체)이 색인이다.

## 규칙

- **묶음별 폴더**에 정리 문서를 넣는다. 폴더가 헷갈리면 study_list.md의 키워드 → 섹션 매핑 표를 따른다.
- 코드가 있는 문서는 같은 폴더 하위 `code/`에 두고, **실행·컴파일로 검증한 결과만** 문서에 인용한다.
- 외부 라이브러리가 필요한 실습은 루트 [`Package.swift`](Package.swift)에 타겟을 추가한다. `Sources/`를 새로 만들지 않고 **타겟의 `path:`를 기존 `<묶음>/code/` 폴더로 지정**해 위 규칙을 지킨다. 의존성 없는 실습은 그냥 `swift <파일>`로 단독 실행한다.
- 검증하지 못한 주장은 신뢰도 라벨을 붙여 구분한다 (§4-B 비판적 검증의 실천).
- 공부 중 발견한 링크는 분류하지 말고 [study_list.md 링크 수집함](study_list.md#링크-수집함-inbox)에 던진다.
