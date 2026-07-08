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

## AI-Assisted Onboarding

Copy and paste this prompt into Claude Code to automate setup:

```text
I want to set up claude-code-config. Please:

1. Clone the repo if not present:
   git clone https://github.com/Chisanan232/claude-code-config.git ~/claude-code-config

2. Run the setup check script:
   bash ~/claude-code-config/scripts/check.sh

3. Review the output and help me:
   - Install any missing prerequisites
   - Copy config files to ~/.claude/
   - Set up direnv for secrets management
   - Initialize CodeGraph if I want it

4. Verify the setup is complete by checking:
   - ~/.claude/CLAUDE.md exists
   - ~/.claude/settings.json exists
   - Required CLI tools are in PATH

Guide me through each step, explaining what each config file does.
```

### What the onboarding does

- Checks for required CLI tools (rtk, codegraph, uvx, direnv)
- Validates existing `~/.claude/` configuration
- Guides you through copying config files
- Sets up secrets management with direnv
- Optionally initializes CodeGraph for your projects

## Security

No real credentials are committed. `.claude.json` (holds live tokens / project
history), OAuth credentials (macOS Keychain), and all session/runtime state are
excluded via `.gitignore`. Rotate any token that was ever committed by accident.
