# How completion works

`Register-ClaudeArgumentCompleter` hooks PowerShell's native completer for `claude` and `claude.exe`.

On Tab:

1. Tokens before the cursor are walked.
2. Flags and their values are skipped. A required flag value is always consumed. An optional flag value is consumed only if the next token is not a known subcommand at this help level.
3. Remaining words that match `Commands:` in the current help become the command path (`mcp`, `mcp add`, `plugin marketplace`, …).
4. `claude <path> --help` is fetched once per path per session (`Get-ClaudeHelpSpec` cache). Tests replace the fetch with `Set-ClaudeHelpProvider`.
5. `ConvertFrom-ClaudeHelpText` parses Commander-style `Options:`, `Commands:`, and `Arguments:` sections.
6. Suggestions are subcommands, flags (minus already-used non-repeatable aliases), positional argument choices, and flag values (`(choices: …)`, `<a|b>`, `--flag=value`, or filesystem paths when the placeholder looks like a path).

Parser rules that exist because real `--help` text is hostile:

- Only the option *signature* (`-s, --scope <scope>`) registers flags. Mentions of `--print` inside another option's description are ignored.
- Command names are matched case-sensitively so `Examples:` is not a command.
- Option dictionaries are ordinal-case-sensitive so `-h` and `-H` both exist.
