#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

shell_name=""
config_file=""
extension_file=""
force=0
dry_run=0
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

marker_start="# >>> askllm shell extension >>>"
marker_end="# <<< askllm shell extension <<<"

show_help() {
  cat <<'EOF'
Usage: install-shell-extension.sh [options]

Append ask shell integration to a shell config file.

Default behavior:
  - Detect shell from $SHELL
  - Choose config automatically (.zshrc/.bashrc/.kshrc/.profile)
  - Source shellExtension.sh (or shellExtension.fish for fish)

Options:
  -s, --shell NAME      Shell name (zsh, bash, fish, ksh, sh, ...)
  -c, --config PATH     Explicit shell config file path
  -e, --extension PATH  Explicit extension file to source
  -a, --alias NAME      Command alias to define (default in extension: ask)
  -k, --hotkey KEY      Set ASK_HOTKEY_ASK (same as --ask-hotkey)
      --ask-hotkey KEY
      --ask-command CMD
      --codex-hotkey KEY
      --codex-command CMD
      --claude-hotkey KEY
      --claude-command CMD
      --custom-hotkey KEY
      --custom-command CMD
      --force           Replace existing askllm block if already present
      --dry-run         Show actions without writing files
  -h, --help            Show this help message

Examples:
  ./scripts/install-shell-extension.sh --shell zsh --hotkey '^G'
  ./scripts/install-shell-extension.sh --shell bash --codex-hotkey '^O'
  ./scripts/install-shell-extension.sh --shell zsh --alias ai
  ./scripts/install-shell-extension.sh --shell zsh --custom-hotkey '^K' --custom-command 'ollama run llama3.2 '
EOF
}

normalize_shell_name() {
  case "$1" in
    *zsh*) echo "zsh" ;;
    *bash*) echo "bash" ;;
    *fish*) echo "fish" ;;
    *ksh*|*mksh*|*pdksh*) echo "ksh" ;;
    *sh*|*dash*) echo "sh" ;;
    *) echo "$1" ;;
  esac
}

default_config_for_shell() {
  case "$1" in
    zsh) echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    ksh) echo "$HOME/.kshrc" ;;
    sh) echo "$HOME/.profile" ;;
    *) echo "$HOME/.profile" ;;
  esac
}

default_extension_for_shell() {
  case "$1" in
    fish) echo "$repo_root/shellExtension.fish" ;;
    *) echo "$repo_root/shellExtension.sh" ;;
  esac
}

remove_existing_block() {
  src_file="$1"
  dst_file="$2"
  awk -v start="$marker_start" -v end="$marker_end" '
    $0 == start {skip = 1; next}
    $0 == end {skip = 0; next}
    skip == 0 {print}
  ' "$src_file" > "$dst_file"
}

expand_home_path() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#~/}" ;;
    *) printf '%s' "$1" ;;
  esac
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

escape_single_quoted_value() {
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
}

emit_shell_export_line() {
  var_name="$1"
  raw_value="$2"
  escaped_value=$(escape_single_quoted_value "$raw_value")
  printf "export %s='%s'\n" "$var_name" "$escaped_value"
}

emit_fish_export_line() {
  var_name="$1"
  raw_value="$2"
  escaped_value=$(escape_single_quoted_value "$raw_value")
  printf "set -gx %s '%s'\n" "$var_name" "$escaped_value"
}

emit_hotkey_lines_shell() {
  if [ "$alias_name_set" -eq 1 ]; then
    emit_shell_export_line "ASK_ALIAS_NAME" "$alias_name"
  fi
  if [ "$ask_hotkey_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_ASK" "$ask_hotkey"
  fi
  if [ "$ask_command_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_ASK_CMD" "$ask_command"
  fi
  if [ "$codex_hotkey_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_CODEX" "$codex_hotkey"
  fi
  if [ "$codex_command_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_CODEX_CMD" "$codex_command"
  fi
  if [ "$claude_hotkey_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_CLAUDE" "$claude_hotkey"
  fi
  if [ "$claude_command_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_CLAUDE_CMD" "$claude_command"
  fi
  if [ "$custom_hotkey_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_CUSTOM" "$custom_hotkey"
  fi
  if [ "$custom_command_set" -eq 1 ]; then
    emit_shell_export_line "ASK_HOTKEY_CUSTOM_CMD" "$custom_command"
  fi
}

emit_hotkey_lines_fish() {
  if [ "$alias_name_set" -eq 1 ]; then
    emit_fish_export_line "ASK_ALIAS_NAME" "$alias_name"
  fi
  if [ "$ask_hotkey_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_ASK" "$ask_hotkey"
  fi
  if [ "$ask_command_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_ASK_CMD" "$ask_command"
  fi
  if [ "$codex_hotkey_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_CODEX" "$codex_hotkey"
  fi
  if [ "$codex_command_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_CODEX_CMD" "$codex_command"
  fi
  if [ "$claude_hotkey_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_CLAUDE" "$claude_hotkey"
  fi
  if [ "$claude_command_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_CLAUDE_CMD" "$claude_command"
  fi
  if [ "$custom_hotkey_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_CUSTOM" "$custom_hotkey"
  fi
  if [ "$custom_command_set" -eq 1 ]; then
    emit_fish_export_line "ASK_HOTKEY_CUSTOM_CMD" "$custom_command"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s|--shell)
      if [ "$#" -lt 2 ]; then
        echo "Error: $1 requires a value" >&2
        exit 2
      fi
      shell_name="$2"
      shift 2
      ;;
    -c|--config)
      if [ "$#" -lt 2 ]; then
        echo "Error: $1 requires a value" >&2
        exit 2
      fi
      config_file="$2"
      shift 2
      ;;
    -e|--extension)
      if [ "$#" -lt 2 ]; then
        echo "Error: $1 requires a value" >&2
        exit 2
      fi
      extension_file="$2"
      shift 2
      ;;
    -a|--alias)
      if [ "$#" -lt 2 ]; then
        echo "Error: $1 requires a value" >&2
        exit 2
      fi
      alias_name="$2"
      alias_name_set=1
      shift 2
      ;;
    -k|--hotkey|--ask-hotkey)
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
    --force)
      force=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
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

if [ -z "$shell_name" ]; then
  shell_name=$(basename -- "${SHELL:-sh}")
fi
shell_name=$(normalize_shell_name "$shell_name")

if [ -z "$config_file" ]; then
  config_file=$(default_config_for_shell "$shell_name")
fi

if [ -z "$extension_file" ]; then
  extension_file=$(default_extension_for_shell "$shell_name")
fi

config_file=$(expand_home_path "$config_file")
extension_file=$(expand_home_path "$extension_file")

if [ "$alias_name_set" -eq 1 ] && ! is_valid_alias_name "$alias_name"; then
  echo "Error: invalid alias '$alias_name'. Use [A-Za-z_][A-Za-z0-9_]*." >&2
  exit 2
fi

if [ ! -f "$extension_file" ]; then
  echo "Error: extension file not found: $extension_file" >&2
  exit 1
fi

if [ "$shell_name" = "fish" ]; then
  block=$(
    {
      printf '%s\n' "$marker_start"
      emit_hotkey_lines_fish
      printf 'if test -f "%s"\n' "$extension_file"
      printf '  source "%s"\n' "$extension_file"
      printf 'end\n'
      printf '%s\n' "$marker_end"
    }
  )
else
  block=$(
    {
      printf '%s\n' "$marker_start"
      emit_hotkey_lines_shell
      printf 'if [ -f "%s" ]; then\n' "$extension_file"
      printf '  . "%s"\n' "$extension_file"
      printf 'fi\n'
      printf '%s\n' "$marker_end"
    }
  )
fi

existing=0
if [ -f "$config_file" ] && grep -F "$marker_start" "$config_file" >/dev/null 2>&1; then
  existing=1
fi

if [ "$existing" -eq 1 ] && [ "$force" -ne 1 ]; then
  echo "Shell extension block already exists in $config_file"
  echo "Use --force to replace it."
  exit 0
fi

if [ "$dry_run" -eq 1 ]; then
  echo "[dry-run] target shell: $shell_name"
  echo "[dry-run] config file: $config_file"
  echo "[dry-run] extension file: $extension_file"
  if [ "$existing" -eq 1 ]; then
    echo "[dry-run] existing block would be replaced"
  else
    echo "[dry-run] block would be appended"
  fi
  if [ "$alias_name_set" -eq 1 ]; then
    echo "[dry-run] ASK_ALIAS_NAME=$alias_name"
  fi
  if [ "$ask_hotkey_set" -eq 1 ]; then
    echo "[dry-run] ASK_HOTKEY_ASK=$ask_hotkey"
  fi
  if [ "$codex_hotkey_set" -eq 1 ]; then
    echo "[dry-run] ASK_HOTKEY_CODEX=$codex_hotkey"
  fi
  if [ "$claude_hotkey_set" -eq 1 ]; then
    echo "[dry-run] ASK_HOTKEY_CLAUDE=$claude_hotkey"
  fi
  if [ "$custom_hotkey_set" -eq 1 ]; then
    echo "[dry-run] ASK_HOTKEY_CUSTOM=$custom_hotkey"
  fi
  printf '%s\n' "[dry-run] block:" 
  printf '%s\n' "$block"
  exit 0
fi

mkdir -p "$(dirname -- "$config_file")"
touch "$config_file"

if [ "$existing" -eq 1 ] && [ "$force" -eq 1 ]; then
  tmp_file=$(mktemp)
  remove_existing_block "$config_file" "$tmp_file"
  cat "$tmp_file" > "$config_file"
  rm -f "$tmp_file"
fi

{
  printf '\n'
  printf '%s\n' "$block"
} >> "$config_file"

echo "Appended askllm shell extension to $config_file"
