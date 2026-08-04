#!/usr/bin/env python3
"""Check generated MkDocs HTML for broken internal links and fragments."""

from __future__ import annotations

import argparse
import sys
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urljoin, urlsplit


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.links: list[tuple[str, str]] = []
        self.anchors: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        anchor = values.get("id") or values.get("name")
        if anchor:
            self.anchors.add(anchor)
        for attribute in ("href", "src"):
            value = values.get(attribute)
            if value:
                self.links.append((attribute, value))


def public_path(path: Path, site_dir: Path, prefix: str) -> str:
    relative = path.relative_to(site_dir).as_posix()
    if relative == "index.html":
        route = ""
    elif relative.endswith("/index.html"):
        route = relative[: -len("index.html")]
    else:
        route = relative
    return f"{prefix}{route}"


def output_candidates(site_dir: Path, route: str) -> list[Path]:
    relative = route.lstrip("/")
    path = site_dir / relative
    candidates = [path]
    if route.endswith("/"):
        candidates.append(path / "index.html")
    elif not PurePosixPath(route).suffix:
        candidates.extend((path / "index.html", path.with_suffix(".html")))
    return candidates


def check_site(site_dir: Path, site_prefix: str) -> list[str]:
    site_dir = site_dir.resolve()
    prefix = "/" + site_prefix.strip("/") + "/" if site_prefix.strip("/") else "/"
    pages: dict[Path, PageParser] = {}
    for path in sorted(site_dir.rglob("*.html")):
        parser = PageParser()
        parser.feed(path.read_text(encoding="utf-8"))
        pages[path.resolve()] = parser

    failures: list[str] = []
    for source, parser in pages.items():
        source_url = "https://docs.invalid" + public_path(source, site_dir, prefix)
        for attribute, raw_target in parser.links:
            target = raw_target.strip()
            if not target or target.startswith(("mailto:", "tel:", "data:", "javascript:")):
                continue
            split_raw = urlsplit(target)
            if split_raw.scheme or split_raw.netloc:
                continue

            resolved = urlsplit(urljoin(source_url, target))
            route = unquote(resolved.path)
            if prefix != "/":
                if not route.startswith(prefix):
                    failures.append(
                        f"{source.relative_to(site_dir)}: {attribute}={raw_target!r} escapes site prefix {prefix!r}"
                    )
                    continue
                route = "/" + route[len(prefix) :]

            candidates = output_candidates(site_dir, route)
            destination = next((candidate.resolve() for candidate in candidates if candidate.is_file()), None)
            if destination is None:
                failures.append(
                    f"{source.relative_to(site_dir)}: {attribute}={raw_target!r} has no generated target"
                )
                continue

            if resolved.fragment and destination.suffix == ".html":
                destination_parser = pages.get(destination)
                if destination_parser is None or unquote(resolved.fragment) not in destination_parser.anchors:
                    failures.append(
                        f"{source.relative_to(site_dir)}: {attribute}={raw_target!r} has no matching fragment"
                    )

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("site_dir", type=Path)
    parser.add_argument("--site-prefix", default="/lacuna-shell/")
    args = parser.parse_args()

    if not args.site_dir.is_dir():
        parser.error(f"site directory does not exist: {args.site_dir}")

    failures = check_site(args.site_dir, args.site_prefix)
    if failures:
        print("Generated documentation contains broken internal links:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    page_count = sum(1 for _ in args.site_dir.rglob("*.html"))
    print(f"Checked internal links in {page_count} generated HTML pages.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
