# Text to Speech (TTS)

## Enable TTS

```sh
ask --tts "summarize this"
```

## Modes

### Full mode

Speaks after full model response is complete:

```sh
ask --tts --tts-configure full "explain this"
```

### Stream mode

Speaks while tokens are being generated:

```sh
ask --tts --tts-configure stream "read this while generating"
```

## Runtime Requirements

- `piper` executable on `PATH`
- `aplay` executable on `PATH`
- valid Piper model file

Default model path:

- `~/.local/share/piper/en_US-lessac-medium.onnx`

## Relevant Environment Variables

- `ASK_TTS_MODEL`
- `ASK_TTS_SAMPLE_RATE`
- `ASK_TTS_MODE`
- `ASK_TTS_DELAY_SECONDS` (buffer delay, clamped to ~100-300ms)

## Implementation Notes

Current streaming behavior includes:

- small delay buffer for smoother cadence
- tiny chunk merging to reduce choppiness
- flush on Piper stdin after each chunk
- Ctrl+C interrupt support for immediate stop
- lock-based protection against overlapping audio playback
