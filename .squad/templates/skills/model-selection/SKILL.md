# Model Selection

> Determines which LLM model to use for each agent spawn.

## SCOPE

✅ THIS SKILL PRODUCES:
- A resolved `model` parameter for every `task` tool call
- Persistent model preferences in `.squad/config.json`
- Spawn acknowledgments that include the resolved model

❌ THIS SKILL DOES NOT PRODUCE:
- Code, tests, or documentation
- Model performance benchmarks
- Cost reports or billing artifacts

## Context

Squad uses the repository-approved GPT model set for each agent spawn. Users can set persistent preferences that survive across sessions, but every resolved model must remain inside the approved allowlist.

## 5-Layer Model Resolution Hierarchy

Resolution is **first-match-wins** — the highest layer with a value wins.

| Layer | Name | Source | Persistence |
|-------|------|--------|-------------|
| **0a** | Model Policy | `.squad/config.json` → `allowedModels`, `disallowedModelProviders` | Persistent (survives sessions) |
| **0b** | Per-Agent Config | `.squad/config.json` → `agentModelOverrides.{name}` | Persistent (survives sessions) |
| **0c** | Global Config | `.squad/config.json` → `defaultModel` | Persistent (survives sessions) |
| **1** | Session Directive | User said "use X" in current session | Session-only |
| **2** | Charter Preference | Agent's `charter.md` → `## Model` section | Persistent (in charter) |
| **3** | Task-Aware Auto | Code → `gpt-5.3-codex`, analysis → `gpt-5.5`, fast → `gpt-5-mini` | Computed per-spawn |
| **4** | Default | `gpt-5-mini` | Hardcoded fallback |

**Key principle:** Layer 0 policy beats everything. If `allowedModels` is present, every model must be in that list. If `disallowedModelProviders` includes `anthropic`, no Claude/Anthropic model may be selected, retried, or used as an implicit default.

## AGENT WORKFLOW

### On Session Start

1. READ `.squad/config.json`
2. CHECK for `allowedModels` and `disallowedModelProviders` — these constrain every spawn
3. CHECK for `defaultModel` field — if present and allowed, this is the Layer 0 override for all spawns
4. CHECK for `agentModelOverrides` field — if present, these are per-agent Layer 0 overrides
5. STORE these values in session context for the duration

### On Every Agent Spawn

1. CHECK Layer 0a policy: Is the candidate model in `allowedModels` and outside `disallowedModelProviders`? → Only approved models can be used.
2. CHECK Layer 0b: Is there an `agentModelOverrides.{agentName}` in config.json? → Use it if allowed.
3. CHECK Layer 0c: Is there a `defaultModel` in config.json? → Use it if allowed.
4. CHECK Layer 1: Did the user give a session directive? → Use it if allowed.
5. CHECK Layer 2: Does the agent's charter have a `## Model` section? → Use it if allowed.
6. CHECK Layer 3: Determine task type:
   - Code (implementation, tests, refactoring, bug fixes) → `gpt-5.3-codex`
   - Prompts, agent designs, architecture, security, reviews, complex analysis → `gpt-5.5`
   - Non-code (docs, planning, triage, changelogs, logs) → `gpt-5-mini`
7. FALLBACK Layer 4: `gpt-5-mini`
8. INCLUDE model in spawn acknowledgment: `🔧 {Name} ({resolved_model}) — {task}`
9. ALWAYS pass the resolved model as the `model` parameter. Never omit it while Anthropic providers are disallowed.

### When User Sets a Preference

**Trigger phrases:** "always use X", "use X for everything", "switch to X", "default to X"

1. VALIDATE the model ID against `.squad/config.json.allowedModels`
2. WRITE `defaultModel` to `.squad/config.json` (merge, don't overwrite)
3. ACKNOWLEDGE: `✅ Model preference saved: {model} — all future sessions will use this until changed.`

**Per-agent trigger:** "use X for {agent}"

1. VALIDATE model ID against `.squad/config.json.allowedModels`
2. WRITE to `agentModelOverrides.{agent}` in `.squad/config.json`
3. ACKNOWLEDGE: `✅ {Agent} will always use {model} — saved to config.`

### When User Clears a Preference

**Trigger phrases:** "switch back to automatic", "clear model preference", "use default models"

1. REMOVE `defaultModel` from `.squad/config.json`
2. ACKNOWLEDGE: `✅ Model preference cleared — returning to automatic selection.`

### STOP

After resolving the model and including it in the spawn template, this skill is done. Do NOT:
- Generate model comparison reports
- Run benchmarks or speed tests
- Create new config files (only modify existing `.squad/config.json`)
- Change the model after spawn (fallback chains handle runtime failures)

## Config Schema

`.squad/config.json` model-related fields:

```json
{
  "version": 1,
  "defaultModel": "gpt-5.5",
  "allowedModels": [
    "gpt-5.5",
    "gpt-5.3-codex",
    "gpt-5-mini"
  ],
  "disallowedModelProviders": [
    "anthropic"
  ],
  "taskModelDefaults": {
    "analysis": "gpt-5.5",
    "code": "gpt-5.3-codex",
    "fast": "gpt-5-mini"
  },
  "agentModelOverrides": {
    "fenster": "gpt-5.3-codex",
    "mcmanus": "gpt-5-mini"
  }
}
```

- `defaultModel` — applies to ALL agents unless overridden by `agentModelOverrides`
- `agentModelOverrides` — per-agent overrides that take priority over `defaultModel`
- `allowedModels` — hard allowlist for every agent spawn
- `disallowedModelProviders` — provider-level denylist; `anthropic` blocks all Claude models
- `taskModelDefaults` — recommended task-aware defaults when automatic selection is active
- Both fields are optional. When absent, Layers 1-4 apply normally.

## Fallback Chains

If a model is unavailable (rate limit, plan restriction), retry within the approved GPT set:

```
Analysis: gpt-5.5 → gpt-5.3-codex → gpt-5-mini
Code:     gpt-5.3-codex → gpt-5.5 → gpt-5-mini
Fast:     gpt-5-mini → gpt-5.5 → gpt-5.3-codex
```

Never fall outside `gpt-5.5`, `gpt-5.3-codex`, or `gpt-5-mini`. Never omit the `model` parameter as a fallback because the platform default may be Anthropic.
