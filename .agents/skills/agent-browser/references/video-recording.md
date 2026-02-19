# Video Recording

Capture browser automation sessions as video for debugging, documentation, or verification.

## Basic Recording

```bash
agent-browser record start ./demo.webm
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser click @e1
agent-browser record stop
```

## Commands

```bash
agent-browser record start ./output.webm    # Start
agent-browser record stop                   # Stop and save
agent-browser record restart ./take2.webm   # Stop current + start new
```

## Use Cases

### Debugging Failed Automation

```bash
agent-browser record start ./debug-$(date +%Y%m%d-%H%M%S).webm
agent-browser open https://app.example.com
agent-browser snapshot -i
agent-browser click @e1 || {
    echo "Click failed - check recording"
    agent-browser record stop
    exit 1
}
agent-browser record stop
```

### Documentation Generation

```bash
agent-browser record start ./docs/how-to-login.webm
agent-browser open https://app.example.com/login
agent-browser wait 1000
agent-browser snapshot -i
agent-browser fill @e1 "demo@example.com"
agent-browser wait 500
agent-browser fill @e2 "password"
agent-browser wait 500
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser record stop
```

## Best Practices

1. Add `wait 500` pauses for human viewing clarity
2. Use descriptive filenames with dates
3. Handle cleanup with `trap` on EXIT
4. Combine with screenshots for key frames

## Output Format

- Default: WebM (VP8/VP9)
- Compatible with all modern browsers
