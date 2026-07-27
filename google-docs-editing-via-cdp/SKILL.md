---
name: google-docs-editing-via-cdp
description: Edit Google Docs documents programmatically using Chrome DevTools Protocol when google.docs API is unavailable
trigger: Need to insert, modify, or navigate text in Google Docs via browser automation
---

# Editing Google Docs via Chrome DevTools Protocol

## Problem
Google Docs is a complex SPA. The google.docs JavaScript API is NOT accessible via Runtime.evaluate in the page context - it's sandboxed inside an iframe.

## Solution: Keyboard/Mouse Simulation via CDP

### Step 1: Find the target tab
Use Target.getTargets to list all tabs. Find the page with type="page" and title containing "Google Docs". Note the targetId.

### Step 2: Click in the document to focus
Use Input.dispatchMouseEvent to click at the desired position. Adjust x/y based on where you need the cursor. Use Page.captureScreenshot to verify cursor position.

### Step 3: Create new line (if needed)
Use Input.dispatchKeyEvent with keyCode 13 (Enter) - send both keyDown and keyUp.

### Step 4: Insert text
Use Input.insertText - this is the MOST RELIABLE method for inserting text into Google Docs, much better than dispatchKeyEvent with char types.

### Step 5: Verify
Take a screenshot with Page.captureScreenshot to confirm the text was inserted correctly.

## Pitfalls
- Runtime.evaluate cannot access google.docs API - it's in a sandboxed iframe
- Input.dispatchKeyEvent with "char" type is unreliable for multi-character text
- Input.insertText is the preferred method for typing text
- Always pass target_id to all CDP calls when working with a specific tab
- Google Docs auto-saves, no explicit save step needed

## Useful CDP Methods
- Target.getTargets: list all tabs
- Page.captureScreenshot: verify cursor position and results
- Input.dispatchMouseEvent: click to position cursor
- Input.dispatchKeyEvent: send keyboard shortcuts (Enter, Tab, etc.)
- Input.insertText: insert text at cursor position
