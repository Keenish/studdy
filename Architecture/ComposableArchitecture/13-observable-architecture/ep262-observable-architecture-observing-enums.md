# Ep. 262 — Observable Architecture: Observing Enums

- 출처: [Point-Free Episode #262](https://www.pointfree.co/episodes/ep262-observable-architecture-observing-enums)
- 코드: [0262-observable-architecture-pt4](https://github.com/pointfreeco/episode-code-samples/tree/main/0262-observable-architecture-pt4) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2023-12-18
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 0:56 | Getting rid of SwitchStore |
| 9:33 | Observable PresentationState |
| 23:07 | Observable enums |
| 29:09 | @ObservableState for enums |
| 42:53 | Next time: observing collections |

---

## 이 편이 하려는 것

구조체([Ep. 260](ep260-observable-architecture-structural-identity.md))와 옵셔널([Ep. 261](ep261-observable-architecture-observing-optionals.md))을 했으니 이번엔 enum이다. 그리고 `SwitchStore`를 없앤다.

도입부의 진단이 명확하다. `SwitchStore`는 **enum 상태의 최소 관찰을 위해서만 존재**했고, 관찰이 자동으로 되는 세상에서는 완전히 불필요하다는 것이다.

같은 논리가 앞 편의 `IfLetStore`에도 적용됐다. 최소 관찰을 손으로 하려고 만든 도구들이 언어가 그걸 해 주자 존재 이유를 잃는다.

## enum 상태가 왜 중요한가

[11 섹션](../11-navigation/00-overview.md)의 결론이 "내비게이션 목적지를 enum으로 모델링하라"였다. [Ep. 247](../12-composable-architecture-1-0/ep247-tour-domain-modeling.md)이 숫자로 보인 것처럼, 목적지가 다섯이면 표현 가능한 상태의 90% 이상이 무효다.

그래서 실제 TCA 앱에서 enum 상태가 흔하다. 그걸 관찰 가능하게 만드는 게 이 편의 실용적 가치다.

## PresentationState도 관찰 가능하게 (9:33)

[11 섹션](../11-navigation/00-overview.md)에서 만든 표시 상태 타입이다. 내비게이션 도구의 핵심이라 여기서 관찰 대응이 필요하다.

## enum용 @ObservableState (29:09)

[Ep. 261](ep261-observable-architecture-observing-optionals.md)에서 만든 매크로를 enum까지 다루게 확장한다.

구조체는 프로퍼티 단위로 접근을 추적하면 되는데 enum은 케이스라 사정이 다르다. 어떤 케이스인지 자체가 관찰 대상이고, 케이스 안의 연관 값도 그렇다.

## 확인 범위

- 영상이 유료라 enum 매크로의 실제 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
