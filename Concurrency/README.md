# Swift Concurrency

[study_list.md §3](../study_list.md#3-swift-concurrency) 묶음. Phase 1b.

**통과 기준**: Swift 6 strict concurrency 경고를 우회 없이 해소할 수 있다.

Phase 1의 나머지 절반인 SwiftUI 렌더링 모델은 [Swift/](../Swift/)에 있다. `@MainActor`와 뷰 갱신의 경계가 두 문서를 잇는다.

## 문서

| 문서 | 범위 | 상태 |
|---|---|---|
| [phase1-concurrency.md](phase1-concurrency.md) | Task와 스레드 · 구조적 동시성 · 협조적 취소 · actor reentrancy와 single-flight · AsyncSequence 버퍼링 · 콜백 브리징 · **Combine 전환 판단** · Sendable/Swift 6 이행 | **Phase 1b 완료.** 데모 6개 실행 검증 + Swift 5 모듈을 우회 없이 이행. ⚠️ **Combine 절은 결정 절차만** — 이 저장소에 Combine 코드가 없다 |

## 코드

리포 루트에서 실행:

```
swift -swift-version 6 Concurrency/code/phase1/concurrency_demo.swift   # 데모 6개
bash Concurrency/code/phase1b/verify_migration.sh                       # 이행 검증 8건
```

- [`code/phase1/`](code/phase1/) — §1~6 데모. `-swift-version 6`(= `complete`)에서 경고 0
- [`code/phase1b/`](code/phase1b/) — 이행 실습. `legacy_service.swift`(Swift 5 관용구) → `migrated_service.swift`(우회 0). `wave2_probe.swift`는 진단이 파도로 온다는 걸 보이는 표본

## 검증할 때 주의

**`-typecheck`으로는 부족하다.** region isolation 진단(`#SendingClosureRisksDataRace`)은 타입체커가 아니라 SIL 패스가 낸다. `-typecheck`은 그걸 **0건** 잡는다 — 실제 컴파일(`-c`)이나 `swift build`/`swift run`을 써야 한다. 실습에서 확인한 내용이고 [§7](phase1-concurrency.md#-typecheck으로는-절반을-못-잡는다)에 있다.
