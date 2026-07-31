# Ep. 207 — Reducer Protocol: Testing

- 출처: [Point-Free Episode #207](https://www.pointfree.co/episodes/ep207-reducer-protocol-testing)
- 코드: [0207-reducer-protocol-pt7](https://github.com/pointfreeco/episode-code-samples/tree/main/0207-reducer-protocol-pt7) (MIT)
- 흐름: [00-overview.md](00-overview.md)
- 정리일: 2026-07-30 · 공개일: 2022-10-03
- 근거: 영상은 유료 회원 전용이라 섹션 제목·도입부만 확인했다

| 시간 | 섹션 |
|---|---|
| 0:05 | Introduction |
| 1:59 | Test store dependencies |
| 9:00 | Unimplemented dependencies |
| 20:46 | Modular dependencies |
| 29:45 | Conclusion |

---

## 이 편이 하려는 것

프로토콜과 새 의존성 체계가 테스트에 어떤 영향을 주는지 본다.

에피소드 설명의 표현이 이 편의 요지다. **테스트 패턴을 라이브러리에 직접 codify**해서 테스트를 즉시 더 강하고 더 빠짐없게(exhaustive) 만든다는 것이다.

지금까지는 좋은 테스트를 쓰는 방법이 관행이었다면, 이제 라이브러리가 그걸 기본값으로 강제하는 쪽으로 간다.

## Unimplemented dependencies

세 섹션 중 이게 가장 흥미롭다(9:00~20:46).

이름이 시사하는 바가 있다. 테스트에서 의존성의 기본값을 **호출되면 실패하는 것**으로 두는 방식이다.

그러면 테스트가 명시적으로 지정하지 않은 의존성을 코드가 건드리는 순간 테스트가 깨진다. 조용히 실제 네트워크를 부르거나 기본값을 반환하고 지나가는 일이 없어진다.

[05 섹션](../05-testing/00-overview.md)의 Environment 방식에서는 `.mock`을 손으로 만들어 줬고, 빠뜨린 부분이 있어도 알기 어려웠다. 실패를 기본값으로 두면 빠뜨린 것이 드러난다.

에피소드 설명의 "더 빠짐없게"가 이 이야기로 보인다.

## 모듈 의존성

세 번째 섹션(20:46)은 모듈 경계와 의존성이다.

[Ep. 205](ep205-reducer-protocol-dependencies-part-1.md) 도입부가 이점으로 든 것 중 하나가 모듈화 시 `public` 이니셜라이저가 필요 없어진다는 점이었다. 그 효과가 테스트에서 어떻게 나타나는지 다루는 것으로 보인다.

## 이 체계가 주는 것

도입부가 정리한다.

- `@Dependency` 덕에 리듀서가 의존성을 받는 이니셜라이저를 따로 두지 않아도 된다
- 그래서 말단을 고쳐도 부모 계층을 건드릴 필요가 없다 — [Ep. 201](ep201-reducer-protocol-the-problem.md)의 네 번째 문제가 닫힌다
- 프리뷰나 온보딩에서 의존성을 밖에서 바꿔 기능을 **일종의 샌드박스**에서 돌릴 수 있다

마지막 표현이 좋다. 사용자가 무엇을 경험할지 완전히 통제할 수 있다는 뜻이다.

## 확인 범위

- 영상이 유료라 실제 테스트 API와 unimplemented 의존성의 구현은 확인하지 못했다. 위 내용은 섹션 제목·도입부·에피소드 설명에서 읽어낸 것이다
