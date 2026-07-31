#!/bin/bash
# §2-B §2의 주장을 실증한다 — check_layering.sh가 실제로 위반을 잡는가.
#
# 가드를 쓰고 로직을 설명하는 것만으로는 "잡는다"를 확인한 게 아니다
# (AI/phase-parallel-ai-verification.md 사례 6 — 검사기도 검증 대상).
# 그래서 임시 픽스처에 위반을 심어 돌려본다.
#
# 사용: bash Architecture/code/phase2/verify_layering_guard.sh
# 반환: 기대와 다른 결과가 하나라도 있으면 1

set -uo pipefail

GUARD="${GUARD:-$(dirname "$0")/check_layering.sh}"
if [ ! -f "$GUARD" ]; then
    echo "가드를 찾을 수 없다: $GUARD"
    exit 1
fi

FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT

# ── 최소 픽스처: Modules/<Layer>[/<Name>]/Project.swift 규약을 흉내낸다
mkdir -p "$FIXTURE/Scripts"
cp "$GUARD" "$FIXTURE/Scripts/check_layering.sh"

for m in Shared DesignSystem Core Domain; do
    mkdir -p "$FIXTURE/Modules/$m/Sources"
    echo "// module" > "$FIXTURE/Modules/$m/Project.swift"
done
for m in Core/Entity Features/Auth Features/Home; do
    mkdir -p "$FIXTURE/Modules/$m/Sources"
    echo "// module" > "$FIXTURE/Modules/$m/Project.swift"
done
mkdir -p "$FIXTURE/Modules/Features"   # Features 엄브렐라에는 Project.swift 를 두지 않는다

# 깨끗한 기준선 — 허용되는 방향만
cat > "$FIXTURE/Modules/Features/Auth/Sources/AuthView.swift" <<'EOF'
import DesignSystem
import Core
import Domain
EOF
echo "import Core" > "$FIXTURE/Modules/Domain/Sources/Service.swift"
echo "import Shared" > "$FIXTURE/Modules/Core/Sources/Client.swift"
echo "import Shared" > "$FIXTURE/Modules/DesignSystem/Sources/Token.swift"
echo "import Foundation" > "$FIXTURE/Modules/Shared/Sources/Util.swift"
echo "import Entity" > "$FIXTURE/Modules/Features/Home/Sources/HomeView.swift"
echo "import Foundation" > "$FIXTURE/Modules/Core/Entity/Sources/Country.swift"

BASELINE=$(cd "$FIXTURE" && cp -R Modules "$FIXTURE/.baseline" && echo ok)
[ "$BASELINE" = ok ] || { echo "픽스처 준비 실패"; exit 1; }

restore() { rm -rf "$FIXTURE/Modules"; cp -R "$FIXTURE/.baseline" "$FIXTURE/Modules"; }

fails=0
# $1 설명  $2 기대(pass|fail)  $3 위반을 심는 명령
case_run() {
    local desc="$1" want="$2" plant="$3"
    restore
    ( cd "$FIXTURE" && eval "$plant" )
    local out rc
    out=$(cd "$FIXTURE" && bash Scripts/check_layering.sh 2>&1); rc=$?
    local got; [ "$rc" -eq 0 ] && got=pass || got=fail

    if [ "$got" = "$want" ]; then
        printf '  ✅ %-46s 기대 %-4s 실제 %-4s\n' "$desc" "$want" "$got"
    else
        printf '  ❌ %-46s 기대 %-4s 실제 %-4s\n' "$desc" "$want" "$got"
        echo "$out" | sed 's/^/       /'
        fails=$((fails + 1))
    fi
}

echo "check_layering.sh 위반 검출 검증"
echo

case_run "기준선 (허용된 방향만)"                  pass ":"
case_run "규칙1  Feature → 다른 Feature"           fail "echo 'import Home' >> Modules/Features/Auth/Sources/AuthView.swift"
case_run "규칙2  Core → DesignSystem (인프라→UI)"  fail "echo 'import DesignSystem' >> Modules/Core/Sources/Client.swift"
case_run "규칙2  Core → Domain"                    fail "echo 'import Domain' >> Modules/Core/Sources/Client.swift"
case_run "규칙3  Domain → DesignSystem"            fail "echo 'import DesignSystem' >> Modules/Domain/Sources/Service.swift"
case_run "규칙3  Domain → Feature"                 fail "echo 'import Auth' >> Modules/Domain/Sources/Service.swift"
case_run "규칙4  DesignSystem → Core"              fail "echo 'import Core' >> Modules/DesignSystem/Sources/Token.swift"
case_run "규칙5  Shared → Core"                    fail "echo 'import Core' >> Modules/Shared/Sources/Util.swift"
case_run "하위 모듈 이름도 인식 (Core/Entity)"      fail "echo 'import Entity' >> Modules/Shared/Sources/Util.swift"
case_run "@testable import도 검출"                 fail "echo '@testable import Domain' >> Modules/Core/Sources/Client.swift"
case_run "Example 경로는 예외 (통과해야 함)"        pass "mkdir -p Modules/Features/Auth/Example && echo 'import Home' > Modules/Features/Auth/Example/Demo.swift"
case_run "Feature가 자기 모듈 import는 허용"        pass "echo 'import Auth' >> Modules/Features/Auth/Sources/AuthView.swift"

echo
if [ "$fails" -eq 0 ]; then
    echo "🎉 12개 케이스 전부 기대와 일치 — 가드가 실제로 위반을 잡는다"
else
    echo "💥 기대와 다른 케이스 ${fails}개"
fi
exit $([ "$fails" -eq 0 ] && echo 0 || echo 1)
