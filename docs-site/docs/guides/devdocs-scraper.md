# DevDocs Scraper

`scripts/devdocs_scraper.py` can list top-level DevDocs docsets, let you select interactively, scrape documents, and run embeddings via `llm embed-multi`.

## List Available Top-level Docsets

```sh
./scripts/devdocs_scraper.py --list-only
```

## Interactive Selection

```sh
./scripts/devdocs_scraper.py
```

Interactive selector behavior:

- top `[ ] Select all` option
- `[X]` marker for selected entries
- terminal-driven multi-select flow

## Non-interactive Selection

```sh
./scripts/devdocs_scraper.py --select react,python
./scripts/devdocs_scraper.py --select all
```

## Embedding Output

Scraped JSONL is written under:

- `~/.local/share/ask/processed/<docset>.jsonl`

Embedding command shape:

```sh
llm embed-multi <docset>_docs ~/.local/share/ask/processed/<docset>.jsonl \
  -d ~/.local/share/ask/docs.db \
  -m sentence-transformers/all-MiniLM-L6-v2 \
  --store
```

## Options

```sh
./scripts/devdocs_scraper.py --help
```

Useful flags:

- `--embedding-model`
- `--embed-db`
- `--processed-dir`
- `--no-embed`
- `--max-pages`
