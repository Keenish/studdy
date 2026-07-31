#!/usr/bin/env python3
"""저장소 안 모든 .md의 상대 링크와 앵커를 전수 검사한다.

사용: python3 AI/code/check_links.py [--quiet]
반환: 깨진 링크가 하나라도 있으면 1, 없으면 0

왜 필요한가 — AI/phase-parallel-ai-verification.md §1 사례 7·8 참조.
문서 링크는 컴파일러가 검사해주지 않는다. 손으로 확인하면 반드시 놓친다.
"""
import os
import re
import sys
import glob

LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
HEADING = re.compile(r"^#{1,6}\s+(.*)$", re.M)
EXTERNAL = ("http://", "https://", "mailto:", "tel:")


def slug(heading: str) -> str:
    """GitHub 앵커 규칙 근사: 소문자화 → 영숫자·공백·하이픈·한글만 남김 → 공백을 하이픈으로."""
    s = heading.lower()
    s = re.sub(r"[^\w\s\-가-힣]", "", s)
    return re.sub(r"\s", "-", s.strip())


def main() -> int:
    quiet = "--quiet" in sys.argv
    files = sorted(p for p in glob.glob("**/*.md", recursive=True) if ".claude" not in p)
    if not files:
        print("검사할 .md가 없다. 리포 루트에서 실행하고 있는지 확인할 것.")
        return 1

    headings = {}
    for path in files:
        with open(path, encoding="utf-8") as f:
            headings[path] = {slug(m.group(1)) for m in HEADING.finditer(f.read())}

    broken_paths: list[tuple[str, str]] = []
    broken_anchors: list[tuple[str, str]] = []

    for path in files:
        base = os.path.dirname(path)
        with open(path, encoding="utf-8") as f:
            body = f.read()

        for match in LINK.finditer(body):
            target = match.group(1)
            if target.startswith(EXTERNAL):
                continue

            file_part, _, anchor = target.partition("#")
            resolved = path

            if file_part:
                full = os.path.normpath(os.path.join(base, file_part))
                if not os.path.exists(full):
                    broken_paths.append((path, target))
                    continue
                resolved = full

            # 앵커는 대상이 이 저장소의 .md일 때만 검사할 수 있다
            if anchor and resolved in headings and anchor not in headings[resolved]:
                broken_anchors.append((path, target))

    total = len(broken_paths) + len(broken_anchors)

    if not quiet or total:
        print(f"md {len(files)}개 검사 → 깨진 경로 {len(broken_paths)}건 / 깨진 앵커 {len(broken_anchors)}건")

    for where, target in broken_paths:
        print(f"  [경로] {where} -> {target}")
    for where, target in broken_anchors:
        print(f"  [앵커] {where} -> {target}")

    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
