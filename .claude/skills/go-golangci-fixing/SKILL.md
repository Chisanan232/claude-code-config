# SKILL.md — go-golangci-fixing

> **Language**: Go. This skill is specific to `golangci-lint`.
> For other languages, see `~/.claude/skills/README.md`.

## Purpose
Fix lint violations reported by `golangci-lint run` so the linter exits clean.
Covers the most common linters in a default golangci-lint configuration.

## Type
Auto-used. Claude Code invokes this skill when `golangci-lint` reports violations.

## Do Not Assume
- Do not assume all violations have auto-fixes — most require manual edits.
- Do not suppress with `//nolint` without a code comment explaining why.
- Do not disable linters in `.golangci.yml` to avoid fixing violations.
- Do not change logic to silence a linter — fix the actual code pattern.

## Steps

### Phase 1 — Understand the violations
1. Run golangci-lint and capture all output:
   ```bash
   golangci-lint run ./... 2>&1 | tee /tmp/golangci-errors.txt
   ```
2. Group violations by linter name (e.g., `errcheck`, `govet`, `staticcheck`,
   `revive`, `gosimple`, `unused`).
3. Count total violations per linter. Fix the highest-volume linter first.

### Phase 2 — Fix by linter category

**`errcheck`** — unhandled error return:
- Wrap the call with error checking: `if err := f(); err != nil { return err }`.
- If the error is intentionally discarded (e.g., `io.Closer.Close` in a defer),
  assign to `_` with a comment: `_ = r.Body.Close() // error not actionable in defer`.

**`govet`** — see `go-vet-debugging` skill for detailed guidance.

**`staticcheck`** — various static analysis checks:
- `SA1019` (deprecated): replace with the recommended alternative.
- `S1000` (use plain channel receive): simplify `select` with a single case.
- `QF1001` (apply De Morgan's law): simplify boolean expression.

**`revive` / `golint`** — Go style violations:
- Exported type/func missing comment: add a doc comment.
- `if-return` pattern: replace `if x { return true }; return false` with `return x`.
- Unused parameter: prefix with `_` if it must be present for interface conformance.

**`gosimple`** — simplification opportunities:
- Usually direct replacements suggested in the output — apply them.

**`unused`** — unexported identifiers with no callers:
- Remove the unused identifier, or export it if it was unintentionally unexported.

4. Apply `//nolint:<linter-name>` only when the false-positive is documented:
   ```go
   //nolint:errcheck // Close errors are not actionable in this defer path
   ```

### Phase 3 — Verify
5. Run `golangci-lint run ./...` — zero violations required before proceeding.
6. Run `go test ./...` to confirm no regressions.

## Safe-Fix Guidance
- Never use `//nolint:all` — suppresses every linter with no audit trail.
- If a linter is consistently producing false positives for your codebase, disable
  it in `.golangci.yml` with a comment explaining why — do not scatter suppression
  comments throughout the code.
- Run `golangci-lint run --fix ./...` first — some linters (e.g., `gofmt`, `goimports`)
  have auto-fix support. Review the diff before committing.
