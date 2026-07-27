---
name: semantic-model-authoring
description: Guidance for reading and authoring Power BI semantic models via TMDL files in a .pbip project. Use when working with measures, columns, relationships, partitions, or DAX in DRS Call Center.SemanticModel.
---

# Power BI Semantic Model Authoring (TMDL)

## Project file structure

```
DRS Call Center.SemanticModel/
  definition/
    model.tmdl          — root: culture, annotations, ref table list
    tables/             — one .tmdl file per table
    relationships.tmdl  — all relationships
    expressions.tmdl    — shared M expressions (calculated tables, error queries)
    cultures/pl-PL.tmdl — translations and format strings
```

Model root (`model.tmdl`) lists all tables via `ref table 'TableName'`.
Each table file is named exactly as the table (with spaces, lowercase).

## TMDL syntax

### Measure (single-line)
```
measure 'Measure Name' =
        <DAX expression>
    formatString: 0
    lineageTag: <new-guid>
```

### Measure (multi-line DAX — use triple backticks)
```
measure 'Measure Name' = ```

        <multi-line DAX>
        ```
    formatString: 0
    lineageTag: <new-guid>
```

### Column (source — loaded from data source)
```
column columnName
    dataType: string|int64|double|boolean|dateTime
    lineageTag: <guid>
    summarizeBy: none|sum|count|average|max|min
    sourceColumn: columnName

    changedProperty = IsHidden

    annotation SummarizationSetBy = Automatic
```

### Calculated column (DAX)
```
column 'Column Name' =
        <DAX expression>
    lineageTag: <guid>
    summarizeBy: none

    annotation SummarizationSetBy = Automatic
```

### Partition (M query — Import mode)
```
partition 'TableName' = m
    mode: import
    source =
            let
                Source = PostgreSQL.Database("host:port", "dbname"),
                table = Source{[Schema="schema", Item="tablename"]}[Data]
            in
                table

    annotation PBI_NavigationStepName = Nawigacja
    annotation PBI_ResultType = Table
```

### Relationship
```
relationship <guid>
    fromColumn: 'TableName'.columnName
    toColumn: 'OtherTable'.columnName
```

Relationship options:
- `crossFilteringBehavior: bothDirections` — bidirectional cross-filter
- `isActive: false` — inactive (used via USERELATIONSHIP in DAX)
- `joinOnDateBehavior: datePartOnly` — date-only join (auto-generated for LocalDateTable)
- `fromCardinality: one` — one-to-many from source side

## Project conventions (DRS Call Center)

**Table names:** `'public tablename'` — lowercase, PostgreSQL schema prefix, single quotes mandatory when name contains spaces.

**Measure names:** Polish language, descriptive. Examples: `'FCR Rate'`, `'Otwarte Zgłoszenia'`, `'Avg Czas Zamkniecia Dni'`.

**lineageTag:** Every object (table, column, measure, relationship, partition) has a unique GUID. Rules:
- NEVER modify existing lineageTag values
- Generate new GUIDs for new objects (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
- Duplicate lineageTags corrupt the model

**Hidden objects:** `changedProperty = IsHidden` below a measure or column means it was marked hidden in Power BI Desktop. Preserve this annotation when editing.

**Format strings:**
- `0` — integer
- `0.00` — decimal
- `0.00%` or `0.00%;-0.00%;0.00%` — percentage
- `General Date` — date/datetime (no custom format)
- `d mmm yyyy` — custom date format

**Auto-generated tables:** `LocalDateTable_*` and `DateTableTemplate_*` — auto-created by Power BI for date hierarchies. Do NOT modify or delete. They are referenced via `joinOnDateBehavior: datePartOnly` relationships.

## MCP tools — use these instead of file edits when possible

| Goal | MCP tool |
|------|----------|
| Create/update/delete measure | `mcp__powerbi-modeling__measure_operations` |
| Column operations | `mcp__powerbi-modeling__column_operations` |
| Relationship management | `mcp__powerbi-modeling__relationship_operations` |
| Validate or execute DAX | `mcp__powerbi-modeling__dax_query_operations` |
| Table info and operations | `mcp__powerbi-modeling__table_operations` |
| Read model structure | `mcp__powerbi-modeling__model_operations` |
| Read database metadata | `mcp__powerbi-modeling__database_operations` |

## When to use MCP vs edit TMDL directly

**Prefer MCP for:**
- Creating or modifying measures (MCP handles lineageTag, annotations automatically)
- Validating DAX expressions (`dax_query_operations` catches syntax errors before save)
- Reading model structure (faster than parsing TMDL files)

**Edit TMDL directly for:**
- Bulk edits to multiple objects
- Partition M queries (MCP has limited M query support)
- Annotations and custom properties not exposed by MCP
- Format strings for complex patterns
- Checking exact current state of the file

## Workflow after TMDL edits

1. Edit `.tmdl` file
2. Validate DAX if changed: `mcp__powerbi-modeling__dax_query_operations`
3. Reload in Power BI Desktop via Desktop Bridge: `file.reload/v1`
4. Capture screenshot to verify: `report.snapshot.capture/v1`

## Safety rules

- Never modify `lineageTag` values on existing objects — breaks model identity
- Never delete `LocalDateTable_*` or `DateTableTemplate_*` — breaks date hierarchies
- Expressions in `expressions.tmdl` prefixed with `Błędy w zapytaniu` are error-capture queries — do not delete, they are diagnostic artifacts
- After file edit: always reload in Power BI Desktop before claiming success
- `public rozmowy_embeddings` has a pre-existing load error (vector embedding table) — this is expected, not caused by edits

## Quick reference: existing measures in DRS Call Center

Table `'public zgloszenia'`: FCR Rate, SLA Compliance, Otwarte Zgłoszenia, Pokrycie Nagrań, FCR TAK, FCR NIE, Ostatni CRM ETL, Ostatni ETL Nagrań, Avg Czas Zamkniecia Dni, L1, L2, Średni czas obsługi (min)

Data source: PostgreSQL at `10.227.1.132:5432`, database `drs_dashboard`, schema `public`.
