// Phase 0 §7 확장 검증 — 세 축을 각각 늘려 본다.
//
// 목적: component_api.swift 의 결과 표가 주장한 것을 **실제로 해서** 확인한다.
//   "색 1개 추가 → +1 선언"
//   "Variant 1개 추가 → +1 타입, 기존 코드 수정 없음"
//
// 규칙: 이 파일은 새로 만들되 **component_api.swift 는 한 줄도 고치지 않는다.**
//       고쳤는지 여부는 git 이 판정한다 (Swift/code/phase0Tests 의 검증 기록 참조).
import SwiftUI

// ── 축 2 확장: 색 1개 추가.
// enum 이 아니라 값 타입 토큰이라 case 추가가 아니라 static 상수 추가다.
// 이 한 줄이 전부이고, 기존 switch 문이 없으니 exhaustiveness 도 안 깨진다.
extension ButtonPalette {
    static let warning = ButtonPalette(
        background: Color(0xE0A93A),
        foreground: Color(0x141310),
        border: nil
    )
}

// ── 축 1 확장: 치수 1개 추가. 마찬가지로 +1 선언.
extension ButtonMetrics {
    static let xlarge = ButtonMetrics(
        height: 60,
        horizontalPadding: 32,
        iconSize: 24,
        fontSize: 18
    )
}

// ── 축 3 확장: Variant 1개 추가 = 새 타입 하나.
// 프로토콜을 채택하기만 하면 되고, 기존 Solid/Outlined 는 이 타입의 존재를 모른다.
// 이것이 PAT 확장 지점의 값어치다 — enum 이었다면 두 곳의 switch 를 고쳐야 했다.
struct GhostButtonStyling: DSButtonStyling {
    func makeBody(_ c: DSButtonConfiguration) -> some View {
        c.label
            .font(.system(size: c.metrics.fontSize, weight: .medium))
            .foregroundStyle(c.palette.background)
            .frame(width: c.isIconOnly ? c.metrics.height : nil, height: c.metrics.height)
            .padding(.horizontal, c.isIconOnly ? 0 : c.metrics.horizontalPadding)
            .background(c.palette.background.opacity(c.isPressed ? 0.16 : 0))
            .clipShape(Capsule())
            .opacity(c.isEnabled ? 1 : 0.4)
    }
}

// ── 세 확장이 서로를 모른 채 자유롭게 조합된다.
// 새 색 × 새 치수 × 새 외형 — 조합을 위해 추가로 쓴 코드는 0줄이다.
struct ExtendedUsageSample: View {
    var body: some View {
        VStack(spacing: 12) {
            DSButton("경고", action: {})
                .dsButtonColor(.warning)

            DSButton("아주 큼", action: {})
                .dsButtonSize(.xlarge)

            DSButton("고스트", action: {})
                .dsButtonStyling(GhostButtonStyling())

            // 세 축 동시 — 기존 두 축(콘텐츠 슬롯·disabled)과도 섞인다
            DSButton(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                    Text("전부 새것")
                }
            }
            .dsButtonStyling(GhostButtonStyling())
            .dsButtonColor(.warning)
            .dsButtonSize(.xlarge)
            .disabled(true)
        }
    }
}
