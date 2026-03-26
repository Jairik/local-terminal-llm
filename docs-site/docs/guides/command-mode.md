# Command Mode

## Generate Commands Only

```sh
ask -co "find all jpeg files modified in last 24 hours"
```

`-co` keeps model output constrained to shell command generation.

## Execute with Confirmation

```sh
ask -co -no "rename all .jpeg files to .jpg recursively"
```

Behavior:

1. Generate command
2. Show confirmation prompt
3. Execute only if you confirm

## Safety Recommendations

- Prefer reviewing generated commands before execution.
- Use narrower prompts that mention exact paths/scopes.
- Avoid broad destructive prompts without path constraints.
