# Development

## Local Validation

Run quick checks:

```sh
python3 -m py_compile askllm scripts/devdocs_scraper.py
./askllm --help
./scripts/setup.sh --help
```

## Documentation Build

```sh
mkdocs build -f docs-site/mkdocs.yml --strict
```

Serve locally:

```sh
mkdocs serve -f docs-site/mkdocs.yml
```

## GitHub Pages Deployment

Deployment is automated via `.github/workflows/docs-site-pages.yml`.

On push to `main` (or manual dispatch), the workflow:

1. installs MkDocs
2. builds `docs-site`
3. uploads artifact
4. deploys to GitHub Pages

## Repository Practices

- Keep scripts shell-agnostic where possible.
- Prefer explicit flags over implicit behavior.
- Keep command execution guarded and confirmable.
