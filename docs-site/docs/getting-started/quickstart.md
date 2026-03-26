# Quickstart

## Basic Prompt

```sh
ask "Explain the difference between rsync -avz and -a"
```

## Command-only Generation

```sh
ask -co "find files larger than 1GB"
```

## Execute Generated Command with Confirmation

```sh
ask -co -no "delete all .tmp files older than 7 days in /var/tmp"
```

## Retrieval Modes

```sh
ask --web "latest bun install instructions"
ask --docs mydocs "how do vite path aliases work"
ask --auto "latest react router api changes"
```

## Model Selection

```sh
# one-time override
ask -m llama3.2:3b "summarize this"

# persist default model
ask -ms
ask -ms llama3.2:3b
```

## TTS

```sh
# speak after full output
ask --tts "summarize this log"

# stream speech while generating
ask --tts --tts-configure stream "read this aloud while generating"
```
