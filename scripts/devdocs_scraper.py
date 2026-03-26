#!/usr/bin/env python3
from __future__ import annotations

import argparse
import curses
import json
import re
import shlex
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path

DEFAULT_CATALOG_URL = "https://devdocs.io/docs.json"
DEFAULT_DOCUMENTS_BASE_URL = "https://documents.devdocs.io"
DEFAULT_PROCESSED_DIR = "~/.local/share/ask/processed"
DEFAULT_EMBED_DB = "~/.local/share/ask/docs.db"
DEFAULT_EMBED_MODEL = "sentence-transformers/all-MiniLM-L6-v2"


@dataclass(frozen=True)
class DocsetOption:
    base_slug: str
    slug: str
    name: str
    release: str
    versions: int
    mtime: int


class HtmlTextExtractor(HTMLParser):
    BLOCK_TAGS = {
        "p",
        "div",
        "section",
        "article",
        "header",
        "footer",
        "nav",
        "main",
        "aside",
        "li",
        "ul",
        "ol",
        "pre",
        "code",
        "table",
        "tr",
        "td",
        "th",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "br",
        "hr",
    }

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.skip_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        lowered = tag.lower()
        if lowered in {"script", "style", "noscript"}:
            self.skip_depth += 1
            return
        if self.skip_depth == 0 and lowered in self.BLOCK_TAGS:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        lowered = tag.lower()
        if lowered in {"script", "style", "noscript"}:
            self.skip_depth = max(self.skip_depth - 1, 0)
            return
        if self.skip_depth == 0 and lowered in self.BLOCK_TAGS:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if self.skip_depth == 0:
            self.parts.append(data)

    def get_text(self) -> str:
        text = "".join(self.parts)
        text = text.replace("\r", "")
        text = re.sub(r"[ \t]+", " ", text)
        text = re.sub(r" *\n+ *", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="devdocs_scraper.py",
        description=(
            "Scrape DevDocs docsets, write JSONL files, and optionally store embeddings "
            "using llm embed-multi."
        ),
    )
    parser.add_argument(
        "--catalog-url",
        default=DEFAULT_CATALOG_URL,
        help=f"DevDocs catalog endpoint (default: {DEFAULT_CATALOG_URL})",
    )
    parser.add_argument(
        "--documents-base-url",
        default=DEFAULT_DOCUMENTS_BASE_URL,
        help=f"Base URL for index.json/db.json files (default: {DEFAULT_DOCUMENTS_BASE_URL})",
    )
    parser.add_argument(
        "--processed-dir",
        default=DEFAULT_PROCESSED_DIR,
        help=f"Where JSONL files are written (default: {DEFAULT_PROCESSED_DIR})",
    )
    parser.add_argument(
        "--embed-db",
        default=DEFAULT_EMBED_DB,
        help=f"Embeddings SQLite database path (default: {DEFAULT_EMBED_DB})",
    )
    parser.add_argument(
        "--embedding-model",
        default=DEFAULT_EMBED_MODEL,
        help=f"Embedding model for llm embed-multi (default: {DEFAULT_EMBED_MODEL})",
    )
    parser.add_argument(
        "--select",
        default="",
        help=(
            "Comma-separated selections by base slug, full slug, or display name. "
            "Use 'all' to select all docsets. If omitted, interactive selector is shown."
        ),
    )
    parser.add_argument(
        "--list-only",
        action="store_true",
        help="List highest-level docsets and exit.",
    )
    parser.add_argument(
        "--no-embed",
        action="store_true",
        help="Only scrape/write JSONL; do not run llm embed-multi.",
    )
    parser.add_argument(
        "--max-pages",
        type=int,
        default=0,
        help="Optional cap on number of pages per docset for testing.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="HTTP timeout in seconds for each request.",
    )
    return parser.parse_args()


def fetch_json(url: str, timeout: float, retries: int = 3) -> object:
    last_error: Exception | None = None
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "devdocs-scraper/1.0",
            "Accept": "application/json",
        },
    )

    for attempt in range(1, retries + 1):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                payload = response.read().decode("utf-8")
            return json.loads(payload)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError) as exc:
            last_error = exc
            if attempt < retries:
                time.sleep(min(1.5 * attempt, 3.0))

    raise RuntimeError(f"Failed to fetch JSON from {url}: {last_error}")


def slug_base(slug: str) -> str:
    return slug.split("~", 1)[0]


def choose_primary_docset(items: list[dict[str, object]], base: str) -> dict[str, object]:
    exact = [item for item in items if str(item.get("slug", "")) == base]
    candidates = exact if exact else items

    def key(item: dict[str, object]) -> tuple[int, str]:
        mtime = item.get("mtime")
        mtime_int = int(mtime) if isinstance(mtime, (int, float, str)) and str(mtime).isdigit() else 0
        return (mtime_int, str(item.get("release", "")))

    return sorted(candidates, key=key, reverse=True)[0]


def highest_level_docsets(catalog: list[dict[str, object]]) -> list[DocsetOption]:
    groups: dict[str, list[dict[str, object]]] = defaultdict(list)

    for raw in catalog:
        slug = str(raw.get("slug", "")).strip()
        if not slug:
            continue
        groups[slug_base(slug)].append(raw)

    options: list[DocsetOption] = []
    for base, items in groups.items():
        primary = choose_primary_docset(items, base)
        slug = str(primary.get("slug", "")).strip()
        name = str(primary.get("name", "")).strip() or base
        release = str(primary.get("release", "")).strip()
        mtime_raw = primary.get("mtime")
        mtime = int(mtime_raw) if isinstance(mtime_raw, (int, float, str)) and str(mtime_raw).isdigit() else 0
        options.append(
            DocsetOption(
                base_slug=base,
                slug=slug,
                name=name,
                release=release,
                versions=len(items),
                mtime=mtime,
            )
        )

    options.sort(key=lambda option: (option.name.lower(), option.base_slug))
    return options


def render_label(option: DocsetOption) -> str:
    version_note = f" | release={option.release}" if option.release else ""
    alias_note = "" if option.slug == option.base_slug else f" | slug={option.slug}"
    variants_note = f" | variants={option.versions}" if option.versions > 1 else ""
    return f"{option.name} ({option.base_slug}){alias_note}{version_note}{variants_note}"


def interactive_select(options: list[DocsetOption]) -> list[DocsetOption]:
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        raise RuntimeError("Interactive mode requires a TTY. Use --select for non-interactive runs.")

    try:
        selected_indices = curses.wrapper(_run_selector_ui, options)
    except curses.error as exc:
        raise RuntimeError(f"Terminal does not support interactive curses UI: {exc}") from exc

    return [options[i] for i in selected_indices]


def _run_selector_ui(stdscr: curses.window, options: list[DocsetOption]) -> list[int]:
    curses.curs_set(0)
    stdscr.keypad(True)

    selected: set[int] = set()
    cursor = 0
    scroll = 0
    total_rows = len(options) + 1  # +1 for select-all row

    while True:
        stdscr.erase()
        height, width = stdscr.getmaxyx()
        body_height = max(3, height - 5)

        if cursor < scroll:
            scroll = cursor
        if cursor >= scroll + body_height:
            scroll = cursor - body_height + 1

        all_selected = len(selected) == len(options) and len(options) > 0
        header = "DevDocs selector: SPACE/X toggle | ENTER confirm | Q quit"
        status = f"Selected: {len(selected)}/{len(options)}"
        stdscr.addnstr(0, 0, header, max(1, width - 1), curses.A_BOLD)
        stdscr.addnstr(1, 0, status, max(1, width - 1), curses.A_DIM)

        visible_end = min(total_rows, scroll + body_height)
        y = 3
        for row in range(scroll, visible_end):
            if row == 0:
                checked = all_selected
                label = "Select all"
            else:
                option = options[row - 1]
                checked = (row - 1) in selected
                label = render_label(option)

            marker = "[X]" if checked else "[ ]"
            line = f"{marker} {label}"
            attr = curses.A_REVERSE if row == cursor else curses.A_NORMAL
            stdscr.addnstr(y, 0, line, max(1, width - 1), attr)
            y += 1

        footer = "Use arrows to move. Toggle top row to select/deselect everything."
        stdscr.addnstr(height - 1, 0, footer, max(1, width - 1), curses.A_DIM)
        stdscr.refresh()

        key = stdscr.getch()

        if key in (ord("q"), ord("Q")):
            return []
        if key in (curses.KEY_UP, ord("k"), ord("K")):
            cursor = max(0, cursor - 1)
            continue
        if key in (curses.KEY_DOWN, ord("j"), ord("J")):
            cursor = min(total_rows - 1, cursor + 1)
            continue
        if key in (ord("x"), ord("X"), ord(" ")):
            if cursor == 0:
                if all_selected:
                    selected.clear()
                else:
                    selected = set(range(len(options)))
            else:
                idx = cursor - 1
                if idx in selected:
                    selected.remove(idx)
                else:
                    selected.add(idx)
            continue
        if key in (ord("a"), ord("A")):
            if all_selected:
                selected.clear()
            else:
                selected = set(range(len(options)))
            continue
        if key in (curses.KEY_ENTER, 10, 13):
            return sorted(selected)


def parse_non_interactive_selection(raw: str, options: list[DocsetOption]) -> list[DocsetOption]:
    raw_tokens = [token.strip() for token in raw.split(",") if token.strip()]
    if not raw_tokens:
        return []

    if any(token.lower() == "all" for token in raw_tokens):
        return options

    by_base = {item.base_slug.lower(): item for item in options}
    by_slug = {item.slug.lower(): item for item in options}
    by_name = {item.name.lower(): item for item in options}

    selected: list[DocsetOption] = []
    seen: set[str] = set()

    for token in raw_tokens:
        lower = token.lower()
        match = by_base.get(lower) or by_slug.get(lower) or by_name.get(lower)
        if match is None:
            raise RuntimeError(f"Selection '{token}' did not match any top-level docset")
        if match.base_slug not in seen:
            selected.append(match)
            seen.add(match.base_slug)

    return selected


def sanitize_name(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9_]+", "_", value.lower())
    cleaned = cleaned.strip("_")
    return cleaned or "docset"


def strip_html(html_text: str) -> str:
    parser = HtmlTextExtractor()
    parser.feed(html_text)
    parser.close()
    return parser.get_text()


def docset_urls(base_url: str, slug: str) -> tuple[str, str]:
    root = base_url.rstrip("/")
    escaped_slug = urllib.parse.quote(slug)
    return (f"{root}/{escaped_slug}/index.json", f"{root}/{escaped_slug}/db.json")


def build_records(
    option: DocsetOption,
    index_payload: dict[str, object],
    db_payload: dict[str, str],
    max_pages: int,
) -> list[dict[str, str]]:
    raw_entries = index_payload.get("entries")
    if not isinstance(raw_entries, list):
        raise RuntimeError(f"Unexpected index payload format for {option.slug}: missing 'entries' list")

    records: list[dict[str, str]] = []

    for entry in raw_entries:
        if not isinstance(entry, dict):
            continue
        path = str(entry.get("path", "")).strip()
        title = str(entry.get("name", "")).strip() or path
        section = str(entry.get("type", "")).strip()
        if not path:
            continue

        html_doc = db_payload.get(path, "")
        text = strip_html(html_doc)
        if not text:
            continue

        records.append(
            {
                "id": f"{option.base_slug}:{path}",
                "text": text,
                "title": title,
                "section": section,
                "path": path,
                "url": f"https://devdocs.io/{option.slug}/{path}",
                "docset": option.base_slug,
                "docset_slug": option.slug,
            }
        )

        if max_pages > 0 and len(records) >= max_pages:
            break

    if (max_pages <= 0 or len(records) < max_pages) and "index" in db_payload:
        home_text = strip_html(db_payload.get("index", ""))
        if home_text:
            records.append(
                {
                    "id": f"{option.base_slug}:index",
                    "text": home_text,
                    "title": f"{option.name} index",
                    "section": "Index",
                    "path": "index",
                    "url": f"https://devdocs.io/{option.slug}",
                    "docset": option.base_slug,
                    "docset_slug": option.slug,
                }
            )

    return records


def write_jsonl(path: Path, records: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as file_obj:
        for record in records:
            file_obj.write(json.dumps(record, ensure_ascii=False) + "\n")


def run_embed_multi(collection: str, jsonl_path: Path, embed_db: Path, embedding_model: str) -> None:
    model_candidates: list[str] = []
    for candidate in (
        embedding_model,
        embedding_model.split("/", 1)[1] if embedding_model.startswith("sentence-transformers/") else "",
        f"sentence-transformers/{embedding_model}" if "/" not in embedding_model else "",
    ):
        cleaned = candidate.strip()
        if cleaned and cleaned not in model_candidates:
            model_candidates.append(cleaned)

    last_error = ""
    for model_name in model_candidates:
        cmd = [
            "llm",
            "embed-multi",
            collection,
            str(jsonl_path),
            "-d",
            str(embed_db),
            "-m",
            model_name,
            "--store",
        ]
        print("[embed]", " ".join(shlex.quote(part) for part in cmd))
        result = subprocess.run(cmd, check=False, capture_output=True, text=True)
        if result.returncode == 0:
            if model_name != embedding_model:
                print(f"[embed] model fallback used: {model_name}")
            return

        stderr = (result.stderr or "").strip()
        stdout = (result.stdout or "").strip()
        combined = "\n".join(part for part in (stderr, stdout) if part).strip()
        last_error = combined or f"exit code {result.returncode}"

        if "Unknown model:" in last_error and model_name != model_candidates[-1]:
            print(f"[embed] model '{model_name}' unavailable, trying next alias...")
            continue

        break

    raise RuntimeError(
        "llm embed-multi failed for collection "
        f"'{collection}'. Last error:\n{last_error}\n\n"
        "If this is a model issue, run:\n"
        "  llm install llm-sentence-transformers\n"
        "Then retry with --embedding-model all-MiniLM-L6-v2"
    )


def print_docset_list(options: list[DocsetOption]) -> None:
    print(f"Top-level DevDocs docsets: {len(options)}")
    for option in options:
        print(f"- {render_label(option)}")


def main() -> int:
    args = parse_args()

    processed_dir = Path(args.processed_dir).expanduser()
    embed_db = Path(args.embed_db).expanduser()

    catalog_payload = fetch_json(args.catalog_url, timeout=args.timeout)
    if not isinstance(catalog_payload, list):
        raise RuntimeError(f"Unexpected catalog payload from {args.catalog_url}: expected JSON array")

    docset_options = highest_level_docsets(catalog_payload)
    if not docset_options:
        raise RuntimeError("No docsets found in DevDocs catalog")

    if args.list_only:
        print_docset_list(docset_options)
        return 0

    if args.select:
        selected = parse_non_interactive_selection(args.select, docset_options)
    else:
        selected = interactive_select(docset_options)

    if not selected:
        print("No docsets selected. Exiting.")
        return 0

    print(f"Selected {len(selected)} docset(s): {', '.join(item.base_slug for item in selected)}")

    for option in selected:
        print(f"\n[scrape] {option.name} ({option.slug})")
        index_url, db_url = docset_urls(args.documents_base_url, option.slug)
        print(f"[fetch] {index_url}")
        index_payload_obj = fetch_json(index_url, timeout=args.timeout)
        print(f"[fetch] {db_url}")
        db_payload_obj = fetch_json(db_url, timeout=args.timeout)

        if not isinstance(index_payload_obj, dict):
            raise RuntimeError(f"Unexpected index payload for {option.slug}: expected object")
        if not isinstance(db_payload_obj, dict):
            raise RuntimeError(f"Unexpected db payload for {option.slug}: expected object")

        db_payload: dict[str, str] = {}
        for key, value in db_payload_obj.items():
            if isinstance(key, str) and isinstance(value, str):
                db_payload[key] = value

        records = build_records(
            option=option,
            index_payload=index_payload_obj,
            db_payload=db_payload,
            max_pages=args.max_pages,
        )
        if not records:
            print(f"[warn] No records extracted for {option.base_slug}, skipping.")
            continue

        out_file = processed_dir / f"{sanitize_name(option.base_slug)}.jsonl"
        write_jsonl(out_file, records)
        print(f"[write] {out_file} ({len(records)} records)")

        if args.no_embed:
            continue

        collection_name = f"{sanitize_name(option.base_slug)}_docs"
        run_embed_multi(
            collection=collection_name,
            jsonl_path=out_file,
            embed_db=embed_db,
            embedding_model=args.embedding_model,
        )

    print("\nDone.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nAborted by user.")
        raise SystemExit(130)
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)
