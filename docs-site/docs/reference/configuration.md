# Configuration Reference

## CLI Flags

Run full help:

```sh
ask --help
```

High-impact flags:

- `-co`, `--command-only`
- `-no`, `--no-output`
- `-m`, `--model`
- `-sm`, `--select-model`
- `-ms`, `--model-select`
- `-pc`, `--power-config`
- `-p`, `--power`
- `--web`, `--docs`, `--auto`
- `--tts`, `--tts-configure`
- `--env-setup`, `--env-shell`, `--env-config-file`

## Interactive Env Setup

Configure all supported environment keys in one guided flow:

```sh
ask --env-setup
```

Optional shell/config targeting:

```sh
ask --env-setup --env-shell zsh --env-config-file ~/.zshrc
```

By default, API keys entered in this setup are stored in your local `llm` key store and are not written to shell config unless you explicitly opt in.

## Config File

Default:

- `~/.config/askllm/config.json`

May contain keys like:

- `default_model`
- `power_model`
- `spinner_style`

## Environment Variables

Core:

- `ASK_MODEL`
- `ASK_POWER_MODEL`
- `ASK_SYSTEM`
- `ASK_CONFIG_FILE`
- `ASK_ALIAS_NAME`
- `ASKLLM_BIN`

Retrieval:

- `ASK_DOCS_DB`
- `ASK_DOCS_COLLECTION`
- `ASK_WEB_PROVIDER`

UI:

- `ASK_SPINNER_STYLE`

TTS:

- `ASK_TTS_MODEL`
- `ASK_TTS_SAMPLE_RATE`
- `ASK_TTS_MODE`
- `ASK_TTS_DELAY_SECONDS`

Hotkeys:

- `ASK_HOTKEY_ASK`
- `ASK_HOTKEY_ASK_CMD`
- `ASK_HOTKEY_CODEX`
- `ASK_HOTKEY_CODEX_CMD`
- `ASK_HOTKEY_CLAUDE`
- `ASK_HOTKEY_CLAUDE_CMD`
- `ASK_HOTKEY_CUSTOM`
- `ASK_HOTKEY_CUSTOM_CMD`

Provider API key env names:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY`
- `MISTRAL_API_KEY`
- `GROQ_API_KEY`
- `OPENROUTER_API_KEY`
- `COHERE_API_KEY`
- `HUGGINGFACE_API_KEY`
- `EXA_API_KEY`
