# claude-code-config

Versioned personal configuration for [Claude Code](https://claude.com/claude-code).
Snapshot of `~/.claude/` — global behavioral policy, hooks, skills, and MCP server
config — with all secrets redacted to `${ENV_VAR}` placeholders.

## Prerequisites

This configuration depends on several CLI tools. Install them before use:

| Tool | Install | Used by |
|---|---|---|
| `rtk` | `cargo install rtk-token-killer` | Token-optimized CLI proxy for dev operations |
| `codegraph` | See [CodeGraph](#codegraph) section | Codebase knowledge graph for symbol/call-path queries |
| `codebase-memory-mcp` | `cargo install codebase-memory-mcp` | MCP server for structural code queries |
| `uvx` | `pip install uv` (provides `uvx`) | Run Python tools without global installs |
| `direnv` | `brew install direnv` (macOS) | Auto-load secrets from `.envrc` |

**Graceful degradation**: Most features work without every tool installed.
Missing tools trigger warnings in hooks but do not block execution. Install
tools incrementally as you adopt each capability.

## Layout

```
.claude/
├── CLAUDE.md                  # Global behavioral policy (all projects)
├── RTK.md                     # RTK (token-killer proxy) command reference
├── settings.json              # Permissions, model, hook wiring
├── config.env                 # Hook env overrides (gate toggles)
├── .mcp.json                  # MCP server templates (env placeholders)
├── mcp-servers.runtime.json   # Runtime MCP servers, secrets redacted
├── hooks/                     # Workflow / gate shell hooks
└── skills/                    # Custom skills (SKILL.md each)
```

## Install

Copy into your home config (review first):

```bash
cp -R .claude/CLAUDE.md .claude/RTK.md .claude/settings.json \
      .claude/config.env .claude/hooks .claude/skills ~/.claude/
```

## MCP servers

`mcp-servers.runtime.json` lists the configured servers. Secrets are redacted —
supply real values via environment before use:

| Server | Auth | How |
|---|---|---|
| cloudflare-* (docs, bindings, observability, browser) | OAuth | `/mcp` → Authenticate |
| neon | OAuth | `/mcp` → Authenticate |
| circleci-mcp-server | `CIRCLECI_TOKEN` | Personal API token |
| gcloud | gcloud CLI creds | `gcloud auth login` |
| codegraph, codebase-memory-mcp | none | local index |
| github | local | localhost bridge |

Register a server:

```bash
claude mcp add --scope user --transport http neon https://mcp.neon.tech/mcp
```

## Security

No real credentials are committed. `.claude.json` (holds live tokens / project
history), OAuth credentials (macOS Keychain), and all session/runtime state are
excluded via `.gitignore`. Rotate any token that was ever committed by accident.
