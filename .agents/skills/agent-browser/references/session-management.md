# Session Management

Run multiple isolated browser sessions concurrently with state persistence.

## Named Sessions

```bash
agent-browser --session auth open https://app.example.com/login
agent-browser --session public open https://example.com
agent-browser --session auth fill @e1 "user@example.com"
agent-browser --session public get text body
```

## Session Isolation Properties

Each session has independent: Cookies, LocalStorage, SessionStorage, IndexedDB, Cache, History, Tabs.

## State Persistence

```bash
agent-browser state save /path/to/auth-state.json
agent-browser state load /path/to/auth-state.json
agent-browser open https://app.example.com/dashboard
```

## Common Patterns

### Authenticated Session Reuse

```bash
STATE_FILE="/tmp/auth-state.json"
if [[ -f "$STATE_FILE" ]]; then
    agent-browser state load "$STATE_FILE"
    agent-browser open https://app.example.com/dashboard
else
    agent-browser open https://app.example.com/login
    agent-browser snapshot -i
    agent-browser fill @e1 "$USERNAME"
    agent-browser fill @e2 "$PASSWORD"
    agent-browser click @e3
    agent-browser wait --load networkidle
    agent-browser state save "$STATE_FILE"
fi
```

### Concurrent Scraping

```bash
agent-browser --session site1 open https://site1.com &
agent-browser --session site2 open https://site2.com &
wait
agent-browser --session site1 get text body > site1.txt
agent-browser --session site2 get text body > site2.txt
agent-browser --session site1 close
agent-browser --session site2 close
```

## Best Practices

1. Name sessions semantically (e.g., `github-auth`, `docs-scrape`)
2. Always close sessions when done
3. Never commit state files (contain auth tokens)
4. Use timeouts for automated scripts
