# Retrieval Modes

## Web Grounding

```sh
ask --web "latest python release highlights"
```

- Uses wrapper-controlled retrieval provider logic
- Intended for freshness-sensitive prompts

Provider selection:

- `--web-provider auto`
- `--web-provider exa`
- `--web-provider ddgr`

## Local Docs Grounding

```sh
ask --docs react_docs "how to use useMemo correctly"
```

Documents root defaults to `~/.local/share/ask/docs` and can be changed via `--docs-db` or `ASK_DOCS_DB`.

## Auto Routing

```sh
ask --auto "latest bun install process"
```

Heuristic behavior:

- freshness-sensitive prompts prefer web retrieval
- otherwise docs retrieval if available
- fallback to ungrounded if no backend is available
