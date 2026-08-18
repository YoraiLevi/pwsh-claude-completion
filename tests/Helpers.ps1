# Single source of the boolean axes. Adding a name here doubles the generated suite.
# A dedicated test asserts the suite size is exactly 2^n and that no config is skipped.

$script:ClaudeHelpAxes = @(
    'HasCommands'
    'HasOptions'
    'HasArguments'
    'OptionHasAlias'
    'OptionHasRequiredArg'
    'OptionHasChoices'
    'OptionRepeatable'
    'CommandHasAlias'
)

function Get-ClaudeHelpAxes {
    return , $script:ClaudeHelpAxes
}

function Get-ClaudeHelpConfigurations {
    $axes = Get-ClaudeHelpAxes
    $n = $axes.Count
    $total = [int][Math]::Pow(2, $n)
    $configs = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $total; $i++) {
        $bits = [ordered]@{}
        for ($b = 0; $b -lt $n; $b++) {
            $bits[$axes[$b]] = [bool]($i -band (1 -shl $b))
        }
        $bits['Index'] = $i
        # Hashtable (not PSCustomObject): Pester -ForEach binds keys as variables
        # and can expand <Index> in the test name.
        [void]$configs.Add(@{} + $bits)
    }
    return , $configs.ToArray()
}

function New-FakeClaudeHelp {
    param($Config)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('Usage: claude [options] [command] [prompt]')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Fake help for combinatorial parser tests.')
    [void]$sb.AppendLine('')

    if ($Config.HasArguments) {
        [void]$sb.AppendLine('Arguments:')
        [void]$sb.AppendLine('  source      Which agent to import from (codex, gemini)')
        [void]$sb.AppendLine('')
    }

    if ($Config.HasOptions) {
        [void]$sb.AppendLine('Options:')
        $sig = if ($Config.OptionHasAlias) { '-s, --scope' } else { '--scope' }
        if ($Config.OptionHasRequiredArg) {
            if ($Config.OptionRepeatable) { $sig += ' <scope...>' } else { $sig += ' <scope>' }
        }
        $desc = 'Configuration scope'
        if ($Config.OptionHasChoices) { $desc += ' (choices: "local", "user")' }
        if ($Config.OptionRepeatable) { $desc += ' (repeatable)' }
        # Deliberate trap: description mentions other flags. Parser must not steal them.
        $desc += ' (only works with --print and --output-format=stream-json)'
        [void]$sb.AppendLine(("  {0,-32} {1}" -f $sig, $desc))
        [void]$sb.AppendLine('  -h, --help                       Display help for command')
        [void]$sb.AppendLine('  -H, --header <header...>         Set a header (repeatable)')
        [void]$sb.AppendLine('')
    }

    if ($Config.HasCommands) {
        [void]$sb.AppendLine('Commands:')
        $name = if ($Config.CommandHasAlias) { 'plugin|plugins' } else { 'plugin' }
        [void]$sb.AppendLine(("  {0} [options]                   Manage plugins" -f $name))
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('  Examples:')
        [void]$sb.AppendLine('    claude plugin list')
    }

    return $sb.ToString()
}

function Get-CompletionTexts {
    param(
        [string]$WordToComplete = '',
        [string[]]$Tokens = @()
    )
    $hits = @(Complete-ClaudeNativeArgument -wordToComplete $WordToComplete -Tokens $Tokens)
    return @($hits | ForEach-Object { $_.CompletionText })
}
