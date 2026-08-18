## What

-

## How to check

- [ ] `pwsh -NoProfile -File ./tests/Invoke-Tests.ps1` is green locally
- [ ] If you touched parser/completer/CI: `powershell -NoProfile -File ./tests/Invoke-Tests.ps1` is green locally (Windows PowerShell 5.1)
- [ ] Combinatorial count is still exactly `2^n` (do not skip configs)
- [ ] Named regressions in `tests/Parser.Tests.ps1` still cover the silent-failure you touched
