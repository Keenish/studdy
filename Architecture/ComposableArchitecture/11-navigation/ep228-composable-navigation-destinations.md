# Ep. 228 — Composable Navigation: Destinations

- 출처: [Point-Free Episode #228](https://www.pointfree.co/episodes/ep228-composable-navigation-destinations)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:19 | Testing links |
| 13:10 | Destinations |
| 29:03 | Next time: enum routing |

---

## 이 편이 하려는 것

[Ep. 227](ep227-composable-navigation-links.md)이 deprecated API로 드릴다운을 만들었으니, 이제 iOS 16의 `navigationDestination`으로 같은 걸 한다. 그리고 링크 테스트를 다룬다.

## 지금까지의 성과

도입부가 여섯 형태를 지원하게 됐다고 정리한다. 알럿, 다이얼로그, 시트, 팝오버, 커버, 그리고 링크다.

그리고 그게 가능했던 이유를 짚는다. **도메인을 먼저 제대로 모델링해 뒀기 때문**에 온갖 내비게이션 형태를 균일하게 다룰 수 있다는 것이다. 옵셔널 상태, 리듀서 연산자, 뷰 레이어 연결 방식이 형태와 무관하게 같은 모양이다.

이 시리즈가 반복하는 주장이다 — 도메인 모델링이 먼저고 도구는 거기서 나온다.

## 부모와 자식의 통신

도입부에 인용된 표현이 이 섹션의 요지를 담는다. 부모와 자식 도메인이 **서로 소통할 아주 단순한 방법**을 갖게 된다는 것이다.

[Ep. 222](ep222-composable-navigation-tabs.md)에서 delegate 패턴으로 시작한 이야기가 여기까지 이어진다. 내비게이션 도구를 만드는 것처럼 보이지만 실제로 만드는 건 **기능 간 통신 체계**다.

## 다음 편 예고

"Next time: enum routing"이 [Ep. 229](ep229-composable-navigation-correctness.md)를 가리킨다. 여섯 형태를 다 지원하게 됐더니 이번엔 그것들이 동시에 존재할 수 있다는 문제가 생긴다.

## 확인 범위

- 영상이 유료라 `navigationDestination` 연동의 실제 구현과 링크 테스트 방법은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
