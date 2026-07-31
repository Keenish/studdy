#!/bin/bash
# 이행본을 ThreadSanitizer 아래서 실행한다. 문서 §7 의 "런타임에도 옳은지" 항목.
#
# 양성 대조를 먼저 돌린다 — 일부러 심은 레이스를 못 잡으면 그 뒤의 0 은
# "레이스 없음"이 아니라 "검사가 안 돌았음"이다 (사례 17·19·22).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/racy.swift" <<'RACY'
import Foundation
final class Box: @unchecked Sendable { var v = 0 }
let box = Box()
let g = DispatchGroup()
for _ in 0..<8 {
    DispatchQueue.global().async(group: g) { for _ in 0..<10_000 { box.v += 1 } }
}
g.wait()
print("v=\(box.v)")
RACY

swiftc -swift-version 6 -sanitize=thread -O -o "$TMP/racy" "$TMP/racy.swift" 2>/dev/null || exit 1
# TSan 은 레이스를 만나면 프로세스를 죽인다. 그게 정상이라 종료 코드는 무시한다.
"$TMP/racy" > "$TMP/racy.log" 2>&1 || true
planted=$(grep -c "WARNING: ThreadSanitizer: data race" "$TMP/racy.log")
if [ "$planted" -eq 0 ]; then
    echo "양성 대조 실패 — TSan 이 일부러 심은 레이스를 못 잡았다. 아래 결과는 무의미하다."
    exit 1
fi
echo "  양성 대조: 심은 레이스 ${planted}건 검출 — 검사기가 살아 있다"

swiftc -swift-version 6 -sanitize=thread -O -o "$TMP/run" \
    migrated_service.swift tsan_driver.swift 2>&1 | grep -E "error" && exit 1
"$TMP/run" > "$TMP/run.log" 2>&1
found=$(grep -c "WARNING: ThreadSanitizer" "$TMP/run.log")
tail -1 "$TMP/run.log" | sed 's/^/  /'
echo "  이행본 TSan 보고: ${found}건"
[ "$found" -eq 0 ]
