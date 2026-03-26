# Core Usage

## Command Format

```sh
ask [flags] "prompt"
```

You can also pipe context through stdin:

```sh
cat package.json | ask "summarize dependencies"
```

## Main Modes

- Standard response mode (default)
- Command-only mode (`-co`)
- Retrieval-augmented mode (`--web`, `--docs`, `--auto`)

## System Prompt Control

```sh
ask -s "be concise and output bullet points" "explain namespaces in C++"
```

## Spinner Controls

```sh
ask --spinner-style dots "explain rsync"
ask --spinner-style-select bounce
ask --no-spinner "quick answer"
```

## Escaping and Quoting Prompts

Use quotes for prompts with shell wildcards:

```sh
ask --web "what day is it?"
```

Without quoting in shells like zsh, `?` and `*` may be glob-expanded before `ask` receives your prompt.
