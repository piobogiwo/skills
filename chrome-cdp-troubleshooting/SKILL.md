---
name: chrome-cdp-troubleshooting
description: Troubleshoot Chrome CDP connection issues when multiple Chrome instances conflict on the same debugging port
trigger: Chrome CDP connection fails, wrong Chrome instance connected, multiple Chrome processes, browser tool connects to headless instead of main Chrome
---

# Chrome CDP Connection Troubleshooting

When connecting to Chrome via CDP fails or connects to the wrong instance:

## Problem: Multiple Chrome instances on same port

If both headless Chrome (launched by browser tool) and a manual Chrome have `--remote-debugging-port=9222`, only the first one to start actually binds the port. The second instance silently ignores it.

## Diagnosis

```bash
# Find all Chrome processes with PIDs
ps aux | grep chrome | grep -v grep

# Check which port is actually listening
ss -tlnp | grep 9222

# Check CDP endpoint
curl -s http://localhost:9222/json/version
```

## Fix: Kill conflicting headless Chrome

```bash
# Kill the headless instance (look for --headless --ozone-platform=headless in ps output)
kill <HEADLESS_PID>

# Verify main Chrome now responds
curl -s http://localhost:9222/json/version
```

## Fix: Use different port for browser tool

If you need both instances running simultaneously, start the browser tool's Chrome on a different port:

```yaml
# In config.yaml, change:
browser:
  cdp_url: 'http://localhost:9223'
```

Then launch headless Chrome manually on 9223 or let browser_navigate do it.

## Chrome process exists but port not listening

Chrome can have `--remote-debugging-port=N` in its command line but the port never actually binds. This is common on Wayland/Linux setups. Always verify:

```bash
# Check if port is actually listening (not just process running)
ss -tlnp | grep 9224

# Test CDP endpoint directly
curl -s http://localhost:9224/json/version
```

If the process exists but port is closed, restart Chrome with explicit address binding:

```bash
google-chrome --remote-debugging-port=9224 --remote-debugging-address=127.0.0.1 --no-first-run --no-default-browser-check
```

## Config changes require verification

Changing `browser.cdp_url` in `~/.hermes/config.yaml` does NOT always take effect immediately in the current session. Always verify the new port works with `curl` before calling browser tools:

```bash
curl -s http://localhost:NEW_PORT/json/version
```

## Important: browser_navigate auto-launches headless Chrome

When browser_navigate runs and no CDP is available, it auto-starts headless Chrome on the configured cdp_url port. To prevent this, ensure your desired Chrome instance is already running and responding on that port before calling browser_navigate.

## Verification after changes

```bash
# List tabs in connected Chrome
# Use browser_cdp with method Target.getTargets, params {}
```
