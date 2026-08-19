# Changelog

## Unreleased

- Do not offer Commander `help` or `-h`/`--help` as siblings of real subcommands. Empty Tab after `mcp ` lists `add`/`list`/…; type `-` for flags. Leaf commands such as `mcp add` still offer flags on empty Tab.

## 0.1.0 — 2026-08-18

- Initial public release.
- Help-driven native completer for `claude` / `claude.exe`.
- Injectable `Set-ClaudeHelpProvider` so CI never needs the real CLI.
- Combinatorial Pester suite: every `2^n` help shape from `tests/Helpers.ps1`.
- Call `claude.exe` (or the `claude` Application) so a profile function/alias named `claude` cannot hide the CLI.
- Read `--help` as UTF-8 and fold en-dashes / smart quotes / OEM mojibake to ASCII in tooltips.
- Engine tests via `TabExpansion2` / `CommandCompletion::CompleteInput`.
- `Test-ModuleManifest` and PSScriptAnalyzer in CI.
- Profile install is one line: `Import-Module ...; Register-ClaudeArgumentCompleter`.
- CI: Ubuntu / Windows / macOS `pwsh`, plus Windows PowerShell 5.1 (`test (windows-powershell-5.1)`).
- Badge pinned with `?branch=master`.
