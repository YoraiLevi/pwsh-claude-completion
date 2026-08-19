# How completion works

`Register-ClaudeArgumentCompleter` hooks PowerShell's native completer for `claude`, `claude.exe`, and `Invoke-Claude`.

On Tab:

1. Tokens before the cursor are walked.
2. Flags and their values are skipped. A required flag value is always consumed. An optional flag value is consumed only if the next token is not a known subcommand at this help level.
3. Remaining words that match `Commands:` in the current help become the command path (`mcp`, `mcp add`, `plugin marketplace`, …).
4. `claude.exe <path> --help` is fetched once per path per session (`Get-ClaudeHelpSpec` cache). The profile `claude` alias/function is ignored. Tests replace the fetch with `Set-ClaudeHelpProvider`.
5. Help is read as UTF-8 and passed through `ConvertTo-ClaudePlainText` so en-dashes and smart quotes become ASCII (`100k-1M`, `"api,hooks"`).
6. `ConvertFrom-ClaudeHelpText` parses Commander-style `Options:`, `Commands:`, and `Arguments:` sections.
7. If the current token starts with `-`, suggestions are flags (minus already-used non-repeatable aliases). Otherwise they are subcommands and positional argument choices. Flags are also offered on an empty token when this help level has no `Commands:` (a leaf such as `mcp add`), so Tab does not fall through to filesystem completion.
8. After a flag that takes a value, suggestions are `(choices: ...)`, `<a|b>`, `--flag=value`, or filesystem paths when the placeholder looks like a path.

Parser rules that exist because real `--help` text is hostile:

- Only the option *signature* (`-s, --scope <scope>`) registers flags. Mentions of `--print` inside another option's description are ignored.
- Command names are matched case-sensitively so `Examples:` is not a command.
- Option dictionaries are ordinal-case-sensitive so `-h` and `-H` both exist.
- Commander lists `help [command]` under Commands while `-h, --help` is already an option. That `help` command is dropped; it is not `claude mcp help`.
