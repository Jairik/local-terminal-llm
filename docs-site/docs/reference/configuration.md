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
- `ASK_SYSTEM`
- `ASK_CONFIG_FILE`
- `ASK_ALIAS_NAME`

Retrieval:

- `ASK_DOCS_DB`
- `ASK_DOCS_COLLECTION`
- `ASK_WEB_PROVIDER`

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
