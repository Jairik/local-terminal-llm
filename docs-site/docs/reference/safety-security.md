# Safety and Security

## Key Storage Model

- API keys entered through `ask` setup flows are stored locally using `llm keys set`.
- This key store is offline/local to your machine and is not synced by this project.
- Key read/write operations in `ask` use the local `llm` package workflow (`llm keys set/get`).

## Shell Config Behavior

- `ask --env-setup` writes non-secret environment values into a marked block in your shell config.
- API keys are not written into shell config by default.
- You can explicitly opt in to writing API keys as plain environment variables, but that is less secure.

## Runtime Behavior

- `ask` runs locally and invokes local CLI tools (`llm`, optional `ddgr`, optional `piper/aplay`).
- Retrieval/API requests happen only when you invoke features that require them (for example `--web` with Exa).
- Key material is used only for the provider calls you trigger in the current workflow.
