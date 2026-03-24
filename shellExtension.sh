# Bash alias to add to the config file
gask() {
  local script="$HOME/.local/bin/askllm"
  local arg
  local command_only=0

  for arg in "$@"; do
    if [[ "$arg" == "-co" || "$arg" == "--command-only" ]]; then
      command_only=1
      break
    fi
  done

  if ((command_only)); then
    local generated_cmd
    generated_cmd="$("$script" "$@")" || return $?

    # Trim trailing newlines/spaces
    generated_cmd="${generated_cmd%"${generated_cmd##*[![:space:]]}"}"

    if [[ -z "$generated_cmd" ]]; then
      printf '%s\n' "No command was generated." >&2
      return 1
    fi

    print -z -- "$generated_cmd"
    return 0
  fi

  "$script" "$@"
}
it@github.com:Jairik/local-terminal-llm.git
