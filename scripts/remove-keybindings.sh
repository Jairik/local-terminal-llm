#!/usr/bin/env sh
set -eu

shell_name=""
config_file=""
dry_run=0

disable_marker_start="# >>> askllm keybindings disabled >>>"
disable_marker_end="# <<< askllm keybindings disabled <<<"
extension_marker_start="# >>> askllm shell extension >>>"

show_help() {
  cat <<'EOF'
Usage: remove-keybindings.sh [options]

Remove askllm hotkey/keybinding settings from a shell config and disable them.

Options:
  -s, --shell NAME      Shell name (zsh, bash, fish, ksh, sh, ...)
  -c, --config PATH     Explicit shell config file path
      --dry-run         Show actions without writing files
  -h, --help            Show this help message

Examples:
  ./scripts/remove-keybindings.sh
  ./scripts/remove-keybindings.sh --shell zsh
  ./scripts/remove-keybindings.sh --config ~/.zshrc
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

expand_home_path() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

remove_existing_disable_block() {
  src_file="$1"
  dst_file="$2"
  awk -v start="$disable_marker_start" -v end="$disable_marker_end" '
    $0 == start {skip = 1; next}
    $0 == end {skip = 0; next}
    skip == 0 {print}
  ' "$src_file" > "$dst_file"
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
config_file=$(expand_home_path "$config_file")

if [ ! -f "$config_file" ]; then
  echo "No config file found at $config_file; nothing to update."
  exit 0
fi

tmp_no_block=""
tmp_cleaned=""
cleanup() {
  [ -n "$tmp_no_block" ] && rm -f "$tmp_no_block"
  [ -n "$tmp_cleaned" ] && rm -f "$tmp_cleaned"
}
trap cleanup EXIT

tmp_no_block=$(mktemp)
tmp_cleaned=$(mktemp)

remove_existing_disable_block "$config_file" "$tmp_no_block"

sed -E \
  -e '/^[[:space:]]*(export[[:space:]]+)?ASK_HOTKEY_(ASK|ASK_CMD|CODEX|CODEX_CMD|CLAUDE|CLAUDE_CMD|CUSTOM|CUSTOM_CMD)=/d' \
  -e '/^[[:space:]]*set[[:space:]]+-g[x]?[[:space:]]+ASK_HOTKEY_(ASK|ASK_CMD|CODEX|CODEX_CMD|CLAUDE|CLAUDE_CMD|CUSTOM|CUSTOM_CMD)([[:space:]]|$)/d' \
  "$tmp_no_block" > "$tmp_cleaned"

if [ "$dry_run" -eq 1 ]; then
  echo "[dry-run] shell: $shell_name"
  echo "[dry-run] config file: $config_file"
  echo "[dry-run] askllm hotkey assignments would be removed"
  if grep -F "$extension_marker_start" "$tmp_cleaned" >/dev/null 2>&1; then
    echo "[dry-run] disable block would be inserted before askllm shell extension block"
  else
    echo "[dry-run] no askllm extension block found; disable block would be appended"
  fi
  if [ "$shell_name" = "fish" ]; then
    echo "[dry-run] disable block:"
    printf '%s\n' "$disable_marker_start"
    printf "set -gx ASK_HOTKEY_ASK ''\n"
    printf "set -gx ASK_HOTKEY_CODEX ''\n"
    printf "set -gx ASK_HOTKEY_CLAUDE ''\n"
    printf "set -gx ASK_HOTKEY_CUSTOM ''\n"
    printf '%s\n' "$disable_marker_end"
  else
    echo "[dry-run] disable block:"
    printf '%s\n' "$disable_marker_start"
    printf "export ASK_HOTKEY_ASK=''\n"
    printf "export ASK_HOTKEY_CODEX=''\n"
    printf "export ASK_HOTKEY_CLAUDE=''\n"
    printf "export ASK_HOTKEY_CUSTOM=''\n"
    printf '%s\n' "$disable_marker_end"
  fi
  exit 0
fi

awk \
  -v ext_marker="$extension_marker_start" \
  -v disable_start="$disable_marker_start" \
  -v disable_end="$disable_marker_end" \
  -v shell_name="$shell_name" \
  '
  function emit_disable_block() {
    print disable_start
    if (shell_name == "fish") {
      print "set -gx ASK_HOTKEY_ASK '\'''\''"
      print "set -gx ASK_HOTKEY_CODEX '\'''\''"
      print "set -gx ASK_HOTKEY_CLAUDE '\'''\''"
      print "set -gx ASK_HOTKEY_CUSTOM '\'''\''"
    } else {
      print "export ASK_HOTKEY_ASK='\'''\''"
      print "export ASK_HOTKEY_CODEX='\'''\''"
      print "export ASK_HOTKEY_CLAUDE='\'''\''"
      print "export ASK_HOTKEY_CUSTOM='\'''\''"
    }
    print disable_end
  }
  {
    if (!inserted && $0 == ext_marker) {
      emit_disable_block()
      print ""
      inserted = 1
    }
    print
  }
  END {
    if (!inserted) {
      if (NR > 0) {
        print ""
      }
      emit_disable_block()
    }
  }
  ' "$tmp_cleaned" > "$config_file"

echo "Removed askllm keybindings from $config_file"
echo "Reload your shell config (or open a new shell)."
if [ "$shell_name" = "bash" ]; then
  echo "If TAB is still remapped in the current shell session, run:"
  echo "  bind '\"\\C-i\": complete'"
fi
