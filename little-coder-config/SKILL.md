---
name: little-coder-config
description: Configure little-coder to connect to Ollama or llama.cpp. Covers both backends used on this machine.
category: llm-tools
---

# little-coder — konfiguracja backendów

little-coder obsługuje trzy backendy przez OpenAI-compatible API. Każdy wymaga oddzielnej konfiguracji providera.

Installed: `/usr/lib/node_modules/little-coder` (global npm, Arch Linux → aktualizacja: `sudo npm install -g little-coder@latest`)

---

## Pliki konfiguracyjne

| Plik | Rola | Przeżywa npm update? |
|------|------|----------------------|
| `~/.pi/agent/settings.json` | Główne ustawienia agenta (defaultProvider, defaultModel, thinkingLevel) | TAK |
| `~/.pi/agent/models.json` | Provider Ollama | TAK |
| `~/.config/little-coder/models.json` | Provider llama.cpp (user override) | **TAK** |

> Nigdy nie edytuj globalnego `/usr/lib/node_modules/little-coder/...` — zostanie nadpisany przy aktualizacji.

---

## Backend 1: Ollama (port 11434)

Konfiguracja w `~/.pi/agent/models.json`:

```json
{
  "providers": {
    "ollama-local": {
      "baseUrl": "http://127.0.0.1:11434/v1",
      "apiKey": "noop",
      "api": "openai-completions",
      "models": [
        {
          "id": "qwen3.6-27b-128k-q5:latest",
          "name": "Qwen 3.6 27B MTP Q5 (128K)",
          "contextWindow": 131072,
          "maxTokens": 8192
        }
      ]
    }
  }
}
```

Uruchomienie:
```bash
little-coder --model ollama-local/qwen3.6-27b-128k-q5:latest
```

Domyślny provider/model w `~/.pi/agent/settings.json`:
```json
{
  "defaultProvider": "ollama-local",
  "defaultModel": "qwen3.6-27b-128k-q5:latest",
  "defaultThinkingLevel": "minimal"
}
```

---

## Backend 2: llama.cpp (direct, dynamic port)

llama-server nie ma stałego portu — zmienia się przy każdym załadowaniu modelu. Launcher wykrywa port dynamicznie.

Launcher `~/bin/little-coder-unsloth` (zachowana nazwa dla kompatybilności):

```bash
#!/usr/bin/env bash
set -euo pipefail

LLAMA_PORT=$(pgrep -a llama-server 2>/dev/null | grep -oP '(?<=--port )\d+' | head -1)

if [ -z "$LLAMA_PORT" ]; then
    echo "Error: llama-server not running." >&2
    exit 1
fi

export LLAMACPP_BASE_URL="http://127.0.0.1:${LLAMA_PORT}/v1"
export LLAMACPP_API_KEY="noop"

echo "→ llama.cpp on port $LLAMA_PORT"
exec little-coder "$@"
```

Konfiguracja w `~/.config/little-coder/models.json`:

```json
{
  "providers": {
    "llamacpp": {
      "api": "openai-completions",
      "baseUrl": "http://127.0.0.1:8888/v1",
      "apiKey": "noop",
      "models": [
        {
          "id": "qwen3.6-27b",
          "name": "Qwen3.6-27B-MTP (128K)",
          "reasoning": true,
          "input": ["text", "image"],
          "contextWindow": 131072,
          "maxTokens": 4096,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

> `baseUrl` w models.json jest nadpisywany przez env `LLAMACPP_BASE_URL` z launchera — wartość w pliku jest tylko fallbackiem.

Uruchomienie:
```bash
little-coder-unsloth --model llamacpp/qwen3.6-27b
```

---

## Thinking budget

### Poziomy i tokeny

| Level | Tokeny |
|-------|--------|
| `off` | 0 (wyłączone) |
| `minimal` | 1 024 |
| `low` | 2 048 |
| `medium` | 8 192 |
| `high` | 16 384 |
| `xhigh` | bardzo wysokie |

### Zmiana thinking level

**Domyślny (trwały)** — w `~/.pi/agent/settings.json`:
```json
{ "defaultThinkingLevel": "minimal" }
```

**Na jedno uruchomienie** — flaga CLI:
```bash
little-coder --thinking off
little-coder --thinking high "rozwiąż ten problem"
```

**Inline w modelu** — składnia `model:level`:
```bash
little-coder --model ollama-local/qwen3.6-27b-128k-q5:latest:off
little-coder --model ollama-local/qwen3.6-27b-128k-q5:latest:minimal
```

Aktualnie ustawiony domyślny: `minimal` (po tym jak v1.5.0 podniósł budżet 2048→4096 i naprawił recovery bug — skutkiem był drastyczny wzrost czasu odpowiedzi).

> Thinking w Ollama przez API (`"think": false`) nie ma wpływu na little-coder — little-coder steruje thinking przez własną logikę, nie przez parametr Ollamy.

---

## v1.8.0+ auto-probe kontekstu

little-coder pobiera rzeczywiste `-c` z `/props` endpointu serwera i nadpisuje `contextWindow` z models.json. Wyłączenie:
```bash
LITTLE_CODER_NO_CTX_PROBE=1 little-coder ...
```

---

## Weryfikacja połączenia

```bash
# Ollama
curl -s http://127.0.0.1:11434/v1/models | python3 -m json.tool

# llama.cpp (znajdź port)
PORT=$(pgrep -a llama-server | grep -oP '(?<=--port )\d+' | head -1)
curl -s http://127.0.0.1:${PORT}/v1/models | python3 -m json.tool
```
