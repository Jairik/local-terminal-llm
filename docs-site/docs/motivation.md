# Motivation

## Problem

Terminal users often need fast model assistance without leaving the shell and without losing control over what actually runs on their machine.

Two common pain points:

- Generic chat UX does not map cleanly to shell workflows.
- Command generation can be unsafe unless execution is explicit and inspectable.

## Design Goals

### 1. Local-first by default

`ask` is designed to work with local model backends through `llm` and tools like Ollama.

### 2. Shell-native ergonomics

The tool is installed as a normal CLI command and integrates with shell aliases and hotkeys.

### 3. Explicit safety boundaries

- `-co` generates commands only.
- `-no` executes generated commands only after a confirmation prompt.

### 4. Better answers when needed

The wrapper can inject retrieval context from web or local docs before model invocation.

### 5. Practical speed and feedback

Streaming output, spinner styles, and optional streaming TTS keep interaction responsive.

## Why This Approach

This project favors practical terminal productivity over heavy framework complexity:

- minimal dependencies
- inspectable scripts
- deterministic shell setup
- explicit flags for powerful behavior
