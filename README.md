# local-terminal-llm

A local-first shell copilot wrapper around the `llm` CLI.

## What this repo provides

- `askllm` Python CLI with:
  - normal Q&A mode
  - command-only mode (`-co`, `--command-only`)
  - spinner rendered to stderr
  - wrapper-controlled web retrieval (`--web`)
  - local docs retrieval (`--docs`, `--docs-db`)
  - heuristic routing (`--auto`)
  - persistent default model selection (`-ms`, `--model-select`)
- `shellExtension.sh` for zsh/bash/ksh-style shells
- `shellExtension.fish` for fish
- installer scripts with `-h` / `--help`:
  - `scripts/install-askllm.sh`
  - `scripts/install-shell-extension.sh`
  - `scripts/setup.sh`

## Quick setup

```sh
./scripts/setup.sh
# only validate/install dependencies:
./scripts/setup.sh --dep-only
```

When run interactively, `setup.sh` asks whether to keep the default command alias `ask` or configure a custom alias.
Hotkeys are disabled by default when using `setup.sh`.
Normal setup also validates/installs runtime dependencies (including `llm`) to avoid missing PATH/runtime errors.

Then reload your shell config (or open a new shell).

Configure all supported environment keys interactively:

```sh
ask --env-setup
```

### Shell-specific setup (optional)

```sh
./scripts/install-shell-extension.sh --shell zsh
./scripts/install-shell-extension.sh --shell bash
./scripts/install-shell-extension.sh --shell fish
./scripts/install-shell-extension.sh --shell zsh --alias ask
./scripts/install-shell-extension.sh --shell zsh --hotkey '^G'
./scripts/install-shell-extension.sh --shell zsh --codex-hotkey '^O'
```

## Hotkeys

The shell extension now supports keyboard hotkeys that inject commands directly into your prompt.

You can also configure them during install/setup:

```sh
./scripts/setup.sh --shell zsh --hotkey '^G'
./scripts/setup.sh --shell zsh --codex-hotkey '^O' --claude-hotkey '^Y'
```

Default when using `setup.sh`:

- all askllm hotkeys are disabled
- zsh integration wraps `ask` with `noglob`, so unquoted prompts like `ask --web what day is it?` work.

To remove all existing keybindings from your shell config:

```sh
./scripts/remove-keybindings.sh
```

If your current Bash session still has TAB remapped, run:

```sh
bind '"\C-i": complete'
```

You can also configure shortcuts for other CLI tools like codex or claude:

```sh
# disable the default if you don't want Ctrl+I / Tab behavior
export ASK_HOTKEY_ASK=""

# bind Ctrl+G to ask
export ASK_HOTKEY_ASK="^G"
export ASK_HOTKEY_ASK_CMD="ask "

# bind Ctrl+O to codex
export ASK_HOTKEY_CODEX="^O"
export ASK_HOTKEY_CODEX_CMD="codex "

# bind Ctrl+Y to claude
export ASK_HOTKEY_CLAUDE="^Y"
export ASK_HOTKEY_CLAUDE_CMD="claude "

# optional custom hotkey/command
export ASK_HOTKEY_CUSTOM="^K"
export ASK_HOTKEY_CUSTOM_CMD="ollama run llama3.2 "
```

Then reload your shell config.

## Usage examples

```sh
ask "Explain rsync -avz"
ask -co "find files larger than 1GB"
ask --web "latest bun install instructions"
ask --docs mydocs "how do vite path aliases work"
ask --auto "latest react router api changes"
cat package.json | ask -co "write a jq command to print dependencies"
```

## Model selection

Temporary override:

```sh
ask -m llama3.2:3b "summarize this"
```

Persist default model for future runs:

```sh
ask -ms llama3.2:3b
```

Interactive model picker (CLI selector + optional API key paste prompt):

```sh
ask -ms
# alias:
ask -sm
# both also accept a MODEL value for direct persistence:
ask -sm llama3.2:3b
```

The picker now prints ASCII model cards for the current default model and your newly selected model.
If a provider/API key is missing at runtime, `ask` will prompt to set one and can print an `export ...` command for copy/paste.
If a local Ollama-style model is missing (for example `phi3:mini`), `ask` can prompt to install/configure it and then retry.
Provider keys can also be entered in one pass with `ask --env-setup`.

Power model (OpenAI) configuration and usage:

```sh
ask -pc gpt-5.4
ask -p "analyze this architecture and propose a migration plan"
```

Direct file-affecting command execution with confirmation:

```sh
ask -co -no "rename all .jpeg files to .jpg in this repo"
```

Custom spinner animation (2-3 styles):

```sh
ask --spinner-style dots "explain rsync flags"
ask --spinner-style bounce "summarize this design"
ask --spinner-style-select line
```

This stores the default in:

- `~/.config/askllm/config.json`

Environment variables still work:

Core:

- `ASK_MODEL` (highest-priority default model)
- `ASK_POWER_MODEL`
- `ASK_SYSTEM`
- `ASK_CONFIG_FILE`
- `ASK_ALIAS_NAME`
- `ASKLLM_BIN`

Retrieval:

- `ASK_DOCS_DB`
- `ASK_DOCS_COLLECTION`
- `ASK_WEB_PROVIDER`

TTS:

- `ASK_TTS_MODEL`
- `ASK_TTS_SAMPLE_RATE`
- `ASK_TTS_MODE`
- `ASK_TTS_DELAY_SECONDS`

UI:

- `ASK_SPINNER_STYLE`

Hotkeys:

- `ASK_HOTKEY_ASK`
- `ASK_HOTKEY_ASK_CMD`
- `ASK_HOTKEY_CODEX`
- `ASK_HOTKEY_CODEX_CMD`
- `ASK_HOTKEY_CLAUDE`
- `ASK_HOTKEY_CLAUDE_CMD`
- `ASK_HOTKEY_CUSTOM`
- `ASK_HOTKEY_CUSTOM_CMD`

API key env names:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY`
- `MISTRAL_API_KEY`
- `GROQ_API_KEY`
- `OPENROUTER_API_KEY`
- `COHERE_API_KEY`
- `HUGGINGFACE_API_KEY`
- `EXA_API_KEY`

## Safety / Security

- API keys entered through `ask` are saved locally using `llm keys set` (offline key store on your machine).
- `ask --env-setup` does not write API keys to your shell config unless you explicitly opt in.
- Provider key handling is local-first and integrated with the `llm` key workflow (`llm keys set/get`).

## Docs mode layout

By default, docs collections are read from:

- `~/.local/share/ask/docs`

Expected structure:

- `~/.local/share/ask/docs/<collection-name>/...`

Indexes are stored automatically under:

- `~/.local/share/ask/docs/.index/`

## Help

```sh
ask --help
./scripts/setup.sh --help
./scripts/install-shell-extension.sh --help
./scripts/install-askllm.sh --help
./scripts/remove-keybindings.sh --help
./scripts/devdocs_scraper.py --help
```

## DevDocs scraper + embeddings

Interactive mode (terminal checkbox UI with `[ ] Select all` at top, `[X]` toggles):

```sh
./scripts/devdocs_scraper.py
```

Non-interactive selection:

```sh
./scripts/devdocs_scraper.py --select react,python
```

This writes JSONL to `~/.local/share/ask/processed/<docset>.jsonl` and then runs:

```sh
llm embed-multi <docset>_docs ~/.local/share/ask/processed/<docset>.jsonl \
  -d ~/.local/share/ask/docs.db \
  -m sentence-transformers/all-MiniLM-L6-v2 \
  --store
```
