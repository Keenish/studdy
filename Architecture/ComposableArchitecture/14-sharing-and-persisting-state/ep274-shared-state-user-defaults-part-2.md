# Ep. 274 — Shared State: User Defaults, Part 2

- 출처: [Point-Free Episode #274](https://www.pointfree.co/episodes/ep274-shared-state-user-defaults-part-2)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2024-04-08
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:55 | External updates |
| 10:08 | Testing app storage |
| 24:52 | Next time: file storage |

---

## 이 편이 하려는 것

[Ep. 273](ep273-shared-state-user-defaults-part-1.md)에서 `@Shared`를 user defaults에 저장하게 만들었다. 그런데 한 방향뿐이다.

도입부가 빠진 것을 짚는다. **바깥에서 user defaults가 바뀐 것을 감지하지 못한다.**

설정 앱에서 값이 바뀌거나, 앱의 다른 경로가 직접 `UserDefaults`를 건드리거나, 시스템이 값을 갱신하는 경우가 있다. 그러면 `@Shared`가 들고 있는 값이 실제와 어긋난다.

## 해법 — PersistenceKey를 강화한다

도입부가 방향을 밝힌다. 이전 접근들과 달리 `PersistenceKey` 프로토콜을 보강해, **준수하는 타입이 외부 시스템에서 일어난 값 변경을 서술할 수 있게** 만든다는 것이다.

프로토콜에 "바깥 변화를 알려주는" 능력을 요구사항으로 넣는 셈이다. 그러면 user defaults뿐 아니라 다음 편의 파일 저장에도 같은 구조가 적용된다.

이 시리즈가 반복해 온 방식이다. 특정 사례를 풀 때 그 사례만 처리하지 않고 프로토콜이나 타입으로 일반화한다.

## 테스트 (10:08)

절반 이상을 여기 쓴다.

바깥 시스템을 관찰하는 기능은 테스트하기 까다롭다. 실제 `UserDefaults`를 건드리면 테스트끼리 상태를 공유하게 되고, [Ep. 249](../12-composable-architecture-1-0/ep249-tour-persistence.md)가 영속화에 대해 경고한 문제가 그대로 재현된다.

에피소드 설명도 **모든 것을 테스트 가능하게 만들려면 추가 작업이 필요하다**고 밝힌다.

## 확인 범위

- 영상이 유료라 `PersistenceKey`의 실제 정의와 외부 변경 감지 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
