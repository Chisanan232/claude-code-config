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

## CodeGraph

[CodeGraph](https://github.com/colbymchenry/codegraph) builds a SQLite knowledge
graph of your codebase's symbols, edges, and files. One `codegraph_explore` call
returns verbatim, line-numbered source of relevant symbols plus call paths between
them — replacing a grep + Read loop with a single round-trip.

### Installation

```bash
# Clone and build
git clone https://github.com/colbymchenry/codegraph.git
cd codegraph
cargo build --release

# Add to PATH (add to ~/.zshrc for persistence)
export PATH="$PATH:$(pwd)/target/release"
```

### Usage

```bash
# Initialize index in a project (creates .codegraph/)
cd /path/to/your/project
codegraph init

# Query symbols and call paths
codegraph explore "function_name"
```

### MCP integration

When CodeGraph is installed and a project has a `.codegraph/` directory,
Claude Code can use the `codegraph_explore` MCP tool for structural code queries.
The MCP server is configured in `mcp-servers.runtime.json`.

## Security

No real credentials are committed. `.claude.json` (holds live tokens / project
history), OAuth credentials (macOS Keychain), and all session/runtime state are
excluded via `.gitignore`. Rotate any token that was ever committed by accident.
