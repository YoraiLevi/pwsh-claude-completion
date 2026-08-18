# pwsh-claude-completion

[![CI](https://github.com/YoraiLevi/pwsh-claude-completion/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/YoraiLevi/pwsh-claude-completion/actions/workflows/ci.yml?query=branch%3Amaster)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Native PowerShell tab completion for the `claude` CLI.

Completions are generated from `claude [<subcommand>...] --help` at runtime.
Nothing is hardcoded from a particular Claude Code version.

## Install (about 1 minute)

1. Clone this repo
2. Add the two lines below to your PowerShell profile (`notepad $PROFILE`)
3. Open a new `pwsh`

```powershell
Import-Module 'C:\path\to\pwsh-claude-completion\ClaudeCompletion.psd1'
Register-ClaudeArgumentCompleter
```

Replace the path with wherever you cloned the repo.

Then type `claude ` and press Tab.

First Tab after a new shell shells out to `claude.exe --help` (never the `claude` function/alias) once per command path (~0.4s here), then caches that path for the session.

Help text is read as UTF-8 and folded to ASCII punctuation, so tooltips say `100k-1M` instead of a garbled en-dash.

## What Tab completes

| You type | Tab offers |
|---|---|
| `claude ` | subcommands + flags from root `--help` |
| `claude --output-format ` | `text`, `json`, `stream-json` |
| `claude mcp add --transport ` | `stdio`, `sse`, `http` |
| `claude plugin marketplace ` | nested subcommands |
| `claude import ` | positional choices such as `codex`, `gemini` |
| `claude --add-dir ` | filesystem paths |

After a Claude upgrade, open a new shell so help is re-parsed.

## Tests

```powershell
pwsh -NoProfile -File ./tests/Invoke-Tests.ps1
```

The suite **builds every 2^n help shape** from the boolean axes in `tests/Helpers.ps1` and asserts parser + completer invariants on each one.

Today `n = 8`, so `256` generated help texts, each run through parser tests and completer tests.

CI must see exactly `2^n` configs. Skipping a combo is a failed test, not a silent filter.

Axes (single source: `tests/Helpers.ps1`):

1. `HasCommands`
2. `HasOptions`
3. `HasArguments`
4. `OptionHasAlias`
5. `OptionHasRequiredArg`
6. `OptionHasChoices`
7. `OptionRepeatable`
8. `CommandHasAlias`

Adding a name to that list doubles the generated suite.

CI also runs the same suite on Ubuntu, Windows, and macOS (`pwsh`).

## Require a PR

`master` is protected by a repository ruleset: pull requests only, no force-push, no branch delete, CI `test (ubuntu-latest)`, `test (windows-latest)`, and `test (macos-latest)` must be green. See `CONTRIBUTING.md`.

## License

MIT. See `LICENSE`.
