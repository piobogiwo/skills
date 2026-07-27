---
name: s8-security-check
description: Use when the user invokes /s8-security-check (or legacy alias /security-check), requests a security review, security audit, vulnerability check, or pre-release security sweep. Trigger on explicit user invocation only — never automatically.
---

# Security Check

## Overview

Standalone, ad-hoc security review skill. Produces a dated `security/SECURITY_REVIEW_YYYY-MM-DD.md` file. Does not sit in the 6-step dev workflow and does not gate any other skill. Run before major releases or after batches of stages complete.

## When to Use

- `/s8-security-check`, `/security-check` (legacy alias), "security review", "security audit"
- "check for vulnerabilities", "pre-release security", "run security"

**Do NOT trigger automatically.** Always manually invoked.

## Step 1 — Determine Scope

Ask the user if scope is not stated:

> "What range should I review? (e.g., since last release tag, since last security review, or a specific branch diff)"

Default: all changes since the last git tag or release branch.

```bash
git log --oneline [ref]..HEAD          # show what's in scope
git diff --stat [ref]..HEAD            # surface map
git diff [ref]..HEAD                   # full diff for subagent
```

If the diff exceeds ~2000 lines, tell the user and ask whether to review the full diff or focus on high-risk areas (auth, input handling, new dependencies).

## Step 2 — Gather Context Files

Read these if they exist (all optional):

| File | Purpose |
|------|---------|
| `ARCHITECTURE.md` | Threat surface, public-facing parts, auth/data boundaries |
| `CLAUDE.md` | Project conventions and known decisions |
| `IMPLEMENTATION_PLAN.md` | Which stages were completed in this batch |
| `security/SECURITY_REVIEW_*.md` (most recent) | Carry forward open findings; note resolved ones |

## Step 3 — Spawn a Ringfenced Subagent

Launch a subagent with ONLY:
- The git diff output
- `ARCHITECTURE.md` (if it exists)
- `CLAUDE.md` (if it exists)
- The most recent `SECURITY_REVIEW_*.md` (if it exists)

**Do NOT pass** to the subagent:
- `STAGE_X_CHANGES.md` files
- `STAGE_X_PLAN.md` files
- Any conversation history

### Subagent Review Categories

The subagent checks each category and reports findings or explicitly states "none found":

**INJECTION**
- SQL injection in query construction touching user input
- Command injection in shell/subprocess calls
- Template injection in rendering logic
- Path traversal in file operations with user-controlled paths

**AUTHENTICATION & AUTHORISATION**
- New routes/endpoints — are they properly authenticated?
- New operations on user-owned resources — are ownership checks present?
- Privilege escalation paths

**INPUT VALIDATION**
- User-supplied input used without validation or sanitisation
- External API responses trusted without schema validation
- File uploads without type/size/content checks

**SECRETS & CREDENTIAL EXPOSURE**
- Hardcoded secrets, API keys, passwords in source or config
- Secrets logged, printed, or returned in API responses
- Secrets committed to version control (`.env`, config files)

**SENSITIVE DATA LEAKAGE**
- PII in logs, error messages, or stack traces
- Internal system details (paths, versions, DB structure) in responses
- Verbose error handling that aids enumeration

**NEW DEPENDENCIES**
- List every new package added in the diff with its pinned version
- Flag any that are: pinned to an old version, have known CVEs, or are unfamiliar/low-trust
- **License compliance**: check the licence of each new dependency. Flag any
  that are GPL (may affect distribution), proprietary/commercial (vendor lock
  risk), or incompatible with the project's own licence. Preferred: open,
  permissive licences (MIT, Apache 2.0, BSD).

**OWASP TOP 10** (relevant items for this stack):
- Broken access control, cryptographic failures, security misconfiguration, insecure design, software/data integrity failures

## Step 4 — Human Review Step

Present findings to the user.

- **CRITICAL / HIGH findings:** Ask the user to confirm they've understood each one before proceeding.
- **MEDIUM and below:** Present as a list without requiring per-item confirmation.

## Step 5 — Write the Review File

Create `security/` directory if it doesn't exist. Write `security/SECURITY_REVIEW_YYYY-MM-DD.md`.

```markdown
# Security Review: YYYY-MM-DD
Scope: [git ref range reviewed, e.g., v1.2.0..HEAD]
Stages covered: [list from IMPLEMENTATION_PLAN.md, or "n/a"]
Reviewed by: independent agent
Previous review: [filename or "none"]

## Carried-forward findings (from previous review)
### Resolved
- [finding ID] — resolved in [commit/file]

### Still open
- [finding ID] — [original description, still present]

## New findings

### [CRITICAL] [short title]
- Location: file:line
- Description: [what the issue is]
- Risk: [what an attacker could do]
- Recommendation: [specific fix]

### [HIGH] [short title]
- Location: file:line
- Description:
- Risk:
- Recommendation:

### [MEDIUM] [short title]
...

### [LOW / INFORMATIONAL] [short title]
...

## Areas reviewed
- Injection risks (SQL, command, template, path)
- Authentication and authorisation boundaries
- Input validation and sanitisation
- Secrets and credential exposure
- Sensitive data leakage (logs, errors, API responses)
- New dependencies added (list with versions)
- OWASP Top 10 items relevant to this stack

## Verdict: CLEAR | FINDINGS | CRITICAL
- CLEAR: no new findings, all previous findings resolved
- FINDINGS: one or more medium/low findings, no criticals
- CRITICAL: one or more critical or high findings — do not release

## Next Step
> [If CLEAR]: Safe to proceed with release.
> [If FINDINGS]: Review findings above. Fix or accept with documented rationale before release.
> [If CRITICAL]: Do not release. Fix critical findings and re-run /s8-security-check.
```

## Important Constraints

- **DO NOT fix any code.** Report findings only.
- **DO NOT block or modify any other skill's files.**
- Previous reviews in `security/` are **read-only** — never modify them. Each run produces a new dated file.
- If verdict is **CRITICAL**, state clearly: do not release until fixed.
