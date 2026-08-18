# PITFALLS

- **PowerShell `-match` is case-insensitive.** Command parsing must use `-cmatch`. Otherwise `Examples:` becomes a command.
- **PowerShell hashtables and `[ordered]@{}` are case-insensitive.** `-h` and `-H` collide. Option maps must be `Dictionary[string,object]` with `StringComparer.Ordinal`.
- **Do not parse flags out of descriptions.** Real `claude --help` mentions `--print` and `--system-prompt[-file]` inside other options. That produced fake options and stole `<model>` onto `--print`.
- **Pester 5 `-ForEach` runs at discovery.** Configs must be built in `BeforeDiscovery` / directly in `-ForEach (Get-…)`, not in `BeforeAll`.
- **Windows ships Pester 3.4.** CI and `Invoke-Tests.ps1` must `Import-Module Pester -MinimumVersion 5.0`.
- **Windows PowerShell 5.1 defaults to TLS 1.0.** `Install-Module` from PSGallery fails until `[Net.ServicePointManager]::SecurityProtocol` includes TLS 1.2. `Invoke-Tests.ps1` does this before installing Pester 5. `Install-PackageProvider` needs `-Scope CurrentUser` or it demands admin.
- **Required status check names are the GitHub Actions *check* names**, e.g. `test (ubuntu-latest)`, not the workflow file name. The `test` job matrix is OS-only so those names stay stable. Windows PowerShell 5.1 is a separate job named `test (windows-powershell-5.1)` — do not fold it into the OS matrix as a `shell` axis.
- **Empty completer results fall back to filesystem completion.** That looks like success for free-form values such as `--agents <json>`. Do not treat file suggestions as proof the parser chose a path type.
- **`2^n` is help-shape axes, not CLI flags.** `2^(flag count)` is not a test plan.
- **`claude` on this machine is an alias to `Invoke-Claude`.** `& claude --help` never reaches the CLI. Resolve `claude.exe` / `CommandType Application` only.
- **`ΓÇô` in tooltips is an en-dash (`–`, UTF-8 `E2 80 93`) decoded as OEM CP437.** Do not pipe `claude.exe` through the console encoding. Redirect to a file and `Get-Content -Encoding UTF8`, then fold remaining punctuation to ASCII.
