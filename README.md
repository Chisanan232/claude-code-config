# claude-code-config

Versioned personal configuration for [Claude Code](https://claude.com/claude-code).
Snapshot of `~/.claude/` — global behavioral policy, hooks, skills, and MCP server
config — with all secrets redacted to `${ENV_VAR}` placeholders.

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

## Configuration Scope Hierarchy

Claude Code reads configuration from two locations with a defined precedence:

| Scope | Location | Applies to |
|---|---|---|
| **Global** | `~/.claude/` | All projects on this machine |
| **Project** | `<repo>/.claude/` | Single repository only |

### Layering behavior

1. Claude Code loads global config (`~/.claude/`) first
2. Then loads project config (`<repo>/.claude/`) if present
3. Project values **override** global values for the same key

### What belongs where

| File | Global scope | Project scope |
|---|---|---|
| `CLAUDE.md` | Durable behavioral policy, workflow conventions | Repo-specific commands, architecture constraints |
| `settings.json` | Default permissions, model preference | Project-specific permissions, hook overrides |
| `hooks/` | Shared workflow hooks | Project-specific automation |
| `skills/` | General-purpose skills | Domain-specific skills |

### Example: permission layering

```jsonc
// ~/.claude/settings.json (global)
{ "permissions": { "allow": ["Bash(git *)"] } }

// <repo>/.claude/settings.json (project)
{ "permissions": { "allow": ["Bash(npm *)"] } }

// Result: both "git *" and "npm *" are allowed in this repo
```

**Tip**: Keep global config minimal and stable. Use project config for
repo-specific overrides and experimental settings.

## Security

No real credentials are committed. `.claude.json` (holds live tokens / project
history), OAuth credentials (macOS Keychain), and all session/runtime state are
excluded via `.gitignore`. Rotate any token that was ever committed by accident.
