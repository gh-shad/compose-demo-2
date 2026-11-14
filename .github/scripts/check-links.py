#!/usr/bin/env python3
"""Check every link inside the project's Markdown files.

For each link to another file of the project, the file must exist. For a link to a
heading (the part after '#'), the heading must exist in that file, written the way
GitHub turns headings into links. Links to websites are not checked (no internet needed).

Run it from the project folder:  python3 .github/scripts/check-links.py
It prints every broken link, and ends with exit code 1 if there is at least one.
"""
import os
import re
import sys

FENCE = re.compile(r"```.*?```", re.S)
LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)\)")
HEADING = re.compile(r"^#{1,6}\s+(.*?)\s*$", re.M)


def heading_ids(path):
    """The link names GitHub gives to the headings of a Markdown file."""
    text = FENCE.sub("", open(path, encoding="utf-8").read())
    ids, seen = set(), {}
    for match in HEADING.finditer(text):
        title = match.group(1).replace("`", "")
        title = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", title).strip().lower()
        slug = re.sub(r"[^\w\- ]", "", title).replace(" ", "-")
        if slug in seen:
            seen[slug] += 1
            ids.add(f"{slug}-{seen[slug]}")
        else:
            seen[slug] = 0
            ids.add(slug)
    ids.update(re.findall(r'<a (?:name|id)="([^"]+)"', text))
    return ids


def markdown_files(root):
    for folder, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d != ".git"]
        for name in sorted(files):
            if name.endswith(".md"):
                yield os.path.relpath(os.path.join(folder, name), root)


def main():
    root = os.getcwd()
    checked = broken = 0
    for md in sorted(markdown_files(root)):
        text = FENCE.sub("", open(md, encoding="utf-8").read())
        for target in LINK.findall(text):
            if re.match(r"^(https?|mailto):", target):
                continue
            checked += 1
            path, _, anchor = target.partition("#")
            dest = os.path.normpath(os.path.join(os.path.dirname(md), path)) if path else md
            if not os.path.exists(dest):
                print(f"BROKEN  {md}: '{target}' (file not found)")
                broken += 1
            elif anchor and (not dest.endswith(".md") or anchor not in heading_ids(dest)):
                print(f"BROKEN  {md}: '{target}' (heading not found)")
                broken += 1
    print(f"{checked} links checked, {broken} broken.")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
