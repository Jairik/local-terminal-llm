# Shell Integration and Hotkeys

## Shell Extension

The installer appends `shellExtension.sh` (or fish equivalent) to your shell config.

```sh
./scripts/install-shell-extension.sh --shell zsh
./scripts/install-shell-extension.sh --shell fish
```

## Default Alias

Default alias is `ask`, configurable during setup or via `--alias`.

## Hotkey Setup via Script

```sh
./scripts/setup.sh --shell zsh --hotkey '^G'
./scripts/setup.sh --shell zsh --codex-hotkey '^O' --claude-hotkey '^Y'
```

## Environment Variable Controls

- `ASK_HOTKEY_ASK`
- `ASK_HOTKEY_ASK_CMD`
- `ASK_HOTKEY_CODEX`
- `ASK_HOTKEY_CODEX_CMD`
- `ASK_HOTKEY_CLAUDE`
- `ASK_HOTKEY_CLAUDE_CMD`
- `ASK_HOTKEY_CUSTOM`
- `ASK_HOTKEY_CUSTOM_CMD`

Example:

```sh
export ASK_HOTKEY_ASK='^G'
export ASK_HOTKEY_ASK_CMD='ask '
```
