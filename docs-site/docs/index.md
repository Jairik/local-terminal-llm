# local-terminal-llm

`ask` is a local-first terminal workflow built around the `llm` CLI, optional local retrieval, and shell-native command execution.

This site documents how to install it, configure it, and use its higher-level features safely.

## What You Get

- A Python CLI (`askllm`) normally invoked as `ask`
- Normal Q&A mode with selectable models
- Command-only mode (`-co`) with optional direct execution (`-no`)
- Retrieval grounding:
  - `--web` for current web context
  - `--docs` for local document collections
  - `--auto` for heuristic routing
- Text-to-speech with Piper (`--tts`) in `full` or `stream` mode
- Shell integration for bash, zsh, fish, and similar shells
- Configurable prompt-insert hotkeys for `ask`, `codex`, `claude`, or custom commands

## Quick Start

```sh
./scripts/setup.sh
ask "Explain rsync -avz"
```

Only install/validate dependencies:

```sh
./scripts/setup.sh --dep-only
```

## Typical Flows

```sh
# command generation only
ask -co "find the 20 largest files"

# command generation + execute after confirmation
ask -co -no "rename all .jpeg files to .jpg in this repo"

# stream speech while tokens are generated
ask --tts --tts-configure stream "summarize this changelog"
```

## Documentation Structure

- [Motivation](motivation.md)
- [Installation](getting-started/installation.md)
- [Quickstart](getting-started/quickstart.md)
- [Guides](guides/core-usage.md)
- [Configuration Reference](reference/configuration.md)
- [Safety and Security](reference/safety-security.md)
- [Troubleshooting](reference/troubleshooting.md)
