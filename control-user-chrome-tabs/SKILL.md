---
name: control-user-chrome-tabs
description: Control and read tabs in the user's real Chrome/Chromium browser (not headless) via CDP on port 9224
trigger: User asks to interact with their Chrome tabs, read a page in their browser, navigate a specific tab, extract content from their browser session
---

# Control User's Real Chrome Tabs via CDP

## Dual-browser setup

- **Port 9222** — headless browser (used by browser_navigate, browser_click, etc.)
- **Port 9224** — user's real Chromium with logged-in sessions (accessed via browser_cdp)

## Workflow

### 1. List all tabs in user's Chrome

```
browser_cdp(method="Target.getTargets", params={})
```

Filter results by `type: "page"` to get actual tabs (ignore iframe, service_worker).

### 2. Navigate a specific tab

Pick a target_id from step 1, then:

```
browser_cdp(method="Page.navigate", params={"url": "https://..."}, target_id="<target_id>")
```

Wait a few seconds for the page to load before reading content.

### 3. Read page content

```
browser_cdp(method="Runtime.evaluate", params={"expression": "document.title + '\\n---\\n' + document.body.innerText.substring(0, 10000)", "returnByValue": true}, target_id="<target_id>")
```

### 4. Take a DOM snapshot of a tab

```
browser_cdp(method="DOM.getDocument", params={"depth": 10}, target_id="<target_id>")
```

Or use `Page.getLayoutMetadata` for viewport info, `Page.getNavigationHistory` for history.

## Key CDP methods for tab control

- `Target.getTargets` — list all tabs/targets
- `Page.navigate` — navigate a tab to a URL
- `Runtime.evaluate` — run JS in page context (read DOM, extract data)
- `Page.captureScreenshot` — screenshot a tab
- `Input.dispatchMouseEvent` / `Input.dispatchKeyEvent` — simulate user input
- `Target.createTarget` — open a new tab
- `Target.closeTarget` — close a tab

## Important

- Always pass `target_id` for page-level methods (Page.*, Runtime.*, DOM.*, Input.*)
- Omit `target_id` for browser-level methods (Target.*, Browser.*, Storage.*)
- After `Page.navigate`, wait a moment before reading — pages need time to load
- Use `timeout` parameter (up to 300s) for slow-loading pages like Google Docs
- Google Docs is a heavy SPA — give it 10-30 seconds to fully render before evaluating
