---
name: drs-call-center-powerbi
description: Ready-to-use skill for querying the "DRS Call Center" Power BI dataset via the powerbi-mcp-reader MCP server. Contains all IDs, table/column/measure/relationship reference, domain context, and validated DAX query templates. Use this skill whenever the user asks about DRS call center data, połączenia, zgłoszenia, rozmowy, clusters, FCR, SLA, worki, kaucja, or any analysis of the DRS deposit return system call center. Always read this skill before writing any DAX or asking the user for IDs.
---

Connection/query mechanics (how to reach the MCP, run DAX, etc.) live in
`powerbi-mcp-skill` — this file is purely the DRS Call Center domain
knowledge.

## Connection IDs — never look these up again

```
workspace_id : f3c38588-a2fe-46f6-bd1e-7ed1de5a49de   (DRS Online)
dataset_id   : 14b6ddd1-d290-48b2-b185-99fc939fd4a5   (DRS Call Center)
```

---

## Domain Context

This is a **Polish call center** for a **Deposit Return System (DRS / System Kaucyjny)**. Customers are dealers, informatycy (IT staff), and operators who call about:
- `worki` / `plomby` — deposit bags and seals
- `RVM` / `butelkomaty` — reverse vending machines
- Panel `kaucyjni.pl` / `Europlatform` — operator portals
- Subskrypcje, faktury, płatności — subscription and billing
- Integracja z kasami — POS system integrations (Novitus, PCMarket, InSoft)

All tickets belong to campaign **"System Kaucyjny"** — no filtering by campaign is needed.

---

## Business Tables

### `public zgloszenia` — Tickets / Cases (4 591 rows)
Core CRM table. One row = one support ticket.

| Column | Type | Notes |
|--------|------|-------|
| id_zgloszenia | Text | PK |
| kampania | Text | Always "System Kaucyjny" |
| temat | Text | Subject |
| opis | Text | Description |
| status | Text | See values below |
| typ | Text | See values below |
| priorytet | Text | Niski / Średni / Wysoki |
| pole_znaczace | Text | FK → taryfy.bo_location_id |
| sum_czas | Number | Total handling time |
| avg_czas | Number | Average handling time |
| data_utworzenia | Date | Created date |
| data_zmiany | Date | Last modified date |
| czas_istnienia | Number | Ticket lifespan |
| zrodlo | Text | Source channel |
| fcr | True/False | First Call Resolution flag |
| sla | Text | SLA level |
| czas_sla | Text | SLA deadline text |
| zamkniete | Date | Closed date |
| zamkniete_przez | Text | Closed by |
| etl_batch_id | Integer | FK → etl_batches |
| first_seen | Date | First ETL import |
| Kategoria L1L2 | Text | Calculated — L1/L2 category label |
| Poczatek Tygodnia | Date | Calculated — week start |
| Status ZO | Text | Calculated — simplified status |
| Rok Tydzien | Integer | Calculated — YYYYWW |
| Kategoria klienta | Text | Calculated — client category |

**status** values: `Zamknięte`, `Zamknięte Wiadomość`, `Błędne`, `W trakcie weryfikacji`, `W trakcie rozwiązania`, `W trakcie - przekazane do serwisu zewnętrznego`, `W trakcie - oczekiwanie na decyzję/kontakt detalisty`, `Nowy (System)`, `W trakcie - przekazane development`, `Nowe Zgłoszenie`

**typ** values: `Błąd Aplikacji`, `Informacja`, `Aktywacja`, `Błąd Kasa`, `Zmiana Danych Klienta`, `Wypowiedzenie umowy`, `Instalacja`, `Reklamacja`, `Biznes`, `Obsługa Dealer`, `Operator`, `Brak Internetu`, `Naliczenie Wew`, `Nieaktywny Punkt`

**zrodlo** values: `Mail`, `Połączenie przychodzące`, `Ręczne`, `SMS`, `Połączenie wychodzące`

---

### `public polaczenia` — Calls / Connections (10 451 rows)
One row = one call or contact event linked to a ticket.

| Column | Type | Notes |
|--------|------|-------|
| id_polaczenia | Text | PK |
| id_zgloszenia | Text | FK → zgloszenia |
| id_rekordu | Text | External system record ID |
| kiedy | Date | When the call happened |
| typ_polaczenia | Text | See values below |
| rozmowa_z_agent | Number | Flag: call reached agent |
| etl_batch_id | Integer | FK → etl_batches |
| first_seen | Date | First ETL import |
| agent | Text | Agent name |
| status_polaczenia | Text | Always "ANSWERED" |
| czas_rozmowy | Number | **Stored as day fraction** — multiply by 1440 for minutes |
| Dzien Tygodnia | Text | Calculated — Polish day name |

**typ_polaczenia** values: `e-mail przychodzący`, `e-mail wychodzący`, `przychodzące w kampanii`, `wychodzące`

> **Warning:** `czas_rozmowy` is stored as a Power BI day fraction (e.g. 0.00069 ≈ 1 min). Always multiply by 1440 to get minutes in DAX.

---

### `public rozmowy` — Call Recordings with AI Analysis (3 823 rows)
One row = one recorded call with NLP/ML enrichment. Links 1:1 to polaczenia.

| Column | Type | Notes |
|--------|------|-------|
| id_polaczenia | Text | PK + FK → polaczenia (1:1) |
| agent | Text | Agent name |
| data_godzina | Date | Recording timestamp |
| duration_sec | Number | Duration in **actual seconds** |
| summary | Text | AI-generated call summary |
| tags_str | Text | Comma-separated tags string |
| final_cluster | Integer | FK → clusters.cluster_id |
| cluster_label | Text | Cluster name (denormalized) |
| bei | Number | BEI score — higher = more complex call |
| knn_entropy | Number | Topical entropy within cluster |
| silhouette_i | Number | Cluster fit score |
| border_score | Number | How close to cluster boundary |
| is_key_area | True/False | Representative of cluster core |
| is_mixed | True/False | Spans multiple topics |
| is_artifact | True/False | Noise / low-quality call |
| was_reallocated | True/False | Moved to different cluster |
| etl_batch_id | Integer | FK → etl_batches |
| first_seen | Date | First ETL import |

---

### `public clusters` — Cluster Definitions (10 clusters)
One row = one AI-identified call topic cluster.

| cluster_id | short_label |
|------------|-------------|
| 0 | Błędy plomby worka i rozliczenia |
| 1 | Integracja systemów i konfiguracja paneli |
| 3 | Konfiguracja RVM i integracja systemów InSoft |
| 4 | Zarządzanie workami i plombami w panelu |
| 5 | Problemy rozliczeń i integracji systemu kaucyjnego |
| 7 | Problemy z realizacją i weryfikacją kuponów |
| 8 | Konfiguracja panelu i integracji operatora |
| 9 | Integracja i konfiguracja butelkomatów RVM |
| 10 | Problemy z subskrypcją i rozliczeniami w panelu |
| 12 | Klaster 12 (unlabelled) |

Cluster 4 (worki/plomby) is the largest — 1 438 calls.

---

### `public rozmowy_tagi` — Call Tags (12 031 rows)
Many-to-many: each call can have multiple tags.

| Column | Type |
|--------|------|
| id_polaczenia | Text | FK → rozmowy |
| tag | Text | Tag value |

**Top tags by frequency:** `panel_kpl` (1696), `worek` (1631), `inne_sprawy` (1122), `kaucja` (1078), `rvm` (774), `konfiguracja` (745), `informatyk_det` (710), `op_rozliczenie` (548), `integracja_oper` (425), `kupon` (442), `psk` (404)

---

### `public zgloszenie_tagi` — Ticket Tags (300 rows)

| Column | Type |
|--------|------|
| id_zgloszenia | Text | FK → zgloszenia |
| tag | Text | Tag value |

---

### `public rozmowy_podobienstwo` — Conversation Similarity (100 410 rows)
Pairwise similarity matrix between calls. Used for finding related/duplicate conversations.

| Column | Type | Notes |
|--------|------|-------|
| id_a | Text | FK → rozmowy.id_polaczenia |
| id_b | Text | FK → rozmowy b.id_polaczenia |
| sim_composite | Number | Composite similarity score (0–1) |
| sim_rank | Integer | Rank of similarity for id_a |

`public rozmowy b` and `public rozmowy_tagi b` are **mirror tables** (same schema as rozmowy/rozmowy_tagi) used as the "B" side of similarity pairs — do not query them for aggregations.

---

### `public taryfy` — Tariffs (lookup)

| Column | Type |
|--------|------|
| bo_location_id | Text | PK — links to zgloszenia.pole_znaczace |
| taryfa | Text | Tariff name |

---

### `public etl_batches` / `public etl_zmiany` — ETL Audit Tables
Operational tables tracking data pipeline runs and field-level changes. Rarely queried for business analysis.

---

## Measures (all in `public zgloszenia`)

| Measure | Current Value | Description |
|---------|--------------|-------------|
| [Otwarte Zgłoszenia] | 271 | Open ticket count |
| [FCR Rate] | 27.7% | First Call Resolution rate |
| [SLA Compliance] | — | SLA compliance rate |
| [Avg Czas Zamkniecia Dni] | 6.71 days | Average ticket close time |
| [Pokrycie Nagrań] | 36.6% | % of calls with a recording |
| [Średni czas obsługi (min)] | — | Avg handling time in minutes |
| [FCR TAK] | — | Count of FCR = true |
| [FCR NIE] | — | Count of FCR = false |
| [L1] | — | L1 category label |
| [L2] | — | L2 category label |
| [Ostatni CRM ETL] | — | Timestamp of last CRM data load |
| [Ostatni ETL Nagrań] | — | Timestamp of last recordings load |

---

## Key Relationships

```
zgloszenia.id_zgloszenia  1──< polaczenia.id_zgloszenia
polaczenia.id_polaczenia  1──1 rozmowy.id_polaczenia
rozmowy.final_cluster     >──1 clusters.cluster_id
rozmowy.id_polaczenia     1──< rozmowy_tagi.id_polaczenia
zgloszenia.id_zgloszenia  1──< zgloszenie_tagi.id_zgloszenia
zgloszenia.pole_znaczace  >──1 taryfy.bo_location_id
rozmowy_podobienstwo.id_a >──1 rozmowy.id_polaczenia
rozmowy_podobienstwo.id_b >──1 [rozmowy b].id_polaczenia
etl_batches.batch_id      1──< polaczenia.etl_batch_id
etl_batches.batch_id      1──< etl_zmiany.batch_id
```

---

## Validated DAX Query Templates

### KPI Dashboard — all top-level metrics at once
```dax
EVALUATE ROW(
    "FCR Rate",                [FCR Rate],
    "Otwarte Zgłoszenia",      [Otwarte Zgłoszenia],
    "Avg Czas Zamkniecia Dni", [Avg Czas Zamkniecia Dni],
    "Pokrycie Nagrań",         [Pokrycie Nagrań],
    "Sredni czas obsługi min", [Średni czas obsługi (min)]
)
```

### Ticket volume and FCR by type
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'public zgloszenia'[typ],
    "Liczba",    COUNTROWS('public zgloszenia'),
    "FCR Rate",  DIVIDE(
        COUNTROWS(FILTER('public zgloszenia', 'public zgloszenia'[fcr] = TRUE())),
        COUNTROWS('public zgloszenia')
    )
)
ORDER BY [Liczba] DESC
```

### Calls by day of week with avg duration (in minutes)
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'public polaczenia'[Dzien Tygodnia],
    "Liczba polaczen",      COUNTROWS('public polaczenia'),
    "Avg czas min",         AVERAGE('public polaczenia'[czas_rozmowy]) * 1440
)
ORDER BY [Liczba polaczen] DESC
```

### Agent performance — call count and avg duration
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'public polaczenia'[agent],
    "Polaczenia",     COUNTROWS('public polaczenia'),
    "Avg czas min",   AVERAGE('public polaczenia'[czas_rozmowy]) * 1440,
    "Nagrania",       COUNTROWS('public rozmowy')
)
ORDER BY [Polaczenia] DESC
```

### Cluster distribution with BEI complexity score
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'public rozmowy'[cluster_label],
    "Liczba rozmo",  COUNTROWS('public rozmowy'),
    "Avg BEI",       AVERAGE('public rozmowy'[bei])
)
ORDER BY [Liczba rozmo] DESC
```

### Top tags in call recordings
```dax
EVALUATE
TOPN(20,
    SUMMARIZECOLUMNS(
        'public rozmowy_tagi'[tag],
        "Liczba", COUNTROWS('public rozmowy_tagi')
    ),
    [Liczba], DESC
)
```

### Tickets by status (open vs closed breakdown)
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'public zgloszenia'[status],
    "Liczba", COUNTROWS('public zgloszenia')
)
ORDER BY [Liczba] DESC
```

### Ticket volume over time (by week number)
```dax
-- Rok Tydzien format: YYYYWW (e.g. 202623 = week 23 of 2026)
-- Data spans weeks 202605–202624 (Feb–Jun 2026)
-- Do NOT use Poczatek Tygodnia in SUMMARIZECOLUMNS — it produces per-row output (thousands of rows)
EVALUATE
TOPN(52,
    SUMMARIZECOLUMNS(
        'public zgloszenia'[Rok Tydzien],
        "Nowe",      COUNTROWS('public zgloszenia'),
        "Zamkniete", CALCULATE(COUNTROWS('public zgloszenia'), NOT(ISBLANK('public zgloszenia'[zamkniete])))
    ),
    'public zgloszenia'[Rok Tydzien], DESC
)
```

### Find calls most similar to a given call
```dax
-- Replace 'CALL-ID-HERE' with the actual id_polaczenia value
-- FILTER must wrap the source table; do NOT wrap SELECTCOLUMNS
EVALUATE
TOPN(10,
    SELECTCOLUMNS(
        FILTER('public rozmowy_podobienstwo',
            'public rozmowy_podobienstwo'[id_a] = "CALL-ID-HERE"
        ),
        "id_b",          [id_b],
        "sim_composite", [sim_composite],
        "sim_rank",      [sim_rank]
    ),
    [sim_composite], DESC
)
```

### Tickets by source channel with avg close time
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'public zgloszenia'[zrodlo],
    "Liczba",        COUNTROWS('public zgloszenia'),
    "Avg dni zamkn", AVERAGE('public zgloszenia'[czas_istnienia])
)
ORDER BY [Liczba] DESC
```

### Key area calls — representative recordings for a specific cluster
```dax
-- Returns the most complex (high BEI) key-area calls for a given cluster
-- Filter by cluster_label to avoid returning too many rows — key-area set is ~2 000+ records
-- FILTER must wrap the source table; do NOT wrap SELECTCOLUMNS
EVALUATE
TOPN(10,
    SELECTCOLUMNS(
        FILTER('public rozmowy',
            'public rozmowy'[is_key_area] = TRUE()
                && 'public rozmowy'[is_artifact] = FALSE()
                && 'public rozmowy'[cluster_label] = "Zarządzanie workami i plombami w panelu"
        ),
        "id_polaczenia", [id_polaczenia],
        "agent",         [agent],
        "cluster_label", [cluster_label],
        "bei",           [bei],
        "summary",       [summary]
    ),
    [bei], DESC
)
```

---

## Agent prefix codes

Agents follow the pattern `(PREFIX) Imię Nazwisko`. Prefixes observed:
- `(HD)` — Helpdesk agents — bulk of calls, avg 0.5–2.4 min
- `(OP)` — Operator support — short contacts, often email
- `(NS)` — Specialist/escalation — longer calls, avg 5–9 min
- `(BIZ)` — Business team
- Empty string `""` — 2 851 calls with no agent assigned (IVR / unrouted)

`rozmowy.agent` stores login names (e.g. `lukbrz`, `renwil`) not display names — joining to `polaczenia.agent` requires a name mapping that does not exist in this dataset.

---

## DAX Pitfalls

- `czas_rozmowy` (polaczenia) is a **day fraction** — always multiply by 1440 for minutes.
- `duration_sec` (rozmowy) is **actual seconds** — no conversion needed.
- `Poczatek Tygodnia` in SUMMARIZECOLUMNS produces per-row output (thousands of rows) — use `Rok Tydzien` (integer YYYYWW) instead.
- Boolean column filters: always write `FILTER(source_table, ...)` then `SELECTCOLUMNS(...)` on the result — never `FILTER(SELECTCOLUMNS(...), ...)` — the inner boolean columns are not projected and DAX errors.
- `rozmowy b` is a mirror table for similarity analysis — do not aggregate it independently.
- `status_polaczenia` has only one value (`ANSWERED`) — filtering on it adds no value.
- Measure expressions are not exposed via INFO.VIEW.MEASURES() in this dataset — reference the measure list above instead of trying to retrieve expressions dynamically.
