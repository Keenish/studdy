#!/usr/bin/env python3
"""싱글톤(`static let shared`)을 **격리 방식으로** 분류한다.

개수만 세면 판정에 쓸모가 없다. "싱글톤 25곳"은 그것이 부채인지 경계인지 말해주지 않는다.
Swift 6에서는 actor로 감싼 싱글톤과 검사를 끈 싱글톤이 완전히 다른 물건이다.

사용: python3 Refactoring/code/phase4/classify_singletons.py <코드베이스경로>
경로는 인자로 받는다 — 어떤 Swift 코드베이스에도 돌릴 수 있다.

⚠️ 이 스크립트는 세 번 고쳐서 맞았다 (Refactoring/phase4-large-scale-refactoring.md §8):
  1) 파일의 첫 타입을 집어 `Keychain`·`VideoThumbnailCache`를 놓쳤다
  2) `private` 수정자를 정규식에서 빠뜨렸다
  3) `shared` 앞에 중첩 타입이 있으면 그것을 감싸는 타입으로 착각했다 → 들여쓰기 비교로 해결
그리고 첫 집계는 **주석 처리된 선언과 의존성 소스**를 포함했다.
grep 한 줄로 낸 수치를 그대로 쓰면 이런 것들이 섞인다.
"""
import os
import re
import subprocess
import sys

DEFAULT = None
EXCLUDE = ("/Derived/", "/.build/", "/checkouts/")

TYPE = re.compile(
    r"^(\s*)"                                              # 들여쓰기
    r"((?:@\w+(?:\([^)]*\))?\s+)*)"                        # 속성 (@MainActor 등)
    r"(?:public |internal |package |fileprivate |private |open )*"
    r"(?:final )?"
    r"(class|actor|struct|enum)\s+(\w+)(.*)$"
)

BUCKETS = [
    "actor 격리",
    "@MainActor 격리",
    "Sendable 명시",
    "⚠️ @unchecked Sendable",
    "⚠️ nonisolated(unsafe) shared",
    "표시 없음",
]


def enclosing_type(lines: list[str], index: int, indent: int):
    """`shared` 선언을 감싸는 타입을 찾는다. 들여쓰기가 더 얕은 첫 타입 선언이다."""
    for j in range(index - 1, -1, -1):
        m = TYPE.match(lines[j])
        if m and len(m.group(1)) < indent:
            return m.group(2), m.group(3), m.group(4), m.group(5)
    return "", "", "", ""


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    if root is None:
        print("사용: python3 classify_singletons.py <코드베이스경로>")
        return 2
    if not os.path.isdir(root):
        print(f"건너뜀 — 경로가 없다: {root}")
        return 0

    grep = subprocess.run(
        ["grep", "-rn", "static let shared", "--include=*.swift", root],
        capture_output=True, text=True,
    ).stdout

    buckets: dict[str, list[str]] = {k: [] for k in BUCKETS}
    skipped: list[tuple[str, str]] = []

    for line in grep.splitlines():
        path, lineno, code = line.split(":", 2)
        rel = os.path.relpath(path, root)

        if any(x in path for x in EXCLUDE):
            skipped.append(("의존성·생성물", rel)); continue
        if re.match(r"\s*//", code):
            skipped.append(("주석 처리됨", rel)); continue

        with open(path, encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()

        i = int(lineno) - 1
        indent = len(code) - len(code.lstrip())
        attrs, kind, name, rest = enclosing_type(lines, i, indent)

        if "nonisolated(unsafe)" in code:
            buckets["⚠️ nonisolated(unsafe) shared"].append(name)
        elif kind == "actor":
            buckets["actor 격리"].append(name)
        elif "@unchecked Sendable" in rest:
            buckets["⚠️ @unchecked Sendable"].append(name)
        elif "@MainActor" in attrs:
            buckets["@MainActor 격리"].append(name)
        elif "Sendable" in rest:
            buckets["Sendable 명시"].append(name)
        else:
            buckets["표시 없음"].append(name)

    total = sum(len(v) for v in buckets.values())
    print(f"{os.path.basename(root)} — 앱 코드 싱글톤 {total}개")
    print(f"(집계 제외 {len(skipped)}건: " + ", ".join(sorted({w for w, _ in skipped})) + ")\n")

    for key in BUCKETS:
        names = buckets[key]
        if names:
            print(f"  {key:30} {len(names):2}개  {', '.join(sorted(names))}")

    handled = len(buckets["actor 격리"]) + len(buckets["@MainActor 격리"]) + len(buckets["Sendable 명시"])
    escaped = len(buckets["⚠️ @unchecked Sendable"]) + len(buckets["⚠️ nonisolated(unsafe) shared"])
    print(f"\n  격리 처리됨 {handled}개 · 검사를 끈 것 {escaped}개 · 확인 필요 {len(buckets['표시 없음'])}개")
    return 0


if __name__ == "__main__":
    sys.exit(main())
