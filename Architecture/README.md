# 아키텍처 — MVVM / Clean / TCA

[study_list.md §2](../study_list.md#2-아키텍처--mvvm--clean--tca) 묶음. Phase 2.

**통과 기준**: 같은 화면 하나를 MVVM / Clean+MVVM / TCA 3가지로 구현하고 트레이드오프를 수치로 말할 수 있다.

## 하위 정리

| 범위 | 위치 | 상태 |
|---|---|---|
| §2-A MVVM | [phase2-mvvm.md](phase2-mvvm.md) | 작성 완료. 단방향 상태 흐름·Tasker·God object 방어선 |
| §2-B Clean / Layered | [phase2-clean-layered.md](phase2-clean-layered.md) | 작성 완료. 레이어 모델·경계 가드 자체 구현·DTO 매핑 |
| §2-C TCA — 실물 | [phase2c-tca.md](phase2c-tca.md) | 작성 완료. TCA 1.26.1로 같은 화면 재구현 + `TestStore` 8건 통과 + 비용 실측 |
| §2-C TCA — 영상 | [ComposableArchitecture/](ComposableArchitecture/) | 완료 — Point-Free 컬렉션 14섹션 84편 (자체 인덱스 있음) |
| §2-D 비교 & 모듈화 | [phase2d-comparison.md](phase2d-comparison.md) | 작성 완료. 3자 비교 + 모듈화 실물 대조 |

## 통과 기준 — Phase 2 종료

- [x] MVVM 구현 ([phase2-mvvm.md §5](phase2-mvvm.md#5-확인--같은-화면을-이-패턴으로))
- [x] Clean + MVVM 구현 ([phase2-clean-layered.md §5](phase2-clean-layered.md#5-확인--같은-화면을-clean으로))
- [x] Reducer + Store 구현 ([phase2d-comparison.md §1](phase2d-comparison.md#1-세-번째-구현--reducer--store)) — **단 TCA 라이브러리가 아니라 최소 재현**
- [x] 세 구현의 관측 동작이 동일함을 출력으로 확인
- [x] 트레이드오프 수치화 — 화면당 코드량 · 테스트 결정론 · 규칙 위치 ([§2-D §2](phase2d-comparison.md#2-비교-축--수치))
- [x] 측정 불가한 축(컴파일 시간·러닝커브·lock-in)을 명시하고 수치를 만들지 않음
- [x] 실제 TCA 라이브러리를 붙여 컴파일 시간·러닝커브 측정 ([phase2c-tca.md §5](phase2c-tca.md#5-비용--실측)) — 증분 9.51s vs 1.15s, API 표면 22개 vs 9개
- [x] 상태 합성(`Scope`·`ifLet`·`forEach`)과 `@Dependency`를 실물로 확인 ([§2-C §2·§3](phase2c-tca.md#3-상태-합성--scope--foreach--iflet))

남은 것: **팀 온보딩 비용**은 혼자 하는 학습으로는 원리적으로 측정 불가라 열어 둔다.

## 코드

[`code/phase2/`](code/phase2/) — 단독 실행. 리포 루트에서:

```
swift -swift-version 6 Architecture/code/phase2/mvvm_vs_clean.swift   # A·B
swift -swift-version 6 Architecture/code/phase2/three_way.swift       # C + TestStore (손코딩)
bash  Architecture/code/phase2/verify_layering_guard.sh               # 레이어 가드 실증
```

[`code/phase2c/`](code/phase2c/) — SPM 타겟. 루트 `Package.swift`가 이 경로를 가리킨다:

```
swift test --filter TCADemo    # 실물 TCA — 8건
```

같은 화면(국가 선택)을 네 번 구현해 **동작이 같고 구조만 다르다**는 것을 확인한다. `phase2c`는 `three_way.swift`의 도메인을 그대로 쓴다 — 차이가 라이브러리에서만 오게 하려고.

## 예상과 달랐던 결과

**화면당 코드량에서 C가 A와 거의 같았다.** "리듀서 패턴은 보일러플레이트가 많다"는 통념이 이 축에서는 확인되지 않았다 — 추가 비용이 화면이 아니라 **일회성 인프라**(리듀서 코어 + 테스트 하네스)에 있었다. 실제 차이는 **테스트 결정론**이었다.

수치는 [§2-D §2](phase2d-comparison.md#2-비교-축--수치)와 소스 마커 파싱이 SoT다. 여기 옮겨 적으면 낡는다.

## 읽을 때 유지할 것

아키텍처 자료는 장점만 적혀 있다. 각 자료마다 **"이 구조가 무엇을 포기했는지"**를 따로 메모해 §2-D 비교 축(테스트 용이성 / 온보딩 비용 / 컴파일 시간 / 화면당 코드량)의 재료로 쌓는다. 채택 회사의 회고([Refactoring/](../Refactoring/))와 붙여 읽으면 균형이 잡힌다.

