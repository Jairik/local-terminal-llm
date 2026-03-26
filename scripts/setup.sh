#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

shell_name=""
config_file=""
target_file=""
extension_file=""
force=0
dry_run=0
dep_only=0
embedding_model="sentence-transformers/all-MiniLM-L6-v2"
ask_hotkey=""
ask_hotkey_set=0
ask_command=""
ask_command_set=0
codex_hotkey=""
codex_hotkey_set=0
codex_command=""
codex_command_set=0
claude_hotkey=""
claude_hotkey_set=0
claude_command=""
claude_command_set=0
custom_hotkey=""
custom_hotkey_set=0
custom_command=""
custom_command_set=0
alias_name=""
alias_name_set=0

show_help() {
  cat <<'EOF'
Usage: setup.sh [options]

Install askllm and append shell integration in one command.

Options:
  -s, --shell NAME      Shell type (zsh, bash, fish, ...)
  -c, --config PATH     Shell config file to modify
  -t, --target PATH     askllm install path (default: ~/.local/bin/askllm)
  -e, --extension PATH  Extension file to source from config
  -a, --alias NAME      Command alias to define (default: ask)
  -k, --hotkey KEY      Set ASK_HOTKEY_ASK (same as --ask-hotkey)
      --ask-hotkey KEY
      --ask-command CMD
      --codex-hotkey KEY
      --codex-command CMD
      --claude-hotkey KEY
      --claude-command CMD
      --custom-hotkey KEY
      --custom-command CMD
      --dep-only        Validate/install runtime dependencies only, then exit
      --embedding-model MODEL
                        Embedding model to validate in dep mode
      --force           Replace existing extension block in config
      --dry-run         Show actions only
  -h, --help            Show this help message

Notes:
  If --alias is not provided and setup is interactive, you will be prompted:
  - Enter/Y -> use default alias `ask`
  - n       -> enter a custom alias name

Examples:
  ./scripts/setup.sh
  ./scripts/setup.sh --shell zsh
  ./scripts/setup.sh --shell fish --force
  ./scripts/setup.sh --alias ask
  ./scripts/setup.sh --shell zsh --hotkey '^G'
  ./scripts/setup.sh --shell zsh --codex-hotkey '^O'
  ./scripts/setup.sh --dep-only
EOF
}

ensure_python3() {
  if command -v python3 >/dev/null 2>&1; then
    return 0
  fi
  echo "Error: python3 is required but was not found on PATH." >&2
  return 1
}

install_llm_cli() {
  if command -v llm >/dev/null 2>&1; then
    return 0
  fi

  if [ "$dry_run" -eq 1 ]; then
    echo "[dry-run] llm not found; would install using pipx or python3 -m pip --user"
    return 0
  fi

  echo "llm CLI not found. Installing..."

  if command -v pipx >/dev/null 2>&1; then
    pipx install llm >/dev/null 2>&1 || pipx upgrade llm >/dev/null 2>&1 || true
  fi

  if ! command -v llm >/dev/null 2>&1; then
    if ! python3 -m pip --version >/dev/null 2>&1; then
      python3 -m ensurepip --upgrade >/dev/null 2>&1 || true
    fi
    python3 -m pip install --user --upgrade llm >/dev/null 2>&1
  fi

  if ! command -v llm >/dev/null 2>&1 && [ -x "$HOME/.local/bin/llm" ]; then
    PATH="$HOME/.local/bin:$PATH"
    export PATH
  fi

  if ! command -v llm >/dev/null 2>&1; then
    echo "Error: llm is still unavailable after install attempts." >&2
    echo "Add ~/.local/bin to PATH if llm was installed there." >&2
    return 1
  fi
}

ensure_embed_multi() {
  if ! command -v llm >/dev/null 2>&1; then
    if [ "$dry_run" -eq 1 ]; then
      echo "[dry-run] would verify llm embed-multi availability"
      return 0
    fi
    echo "Error: llm is not available on PATH." >&2
    return 1
  fi

  if [ "$dry_run" -eq 1 ]; then
    echo "[dry-run] would verify llm embed-multi availability"
    return 0
  fi

  if llm embed-multi --help >/dev/null 2>&1; then
    return 0
  fi
  echo "Error: llm embed-multi is unavailable. Upgrade llm." >&2
  return 1
}

ensure_embedding_model() {
  model_name="$1"
  alt_model_name="$model_name"
  if [ "${model_name#sentence-transformers/}" != "$model_name" ]; then
    alt_model_name="${model_name#sentence-transformers/}"
  fi

  if ! command -v llm >/dev/null 2>&1; then
    if [ "$dry_run" -eq 1 ]; then
      echo "[dry-run] would verify embedding model '$model_name'"
      return 0
    fi
    echo "Error: llm is not available on PATH." >&2
    return 1
  fi

  if llm embed-models 2>/dev/null | grep -F "$model_name" >/dev/null 2>&1; then
    return 0
  fi
  if [ "$alt_model_name" != "$model_name" ] && llm embed-models 2>/dev/null | grep -F "$alt_model_name" >/dev/null 2>&1; then
    return 0
  fi

  if [ "$dry_run" -eq 1 ]; then
    echo "[dry-run] embedding model '$model_name' missing; would install llm-sentence-transformers"
    return 0
  fi

  echo "Embedding model '$model_name' not found. Installing plugin..."

  llm install llm-sentence-transformers >/dev/null 2>&1 || true

  if ! llm embed-models 2>/dev/null | grep -F "$model_name" >/dev/null 2>&1; then
    if [ "$alt_model_name" != "$model_name" ] && llm embed-models 2>/dev/null | grep -F "$alt_model_name" >/dev/null 2>&1; then
      return 0
    fi
    if command -v pipx >/dev/null 2>&1; then
      pipx inject llm llm-sentence-transformers >/dev/null 2>&1 || true
    fi
  fi

  if ! llm embed-models 2>/dev/null | grep -F "$model_name" >/dev/null 2>&1; then
    if [ "$alt_model_name" != "$model_name" ] && llm embed-models 2>/dev/null | grep -F "$alt_model_name" >/dev/null 2>&1; then
      return 0
    fi
    python3 -m pip install --user --upgrade llm-sentence-transformers >/dev/null 2>&1 || true
  fi

  if llm embed-models 2>/dev/null | grep -F "$model_name" >/dev/null 2>&1; then
    return 0
  fi
  if [ "$alt_model_name" != "$model_name" ] && llm embed-models 2>/dev/null | grep -F "$alt_model_name" >/dev/null 2>&1; then
    return 0
  fi

  if ! llm embed-models 2>/dev/null | grep -F "$model_name" >/dev/null 2>&1; then
    echo "Error: embedding model '$model_name' is still unavailable." >&2
    if [ "$alt_model_name" != "$model_name" ]; then
      echo "Tried alias '$alt_model_name' as well." >&2
    fi
    return 1
  fi
}

install_dependencies() {
  echo "Validating dependencies..."
  ensure_python3
  install_llm_cli
  ensure_embed_multi
  ensure_embedding_model "$embedding_model"
  echo "Dependency validation complete."
}

is_valid_alias_name() {
  case "$1" in
    ''|[0-9]*|*[!A-Za-z0-9_]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

prompt_alias_choice() {
  if [ "$alias_name_set" -eq 1 ]; then
    return 0
  fi

  if [ ! -t 0 ] || [ ! -t 1 ]; then
    alias_name="ask"
    alias_name_set=1
    return 0
  fi

  while :; do
    printf "Use default alias 'ask'? [Y/n]: "
    if ! IFS= read -r _askllm_choice; then
      alias_name="ask"
      alias_name_set=1
      return 0
    fi
    _askllm_choice=$(printf '%s' "$_askllm_choice" | tr '[:upper:]' '[:lower:]')
    case "$_askllm_choice" in
      ''|y|yes)
        alias_name="ask"
        alias_name_set=1
        return 0
        ;;
      n|no)
        break
        ;;
      *)
        echo "Please answer Y or n."
        ;;
    esac
  done

  while :; do
    printf "Enter alias name: "
    if ! IFS= read -r _askllm_alias_input; then
      echo "Error: alias input was interrupted." >&2
      return 1
    fi
    _askllm_alias_input=$(printf '%s' "$_askllm_alias_input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if ! is_valid_alias_name "$_askllm_alias_input"; then
      echo "Error: invalid alias. Use [A-Za-z_][A-Za-z0-9_]*." >&2
      continue
    fi
    alias_name="$_askllm_alias_input"
    alias_name_set=1
    return 0
  done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  -s | --shell)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    shell_name="$2"
    shift 2
    ;;
  -c | --config)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    config_file="$2"
    shift 2
    ;;
  -t | --target)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    target_file="$2"
    shift 2
    ;;
  -e | --extension)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    extension_file="$2"
    shift 2
    ;;
  -a | --alias)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    alias_name="$2"
    alias_name_set=1
    shift 2
    ;;
  -k | --hotkey | --ask-hotkey)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    ask_hotkey="$2"
    ask_hotkey_set=1
    shift 2
    ;;
  --ask-command)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    ask_command="$2"
    ask_command_set=1
    shift 2
    ;;
  --codex-hotkey)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    codex_hotkey="$2"
    codex_hotkey_set=1
    shift 2
    ;;
  --codex-command)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    codex_command="$2"
    codex_command_set=1
    shift 2
    ;;
  --claude-hotkey)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    claude_hotkey="$2"
    claude_hotkey_set=1
    shift 2
    ;;
  --claude-command)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    claude_command="$2"
    claude_command_set=1
    shift 2
    ;;
  --custom-hotkey)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    custom_hotkey="$2"
    custom_hotkey_set=1
    shift 2
    ;;
  --custom-command)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    custom_command="$2"
    custom_command_set=1
    shift 2
    ;;
  --dep-only)
    dep_only=1
    shift
    ;;
  --embedding-model)
    if [ "$#" -lt 2 ]; then
      echo "Error: $1 requires a value" >&2
      exit 2
    fi
    embedding_model="$2"
    shift 2
    ;;
  --force)
    force=1
    shift
    ;;
  --dry-run)
    dry_run=1
    shift
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  *)
    echo "Error: unknown option: $1" >&2
    show_help >&2
    exit 2
    ;;
  esac
done

if [ "$alias_name_set" -eq 1 ] && ! is_valid_alias_name "$alias_name"; then
  echo "Error: invalid alias '$alias_name'. Use [A-Za-z_][A-Za-z0-9_]*." >&2
  exit 2
fi

if [ "$dep_only" -eq 1 ]; then
  install_dependencies
  exit 0
fi

prompt_alias_choice

install_cmd="$script_dir/install-askllm.sh"
extension_cmd="$script_dir/install-shell-extension.sh"

if [ ! -x "$install_cmd" ] || [ ! -x "$extension_cmd" ]; then
  echo "Error: expected executable scripts in $script_dir" >&2
  echo "Run: chmod +x scripts/*.sh" >&2
  exit 1
fi

set --
if [ -n "$target_file" ]; then
  set -- "$@" --target "$target_file"
fi
if [ "$dry_run" -eq 1 ]; then
  set -- "$@" --dry-run
fi
sh "$install_cmd" "$@"

set --
if [ -n "$shell_name" ]; then
  set -- "$@" --shell "$shell_name"
fi
if [ -n "$config_file" ]; then
  set -- "$@" --config "$config_file"
fi
if [ -n "$extension_file" ]; then
  set -- "$@" --extension "$extension_file"
fi
if [ "$force" -eq 1 ]; then
  set -- "$@" --force
fi
if [ "$alias_name_set" -eq 1 ]; then
  set -- "$@" --alias "$alias_name"
fi
if [ "$ask_hotkey_set" -eq 1 ]; then
  set -- "$@" --ask-hotkey "$ask_hotkey"
fi
if [ "$ask_command_set" -eq 1 ]; then
  set -- "$@" --ask-command "$ask_command"
fi
if [ "$codex_hotkey_set" -eq 1 ]; then
  set -- "$@" --codex-hotkey "$codex_hotkey"
fi
if [ "$codex_command_set" -eq 1 ]; then
  set -- "$@" --codex-command "$codex_command"
fi
if [ "$claude_hotkey_set" -eq 1 ]; then
  set -- "$@" --claude-hotkey "$claude_hotkey"
fi
if [ "$claude_command_set" -eq 1 ]; then
  set -- "$@" --claude-command "$claude_command"
fi
if [ "$custom_hotkey_set" -eq 1 ]; then
  set -- "$@" --custom-hotkey "$custom_hotkey"
fi
if [ "$custom_command_set" -eq 1 ]; then
  set -- "$@" --custom-command "$custom_command"
fi
if [ "$dry_run" -eq 1 ]; then
  set -- "$@" --dry-run
fi
sh "$extension_cmd" "$@"
