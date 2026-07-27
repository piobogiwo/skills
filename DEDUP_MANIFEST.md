# Manifest deduplikacji skilli (2026-07-27)

Zrodlo: c:/piotr/skills-do-uporzadkowania (surowe importy z Laptop, Spark, Arch)
Cel: c:/piotr/skills-canonical (jedna wersja na skill)

## Status: 21 skilli kanonicznych

### Identyczne bit-po-bicie na Laptop + Spark (Claude) - 11 skilli
architect, architecture-audit, documenting, excalidraw-diagram, plantuml-archimate,
review-stage, security-check, single-stage-detailed-plan, stage-execution, staged-plan,
start-session
-> skopiowane 1x do skills-canonical/<nazwa>/, nadmiarowe kopie ze Spark USUNIETE
   z skills-do-uporzadkowania/skills_archiwe_spark/.

### Przenumerowanie 7 z tych skilli na schemat s1-s8 (2026-07-27)
Skille dev-workflow zostaly przemianowane zeby kolejnosc byla widoczna z nazwy folderu.
Komendy slash tez zostaly zmienione (stare nazwy dzialaja nadal jako "legacy alias" -
wpisane w opisie triggera kazdego skilla). Cross-referencje miedzy skillami (strzalki
przeplywu, "Trigger on:", "How this connects to the workflow") zaktualizowane wszedzie.

| Nowa nazwa folderu / komenda      | Stara nazwa / komenda        | Pozycja w przeplywie |
|------------------------------------|-------------------------------|-----------------------|
| s1-architect                       | architect                     | krok 1 |
| s2-planing-stages                  | staged-plan                   | krok 2 |
| s3-stage-detailed-plan             | single-stage-detailed-plan    | krok 3 |
| s4-stage-execution                 | stage-execution                | krok 4 |
| s5-stage-review                    | review-stage                   | krok 5 |
| s6-stage-documenting                | documenting                    | krok 6 |
| s7-architecture-audit              | architecture-audit             | okresowa kontrola (nie liniowy krok) |
| s8-security-check                  | security-check                  | okresowa kontrola (nie liniowy krok) |

`start-session` NIE zostal przenumerowany (to router/entry-point, nie ogniwo sekwencji) -
ale jego tresc zostala zaktualizowana, zeby odwolywac sie do nowych komend s1-s8.

s7 i s8 NIE sa krokami 7/8 tego samego liniowego przebiegu co s1-s6 - obie sa opisane
w swojej tresci jako uruchamiane okresowo/na zadanie ("any time you suspect drift",
"Trigger on explicit user invocation only — never automatically"), nie jako kolejne
ogniwo po s6. Numeracja s7/s8 jest czysto porzadkowa (dodatkowe kontrole w tym samym
zestawie), nie sekwencyjna.

### Nowy dodatek: s9-skill-retro (2026-07-28)
Na prosbe uzytkownika: s6-stage-documenting dostal nowy Step 9 ("Sprint retrospective") -
opcjonalny, lekki zapis pomyslow na ulepszenie samych skilli (nie kodu produktu) do
docs/skills-improvement-ideas.md w projekcie, append-only, tylko gdy obserwacja jest
naprawde istotna (nie kazdy stage bedzie mial wpis).

Nowy skill s9-skill-retro (rowniez tylko na zadanie, nigdy automatycznie) czyta ten
plik, grupuje pomysly per docelowy skill, i PROPONUJE konkretna tresc zmiany do
zatwierdzenia - nigdy nie edytuje SKILL.md samodzielnie, dokladnie jak s7-architecture-audit
("you propose, you do not apply"). Po decyzji uzytkownika oznacza wpis jako
processed (applied/declined), zeby kolejne uruchomienie nie przetwarzalo go ponownie.

### Unikalne (wystepuja tylko na jednej maszynie) - 8 skilli
- power-bi-report-authoring, semantic-model-authoring -> tylko Laptop (Claude)
- drs-call-center -> tylko Spark (Claude)
- chrome-cdp-troubleshooting, control-user-chrome-tabs, google-docs-editing-via-cdp,
  little-coder-config, ml-classification-pipeline -> tylko Arch (Hermes)
-> skopiowane wprost, oryginaly w skills-do-uporzadkowania NIETKNIETE.

### Rozwiazane konflikty (rozna tresc miedzy maszynami) - 2 skille
- **karpathy-piotr-guidelines**: tresc identyczna na Laptop/Spark-Claude/Arch-Claude/Arch-Hermes,
  roznica tylko w polu `name:` frontmatter. Spark-Codex mial starsza, krotsza wersje (brak sekcji
  "Never Mask Errors"). Przyjeto tresc Laptop/Spark-Claude/Arch, nazwe ujednolicono na
  "karpathy-piotr-guidelines". Szczegoly: karpathy-piotr-guidelines/PROVENANCE.md
- **graphify**: Spark-Claude (58KB, nowsza, z klonowaniem GitHub/multi-backend/Wiki/query
  expansion) przyjeta jako kanoniczna. Arch-Hermes (52KB) to starsza wersja - zachowana w
  _conflicts/graphify/ do wgladu. Laptop nie mial w ogole SKILL.md (uszkodzona kopia zrodlowa).
  Szczegoly: graphify/PROVENANCE.md

## Do zrobienia recznie (na docelowych maszynach)
1. Zaktualizowac Spark-Codex-karpathy-guidelines o brakujaca sekcje "Never Mask Errors"
   (albo podmienic cala tresc na kanoniczna).
2. Podmienic graphify na Arch (starsza wersja) na kanoniczna z tego folderu.
3. Sprawdzic na Laptopie dlaczego ~/.claude/skills/graphify nie ma SKILL.md - odtworzyc z
   kanonicznej wersji.
4. Po weryfikacji, ze skills-canonical dziala poprawnie na kazdej maszynie: mozna usunac
   skills-do-uporzadkowania (surowy import) - na razie zachowany jako backup.

## Nierozwiazane / nietkniete
- skills_archiwe_arch ma podwojnie zagniezdzony folder
  (skills_archiwe_arch/skills_archiwe_arch/...) - kosmetyczny artefakt kopiowania na maszynie Arch,
  nie wplywa na dedup, mozna splaszczyc przy okazji porzadkow.
