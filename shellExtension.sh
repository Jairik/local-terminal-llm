# Source this from your shell config (~/.zshrc, ~/.bashrc, ~/.kshrc, etc.).
# It defines the `ask` shell function and optional hotkey bindings.

ASK_ALIAS_NAME="${ASK_ALIAS_NAME:-ask}"

if alias ask >/dev/null 2>&1; then
  unalias ask 2>/dev/null || true
fi
if [ "$ASK_ALIAS_NAME" != "ask" ] && alias "$ASK_ALIAS_NAME" >/dev/null 2>&1; then
  unalias "$ASK_ALIAS_NAME" 2>/dev/null || true
fi

# Hotkey defaults. Set these in your shell config before sourcing this file.
ASK_HOTKEY_ASK="${ASK_HOTKEY_ASK-^I}"
_askllm_hotkey_cmd_defaulted=0
if [ -z "${ASK_HOTKEY_ASK_CMD+x}" ]; then
  ASK_HOTKEY_ASK_CMD="${ASK_ALIAS_NAME} "
  _askllm_hotkey_cmd_defaulted=1
fi
ASK_HOTKEY_CODEX="${ASK_HOTKEY_CODEX:-}"
ASK_HOTKEY_CODEX_CMD="${ASK_HOTKEY_CODEX_CMD:-codex }"
ASK_HOTKEY_CLAUDE="${ASK_HOTKEY_CLAUDE:-}"
ASK_HOTKEY_CLAUDE_CMD="${ASK_HOTKEY_CLAUDE_CMD:-claude }"
ASK_HOTKEY_CUSTOM="${ASK_HOTKEY_CUSTOM:-}"
ASK_HOTKEY_CUSTOM_CMD="${ASK_HOTKEY_CUSTOM_CMD:-}"

_askllm_is_valid_alias_name() {
  case "$1" in
    ''|[0-9]*|*[!A-Za-z0-9_]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

_askllm_shell_is_interactive() {
  case "$-" in
    *i*) return 0 ;;
    *) return 1 ;;
  esac
}

_askllm_has_command_only_flag() {
  for _askllm_arg in "$@"; do
    case "$_askllm_arg" in
      -co|--command-only)
        return 0
        ;;
    esac
  done
  return 1
}

_askllm_has_no_output_flag() {
  for _askllm_arg in "$@"; do
    case "$_askllm_arg" in
      -no|--no-output)
        return 0
        ;;
    esac
  done
  return 1
}

_askllm_trim_trailing_whitespace() {
  printf '%s' "$1" | sed 's/[[:space:]]*$//'
}

# zsh hotkey widgets
_askllm_zsh_insert_ask() {
  LBUFFER+="${ASK_HOTKEY_ASK_CMD:-ask }"
}

_askllm_zsh_insert_codex() {
  LBUFFER+="${ASK_HOTKEY_CODEX_CMD:-codex }"
}

_askllm_zsh_insert_claude() {
  LBUFFER+="${ASK_HOTKEY_CLAUDE_CMD:-claude }"
}

_askllm_zsh_insert_custom() {
  LBUFFER+="${ASK_HOTKEY_CUSTOM_CMD:-}"
}

_askllm_bind_hotkeys_zsh() {
  [ -n "${ZSH_VERSION-}" ] || return 0
  _askllm_shell_is_interactive || return 0

  zle -N _askllm_zsh_insert_ask
  zle -N _askllm_zsh_insert_codex
  zle -N _askllm_zsh_insert_claude
  zle -N _askllm_zsh_insert_custom

  [ -n "${ASK_HOTKEY_ASK-}" ] && bindkey "${ASK_HOTKEY_ASK}" _askllm_zsh_insert_ask
  [ -n "${ASK_HOTKEY_CODEX-}" ] && bindkey "${ASK_HOTKEY_CODEX}" _askllm_zsh_insert_codex
  [ -n "${ASK_HOTKEY_CLAUDE-}" ] && bindkey "${ASK_HOTKEY_CLAUDE}" _askllm_zsh_insert_claude
  [ -n "${ASK_HOTKEY_CUSTOM-}" ] && [ -n "${ASK_HOTKEY_CUSTOM_CMD-}" ] && bindkey "${ASK_HOTKEY_CUSTOM}" _askllm_zsh_insert_custom
}

# bash hotkey bindings
_askllm_bash_insert_text() {
  _askllm_insert_text="$1"
  READLINE_LINE="${READLINE_LINE}${_askllm_insert_text}"
  READLINE_POINT=${#READLINE_LINE}
}

_askllm_bash_insert_ask() {
  _askllm_bash_insert_text "${ASK_HOTKEY_ASK_CMD:-ask }"
}

_askllm_bash_insert_codex() {
  _askllm_bash_insert_text "${ASK_HOTKEY_CODEX_CMD:-codex }"
}

_askllm_bash_insert_claude() {
  _askllm_bash_insert_text "${ASK_HOTKEY_CLAUDE_CMD:-claude }"
}

_askllm_bash_insert_custom() {
  _askllm_bash_insert_text "${ASK_HOTKEY_CUSTOM_CMD:-}"
}

_askllm_bash_normalize_hotkey() {
  _askllm_hotkey="$1"
  case "$_askllm_hotkey" in
    ^?)
      _askllm_ctrl_char="${_askllm_hotkey#^}"
      _askllm_ctrl_char=$(printf '%s' "$_askllm_ctrl_char" | tr '[:upper:]' '[:lower:]')
      printf '\\C-%s' "$_askllm_ctrl_char"
      ;;
    *)
      printf '%s' "$_askllm_hotkey"
      ;;
  esac
}

_askllm_bash_bind_hotkey() {
  _askllm_hotkey="$1"
  _askllm_func="$2"

  [ -n "$_askllm_hotkey" ] || return 0

  _askllm_bind_seq=$(_askllm_bash_normalize_hotkey "$_askllm_hotkey")
  bind -x "\"$_askllm_bind_seq\":\"$_askllm_func\""
}

_askllm_bash_unbind_existing_hotkeys() {
  _askllm_dump="$(bind -X 2>/dev/null || true)"
  [ -n "$_askllm_dump" ] || return 0

  while IFS= read -r _askllm_line; do
    case "$_askllm_line" in
      *'"_askllm_bash_insert_ask"'*|*'"_askllm_bash_insert_codex"'*|*'"_askllm_bash_insert_claude"'*|*'"_askllm_bash_insert_custom"'*)
        _askllm_seq=$(printf '%s\n' "$_askllm_line" | sed -n 's/^"\([^"]*\)".*/\1/p')
        [ -n "$_askllm_seq" ] && bind -r "$_askllm_seq" >/dev/null 2>&1 || true
        ;;
    esac
  done <<EOF
$_askllm_dump
EOF
}

_askllm_bash_restore_tab_complete_if_needed() {
  _askllm_ask_seq=""
  if [ -n "${ASK_HOTKEY_ASK-}" ]; then
    _askllm_ask_seq=$(_askllm_bash_normalize_hotkey "$ASK_HOTKEY_ASK")
  fi

  if [ "$_askllm_ask_seq" != '\C-i' ]; then
    bind '"\C-i": complete' >/dev/null 2>&1 || true
  fi
}

_askllm_bind_hotkeys_bash() {
  [ -n "${BASH_VERSION-}" ] || return 0
  _askllm_shell_is_interactive || return 0

  _askllm_bash_unbind_existing_hotkeys
  _askllm_bash_restore_tab_complete_if_needed

  _askllm_bash_bind_hotkey "${ASK_HOTKEY_ASK-}" "_askllm_bash_insert_ask"
  _askllm_bash_bind_hotkey "${ASK_HOTKEY_CODEX-}" "_askllm_bash_insert_codex"
  _askllm_bash_bind_hotkey "${ASK_HOTKEY_CLAUDE-}" "_askllm_bash_insert_claude"
  if [ -n "${ASK_HOTKEY_CUSTOM-}" ] && [ -n "${ASK_HOTKEY_CUSTOM_CMD-}" ]; then
    _askllm_bash_bind_hotkey "${ASK_HOTKEY_CUSTOM}" "_askllm_bash_insert_custom"
  fi
}

_askllm_define_cli_alias() {
  _askllm_alias_name="${ASK_ALIAS_NAME:-ask}"
  if ! _askllm_is_valid_alias_name "$_askllm_alias_name"; then
    printf '%s\n' "ask: invalid ASK_ALIAS_NAME '$_askllm_alias_name'; falling back to ask." >&2
    ASK_ALIAS_NAME="ask"
    _askllm_alias_name="ask"
  fi

  if [ "$_askllm_hotkey_cmd_defaulted" -eq 1 ]; then
    ASK_HOTKEY_ASK_CMD="${_askllm_alias_name} "
  fi

  if [ "$_askllm_alias_name" = "ask" ]; then
    return 0
  fi

  if alias "$_askllm_alias_name" >/dev/null 2>&1; then
    unalias "$_askllm_alias_name" 2>/dev/null || true
  fi

  eval "${_askllm_alias_name}() { ask \"\$@\"; }"
}

_askllm_enable_zsh_noglob_alias() {
  [ -n "${ZSH_VERSION-}" ] || return 0
  _askllm_shell_is_interactive || return 0

  # Prevent zsh NOMATCH errors for prompts like: ask --web what day is it?
  alias ask='noglob ask'

  _askllm_alias_name="${ASK_ALIAS_NAME:-ask}"
  if [ "$_askllm_alias_name" != "ask" ] && _askllm_is_valid_alias_name "$_askllm_alias_name"; then
    eval "alias ${_askllm_alias_name}='noglob ${_askllm_alias_name}'"
  fi
}

ask() {
  _askllm_script="${ASKLLM_BIN:-$HOME/.local/bin/askllm}"
  _askllm_first_arg="${1-}"

  if [ "$_askllm_first_arg" = "--help-shell" ] || [ "$_askllm_first_arg" = "--help-integration" ]; then
    cat <<'EOF'
ask shell integration:
  command-only behavior:
    zsh   -> inserts command into next prompt buffer (print -z)
    bash  -> stores command in history (press Up to edit/run)
    other -> prints command to stdout
    -co -no -> askllm executes command directly after confirmation

hotkeys:
  default ask hotkey is Ctrl+I (ASK_HOTKEY_ASK=^I)
  configurable command hotkeys:
    ASK_HOTKEY_ASK / ASK_HOTKEY_ASK_CMD
    ASK_HOTKEY_CODEX / ASK_HOTKEY_CODEX_CMD
    ASK_HOTKEY_CLAUDE / ASK_HOTKEY_CLAUDE_CMD
    ASK_HOTKEY_CUSTOM / ASK_HOTKEY_CUSTOM_CMD
  set a hotkey var to empty to disable it.

special characters:
  zsh integration wraps `ask` with `noglob` so prompts containing ?, *, [, ] do not fail.
  in other shells, quote prompts with wildcard characters.
  example: ask --web "what day is it?"

model + keys:
  ask -ms and ask -sm are aliases (interactive selection, or pass MODEL to persist directly)
  if a provider API key is missing, askllm can prompt to set one and print an export command.

environment:
  ASK_ALIAS_NAME=ask
  ASKLLM_BIN=/path/to/askllm
EOF
    return 0
  fi

  if [ ! -x "$_askllm_script" ]; then
    printf '%s\n' "ask: executable not found at $_askllm_script" >&2
    return 127
  fi

  if _askllm_has_command_only_flag "$@" && _askllm_has_no_output_flag "$@"; then
    "$_askllm_script" "$@"
    return $?
  fi

  if _askllm_has_command_only_flag "$@"; then
    _askllm_generated_cmd="$("$_askllm_script" "$@")" || return $?
    _askllm_generated_cmd="$(_askllm_trim_trailing_whitespace "$_askllm_generated_cmd")"

    if [ -z "$_askllm_generated_cmd" ]; then
      printf '%s\n' "ask: no command was generated." >&2
      return 1
    fi

    if [ -n "${ZSH_VERSION-}" ]; then
      print -z -- "$_askllm_generated_cmd"
      return 0
    fi

    if [ -n "${BASH_VERSION-}" ]; then
      history -s "$_askllm_generated_cmd"
      printf '%s\n' "ask: command saved to history. Press Up to edit/execute." >&2
      return 0
    fi

    printf '%s\n' "$_askllm_generated_cmd"
    return 0
  fi

  "$_askllm_script" "$@"
}

_askllm_define_cli_alias
_askllm_bind_hotkeys_zsh
_askllm_bind_hotkeys_bash
_askllm_enable_zsh_noglob_alias
