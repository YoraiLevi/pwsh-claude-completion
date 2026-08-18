# Changelog

## Unreleased

- Call `claude.exe` (or the `claude` Application) so a profile function/alias named `claude` cannot hide the CLI.
- Read `--help` as UTF-8 and fold en-dashes / smart quotes / OEM mojibake to ASCII in tooltips.
- Engine tests via `TabExpansion2` / `CommandCompletion::CompleteInput`.
- `Test-ModuleManifest` and PSScriptAnalyzer in CI.
- Badge pinned with `?branch=master`.

## 0.1.0 — 2026-08-18

- Initial public release.
- Help-driven native completer for `claude` / `claude.exe`.
- Injectable `Set-ClaudeHelpProvider` so CI never needs the real CLI.
- Combinatorial Pester suite: every `2^n` help shape from `tests/Helpers.ps1`.
