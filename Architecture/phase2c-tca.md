# Phase 2-C — TCA 실물

[study_list.md §2-C](../study_list.md#2-c-tca)의 정리. Phase 2에서 마지막까지 비어 있던 조각이다.

- **코드**: [`Architecture/code/phase2c/`](code/phase2c/) — 소스 4개 · 테스트 2개. `swift test` 로 8건 통과 확인
- **대조 대상**: [`code/phase2/three_way.swift`](code/phase2/three_way.swift) 버전 C — 같은 화면을 라이브러리 없이 손으로 만든 것
- **영상 정리**: [ComposableArchitecture/](ComposableArchitecture/) 14섹션 84편
- **선행**: [§2-D](phase2d-comparison.md) — 이 문서의 실측이 §2-D의 미측정 축을 닫는다

## 이 문서가 존재하는 이유

§2-D는 "같은 화면을 3가지로" 구현했지만 C가 **라이브러리가 아니라 최소 재현**이었다. 그래서 §2-D는 컴파일 시간·러닝커브·lock-in 세 축을 `❌ 측정 불가`로 남기고 이렇게 적었다.

> 이 축은 실제 프로젝트에서 라이브러리를 붙여 재보는 수밖에 없다. 여기서 "차이 없음"이라고 적으면 거짓이 된다. — [§2-D](phase2d-comparison.md#컴파일-시간--이-규모에서는-답이-안-나온다)

붙여서 재봤다. **도메인은 한 글자도 바꾸지 않았다** — `Country`·`LoadFailure`·정렬 규칙·검색 필터가 전부 같다. 그래야 차이가 라이브러리에서만 온다.

**환경**: TCA 1.26.1 · Swift 6.3.3 · macOS 26.0 (arm64) · Xcode 26.6

---

## 1. 기본 루프 — Reducer / Store / Effect

손코딩 리듀서와 TCA 리듀서를 나란히 두면 **로직이 같고 껍데기만 다르다**.

| | 손코딩 (three_way.swift) | TCA 1.26.1 |
|---|---|---|
| 리듀서 | 자유 함수 `let countryReducer: Reducer<...>` | `@Reducer struct CountryList` + `var body` |
| 의존성 | `env` 인자로 명시 전달 | `@Dependency` 프로퍼티 |
| 효과 반환 | `[Effect<Action>]` 배열 | `.run { send in }` / `.none` |
| 상태 | `struct State: Equatable` | `@ObservableState struct State: Equatable` |

분기 안의 코드는 거의 그대로 옮겨졌다. 정렬 규칙도 같은 자리(`.response(.success)`)에 있다.

```swift
case .appeared, .retryTapped:
    state.isLoading = true
    state.errorMessage = nil
    return .run { send in
        do {
            await send(.response(.success(try await countryClient.load())))
        } catch {
            await send(.response(.failure(.network)))
        }
    }
```

손코딩은 `[Effect { .response(await env.loadCountries()) }]` 한 줄이었다. **TCA 쪽이 더 길다** — `.run`은 액션을 여러 번 보낼 수 있는 일반형이라(ep198) 한 번만 보내는 경우엔 오히려 의식이 는다.

### 액션 이름 — ep243의 원칙이 실제로 걸린다

`loadCountries`가 아니라 `appeared`·`retryTapped`다. "사용자가 UI에서 한 일"을 이름에 담으면 같은 처리를 하는 두 진입점이 자연스럽게 한 분기에 묶인다. 손코딩 때도 같은 이름을 썼으니 이건 라이브러리가 준 게 아니라 **영상에서 배운 설계 습관**이다.

---

## 2. 의존성 — `@Dependency`

`CountryEnvironment`와 `CountryClient`는 **필드 구성이 같다**. 프로토콜이 아니라 함수를 담은 구조체라는 점도 같다(ep83). 달라진 건 전달 방식뿐이다.

```swift
struct CountryClient: Sendable {
    var load: @Sendable () async throws -> [Country]
    var preferredCode: String = "KR"
}
```

세 기본값이 각각 다른 상황을 맡는다 — 이게 손코딩에 없던 부분이다.

| | 역할 | 확인된 것 |
|---|---|---|
| `liveValue` | 실서비스 | — |
| `testValue` | **호출되면 실패** (ep207) | 테스트로 실제 발화 확인 |
| `previewValue` | 프리뷰가 멈추지 않게 (ep248) | 미검증 — 프리뷰를 띄우지 않았다 |

### `testValue = unimplemented` 가 실제로 잡는다

말로만 읽었던 걸 테스트로 걸어 확인했다.

```swift
@Test
func 의존성을_빠뜨리면_테스트가_실패한다() async {
    await withKnownIssue {
        let store = TestStore(initialState: CountryList.State()) { CountryList() }
        // load 를 덮지 않았다 → testValue = unimplemented 가 호출된다.
        await store.send(.appeared) { $0.isLoading = true }
        await store.receive(.response(.success([]))) { $0.isLoading = false }
    }
}
```

실행 결과 — 파일·라인까지 짚어 준다:

```
􀢂 Test 의존성을_빠뜨리면_테스트가_실패한다() recorded a known issue
   Unimplemented: CountryClient.load …
     Defined in 'CountryClient' at:
       TCADemo/CountryClient.swift:25
     Invoked with:
       ()
```

**손코딩 버전에는 이 안전망이 없었다.** 거기선 `CountryEnvironment`를 만들 때 클로저를 반드시 채워야 해서 컴파일러가 막아 주긴 했지만, 기본값을 둔 순간(`preferredCode`처럼) 조용히 통과한다. TCA는 "기본값이 있으면서도 쓰이면 실패"라는 제3의 상태를 만든 것이다.

---

## 3. 상태 합성 — `Scope` · `forEach` · `ifLet`

**손코딩 재현본에는 이게 아예 없었다.** 화면 하나짜리라 pullback도 combine도 쓸 일이 없었고, 그래서 §2-D는 "합성이 왜 필요한가"를 다루지 못했다. 여기서 처음으로 부모-자식이 생긴다.

| 도구 | 대상 | 대응하는 영상 |
|---|---|---|
| `Scope` | 자식 도메인 1개 | ep69·70 pullback |
| `.forEach` | 컬렉션의 각 원소 | ep233·235 |
| `.ifLet` | 옵셔널 자식 | ep225·228 |

### 실제로 걸린 것 — `body` 안 리듀서의 실행 순서

부모가 자식 액션을 가로채 즐겨찾기 목록을 만드는 코드를 처음엔 이렇게 썼다.

```swift
case let .list(.response(.success(countries))):
    state.favorites = IdentifiedArray(
        uniqueElements: countries.map { FavoriteRow.State(country: $0) }   // ← 액션 페이로드
    )
```

**테스트가 잡았다.** 목록은 정렬돼 있는데 즐겨찾기는 안 돼 있었다:

```
     _favorites: [
       [0]: FavoriteRow.State(…),
 +     [1]: FavoriteRow.State(country: Country(code: "JP", name: "일본"), …),
       … (2 unchanged)
 −     [3]: FavoriteRow.State(country: Country(code: "JP", name: "일본"), …)
     ],
```

액션 페이로드는 **클라이언트가 준 정렬 전 목록**이고, 정렬은 자식 리듀서가 상태에 한 것이다. `body` 안의 리듀서는 적힌 순서대로 도니까 — `Scope`가 먼저 끝나 있다 — 부모는 페이로드가 아니라 `state.list.countries`를 읽어야 했다.

```swift
case .list(.response(.success)):
    state.favorites = IdentifiedArray(
        uniqueElements: state.list.countries.map { FavoriteRow.State(country: $0) }
    )
```

이건 **라이브러리를 붙여야만 만날 수 있는 종류의 함정**이다. 화면 하나짜리 재현본에서는 존재할 수 없었다. §2-D가 합성을 다루지 못한 대가가 여기서 드러났다.

### `ifLet` — 부모가 "닫기"를 정의하지 않는다

자식이 `@Dependency(\.dismiss)`를 부르면 부모의 옵셔널이 비워진다. 부모 액션에 `detailClosed` 같은 걸 만들지 않았다.

```swift
await store.send(.detail(.presented(.closeTapped)))
await store.receive(\.detail.dismiss) { $0.detail = nil }
```

---

## 4. `TestStore` — 손코딩 하네스와 무엇이 다른가

손코딩 TestStore(42줄)도 같은 일을 했다. 나란히 두면 라이브러리가 더 준 게 뚜렷하다.

| | 손코딩 42줄 | TCA |
|---|---|---|
| 보낸/받은 액션 구분 | ✅ | ✅ |
| 상태 전수 검증 | ✅ (`!=` 비교) | ✅ (**diff 출력**) |
| 잔여 효과 검출 | ✅ (`finish()` 수동 호출) | ✅ (**자동**) |
| 실패 위치 | 문자열 메시지 | **파일·라인** |
| 비전수 모드 | ❌ | ✅ `exhaustivity = .off` |
| 키패스 기반 기대 | ❌ | ✅ `receive(\.list.response.success)` |
| 시간 통제 | ❌ | ✅ `TestClock` (이번엔 미사용) |

**차이는 진단 품질에 몰려 있다.** 위 §3의 버그를 손코딩 하네스는 `"receive(...) 후 상태 불일치"`라는 한 줄로만 알렸을 것이다. TCA는 어느 원소가 어디로 갔는지 diff로 보여줬고, 그래서 원인(정렬 전/후)이 바로 읽혔다.

### `Action: Equatable`을 빼면 값 비교가 막힌다

`AppFeature.Action`에 `Equatable`을 안 붙였더니 컴파일 에러가 났다.

```
error: 'receive(_:...)' is unavailable: Provide a key path to the case you
       expect to receive (like 'store.receive(\.tap)'), or conform 'Action'
       to 'Equatable' to assert against it directly.
```

라이브러리가 **키패스 방식을 기본으로 두고** 값 비교는 옵트인으로 열어 둔 것이다. 큰 액션 트리에서 전체 값을 적는 게 비현실적이니 합리적인 기본값이다.

---

## 5. 비용 — 실측

### 빌드 시간

`swift package clean` 후 측정. 의존성 체크아웃은 유지했다(= 재다운로드 시간 제외).

| | 시간 |
|---|---|
| 클린 빌드 (의존성 14개 전부 컴파일 포함) | **75.07s** |
| 증분 — 리듀서 파일 1개 `touch` | **9.51s** |
| 무변경 | 0.19s |
| *(대조)* 손코딩 단일 파일 `swiftc` 전체 컴파일 | **1.15s** |

**일상 비용은 증분 9.51s다.** 리듀서 한 파일을 고칠 때마다 이만큼 기다린다 — `@Reducer`·`@ObservableState` 매크로 확장이 대부분이다. 손코딩 버전은 파일 전체를 처음부터 컴파일해도 1.15s였다.

§2-D가 "판별되지 않는다"고 적었던 축이 **8배 차이로 판별됐다.** 다만 이건 파일 4개짜리 학습용 타겟이고, 실제 앱에서 화면 수에 따라 어떻게 늘어나는지는 여기서 알 수 없다.

### 의존성

TCA 1.26.1 하나를 넣으면 **13개가 따라온다** (총 14 pin).

```
combine-schedulers 1.2.0          swift-dependencies 1.14.1
swift-case-paths 1.9.1            swift-identified-collections 1.1.1
swift-clocks 1.1.0                swift-navigation 2.11.0
swift-collections 1.6.0           swift-perception 2.0.11
swift-composable-architecture     swift-sharing 2.9.1
                          1.26.1  swift-syntax 603.0.2
swift-concurrency-extras 1.4.1    xctest-dynamic-overlay 1.11.0
swift-custom-dump 1.6.1
```

**통념과 달랐던 것 하나** — swift-syntax를 소스로 빌드하지 않았다. Swift 6.3.3 툴체인에 맞는 **prebuilt 바이너리를 2.61초 만에 내려받았다**.

```
Downloading package prebuilt .../603.0.2/swiftlang-6.3.3.1.3-macosx26.5-MacroSupport.zip
Downloaded (2.61s)
```

"TCA는 swift-syntax 때문에 첫 빌드가 몇 분"이라는 말은 **이 환경에서는 더 이상 사실이 아니다.** 툴체인 버전이 prebuilt와 안 맞으면 소스 빌드로 떨어질 테니 조건부 결론이다.

### 코드량

주석·빈 줄 제외.

| | 줄 |
|---|---|
| 손코딩 — 화면 기능부 `<C>` | 53 |
| **TCA — `CountryList.swift`** | **54** |
| 손코딩 — 직접 만든 인프라 (코어 23 + TestStore 42) | 65 |
| **TCA — 그 인프라에 해당하는 내 코드** | **0** |
| TCA — `AppFeature.swift` (합성, 손코딩에 대응물 없음) | 87 |
| TCA — `CountryClient.swift` | 26 |
| TCA 소스 합계 / 테스트 합계 | 188 / 120 |

**화면 하나만 놓고 보면 라이브러리가 코드를 줄여 주지 않는다** (53 vs 54). 라이브러리가 대신 내주는 건 인프라 65줄이고, 그건 화면 수와 무관하게 한 번 내는 비용이다. 즉 **화면이 적을수록 라이브러리가 손해**다.

### 러닝커브 — 새 API 표면 (프록시)

이 화면 하나를 만드는 데 실제로 쓴 TCA API:

```
@Reducer  @ObservableState  ReducerOf  Reduce  Effect(.run/.none)
@Dependency  DependencyKey  DependencyValues  liveValue/testValue/previewValue
Scope  .forEach  .ifLet  @Presents  PresentationAction  IdentifiedActionOf
IdentifiedArrayOf  TestStore  send/receive  exhaustivity  withDependencies
unimplemented  @Dependency(\.dismiss)
```

**22개.** §2-D의 프록시(C = 9개)는 최소 재현 기준이었다. 실물은 그 2.4배이고, 이것도 `TestClock`·`Shared`·`NavigationStack` 계열을 안 썼을 때의 수치다.

개념 수는 여전히 프록시일 뿐이다. 다만 §2-D에서 "개수가 아니라 낯섦"이라고 적은 것과 별개로, **22개는 개수 자체가 부담이 되는 규모**다.

### lock-in

측정한 게 아니라 코드를 보고 판단한 것이다 `[중]`.

- 도메인 타입(`Country`·`LoadFailure`)은 TCA를 모른다 — 그대로 들어낼 수 있다
- 리듀서의 `switch` 본문도 대부분 옮겨진다. 실제로 손코딩 → TCA 이식이 거의 복붙이었다
- 묶여 있는 건 **합성 계층**이다. `Scope`/`ifLet`/`forEach`와 `@Presents` 기반 내비게이션은 대응물을 직접 만들어야 한다
- 테스트가 가장 강하게 묶인다 — `TestStore` 기반 테스트는 통째로 다시 쓴다

---

## 6. 종합 — §2-D의 표를 닫는다

| 축 | §2-D 상태 | 지금 |
|---|---|---|
| 화면당 코드량 | ✅ 패턴 수준 | ✅ 실물 확인 — 화면부는 같고(53/54), 인프라 65줄이 사라진다 |
| 비즈니스 규칙 위치 | ✅ | ✅ 변화 없음 — 같은 자리 |
| 테스트 결정론 | ✅ | ✅ + 진단 품질이 실제 버그를 잡았다 |
| **컴파일 시간** | ❌ 측정 불가 | ✅ **증분 9.51s vs 1.15s** |
| **러닝커브** | ❌ 측정 불가 | ✅ **API 표면 22개 vs 9개** (프록시) |
| **lock-in** | ❌ 측정 불가 | 🟡 정성 판단 — 도메인은 자유, 합성·테스트가 묶인다 |
| 팀 온보딩 | ❌ | ❌ **여전히 측정 불가** — 혼자 했다 |

### 언제 값을 하나

이 실습만으로 말할 수 있는 범위에서:

- **화면이 적고 합성이 없으면 손해다.** 코드량 이득이 0인데 증분 빌드 8배와 API 22개를 낸다
- **부모-자식 통신이 생기는 순간 값이 붙는다.** §3의 순서 함정은 합성이 있는 곳이면 어디서든 나고, 그걸 잡아 준 게 `TestStore` 진단이었다
- **테스트를 실제로 쓸 때만 최대치가 나온다.** 라이브러리 가치의 절반 이상이 `TestStore`에 있다. 테스트를 안 쓸 거면 대부분을 안 쓰는 것

---

## 7. 스스로 물어볼 것

- 이 앱에 부모-자식 통신이 몇 군데 있나? 하나도 없다면 `Scope`/`ifLet`/`forEach`를 안 쓰는 것이고, 그럼 라이브러리의 절반을 안 쓰는 것이다
- `TestStore`를 실제로 쓸 것인가? 안 쓸 거면 §4·§5 비용을 낼 이유가 약하다
- 증분 빌드 9.5초를 팀이 하루에 몇 번 낼 것인가?
- 의존성 14개의 버전 업을 누가 따라갈 것인가? TCA는 1.x 안에서도 API가 크게 바뀌어 왔다(13섹션에서 `ViewStore`가 통째로 사라졌다)

---

## 8. 검증 기록

### 실행한 것

| 무엇 | 명령 | 결과 |
|---|---|---|
| 컴파일 | `swift build` | 통과 (경고 0) |
| 테스트 | `swift test` | **8건 전부 통과** (0.040s, known issue 1건은 의도된 것) |
| 클린 빌드 시간 | `swift package clean && time swift build` | 75.07s |
| 증분 빌드 시간 | `touch CountryList.swift && time swift build` | 9.51s |
| 손코딩 대조 | `time swiftc -swift-version 6 three_way.swift` | 1.15s |
| 코드량 | 주석·빈 줄 제외 `grep -vE` 카운트 | 위 표 |
| 의존성 | `Package.resolved` 파싱 | 14 pin |

테스트 8건: 기본 루프 성공 · 실패 경로 · 검색 필터 · 의존성 누락 검출 · `Scope` 가로채기 · `forEach` 원소 격리 · `ifLet` dismiss · 비전수 모드.

### 작업 중 실제로 겪은 일

1. **`AppFeature.Action`에 `Equatable`을 빠뜨림** → 컴파일 에러가 대안까지 알려줬다. 라이브러리가 키패스를 기본으로 민다는 걸 여기서 알았다
2. **부모가 액션 페이로드를 읽어 정렬이 어긋남** → `TestStore` diff가 잡았다. §3 참조
3. **검색 필터 기대값을 `["KR","US"]`로 적음** → 실제는 `["KR","US","GB"]`. **`영국`도 "국"을 포함한다.** 코드가 아니라 내 기대가 틀렸다. `#expect` 실패 출력의 `inserted ["GB"]` 한 줄로 즉시 드러났다

### 확인하지 못한 것

- **프리뷰·실기기 동작** — 뷰를 만들지 않았다. `previewValue`의 효용은 ep248 서술을 옮긴 것이지 확인한 게 아니다 `[미검증]`
- **`TestClock`·`Shared`·`NavigationStack` 계열** — 안 썼다. 러닝커브 22개는 그만큼 과소평가다
- **화면 수에 따른 빌드 시간 증가** — 화면 하나짜리 측정이다. 선형인지 아닌지 모른다 `[미검증]`
- **팀 온보딩 비용** — 혼자 했으므로 원리적으로 측정 불가
- **iOS 실기기/시뮬레이터 빌드** — macOS 타겟으로만 빌드했다

### 참조한 정리

- [ComposableArchitecture/10-reducer-protocol/](ComposableArchitecture/10-reducer-protocol/) — `@Reducer`가 왜 이 모양인지
- [ComposableArchitecture/11-navigation/](ComposableArchitecture/11-navigation/) — `ifLet`·`@Presents`. 단 이 섹션은 근거가 얇다
- [ComposableArchitecture/13-observable-architecture/](ComposableArchitecture/13-observable-architecture/) — `@ObservableState`. `WithViewStore`를 안 쓴 이유

## 참고 자료

- 💻 [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) — 1.26.1
- 📄 [TCA 공식 문서](https://pointfreeco.github.io/swift-composable-architecture/) — API 실물 확인처
