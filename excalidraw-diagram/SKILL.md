---
name: excalidraw-diagram
description: >
  Creates diagrams in Excalidraw via the mcp__excalidraw MCP server.
  Use this skill whenever the user wants to visualize anything in Excalidraw,
  draw a diagram, create an architecture diagram, or show structure/flow visually.
  Trigger on: "zwizualizuj X w Excalidraw", "narysuj diagram", "stwórz diagram Excalidraw",
  "pokaż X jako diagram", "visualize X in Excalidraw", "draw a diagram of", "diagram this",
  "create an Excalidraw diagram", "show this as a diagram". Also trigger proactively when
  the user shares a file or architecture description and says "show", "visualize", or "draw".
---

# Excalidraw Diagram Skill

Creates diagrams in Excalidraw using the `mcp__excalidraw` MCP server.
Canvas runs in Docker at **http://localhost:3001**.

## Step 0 — Load MCP tools

The Excalidraw tools are deferred. Load them with ToolSearch before using:

```
ToolSearch: select:mcp__excalidraw__batch_create_elements,mcp__excalidraw__clear_canvas,mcp__excalidraw__get_canvas_screenshot,mcp__excalidraw__describe_scene
```

## Step 1 — Ask style if not specified

Ask the user:
> "Formalny czy nieformalny styl? Formalny = czysty, Helvetica, biznesowy. Nieformalny = odręczny, szybki, jak na tablicy."

If the user's request already mentions style (e.g., "formalny", "formal", "szkicowy", "informal"), skip this and use what they said.

## Step 2 — Analyze content and plan layout

Before touching the canvas:
- Identify the elements: nodes, groups, flows, hierarchies
- Decide layout direction: left-to-right (processes, pipelines), top-to-bottom (hierarchies, trees), or clustered (comparisons, groups)
- Identify sections/color groups
- For >50 nodes, plan which batches to split into (max ~70 elements per call)

Think through coordinates upfront. Use a consistent grid:
- Node width: 180–220px, height: 60–80px
- Section padding: 30–40px around children
- Gap between nodes: 40–60px horizontal, 30–40px vertical
- Canvas origin: start at x=80, y=80

## Step 3 — Clear canvas

Always call `clear_canvas` before drawing a new diagram. Never draw on top of existing content without asking the user first.

## Step 4 — Create elements

**CRITICAL: Always use `batch_create_elements`. Never use `create_from_mermaid`.**

`create_from_mermaid` requires an open browser tab at http://localhost:3001 (conversion runs in browser JS). Without it, the canvas stays empty with no error. `batch_create_elements` works via REST API regardless of browser state.

---

### Informal style

Fast, sketch-like, fewer elements.

```json
{
  "type": "rectangle",
  "x": 100, "y": 100,
  "width": 200, "height": 70,
  "roughness": 1,
  "strokeColor": "#1e1e1e",
  "backgroundColor": "#f0f9ff",
  "fillStyle": "solid",
  "text": "Node label",
  "fontFamily": 1,
  "fontSize": 14
}
```

Key rules:
- `roughness: 1` on all shapes
- Text as `text` field directly on the shape (embedded label)
- `fontFamily: 1` (virgil, handwritten) — matches the sketch aesthetic

---

### Formal style

Clean, professional. Every node = **2 elements**: one rectangle + one separate text element.

#### Why you cannot use embedded labels for formal style

Setting `fontFamily` on a rectangle shape does NOT apply to its built-in `text` label. The label is rendered by a different code path in Excalidraw and always uses virgil (handwritten) regardless of any fontFamily you set on the parent shape. There is no workaround — the only way to get Helvetica or Cascadia in formal diagrams is to create a standalone `type: "text"` element positioned inside the rectangle.

#### The pattern — applied to every single node

**WRONG (text will render as handwritten virgil no matter what):**
```json
{ "type": "rectangle", "text": "API Service", "fontFamily": 2 }
```

**CORRECT (two separate elements):**
```json
[
  {
    "type": "rectangle",
    "id": "api",
    "x": 200, "y": 200,
    "width": 200, "height": 70,
    "roughness": 0, "strokeWidth": 1,
    "strokeColor": "#16a34a",
    "backgroundColor": "#f0fdf4",
    "fillStyle": "solid"
  },
  {
    "type": "text",
    "x": 200, "y": 200,
    "width": 200, "height": 70,
    "text": "API Service",
    "fontSize": 13,
    "fontFamily": 2,
    "textAlign": "center",
    "verticalAlign": "middle"
  }
]
```

The text element's `x`, `y`, `width`, `height` must match the rectangle exactly — this is what centers it visually. For multi-line text, use `\n`. For manual y-centering of fixed-height text: `y = rect.y + (rect.height - lines * fontSize * 1.25) / 2`.

This applies to **every** labeled node: boxes, group headers, section labels. No exceptions in formal style.

#### Typography

- `fontFamily: 2` — Helvetica — labels, titles, descriptions
- `fontFamily: 3` — Cascadia Code (monospace) — ports, paths, commands, version strings
- `fontSize: 15` for section headers, `12–13` for node labels, `11` for code/ports

---

### Arrows

Connect elements by ID — do NOT compute arrow positions manually.

```json
{
  "type": "arrow",
  "x": 0, "y": 0,
  "width": 1, "height": 1,
  "startElementId": "rect-source",
  "endElementId": "rect-target",
  "roughness": 0,
  "strokeColor": "#64748b"
}
```

Position fields (x, y, width, height) are ignored when `startElementId`/`endElementId` are set — Excalidraw auto-routes.

---

### Color palette (formal style)

Use these for section backgrounds and stroke colors:

| Semantic         | backgroundColor | strokeColor |
|-----------------|-----------------|-------------|
| Header / intro  | `#dbeafe`       | `#1d4ed8`   |
| Process / steps | `#f0fdf4`       | `#16a34a`   |
| Warning / cons  | `#fffbeb`       | `#d97706`   |
| Group / cluster | `#ede9fe`       | `#7c3aed`   |
| Ports / instances | `#faf5ff`     | `#9333ea`   |
| Metrics / analysis | `#ccfbf1`   | `#0d9488`   |
| Recommendation  | `#fef9c3`       | `#ca8a04`   |
| Critical / alert | `#fee2e2`      | `#dc2626`   |

Section containers (large rectangles grouping nodes):
- `strokeWidth: 2`, `fillStyle: "solid"`, `roughness: 0`
- Use the same `strokeColor` as children, but a lighter `backgroundColor`

---

### Large diagrams (>50 nodes)

Split into multiple `batch_create_elements` calls by section:
1. Section containers first (large background rectangles)
2. Nodes within each section
3. Arrows last (IDs must exist before referencing)

One call handles ~70 elements reliably.

## Step 5 — Verify

After each `batch_create_elements` call, call `get_canvas_screenshot` and look at the result. Do not claim the diagram is done without visual confirmation. If something looks wrong (empty canvas, misaligned nodes, text outside boxes), fix it before reporting to the user.

## Step 6 — Report

Tell the user:
- The diagram is ready at **http://localhost:3001**
- Brief summary of what was drawn (sections, node count)
- Any notable choices made (why certain colors/groupings were used)

---

## Common mistakes to avoid

1. **Never use `create_from_mermaid`** — canvas stays empty silently if browser tab is closed
2. **Never set `text` on a rectangle in formal style** — fontFamily won't apply, label renders as handwritten virgil
3. **Don't hardcode arrow positions** — always use `startElementId`/`endElementId`
4. **Don't claim success without screenshot** — verify visually every time
5. **Don't put >70 elements in one batch** — split large diagrams into multiple calls

## Troubleshooting

- **Canvas empty after batch_create_elements**: MCP server may not be running. Check: `docker ps | grep excalidraw`
- **Text looks handwritten in formal style**: You used embedded labels (`text` field on rectangle) instead of separate `type: "text"` elements
- **Arrows not routing correctly**: Verify that the referenced element IDs exist in the canvas (were created in a previous batch)
- **MCP tools not found**: Use ToolSearch to load them — they are deferred by default
