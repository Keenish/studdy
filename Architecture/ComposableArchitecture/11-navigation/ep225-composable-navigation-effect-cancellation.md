# Ep. 225 — Composable Navigation: Effect Cancellation

- 출처: [Point-Free Episode #225](https://www.pointfree.co/episodes/ep225-composable-navigation-behavior)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:29 | Effect cancellation |
| 17:20 | Child dismissal |
| 44:55 | Non-exhaustive testing |
| 50:45 | Next time: unification |

---

## 이 편이 하려는 것

[Ep. 224](ep224-composable-navigation-sheets.md)에서 만든 `sheet` 연산자 위에 동작을 얹는다. 도입부가 연산자를 만들어 두니 **적은 노력으로 기능을 덧붙일 수 있다**고 말한다.

세 가지를 다룬다.

## 효과 취소 (1:29)

시트가 떠 있는 동안 시작된 효과가 있는데 시트가 닫히면 어떻게 되나. 도입부의 표현이 명확하다. 그 효과들이 액션을 만들어 내면 **허공으로 사라진다.**

받을 기능이 이미 없어졌으니 그 액션은 아무 데도 가지 않는다. 자원 낭비이고, 경우에 따라 예상치 못한 동작이 된다.

`.task` modifier가 뷰 생명주기에 묶인 효과는 처리해 준다([Ep. 199](../09-async-composable-architecture/ep199-async-composable-architecture-effect-lifetimes.md)에서 만든 연결이다). 그런데 **버튼 탭 같은 사용자 상호작용으로 시작된 효과**는 그 범위 밖이다. 그 빈틈을 `sheet` 연산자가 메운다.

## 자식이 스스로 닫기 (17:20)

자식 기능이 자기를 닫는 방법이다.

상태를 소유한 건 부모다. 그런데 "저장 완료했으니 이 화면을 닫아라"를 판단하는 건 자식이다. 자식이 부모의 상태를 직접 건드리면 [03 섹션](../03-modularity/00-overview.md)의 모듈 경계가 깨진다.

[Ep. 222](ep222-composable-navigation-tabs.md)의 delegate 패턴과 같은 문제인데, 닫기는 워낙 흔한 요구라 별도 장치가 붙는 것으로 보인다.

## 비전수 테스트 (44:55)

이 섹션이 개념적으로 중요하다.

[05 섹션](../05-testing/00-overview.md)이 세운 원칙은 **전수 테스트**였다. 상태 변화를 하나도 빠짐없이 검증하고, 안 그러면 실패한다. 그게 이 아키텍처의 강점이었다.

그런데 기능이 중첩되면 그게 부담이 된다. 부모를 테스트하는데 자식 기능 안의 모든 상태 변화까지 다 적어야 한다면, 자식이 바뀔 때마다 부모 테스트가 깨진다.

비전수 테스트는 **관심 있는 것만 검증**하는 방식이다. 원칙을 완화하는 것처럼 보이지만, 실제로는 기능 합성이 깊어지는 상황에 맞춰 도구를 조정하는 것이다. [Ep. 226](ep226-composable-navigation-unification.md) 도입부도 합성이 정교해질수록 이게 중요해진다고 언급한다.

## 확인 범위

- 영상이 유료라 세 기능의 실제 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
- URL 슬러그가 `ep225-composable-navigation-behavior`인데 제목은 Effect Cancellation이다. 제작 중 제목이 바뀐 것으로 보인다
