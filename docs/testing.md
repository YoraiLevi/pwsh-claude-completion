# Combinatorial tests

The user-facing contract is: **every boolean axis combination is generated and asserted**. Skipping a combo is a failure.

## What `n` is

`n` is the length of `Get-ClaudeHelpAxes` in `tests/Helpers.ps1`.

It is **not** the number of `claude` CLI flags. That would be ~70 bits (`2^70` cases). The axes are independent *help-shape features* the parser must honor:

| Axis | True help shape | False help shape |
|---|---|---|
| HasCommands | `Commands:` section present | omitted |
| HasOptions | `Options:` section present | omitted |
| HasArguments | `Arguments:` section present | omitted |
| OptionHasAlias | `-s, --scope` | `--scope` only |
| OptionHasRequiredArg | `<scope>` / `<scope...>` | flag takes no value |
| OptionHasChoices | `(choices: "local", "user")` | no choices |
| OptionRepeatable | `(repeatable)` and/or `<scope...>` | not repeatable |
| CommandHasAlias | `plugin\|plugins` | `plugin` only |

`2^8 = 256` help texts. Each text is run through:

- parser invariants (`tests/Combinatorial.Tests.ps1`)
- completer suggestions from that same text (injected via `Set-ClaudeHelpProvider`)

A separate test asserts the generated index set is `{0 .. 2^n-1}` with no gaps.

Inert bits stay in the power set. Example: `CommandHasAlias=true` and `HasCommands=false` still runs; the assertion is "zero commands", not "skip this row".

## Why this is one CI job, not 256 jobs

GitHub Actions caps a matrix at 256 jobs and bills per job. The power set is expanded inside Pester at discovery time. The Actions `test` matrix is only OS (`ubuntu`, `windows`, `macos`) × `pwsh` so required check names stay `test (<os>)`. Windows PowerShell 5.1 is a separate job, `test (windows-powershell-5.1)`, not a `shell` matrix axis.

## What would prove the generator is broken

- `configs.Count -ne 2^n`
- duplicate or missing indexes
- a combo that the test body `continue`s past
- CI that only runs a "representative" subset and still reports success
