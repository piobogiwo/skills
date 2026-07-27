---
name: power-bi-report-authoring
description: Guidance for reading and authoring Power BI reports via PBIR (Enhanced Report Format) files in a .pbip project. Use when adding, modifying, or inspecting pages and visuals in DRS Call Center.Report.
---

# Power BI Report Authoring (PBIR)

## Project file structure

```
DRS Call Center.Report/
  definition.pbir                        — root: schema version, SemanticModel reference
  definition/
    report.json                          — report-level settings (theme, settings)
    version.json                         — PBIR format version
    pages/
      pages.json                         — ordered list of page GUIDs + active page
      <pageGuid>/
        page.json                        — page settings (name, size, display)
        visuals/
          <visualGuid>/
            visual.json                  — individual visual definition
  StaticResources/SharedResources/
    BaseThemes/CY26SU05.json             — base Power BI theme
    BuiltInThemes/AccessibleCityPark.json
```

## GUIDs in PBIR

Page and visual directories are named with 20-character hex strings (no dashes):
`c31a2155d4113d435e74`, `1651c60482be0eb2228c`

When creating new pages or visuals: generate unique hex strings of the same length.
Do NOT reuse existing GUIDs — duplicates corrupt the report.

## pages.json — page order and active page

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.1.0/schema.json",
  "pageOrder": [
    "c31a2155d4113d435e74",
    "650249d99bb2c9b6537a"
  ],
  "activePageName": "2401c64c2c53f3838831"
}
```

To add a new page: append its GUID to `pageOrder`. To reorder: change the array order.

## page.json — page definition

```json
{
  "$schema": "...",
  "name": "<pageGuid>",
  "displayName": "Human-readable Page Name",
  "displayOption": "FitToPage",
  "height": 720.0,
  "width": 1280.0
}
```

`displayOption` values: `FitToPage` | `FitToWidth` | `ActualSize`

## visual.json — visual definition

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.10.0/schema.json",
  "name": "<visualGuid>",
  "position": {
    "x": 0,
    "y": 0,
    "z": 1000,
    "height": 150,
    "width": 200,
    "tabOrder": 0
  },
  "visual": {
    "visualType": "cardVisual",
    "query": {
      "queryState": {
        "Data": {
          "projections": [ ... ]
        }
      }
    },
    "objects": { ... },
    "drillFilterOtherVisuals": true
  }
}
```

Position values are in points (pt). Canvas is typically 1280×720 pt.
`tabOrder` controls keyboard navigation; use multiples of 100 (0, 100, 200...).
`z` controls stack order (1000 = default layer).

## Query projections — referencing measures and columns

**Measure reference:**
```json
{
  "field": {
    "Measure": {
      "Expression": { "SourceRef": { "Entity": "public zgloszenia" } },
      "Property": "FCR Rate"
    }
  },
  "queryRef": "public zgloszenia.FCR Rate",
  "nativeQueryRef": "FCR Rate",
  "format": "0.00%;-0.00%;0.00%"
}
```

**Column reference:**
```json
{
  "field": {
    "Column": {
      "Expression": { "SourceRef": { "Entity": "public zgloszenia" } },
      "Property": "status"
    }
  },
  "queryRef": "public zgloszenia.status",
  "nativeQueryRef": "status"
}
```

`Entity` = TMDL table name exactly as written (without single quotes from TMDL syntax).

## Common visual types

| visualType | Description |
|-----------|-------------|
| `cardVisual` | Single-value KPI card |
| `barChart` | Horizontal or vertical bar chart |
| `lineChart` | Line/area chart |
| `pieChart` | Pie or donut chart |
| `tableEx` | Table visual |
| `slicer` | Filter slicer |
| `textbox` | Static text / title |
| `shape` | Shape / rectangle |
| `image` | Image visual |

## Existing pages in DRS Call Center (page order)

```
c31a2155d4113d435e74  (page 1 — ~19 visuals, main dashboard)
650249d99bb2c9b6537a  (page 2 — ~7 visuals)
2401c64c2c53f3838831  (page 3 — ~12 visuals, activePageName)
ae04a30f2b455e375a6c  (page 4 — ~10 visuals)
9137f21cb439e5fa0881  (page 5 — ~8 visuals)
e2806e3fe31290580918  (page 6 — ~5 visuals)
```

## Adding a new visual — step by step

1. Choose the target page directory: `definition/pages/<pageGuid>/visuals/`
2. Generate a new 20-char hex GUID (check existing dirs to avoid collision)
3. Create directory: `visuals/<newGuid>/`
4. Create `visual.json` with:
   - Correct `$schema` (use version 2.10.0)
   - `name` = same as the directory GUID
   - `position`: x/y within page bounds (0–1280 for x, 0–720 for y)
   - `visualType` matching your intent
   - `projections` referencing the correct table + measure/column
5. Validate JSON before saving (malformed JSON causes silent report corruption)
6. Reload in Power BI Desktop: Desktop Bridge `file.reload/v1`
7. Capture screenshot: `report.snapshot.capture/v1`

## Visual formatting objects

The `objects` section controls visual styling. Each property follows this pattern:

```json
"objects": {
  "propertyGroupName": [
    {
      "properties": {
        "propertyName": {
          "expr": { "Literal": { "Value": "'stringValue'" } }
        }
      },
      "selector": { "id": "default" }
    }
  ]
}
```

Color with theme reference:
```json
"fontColor": {
  "solid": {
    "color": {
      "expr": { "ThemeDataColor": { "ColorId": 2, "Percent": -0.5 } }
    }
  }
}
```

Color with literal hex:
```json
"lineColor": {
  "solid": {
    "color": {
      "expr": { "Literal": { "Value": "'#2E7D32'" } }
    }
  }
}
```

## Desktop Bridge integration

After any PBIR file edit:
1. `file.reload/v1` — reloads the .pbip from disk into Power BI Desktop
2. `report.snapshot.capture/v1` — captures screenshot for visual verification

Bridge is available via named pipe `\\.\pipe\pbi-desktop-bridge-{PID}`.
Use `.\Test-DesktopBridge.ps1 -Silent` to verify Bridge is active.

## Safety rules

- Validate JSON syntax before saving any visual.json — malformed JSON causes silent corruption
- Never duplicate visual or page GUIDs
- Check `pages.json` before adding new pages — must update `pageOrder` array
- `position` coordinates must be within page bounds (default 1280×720 pt)
- `tabOrder` must be unique per page for accessibility
- Do not modify `definition.pbir` — it points to the SemanticModel; wrong path breaks the report
- Theme files in `StaticResources/` — read-only for agent; modify only in Power BI Desktop
