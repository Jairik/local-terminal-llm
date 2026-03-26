# Model Selection

## One-time Model Override

```sh
ask -m llama3.2:3b "summarize this"
```

## Persist Default Model

Both flags are equivalent:

```sh
ask -ms
ask -sm
```

Direct persistence without the picker:

```sh
ask -ms llama3.2:3b
```

Stored in:

- `~/.config/askllm/config.json` (unless `ASK_CONFIG_FILE` is set)

## Power Model Flow (OpenAI)

```sh
ask -pc gpt-5.4
ask -p "analyze this architecture and provide migration phases"
```

- `-pc` sets a dedicated power model
- `-p` uses the configured power model for current invocation

## Missing API Key Handling

If a selected provider key is missing, the CLI can prompt you to paste a key and retry.
