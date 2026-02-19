# Proxy Support

Configure proxy servers for geo-testing, rate limiting avoidance, and corporate environments.

## Basic Configuration

```bash
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
agent-browser open https://example.com
```

## Authenticated Proxy

```bash
export HTTP_PROXY="http://username:password@proxy.example.com:8080"
```

## SOCKS Proxy

```bash
export ALL_PROXY="socks5://proxy.example.com:1080"
```

## Proxy Bypass

```bash
export NO_PROXY="localhost,127.0.0.1,.internal.company.com"
```

## Geo-Location Testing

```bash
PROXIES=("http://us-proxy.com:8080" "http://eu-proxy.com:8080")
for proxy in "${PROXIES[@]}"; do
    export HTTP_PROXY="$proxy"
    agent-browser --session "$region" open https://example.com
    agent-browser --session "$region" screenshot "./screenshots/$region.png"
    agent-browser --session "$region" close
done
```

## Verifying Proxy

```bash
agent-browser open https://httpbin.org/ip
agent-browser get text body
```

## Best Practices

1. Use environment variables, don't hardcode credentials
2. Set NO_PROXY for local traffic
3. Test proxy before automation
4. Rotate proxies for large scraping jobs
