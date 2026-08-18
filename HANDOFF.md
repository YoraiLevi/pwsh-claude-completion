# HANDOFF

Public repo: https://github.com/YoraiLevi/pwsh-claude-completion
Default branch: `master` (PR-only, no force-push).

## Now

PowerShell native completer for `claude`, driven by `--help`.
Calls `claude.exe` (not the `claude` -> `Invoke-Claude` alias). Help is UTF-8 + ASCII-folded.
MIT. Pester 5 suite generates all `2^n` help shapes from `tests/Helpers.ps1`.
Install: one profile line (`Import-Module <psd1>; Register-ClaudeArgumentCompleter`). Not on the PowerShell Gallery.
CI: `.github/workflows/ci.yml` — Ubuntu / Windows / macOS `pwsh` jobs named `test (<os>)`, plus `test (windows-powershell-5.1)`. Also `Test-ModuleManifest` + PSScriptAnalyzer.

## Next

1. Tag `v0.1.0` and `gh release create v0.1.0` on the `master` commit that contains `test (windows-powershell-5.1)`. Do not tag a SHA that only ran `pwsh`.
2. After that 5.1 check has run on `master`, add context `test (windows-powershell-5.1)` to PRIMARY (ruleset id `20972954`) and to `.github/primary-ruleset.json`. Live PRIMARY still requires only `test (ubuntu-latest)`, `test (windows-latest)`, `test (macos-latest)`.
3. PowerShell Gallery publish when you want `Install-Module ClaudeCompletion`. Needs a Gallery API key, `Publish-Module`, and a README that can drop the clone path.

## How to run

```powershell
pwsh -NoProfile -File ./tests/Invoke-Tests.ps1
powershell -NoProfile -File ./tests/Invoke-Tests.ps1
```

Windows PowerShell 5.1 only has inbox Pester 3.4. `Invoke-Tests.ps1` enables TLS 1.2, then installs Pester 5 to the current user if needed.

## Public API

`ConvertFrom-ClaudeHelpText`, `ConvertTo-ClaudePlainText`, `Get-ClaudeHelpSpec`, `Get-ClaudeNativeCommand`, `Complete-ClaudeNativeArgument`, `Register-ClaudeArgumentCompleter`, `Set-ClaudeHelpProvider`, `Get-ClaudeHelpProvider`, `Reset-ClaudeHelpCache`.
