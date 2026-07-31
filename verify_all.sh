#!/bin/bash
# 이 저장소가 주장하는 것을 전부 다시 돌린다.
#
# 문서에 인용된 수치·출력은 아래 명령에서 나온 것이다. 시간이 지나 Swift 버전이
# 바뀌거나 문서를 고친 뒤, "아직도 맞는가"를 한 번에 확인하는 진입점이다.
#
# 사용: bash verify_all.sh          전부 실행
#       bash verify_all.sh --quick  빌드·테스트·링크만 (단독 실행물 생략)
#
# 반환: 하나라도 실패하면 1
#
# 주의 — 여기서 통과한다고 문서가 옳은 것은 아니다. 이 스크립트는 **코드가
# 여전히 돌아가는지**만 본다. 문서에 적힌 수치가 출력과 같은지는 사람이 봐야
# 한다 (AI/phase-parallel-ai-verification.md 사례 6·9).

set -uo pipefail
cd "$(dirname "$0")" || exit 1

QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1

pass=0; fail=0; failed_names=()

run() {
    local name="$1"; shift
    printf '  %-46s' "$name"
    local out rc
    out=$("$@" 2>&1); rc=$?
    if [ "$rc" -eq 0 ]; then
        printf '✅\n'; pass=$((pass + 1))
    else
        printf '❌ exit=%s\n' "$rc"
        echo "$out" | tail -15 | sed 's/^/       /'
        fail=$((fail + 1)); failed_names+=("$name")
    fi
}

echo "═══ 빌드·테스트 (SPM 타겟) ═══"
run "swift build"                       swift build
run "swift test (26건)"                 swift test

if [ "$QUICK" -eq 0 ]; then
    echo
    echo "═══ Phase 0 — 언어 코어 ═══"
    run "phase0_demo 데모 8개"           swift -swift-version 6 Swift/code/phase0/phase0_demo.swift
    run "existential 레이아웃 측정"       swift -swift-version 6 Swift/code/phase0/existential_layout.swift

    echo
    echo "═══ Phase 1a — SwiftUI 렌더링 ═══"
    run "observation 무효화 범위"         swift -swift-version 6 Swift/code/phase1/observation_demo.swift
    # -typecheck 이 아니라 -c 다. SIL 패스 진단은 typecheck 이 0건 잡는다 (사례 21)
    run "rendering_views 컴파일"          swiftc -c -swift-version 6 -o /dev/null Swift/code/phase1/rendering_views.swift

    echo
    echo "═══ Phase 1b — Concurrency ═══"
    run "concurrency 데모 6개"            swift -swift-version 6 Concurrency/code/phase1/concurrency_demo.swift
    run "Swift 6 이행 검증 8건"           bash Concurrency/code/phase1b/verify_migration.sh

    echo
    echo "═══ Phase 2 — 아키텍처 ═══"
    run "MVVM vs Clean (A·B)"            swift -swift-version 6 Architecture/code/phase2/mvvm_vs_clean.swift
    run "Reducer + Store (C)"            swift -swift-version 6 Architecture/code/phase2/three_way.swift
    run "레이어 가드 12케이스"             bash Architecture/code/phase2/verify_layering_guard.sh

    echo
    echo "═══ Phase 3 — 디자인 시스템 ═══"
    run "토큰 감사"                       swift -swift-version 6 DesignSystem/code/phase3/token_audit.swift
fi

echo
echo "═══ 문서 ═══"
run "링크·앵커 전수 검사"                 python3 AI/code/check_links.py

echo
echo "───────────────────────────────────────────────"
if [ "$fail" -eq 0 ]; then
    echo "🎉 ${pass}개 전부 통과"
    exit 0
fi
echo "💥 통과 ${pass} / 실패 ${fail}"
printf '   실패: %s\n' "${failed_names[@]}"
exit 1
