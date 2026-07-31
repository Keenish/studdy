#!/bin/bash
# Phase 1b §7 — Swift 6 strict concurrency 이행을 검증한다.
#
# 통과 기준이 "우회 없이 해소"이므로, 우회하지 않았다는 것까지 스크립트가 강제한다.
#
#   bash Concurrency/code/phase1b/verify_migration.sh
set -u
cd "$(dirname "$0")"

pass=0
fail=0
check() {  # check <설명> <기대> <실제>
    if [ "$2" = "$3" ]; then
        echo "  ok   $1"
        pass=$((pass + 1))
    else
        echo "  FAIL $1 — 기대 '$2', 실제 '$3'"
        fail=$((fail + 1))
    fi
}

errors() {  # errors <파일> <모드플래그...>
    swiftc "${@:2}" -o /dev/null -parse-as-library "$1" 2>&1 \
        | grep -cE "^$1:[0-9]+:[0-9]+: error:"
}

echo "═══ 1. 레거시는 Swift 5 에서 빌드된다 (그래서 여태 살아 있었다)"
n=$(errors legacy_service.swift -c -swift-version 5)
check "legacy_service.swift @ Swift 5 → error 0" "0" "$n"

echo
echo "═══ 2. Swift 6 로 올리면 무너진다"
n6=$(errors legacy_service.swift -c -swift-version 6)
if [ "$n6" -gt 0 ]; then
    echo "  ok   legacy_service.swift @ Swift 6 → error ${n6}건 (기대: 1건 이상)"
    pass=$((pass + 1))
else
    echo "  FAIL Swift 6 에서 error 가 안 났다 — 실습이 성립하지 않는다"
    fail=$((fail + 1))
fi
swiftc -c -swift-version 6 -o /dev/null -parse-as-library legacy_service.swift 2>&1 \
    | grep -E "^legacy_service.swift:[0-9]+:[0-9]+: error:" \
    | sed 's|^legacy_service.swift:|       L|' | sort -u

echo
echo "═══ 3. 1차 진단을 넘기면 2차가 드러난다 (진단은 파도로 온다)"
echo "       1차 4건은 전부 타입체커가 낸 것이다. 타입 검사가 실패하면"
echo "       SIL 생성이 안 돌아서 SIL 패스 진단은 가려진다."
nw=$(errors wave2_probe.swift -c -swift-version 6)
if [ "$nw" -gt 0 ]; then
    echo "  ok   wave2_probe.swift @ -c → 새 error ${nw}건"
    pass=$((pass + 1))
else
    echo "  FAIL 2차 진단이 안 나왔다"
    fail=$((fail + 1))
fi
swiftc -c -swift-version 6 -o /dev/null -parse-as-library wave2_probe.swift 2>&1 \
    | grep -E "^wave2_probe.swift:[0-9]+:[0-9]+: error:" \
    | sed 's|^wave2_probe.swift:|       L|' | sort -u

echo
echo "═══ 3b. 그 2차 진단을 -typecheck 은 통째로 놓친다"
nwtc=$(errors wave2_probe.swift -typecheck -swift-version 6)
echo "       -typecheck: ${nwtc}건 / -c: ${nw}건"
check "-typecheck 이 SIL 패스 진단을 못 잡는다" "0" "$nwtc"

echo
echo "═══ 4. 이행본은 Swift 6 에서 깨끗하다"
nm=$(errors migrated_service.swift -c -swift-version 6)
check "migrated_service.swift @ Swift 6 → error 0" "0" "$nm"

echo
echo "═══ 5. 우회 수단을 쓰지 않았다"
for hatch in "@unchecked Sendable" "nonisolated(unsafe)" "@preconcurrency"; do
    # 주석에서 '금지'로 언급한 줄은 제외하고 실제 사용만 센다
    n=$(grep -F "$hatch" migrated_service.swift | grep -vcE "^\s*(//|///)")
    check "$hatch 사용 0회" "0" "$n"
done

echo
echo "───────────────────────────────"
echo "통과 ${pass} · 실패 ${fail}"
[ "$fail" -eq 0 ] || exit 1
