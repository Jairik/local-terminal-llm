# Source this from ~/.config/fish/config.fish

if not set -q ASK_ALIAS_NAME
    set -g ASK_ALIAS_NAME "ask"
end

if not set -q ASK_HOTKEY_ASK
    set -g ASK_HOTKEY_ASK "^I"
end
set -g __ASKLLM_HOTKEY_ASK_CMD_DEFAULTED 0
if not set -q ASK_HOTKEY_ASK_CMD
    set -g ASK_HOTKEY_ASK_CMD "$ASK_ALIAS_NAME "
    set -g __ASKLLM_HOTKEY_ASK_CMD_DEFAULTED 1
end
if not set -q ASK_HOTKEY_CODEX
    set -g ASK_HOTKEY_CODEX ""
end
if not set -q ASK_HOTKEY_CODEX_CMD
    set -g ASK_HOTKEY_CODEX_CMD "codex "
end
if not set -q ASK_HOTKEY_CLAUDE
    set -g ASK_HOTKEY_CLAUDE ""
end
if not set -q ASK_HOTKEY_CLAUDE_CMD
    set -g ASK_HOTKEY_CLAUDE_CMD "claude "
end
if not set -q ASK_HOTKEY_CUSTOM
    set -g ASK_HOTKEY_CUSTOM ""
end
if not set -q ASK_HOTKEY_CUSTOM_CMD
    set -g ASK_HOTKEY_CUSTOM_CMD ""
end

function __askllm_key_to_fish --argument key
    if test -z "$key"
        return 1
    end

    if string match -rq '^\^[A-Za-z]$' -- "$key"
        set -l c (string sub -s 2 -l 1 -- "$key" | string lower)
        printf '\\c%s\n' "$c"
        return 0
    end

    printf '%s\n' "$key"
end

function __askllm_hotkey_insert --argument text
    commandline --insert -- "$text"
    commandline --function repaint
end

function __askllm_hotkey_ask
    __askllm_hotkey_insert "$ASK_HOTKEY_ASK_CMD"
end

function __askllm_hotkey_codex
    __askllm_hotkey_insert "$ASK_HOTKEY_CODEX_CMD"
end

function __askllm_hotkey_claude
    __askllm_hotkey_insert "$ASK_HOTKEY_CLAUDE_CMD"
end

function __askllm_hotkey_custom
    __askllm_hotkey_insert "$ASK_HOTKEY_CUSTOM_CMD"
end

function __askllm_bind_hotkey --argument key handler
    if test -z "$key"
        return 0
    end

    set -l normalized (__askllm_key_to_fish "$key")
    if test -z "$normalized"
        return 0
    end

    bind "$normalized" "$handler"
end

function __askllm_valid_alias_name --argument name
    if string match -rq '^[A-Za-z_][A-Za-z0-9_]*$' -- "$name"
        return 0
    end
    return 1
end

if status --is-interactive
    __askllm_bind_hotkey "$ASK_HOTKEY_ASK" __askllm_hotkey_ask
    __askllm_bind_hotkey "$ASK_HOTKEY_CODEX" __askllm_hotkey_codex
    __askllm_bind_hotkey "$ASK_HOTKEY_CLAUDE" __askllm_hotkey_claude
    if test -n "$ASK_HOTKEY_CUSTOM" -a -n "$ASK_HOTKEY_CUSTOM_CMD"
        __askllm_bind_hotkey "$ASK_HOTKEY_CUSTOM" __askllm_hotkey_custom
    end
end

function ask --description 'askllm shell integration'
    set -l script
    if set -q ASKLLM_BIN
        set script "$ASKLLM_BIN"
    else
        set script "$HOME/.local/bin/askllm"
    end

    if test "$argv[1]" = "--help-shell" -o "$argv[1]" = "--help-integration"
        echo "ask shell integration (fish):"
        echo "  command-only behavior: replaces current commandline buffer"
        echo "  -co -no behavior: askllm executes command directly after confirmation"
        echo ""
        echo "hotkeys:"
        echo "  ASK_HOTKEY_ASK / ASK_HOTKEY_ASK_CMD"
        echo "  ASK_HOTKEY_CODEX / ASK_HOTKEY_CODEX_CMD"
        echo "  ASK_HOTKEY_CLAUDE / ASK_HOTKEY_CLAUDE_CMD"
        echo "  ASK_HOTKEY_CUSTOM / ASK_HOTKEY_CUSTOM_CMD"
        echo "  default ask hotkey is ^I"
        echo ""
        echo "special characters:"
        echo "  quote prompts with wildcard characters like ?, *, [, ]"
        echo "  example: ask --web \"what day is it?\""
        echo ""
        echo "model + keys:"
        echo "  ask -ms and ask -sm are aliases (interactive, or pass MODEL)"
        echo "  if an API key is missing, askllm can prompt to set one and print export syntax"
        echo ""
        echo "environment:"
        echo "  ASK_ALIAS_NAME=ask"
        echo "  ASKLLM_BIN=/path/to/askllm"
        return 0
    end

    if not test -x "$script"
        echo "ask: executable not found at $script" >&2
        return 127
    end

    set -l command_only 0
    set -l no_output 0
    for arg in $argv
        if test "$arg" = "-co" -o "$arg" = "--command-only"
            set command_only 1
        end
        if test "$arg" = "-no" -o "$arg" = "--no-output"
            set no_output 1
        end
    end

    if test $command_only -eq 1 -a $no_output -eq 1
        "$script" $argv
        return $status
    end

    if test $command_only -eq 1
        set -l generated_cmd ("$script" $argv)
        or return $status

        set generated_cmd (string trim --right -- "$generated_cmd")
        if test -z "$generated_cmd"
            echo "ask: no command was generated." >&2
            return 1
        end

        commandline --replace -- "$generated_cmd"
        commandline --function repaint
        return 0
    end

    "$script" $argv
end

function __askllm_define_cli_alias
    if test "$ASK_ALIAS_NAME" = "ask"
        return 0
    end

    if not __askllm_valid_alias_name "$ASK_ALIAS_NAME"
        echo "ask: invalid ASK_ALIAS_NAME '$ASK_ALIAS_NAME'; falling back to ask." >&2
        set -g ASK_ALIAS_NAME "ask"
    end

    if test "$__ASKLLM_HOTKEY_ASK_CMD_DEFAULTED" = "1"
        set -g ASK_HOTKEY_ASK_CMD "$ASK_ALIAS_NAME "
    end

    if test "$ASK_ALIAS_NAME" = "ask"
        return 0
    end

    if functions -q "$ASK_ALIAS_NAME"
        functions -e "$ASK_ALIAS_NAME"
    end
    eval "function $ASK_ALIAS_NAME --wraps ask --description 'askllm alias'; ask \$argv; end"
end

__askllm_define_cli_alias
