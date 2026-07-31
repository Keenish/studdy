# studdy

iOS 학습 정리 저장소. 로드맵은 [study_list.md](study_list.md), 정리 문서는 study_list의 **묶음(§1~§6)별 폴더**에 있다.

**이 저장소의 성격**: 튜토리얼이 아니라 **검증 기록**이다. 각 문서는 "이렇게 하면 된다"가 아니라 "이걸 돌려봤고 이런 출력이 나왔다, 그리고 이건 확인하지 못했다"로 쓰여 있다. 그래서 인용된 수치에는 그것을 낸 명령이 같이 붙어 있고, 확인하지 못한 것에는 라벨이 붙어 있다.

## 증거 규칙

이 저장소를 읽을 때 가장 먼저 알아야 할 규칙이다. 문장마다 무게가 다르다.

| 표기 | 뜻 | 읽는 법 |
|---|---|---|
| (라벨 없음) | **실행·컴파일 출력으로 확인함.** 인용된 출력은 실제 출력과 글자 단위로 같다 | 그대로 믿어도 된다. 재현 명령이 §검증 기록에 있다 |
| `[중]` | 널리 알려진 동작이지만 **여기서 측정하지 않음** | 방향은 맞을 것이나 근거는 이 저장소 밖에 있다 |
| `[저]` | 계획·가설·경험 규칙. **아직 해보지 않음** | 판단의 촉발점으로만 쓴다 |
| **검증되지 않음** | 시도했으나 환경·권한 때문에 확인 실패 | 왜 실패했는지가 같이 적혀 있다 |

각 문서 마지막 절이 **§검증 기록**이고, 거기에 "실행한 것"과 "확인하지 못한 것"이 표로 있다. 저장소 전체의 미검증 항목은 [미검증 대장](AI/phase-parallel-ai-verification.md#미검증-대장--저장소-전체)이 원인별로 색인한다.

**왜 이렇게 쓰나**: 검증 강도를 표시하지 않으면 "돌려본 것"과 "그럴듯한 것"이 같은 무게로 읽힌다. 그 구분이 [§4 비판적 검증](AI/phase-parallel-ai-verification.md)의 주제이고, 이 저장소는 그걸 자기 자신에게 적용한 결과다.

## 재현

문서가 인용한 것을 전부 다시 돌린다.

```
bash verify_all.sh           # 13개 — 빌드·테스트·단독 실행물·링크 검사
bash verify_all.sh --quick   # 빌드·테스트·링크만
```

통과한다고 문서가 옳은 것은 아니다. 이 스크립트는 **코드가 여전히 도는지**만 본다. 문서의 수치가 출력과 같은지는 사람이 봐야 한다.

## 읽는 순서

로드맵은 **의존성 순서**로 짜여 있다. 앞이 뒤의 선수지식이다.

```
Phase 0  언어 코어        Swift/phase0-language-core.md
   ▼
Phase 1a SwiftUI 렌더링   Swift/phase1-swiftui-rendering.md
Phase 1b Concurrency      Concurrency/phase1-concurrency.md      (1a와 같은 층)
   ▼
Phase 2  아키텍처         Architecture/  §2-A → §2-B → §2-C → §2-D
   ▼
Phase 3  디자인 시스템    DesignSystem/phase3-design-system.md
   ▼
Phase 4  대규모 리팩토링  Refactoring/phase4-large-scale-refactoring.md
```

[§4 AI 활용과 비판적 검증](AI/phase-parallel-ai-verification.md)은 전 구간 병행이다. **먼저 읽어도 좋다** — 나머지 문서를 어떤 눈으로 읽어야 하는지가 거기 있다.

각 문서는 `## N. …` 절 + `## 스스로 물어볼 것` + `## 검증 기록`으로 같은 골격을 갖는다. 시간이 없으면 **"스스로 물어볼 것"만 읽고 답해 보는 것**이 가장 빠른 점검이다.

## 폴더 구조

| 폴더 | study_list 묶음 | Phase | 상태 |
|---|---|---|---|
| [Swift/](Swift/) | [§1 Swift / SwiftUI](study_list.md#1-swift--swiftui) | 0, 1a | **완료** — 컴포넌트 API 확장 검증 + body 호출 횟수 실측 |
| [Concurrency/](Concurrency/) | [§3 Swift Concurrency](study_list.md#3-swift-concurrency) | 1b | **완료** — 데모 6개 + Swift 5 모듈을 우회 없이 이행 |
| [Architecture/](Architecture/) | [§2 아키텍처 — MVVM / Clean / TCA](study_list.md#2-아키텍처--mvvm--clean--tca) | 2 | **완료** — §2-A~2-D + TCA 실물 실측, 영상 84편 |
| [DesignSystem/](DesignSystem/) | [§6 공통 컴포넌트 · 디자인 시스템 설계](study_list.md#6-공통-컴포넌트--디자인-시스템-설계) | 3 | **완료** — 접근성 회귀 가드 + 스냅샷 테스트 |
| [Refactoring/](Refactoring/) | [§5 레거시 → 최신 아키텍처 대규모 리팩토링](study_list.md#5-레거시--최신-아키텍처-대규모-리팩토링) | 4 (읽기 전용) | **완료** — 공개 사례 6건 원문 검증, 정정 4건 |
| [AI/](AI/) | [§4 AI 활용 개발 + 비판적 검증](study_list.md#4-ai-활용-개발--비판적-검증) | 전 구간 병행 | 진행형 — 사례를 계속 누적 |

각 폴더의 `README.md`가 그 묶음의 인덱스다. 진행 체크리스트는 [study_list.md](study_list.md#진행-체크리스트).

**Phase 0~4가 전부 닫혔다.** 다음에 무엇을 하는지는 [다음 사이클](study_list.md#다음-사이클-2026-07-31)에 있다 — 새 주제를 늘리지 않고 **이미 약속했는데 안 닫힌 것**만 다룬다.

## 쓸 때의 규칙

- **묶음별 폴더**에 정리 문서를 넣는다. 헷갈리면 study_list의 키워드 → 섹션 매핑 표를 따른다.
- 코드가 있는 문서는 같은 폴더 하위 `code/`에 두고, **실행·컴파일로 검증한 결과만** 인용한다.
- **검증에 `-typecheck`을 쓰지 않는다.** strict concurrency의 region isolation 진단은 SIL 패스에서 나오고 `-typecheck`은 그걸 0건 잡는다. `-c`나 `swift build`를 쓴다 ([사례 21](AI/phase-parallel-ai-verification.md#1-실제로-틀렸던-것들)).
- **같은 수치를 두 곳에 두지 않는다.** 인덱스(`README`)에는 "무엇을 찾았나"만 적고 값은 본문을 가리킨다. 두 사본은 반드시 어긋난다.
- 검증하지 못한 주장은 지우지 말고 **라벨을 붙여 남긴다**. 틀린 결과도 지우지 말고 왜 틀렸는지를 같이 적는다.
- 외부 라이브러리가 필요한 실습은 루트 [`Package.swift`](Package.swift)에 타겟을 추가한다. `Sources/`를 새로 만들지 않고 **타겟의 `path:`를 기존 `<묶음>/code/` 폴더로 지정**한다. 의존성 없는 실습은 `swift <파일>`로 단독 실행한다.
- **비공개 코드·디자인 자산을 인용하지 않는다.** 이 저장소는 public이다. 자세한 규칙은 [`CLAUDE.md`](CLAUDE.md).
- 공부 중 발견한 링크는 분류하지 말고 [링크 수집함](study_list.md#링크-수집함-inbox)에 던진다.

## 환경

```
Apple Swift version 6.3.3 · arm64-apple-macosx26.0
```

**macOS에서 빌드한다.** 그래서 UIKit·Dynamic Type·iOS 실기기가 필요한 항목은 구조적으로 검증할 수 없고, 해당 문서에 그렇게 적혀 있다. 이 환경 제약이 [미검증 대장](AI/phase-parallel-ai-verification.md#미검증-대장--저장소-전체)의 가장 큰 묶음이다.
