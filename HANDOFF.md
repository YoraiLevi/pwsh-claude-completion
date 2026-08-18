# HANDOFF

Public repo: https://github.com/YoraiLevi/pwsh-claude-completion
Default branch: `master` (PR-only, no force-push).

## Now

PowerShell native completer for `claude`, driven by `--help`.
MIT. Pester 5 suite generates all `2^n` help shapes from `tests/Helpers.ps1`.
CI: `.github/workflows/ci.yml` on Ubuntu, Windows, macOS.

## Next

1. Confirm CI is green and the README badge is live.
2. Confirm the `PRIMARY` ruleset is active (`gh api repos/YoraiLevi/pwsh-claude-completion/rulesets`).
3. Open any follow-up as a PR from `feat/` / `fix/` / `docs/`.

## How to run

```powershell
pwsh -NoProfile -File ./tests/Invoke-Tests.ps1
```

## Public API

`ConvertFrom-ClaudeHelpText`, `Get-ClaudeHelpSpec`, `Complete-ClaudeNativeArgument`, `Register-ClaudeArgumentCompleter`, `Set-ClaudeHelpProvider`, `Reset-ClaudeHelpCache`.
