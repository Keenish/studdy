#!/bin/bash
# 레이어 경계를 import 방향으로 강제한다 — §2-B §2의 "선언만으로는 안 지켜진다"의 실물.
#
# 빌드 시스템은 순환 의존만 막는다. 형제 모듈 사이의 "허용된 방향"은
# 아무도 안 막아주므로 이렇게 따로 검사한다.
#
# 규약: Modules/<Layer>/Project.swift  또는  Modules/<Layer>/<Name>/Project.swift
# 사용: bash Architecture/code/phase2/check_layering.sh [루트]
# 반환: 위반이 하나라도 있으면 1

set -uo pipefail
ROOT="${1:-.}"

# ── 레이어별 허용 대상. 여기 없는 내부 모듈을 import 하면 위반이다.
#    외부 모듈(Foundation·SwiftUI 등)은 내부 모듈 목록에 없으므로 그냥 통과한다.
allowed_for() {
    case "$1" in
        Shared)       echo "" ;;
        DesignSystem) echo "Shared" ;;
        Core)         echo "Shared Entity" ;;
        Domain)       echo "Shared Core Entity" ;;
        Features)     echo "Shared DesignSystem Core Entity Domain" ;;
        *)            echo "" ;;
    esac
}

# ── 내부 모듈 목록을 트리에서 수집한다 (하위 모듈 이름 포함)
INTERNAL=$(find "$ROOT/Modules" -name Project.swift 2>/dev/null \
           | sed "s|$ROOT/Modules/||; s|/Project.swift||" \
           | awk -F/ '{print $NF}' | sort -u)
[ -n "$INTERNAL" ] || { echo "Modules/ 아래에 Project.swift 가 없다: $ROOT"; exit 1; }

is_internal() { echo "$INTERNAL" | grep -qx "$1"; }

violations=0
while IFS= read -r file; do
    rel="${file#"$ROOT"/}"
    case "$rel" in */Example/*) continue ;; esac   # 데모 앱은 예외

    layer=$(echo "$rel" | awk -F/ '{print $2}')
    owner=$(echo "$rel" | awk -F/ '{ if ($4 == "Sources") print $3; else print $2 }')
    allow="$(allowed_for "$layer") $owner"

    # @testable import 도 같이 잡는다 — 테스트가 경계를 우회하는 통로다
    while IFS= read -r mod; do
        [ -n "$mod" ] || continue
        is_internal "$mod" || continue
        echo " $allow " | grep -q " $mod " && continue
        echo "  위반  $rel → import $mod   ($layer 레이어는 $mod 를 알면 안 된다)"
        violations=$((violations + 1))
    done < <(grep -hoE '^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$file" \
             | awk '{print $NF}')
done < <(find "$ROOT/Modules" -name '*.swift' 2>/dev/null)

if [ "$violations" -eq 0 ]; then
    echo "레이어 경계 통과 — 위반 0"
    exit 0
fi
echo "레이어 위반 ${violations}건"
exit 1
