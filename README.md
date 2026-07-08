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

## Secrets Management

Use [direnv](https://direnv.net/) to auto-load secrets when entering a project directory.

### Setup

1. Install direnv:
   ```bash
   brew install direnv  # macOS
   ```

2. Add to your shell (e.g., `~/.zshrc`):
   ```bash
   eval "$(direnv hook zsh)"
   ```

3. Create `~/.claude/secrets.env` (never committed):
   ```bash
   # MCP server tokens
   export CIRCLECI_TOKEN="your-token-here"
   export ANTHROPIC_API_KEY="sk-ant-..."

   # Other service credentials
   export GITHUB_TOKEN="ghp_..."
   ```

4. Create `~/.claude/.envrc`:
   ```bash
   source_env secrets.env
   ```

5. Allow direnv:
   ```bash
   cd ~/.claude && direnv allow
   ```

### Security best practices

- **Never commit** `secrets.env` or any file containing credentials
- Add `secrets.env` and `.envrc` to `.gitignore`
- Use `${ENV_VAR}` placeholders in committed config files
- Rotate tokens immediately if accidentally committed
- Use short-lived tokens where possible (OAuth preferred over API keys)

### Per-project secrets

For project-specific secrets, create `<repo>/.envrc`:

```bash
source_up  # Inherit from parent .envrc
export PROJECT_SPECIFIC_KEY="..."
```

## Security

No real credentials are committed. `.claude.json` (holds live tokens / project
history), OAuth credentials (macOS Keychain), and all session/runtime state are
excluded via `.gitignore`. Rotate any token that was ever committed by accident.
