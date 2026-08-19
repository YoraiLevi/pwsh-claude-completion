# HANDOFF

Public repo: https://github.com/YoraiLevi/pwsh-claude-completion
Default branch: `master` (PR-only, no force-push).
Release: https://github.com/YoraiLevi/pwsh-claude-completion/releases/tag/v0.1.0 (`v0.1.0` → `42612c9`).

## Now

PowerShell native completer for `claude`, driven by `--help`.
Calls `claude.exe` (not the `claude` -> `Invoke-Claude` alias). Help is UTF-8 + ASCII-folded.
MIT. Pester 5 suite generates all `2^n` help shapes from `tests/Helpers.ps1`.
Install: one profile line (`Import-Module <psd1>; Register-ClaudeArgumentCompleter`). Not on the PowerShell Gallery.
Empty Tab after a subcommand lists commands only (`mcp ` → `add`/`list`, not `--help`). Type `-` for flags. Leaf commands still offer flags on empty Tab. Commander's `help [command]` is dropped when `-h`/`--help` exist.
CI: `.github/workflows/ci.yml` — Ubuntu / Windows / macOS `pwsh` jobs named `test (<os>)`, plus `test (windows-powershell-5.1)`. Also `Test-ModuleManifest` + PSScriptAnalyzer.
PRIMARY (ruleset id `20972954`) requires all four of those checks.

## Next

1. PowerShell Gallery publish when you want `Install-Module ClaudeCompletion`. Needs a Gallery API key, `Publish-Module`, and a README that can drop the clone path.

## How to run

```powershell
pwsh -NoProfile -File ./tests/Invoke-Tests.ps1
powershell -NoProfile -File ./tests/Invoke-Tests.ps1
```

Windows PowerShell 5.1 only has inbox Pester 3.4. `Invoke-Tests.ps1` enables TLS 1.2, then installs Pester 5 to the current user if needed.

## Public API

`ConvertFrom-ClaudeHelpText`, `ConvertTo-ClaudePlainText`, `Get-ClaudeHelpSpec`, `Get-ClaudeNativeCommand`, `Complete-ClaudeNativeArgument`, `Register-ClaudeArgumentCompleter`, `Set-ClaudeHelpProvider`, `Get-ClaudeHelpProvider`, `Reset-ClaudeHelpCache`.
