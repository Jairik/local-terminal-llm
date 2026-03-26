# Troubleshooting

## `zsh: no matches found: ...?`

Cause: unquoted wildcard characters (`?`, `*`, `[`) in prompt text.

Fix:

```sh
ask --web "what day is it?"
```

If shell extension is installed for zsh, it may also wrap `ask` with `noglob` for convenience.

## Unknown embedding model in `llm embed-multi`

Example:

`Unknown model: sentence-transformers/all-MiniLM-L6-v2`

Cause: embedding model/plugin alias not registered in your `llm` environment.

Checks:

```sh
llm embed-models
llm plugins
```

Use a model identifier available in your local `llm` installation or install the required embedding plugin/provider.

## Unknown chat model in `ask`

Example:

`Error: 'Unknown model: phi3:mini'`

If run in an interactive terminal, `ask` now prompts:

`Model 'phi3:mini' is not installed. Install it now? [Y/n]`

On `Y`, it attempts local model setup (`llm-ollama` provider + `ollama pull <model>`), then retries.
If setup still fails, verify:

```sh
llm plugins
ollama list
```

## TTS not speaking

Check:

```sh
which piper
which aplay
```

Ensure the model path exists:

```sh
echo "$ASK_TTS_MODEL"
```

Or set it explicitly:

```sh
export ASK_TTS_MODEL="$HOME/.local/share/piper/en_US-lessac-medium.onnx"
```

## `ask` command not found

- Open a new terminal session
- Ensure shell config has extension/source block
- Confirm install path is in `PATH`
- Re-run `./scripts/setup.sh` to reinstall dependencies and shell wiring

## `llm` is not installed or not on `PATH`

```sh
./scripts/setup.sh
```

Or dependency-only mode:

```sh
./scripts/setup.sh --dep-only
```

## Web retrieval unavailable

- Verify selected provider dependencies
- Verify API keys for external providers if used
