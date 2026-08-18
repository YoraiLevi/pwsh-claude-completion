# Contributing

## Branch and PR

- Default branch: `master`.
- The `PRIMARY` ruleset requires a PR, blocks force-push and branch deletion, and requires all three CI jobs green:
  - `test (ubuntu-latest)`
  - `test (windows-latest)`
  - `test (macos-latest)`
- `bypass_actors` is empty, so admins cannot merge past a red CI either. If you are blocked, fix the build.
- Branch prefixes: `feat/`, `fix/`, `docs/`, `chore/`, `test/`.
- **Squash merge only.** Merge commits and rebase merges are disabled. Merged branches auto-delete.

## Run tests

```powershell
pwsh -NoProfile -File ./tests/Invoke-Tests.ps1
```

This installs Pester 5 to the current user if needed, then runs `tests/`.

The combinatorial suite is generated at test discovery from `tests/Helpers.ps1`.
If you add a boolean axis, you do not write 2^(n+1) cases by hand — you add one name and the generator doubles.

A test fails if the generated set is not exactly `2^n` unique indexes. Do not filter "invalid" combos out of the generator; inert bits (for example `CommandHasAlias` when `HasCommands` is false) are still run, and the assertions treat them as don't-cares.

## Named regressions (not part of 2^n)

These live in `tests/Parser.Tests.ps1` because they are specific silent-failure modes:

- Flags mentioned only in a description must not become options
- `Examples:` must not become a command
- `-h` and `-H` are distinct
- Optional flag values must not swallow the next subcommand
- A thrown help provider must not surface as a completer exception

## Docs

| Topic | Source |
|---|---|
| How completion works | `docs/completion.md` |
| How 2^n tests work | `docs/testing.md` |
| Now / next | `HANDOFF.md` |
| Known traps | `PITFALLS.md` |
| History | `CHANGELOG.md` |
