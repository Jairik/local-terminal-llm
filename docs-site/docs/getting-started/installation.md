# Installation

## Prerequisites

Required:

- Linux/macOS shell environment (zsh, bash, fish, etc.)
- Python 3.11+ (for the CLI script)
- `llm` installed and available on `PATH`

Optional but recommended:

- Ollama (or another configured `llm` provider)
- `piper` and `aplay` for text-to-speech
- `ddgr` or Exa API key for web retrieval modes

## One-command Setup

```sh
./scripts/setup.sh
```

The setup script can:

- install `askllm`
- append shell extension sourcing to the right shell config file
- configure alias and hotkeys
- validate/install runtime dependencies (including `llm`)

During interactive setup, you will be asked whether to use the default alias `ask`.
Press Enter for default, or choose custom alias input.

After setup, you can configure all environment keys with:

```sh
ask --env-setup
```

## Dependency-only Mode

Use this when you only want dependency validation/install checks:

```sh
./scripts/setup.sh --dep-only
```

## Manual Installation

Install the CLI only:

```sh
./scripts/install-askllm.sh
```

Install shell extension only:

```sh
./scripts/install-shell-extension.sh --shell zsh
./scripts/install-shell-extension.sh --shell bash
./scripts/install-shell-extension.sh --shell fish
```

## Verify Installation

```sh
ask --help
./scripts/setup.sh --help
```

If `ask` is not found, reload your shell config or open a new shell session.
