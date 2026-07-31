# Phase 2-B — Clean / Layered

[study_list.md](../study_list.md) §2-B의 정리.

- **범위**: Entity–UseCase–Repository 경계 · 각 레이어가 아는 것과 모르는 것 · DTO↔Domain 매핑 위치 · 의존성 역전 · 추상화가 과할 때의 신호
- **코드**: [`Architecture/code/phase2/`](code/phase2/) — 구현 비교는 `mvvm_vs_clean.swift`, 경계 가드는 `check_layering.sh`
- **근거**: 인용은 전부 이 저장소의 실행되는 코드다. 레이어 모델 자체는 iOS 앱에서 흔히 쓰는 형태를 정리한 것이고 특정 제품의 것이 아니다

선행: [§2-A 경량 단방향 MVVM](phase2-mvvm.md). 거기서 "Domain이 필요하다"고 미룬 것들을 여기서 다룬다.

---

## 레이어를 나누는 목적은 하나다

경계 자체가 목적이 아니다. **의존성에 방향을 강제하는 것**이 목적이다.

- 모두가 서로 참조하면 순환이 생기고, 순환이 생기면 한 조각만 떼어 테스트하거나 재사용할 수 없다
- 상위(화면)가 하위(기반)에 의존하고 그 역을 금지하면, 기반은 소비자를 모르게 된다. 그때 비로소 재사용·테스트가 가능해진다
- 레이어 개수나 이름은 부차적이다. 방향이 지켜지는지가 전부다

이 관점에서 보면 판단 기준이 하나로 정리된다. **"이 import가 방향을 거스르는가?"**

---

## 1. 레이어 모델

```
        ┌──────────────── Features ────────────────┐   화면 1개 = 모듈 1개
        │                    │                     │
        ▼                    ▼                     │
      Domain ───────────▶ Core(인프라)             │   비즈니스 규칙 / 전역 인프라
        │                    │                     │
        │                    ▼                     ▼
        └──────────────▶ Shared ◀───────── DesignSystem(UI)
                       (순수 유틸)              (토큰·컴포넌트)
```

| 레이어 | 책임 | 판단 기준 | 의존 가능 |
|---|---|---|---|
| **Shared** | 앱/UI/도메인 무관 순수 유틸 | "다른 앱에 복붙 가능?" | Foundation만 |
| **DesignSystem** | UI 파운데이션 | 토큰·컴포넌트·폰트 | Shared |
| **Core** | 전역 인프라 (특정 화면에 안 묶임) | API 클라이언트·Router·DB·플래그 | Shared, ThirdParty |
| **Domain** | 비즈니스 규칙·상태 머신 | 화면을 모른다 | Core, ThirdParty |
| **Features** | 화면 | 화면 1개 = 모듈 1개 | Domain, Core, DesignSystem |
| **ThirdParty** | 외부 SDK 얇은 래퍼 | 벤더 격리 | 서로 |

`[중]` 레이어 개수·이름은 선택이다. **비순환·하향 단방향·"인프라 ↛ UI"만 원칙**이고 나머지는 팀마다 다르게 그어도 된다.

### Core와 DesignSystem은 형제다

여기가 교과서 레이어 그림과 다른 지점이다. 둘은 **위아래가 아니라 병렬**이다.

- 네트워킹 클라이언트가 색상·버튼을 import할 이유가 없다
- 그런데 "하향 단방향" 규칙만으로는 이걸 못 막는다. 둘이 같은 층이라 서로 import해도 방향 위반이 아니다
- 막지 않으면: 네트워킹을 UI 없는 곳(위젯·CLI·테스트)에서 못 쓰고, 버튼 하나 고쳤는데 네트워크 레이어가 재컴파일되고, "Core"의 의미가 흐려진다

선형 레이어로 억지로 세우지 않고 형제로 두되 **별도 가드를 붙이는 것**이 실제 해법이다.

---

## 2. 경계는 선언만으로 지켜지지 않는다

### 빌드 시스템이 잡는 것과 못 잡는 것

- **잡는다**: 순환 의존. SPM/Xcode가 빌드 단계에서 자동 거부한다. 이건 공짜로 얻는다
- **못 잡는다**: 형제 간 방향(`Core → DesignSystem`), Feature 간 직접 참조. 모듈 의존을 선언하면 빌드는 성공한다

그래서 나머지는 lint로 강제해야 한다.

### grep으로 방향을 검사한다

[`code/phase2/check_layering.sh`](code/phase2/check_layering.sh) — 직접 쓴 가드다.

```bash
# 규칙1  Feature       ↛ 다른 Feature
# 규칙2  Core          ↛ Domain / Feature / DesignSystem     ("인프라 ↛ UI" 포함)
# 규칙3  Domain        ↛ Feature / DesignSystem              (비즈니스 로직엔 뷰 없음)
# 규칙4  DesignSystem  ↛ Core / Domain / Feature
# 규칙5  Shared        ↛ 상위 전부
# * 비순환(DAG)은 SPM/Xcode가 빌드에서 자동 강제하므로 여기서 검사하지 않는다.

grep -hoE '^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+[A-Za-z_][A-Za-z0-9_]*'
```

설계에서 챙긴 세 가지:

- **import 문 grep이면 충분하다.** 정적 분석 도구를 붙이지 않아도 방향 규칙은 텍스트 수준에서 검사된다. 위반 시 `exit 1`로 CI를 실패시킨다
- **금지 목록을 폴더 구조에서 자동 발견한다.** `Modules/<Layer>[/<Name>]/Project.swift`가 있으면 모듈로 인식하므로, 모듈을 추가할 때 스크립트를 고치지 않아도 된다
- **예외를 경로로 뚫어놨다.** `*/Example/*`는 제외한다. 예외가 필요하다는 걸 인정하고 **좁게** 뚫는 게 규칙을 살리는 방법이다

### 실제로 잡는지 확인했다

스크립트를 쓰고 로직을 설명하는 것은 "잡는다"를 확인한 게 아니다. 임시 픽스처에 위반을 심어 돌려봤다 ([`verify_layering_guard.sh`](code/phase2/verify_layering_guard.sh)).

```
✅ 기준선 (허용된 방향만)                기대 pass 실제 pass
✅ 규칙1  Feature → 다른 Feature         기대 fail 실제 fail
✅ 규칙2  Core → DesignSystem (인프라→UI) 기대 fail 실제 fail
✅ 규칙2  Core → Domain                  기대 fail 실제 fail
✅ 규칙3  Domain → DesignSystem          기대 fail 실제 fail
✅ 규칙3  Domain → Feature               기대 fail 실제 fail
✅ 규칙4  DesignSystem → Core            기대 fail 실제 fail
✅ 규칙5  Shared → Core                  기대 fail 실제 fail
✅ 하위 모듈 이름도 인식 (Core/Entity)   기대 fail 실제 fail
✅ @testable import도 검출               기대 fail 실제 fail
✅ Example 경로는 예외 (통과해야 함)     기대 pass 실제 pass
✅ Feature가 자기 모듈 import는 허용     기대 pass 실제 pass

🎉 12개 케이스 전부 기대와 일치 — 가드가 실제로 위반을 잡는다
```

확인된 것 셋:

- **`@testable import`도 잡는다.** 정규식의 선택 그룹이 그 일을 한다. 테스트 코드로 규칙을 우회할 수 없다
- **하위 모듈 이름을 자동으로 인식한다.** `Core/Entity`를 `Shared`에서 import하면 잡힌다. "모듈을 추가할 때 스크립트를 고치지 않아도 된다"는 주장이 실증됐다
- **자기 모듈 import는 통과한다.** 소유 모듈을 허용 목록에 더하는 처리가 동작한다

양성 대조를 붙였다는 게 요점이다. 가드가 통과하는 것만 보면 **가드가 죽어 있어도 통과로 보인다** ([§4-B 사례 17·19·22](../AI/phase-parallel-ai-verification.md#1-실제로-틀렸던-것들)).

---

## 3. 포트를 어디 두는가 — 교과서가 지는 사례

교과서 Clean Architecture는 Repository 프로토콜(포트)을 Domain에 두라고 한다. 구현이 Domain을 향해 의존하게 만드는 것(의존성 역전)이 요점이다.

**그런데 §1의 레이어 규칙과 정면으로 충돌한다.**

- 포트를 Domain에 두면, 구현체(Core)가 Domain을 import해야 한다
- 그런데 규칙2가 `Core ↛ Domain`이다. §2의 가드가 이걸 잡는다 — 위 목록의 네 번째 케이스가 정확히 그 상황이다
- 그래서 포트를 구현체와 같은 레이어(Core)에 두는 선택이 나온다. Domain과 Features는 프로토콜을 소비만 한다

### 이걸 어떻게 평가할 것인가

- **잃은 것**: 순수한 의존성 역전이 아니다. Domain이 Core의 프로토콜에 의존한다. Core를 갈아치우면 Domain의 import가 바뀐다
- **지킨 것**: 의존 방향은 여전히 단방향이고 순환이 없다. 테스트 이음새(프로토콜)도 그대로 있다
- **대안의 비용**: 교과서 배치를 지키려면 포트 전용 모듈을 하나 더 만들거나 규칙을 완화해야 한다. 둘 다 비용이다

**원칙(의존 방향)을 지키면서 관례(포트 위치)를 양보하는 것**이 흔한 결론이고, 중요한 건 그 이유가 코드에 남아 있느냐다.

교과서와 다른 결정을 볼 때 물어볼 것은 "틀렸나"가 아니라 **"무엇을 지키려고 무엇을 양보했나"**다. 이유가 적혀 있으면 판단이 가능하고, 없으면 그냥 사고로 보인다.

---

## 4. DTO ↔ Domain 매핑 위치

### 왜 위치가 문제인가

매핑을 어디서 하느냐가 **서버 변경의 파급 범위**를 결정한다.

- Repository에서 매핑 → 서버 필드명이 바뀌면 매핑 함수 하나만 고친다
- ViewModel에서 매핑 → 화면마다 서버 모양을 알아야 한다. 필드명 변경이 화면 수만큼 번진다
- 매핑을 안 하고 DTO를 그대로 쓰면 → View까지 서버 스키마에 묶인다

### 실습 코드에서 확인

Repository가 경계 역할을 한다.

```swift
struct LiveCountryRepository: CountryRepository {
    func countries() async throws -> [Country] {
        try await transport.fetch().map(Self.map)   // 매핑 위치 = Repository
    }

    /// 서버 필드명이 바뀌면 이 함수 하나만 고친다.
    private static func map(_ dto: CountryDTO) -> Country {
        Country(code: dto.country_code, name: dto.country_name, dialCode: dto.dial_code)
    }
}
```

`CountryDTO`의 `country_code` 같은 스네이크 케이스 필드명이 이 함수 밖으로 나가지 않는다. UseCase와 ViewModel은 `Country.code`만 안다.

[§2-A §6](phase2-mvvm.md#6-god-object를-막는-방어선)에서 지적한 신호가 여기서 해소된다. A 버전의 `State.visible`은 `country_name`을 직접 읽는다 — 서버가 필드명을 바꾸면 화면이 깨진다. B 버전에서는 그 이름이 Repository 밖으로 안 나간다.

### 매핑 경계는 "가장 이른 지점"이어야 한다

경계를 잘 잡아도 무효가 되는 조건이 있다.

- 응답 코드를 닫힌 `enum`으로 디코딩하면, 서버가 새 코드를 추가한 날 **디코딩 자체가 실패**한다. 매핑 함수까지 도달하지도 못한다
- 방어는 열린 타입(`RawRepresentable` 문자열 래퍼)으로 받고, 클라이언트가 실제로 분기하는 값만 상수로 노출하는 것이다
- 그런데 OpenAPI 같은 **코드 생성기가 그 앞에서 닫힌 enum으로 디코딩**하면 방어가 무의미해진다

교훈: **매핑 경계는 데이터가 통과하는 가장 이른 지점이어야 한다.** 중간에 코드 생성기나 라이브러리가 끼면 그쪽이 실제 경계다.

`[중]` 이 절은 서술이다. 실습 코드에 코드 생성기를 붙여 재현하지 않았다.

---

## 5. 확인 — 같은 화면을 Clean으로

§2-A와 동일한 화면(국가 선택)을 Entity/UseCase/Repository로 나눠 구현하고 같은 시나리오를 돌렸다.

```
[A] 경량 단방향 MVVM
  재시도 성공: ["KR", "US", "GB", "JP"]
  '국' 필터: ["KR", "US", "GB"]

[B] Clean + MVVM
  재시도 성공: ["KR", "US", "GB", "JP"]
  '국' 필터: ["KR", "US", "GB"]
```

**관측 가능한 동작이 완전히 같다.** 차이는 전부 구조에 있다.

### 수치

주석·빈 줄을 제외하고 실측했다.

| | A: 경량 MVVM | B: Clean + MVVM |
|---|---|---|
| 코드 줄 수 | **54** | **83** (1.5배) |
| 선언 개수 | **3** (ViewModel·State·Action) | **9** (+Entity·Repository 포트·Live·Stub·UseCase 포트·UseCase 구현) |
| ViewModel이 아는 것 | 전송 프로토콜, DTO 필드명 | UseCase 프로토콜 하나 |
| 정렬 규칙 위치 | `State.visible` 계산 프로퍼티 | `FetchCountriesUseCase` |
| 서버 필드명 변경 시 | ViewModel·State 수정 | 매핑 함수 1개 |
| 테스트 이음새 | 전송 프로토콜 (네트워크 흉내) | Repository·UseCase 둘 다 |

### 테스트 이음새의 실제 차이

```
[C] 테스트 이음새
  UseCase 단독 검증(KR 최상단): ["KR", "US"]
  ViewModel 검증(스텁 주입): ["KR", "US"]
```

- B는 **비즈니스 규칙을 ViewModel 없이** 검증할 수 있다. `FetchCountriesUseCase`에 스텁 Repository를 주고 정렬 결과만 본다. 화면도 비동기 완료 대기도 필요 없다
- A에서 같은 규칙(한국 우선 정렬)을 검증하려면 ViewModel을 만들고 `sendAction`을 보내고 로드 완료를 기다려야 한다. 규칙은 `State.visible` 안에 있으니 상태를 세팅해 계산 프로퍼티를 읽는 방법도 있지만, 그러려면 `private(set) state`를 우회할 창구가 필요하다
- 이게 "테스트 용이성"의 구체적 내용이다. 추상적 장점이 아니라 **규칙을 얼마나 작은 단위로 격리해 확인할 수 있는가**의 차이

---

## 6. 과할 때의 신호

레이어는 공짜가 아니다.

| 신호 | 의미 |
|---|---|
| 구현이 하나뿐인 프로토콜이 늘어난다 | 조기 추상화. 두 번째 구현이 나타날 때 뽑는다 ([Phase 0 §3](../Swift/phase0-language-core.md#3-프로토콜--pat와-some--any)) |
| UseCase가 Repository 호출을 그냥 전달한다 | 레이어가 값을 못 만들고 있다. 규칙이 없으면 UseCase도 없어도 된다 |
| 파일 6개를 열어야 한 필드가 추가된다 | 경계 수가 변경 빈도와 안 맞는다 |
| 엄브렐라 모듈이 빈 네임스페이스뿐이다 | 구조를 먼저 만들고 내용을 못 채운 상태 |

두 번째 신호가 실습 코드 B에 있다. `FetchCountriesUseCase`가 하는 일은 정렬 하나뿐이다 — 규칙이 이것뿐이라면 UseCase 레이어의 값은 "규칙을 화면 밖에 둔다" 하나다. 규칙이 늘지 않으면 과한 배치다.

### 가드가 잡아주지 않는 위반

방향 규칙은 통과하는데 설계 의도는 어기는 의존이 있다.

- `Features → Core` 직결. 규칙상 허용이라 가드에 안 걸리지만, Domain을 거쳐야 할 로직이 화면에 붙는 통로가 된다
- 전면 금지하면 DesignSystem·Router 사용까지 막히므로 규칙을 느슨하게 둘 수밖에 없다

교훈: **자동 가드는 방향만 본다. 레이어를 건너뛰는 의존은 리뷰와 문서로 잡아야 한다.**

---

## 7. 통과 기준 진행 상황

Phase 2 통과 기준은 "같은 화면 하나를 MVVM / Clean+MVVM / TCA 3가지로 구현하고 트레이드오프를 수치로 말할 수 있다"다.

- [x] MVVM 구현 ([§2-A §5](phase2-mvvm.md#5-확인--같은-화면을-이-패턴으로))
- [x] Clean + MVVM 구현 (§5)
- [x] Reducer + Store 구현 — [§2-D §1](phase2d-comparison.md#1-세-번째-구현--reducer--store). TCA 라이브러리가 아닌 최소 재현
- [x] A vs B 트레이드오프 수치화 (§5)
- [x] 3자 비교 — [§2-D §2](phase2d-comparison.md#2-비교-축--수치)
- [x] 실제 TCA 라이브러리로 컴파일 시간·러닝커브 측정 — **완료 (2026-07-31)**, [§2-C](phase2c-tca.md)

§2-D에서 이 축들이 수치로 채워졌다: 코드 줄 수 / 선언 수 / 규칙 격리 단위 / 서버 변경 파급 범위 / **결정론을 누가 제공하는가**. 마지막 축이 결국 **유일한 결정적 차이**였다 — 화면당 코드량은 A와 C가 거의 같았다 ([§2-D §2](phase2d-comparison.md#2-비교-축--수치)·[§3](phase2d-comparison.md#3-테스트-결정론이-실제-차이다)).

---

## 8. 스스로 물어볼 것

- 레이어를 나누는 목적을 한 문장으로 말할 수 있는가 (도입부)
- Core와 DesignSystem을 형제로 두면 무엇이 안 막히고, 어떻게 막는가 (§1·§2)
- 빌드 시스템이 자동으로 잡는 위반과 못 잡는 위반은 각각 무엇인가 (§2)
- 가드가 실제로 잡는지 어떻게 확인했는가. 안 했으면 무엇을 착각할 수 있는가 (§2)
- 포트를 Domain이 아니라 Core에 두면 무엇을 지키고 무엇을 양보하는가 (§3)
- DTO 매핑을 Repository에서 하는 이유와, 그 방어가 무효가 되는 조건 (§4)
- 같은 화면을 Clean으로 짜면 코드가 늘어나는 대신 무엇을 얻는가 (§5)
- 레이어가 과하다는 신호 세 가지 (§6)

---

## 9. 검증 기록

### 환경

```
swift-driver version: 1.148.6 Apple Swift version 6.3.3
Target: arm64-apple-macosx26.0
```

### 실행한 것

| 대상 | 명령 | 결과 |
|---|---|---|
| §5 A·B 구현 + 테스트 이음새 | `swift -swift-version 6 Architecture/code/phase2/mvvm_vs_clean.swift` | 실행, 경고 0. 출력을 그대로 인용 |
| §5 수치 (줄 수·선언 수) | 소스의 `<A>`/`<B>` 마커 구간을 파싱해 계산 | A 54줄·3선언 / B 83줄·9선언 |
| §2 가드가 실제로 위반을 잡는지 | `bash Architecture/code/phase2/verify_layering_guard.sh` | 12개 케이스 전부 기대와 일치 |

### 확인하지 못한 것

| 주장 | 상태 |
|---|---|
| §4의 "생성기가 앞에서 닫힌 enum으로 디코딩한다" | **서술 [중]**. 실습 코드에 코드 생성기를 붙여 재현하지 않았다 |
| §5 수치의 일반성 | **이 화면 한정 [중]**. 화면이 복잡해지면 비율이 달라진다. 절대 수가 아니라 방향만 참고 |
| 실제 앱 규모에서 레이어 유지 비용 | **미검증 [저]**. 화면 하나짜리 실습이다 |
| 교과서 Clean Architecture 원문 대조 | **미확인 [저]**. §3의 "교과서는 포트를 Domain에" 서술은 통념 기준이고 원전을 대조하지 않았다 |
| §1 레이어 모델이 최선인지 | **선택 [중]**. 흔한 형태 하나를 정리한 것이다. 원칙은 방향이고 배치는 팀마다 다르다 |

---

## 참고 자료

- 📚 [objc.io — App Architecture](https://www.objc.io/books/app-architecture/) — 같은 앱을 여러 패턴으로 구현해 비교

다음은 [§2-C — TCA 실물](phase2c-tca.md). 여기까지가 라이브러리 없이 가는 길이고, 거기서 실제 TCA를 붙여 비용을 잰다.
