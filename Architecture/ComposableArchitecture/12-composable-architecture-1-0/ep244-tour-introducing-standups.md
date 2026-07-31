# Ep. 244 — Tour of the Composable Architecture 1.0: Introducing Standups

- 출처: [Point-Free Episode #244](https://www.pointfree.co/episodes/ep244-tour-of-the-composable-architecture-1-0-standups-part-1)
- 코드: [0244-tca-tour-pt2](https://github.com/pointfreeco/episode-code-samples/tree/main/0244-tca-tour-pt2) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-08-07
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Tour of Scrumdinger |
| 5:31 | Introducing Standups |
| 16:09 | Building the standup form |
| 41:59 | Testing the standup form |
| 49:56 | Next time: adding a standup |

---

## 이 편이 하려는 것

본격적인 예제가 시작된다. **Apple의 Scrumdinger를 TCA로 다시 만든다.**

Scrumdinger는 Apple이 SwiftUI 튜토리얼용으로 내놓은 데일리 스크럼 관리 앱이다. 비교 대상으로 이보다 나은 선택이 드물다.

- Apple이 직접 만든 것이라 "SwiftUI다운 방식"의 기준점이 된다
- 이미 존재하는 앱이라 요구사항을 새로 만들 필요가 없다
- 목록·폼·상세·녹음·영속화까지 실제 앱의 요소를 고루 담고 있다

[Ep. 85](../05-testing/ep85-testable-state-management-the-point.md)가 바닐라 SwiftUI로 짠 앱과 대조했던 방식의 확장판이다. 이번엔 상대가 Apple의 공식 샘플이다.

## 이름

TCA 버전은 **Standups**라고 부른다.

## 폼부터

첫 기능으로 스크럼 생성/편집 폼을 만든다(16:09). 그리고 바로 테스트한다(41:59).

폼을 먼저 고른 게 자연스럽다. 다른 화면에 의존하지 않는 말단 기능이라 [03 섹션](../03-modularity/00-overview.md)의 모듈 원칙대로 독립적으로 만들고 테스트할 수 있다. 목록과 상세는 이걸 조립해 쓴다.

## 라이브러리 저장소 안내

도입부가 TCA 저장소에 **여러 데모와 케이스 스터디**가 들어 있다고 언급한다. 일상적으로 마주치는 다른 종류의 문제들을 다룬 것들이다.

에피소드가 다루지 못한 상황은 거기서 찾으라는 안내로 읽힌다.

## 확인 범위

- 영상이 유료라 폼의 실제 구현과 테스트는 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
