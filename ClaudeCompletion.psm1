# Claude Code native tab completion.
# Parses `claude [<subcommand>...] --help` per command path (session cache).

Set-StrictMode -Version Latest

$script:HelpCache = @{}
$script:HelpProvider = $null

function Reset-ClaudeHelpCache {
    [CmdletBinding()]
    param()
    $script:HelpCache = @{}
}

function Set-ClaudeHelpProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [scriptblock]$Provider
    )
    $script:HelpProvider = $Provider
    Reset-ClaudeHelpCache
}

function ConvertTo-ClaudePlainText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )
    if ([string]::IsNullOrEmpty($Text)) { return $Text }

    # Repair UTF-8 bytes of U+2013/U+2014 decoded as OEM CP437 / Windows-1252.
    # CP437: E2 80 93 -> ΓÇô   CP1252: E2 80 93 -> â€“ (en-dash) / â€” (em-dash)
    $t = $Text
    $t = $t.Replace(([string][char]0x0393 + [char]0x00C7 + [char]0x00F4), '-')   # ΓÇô
    $t = $t.Replace(([string][char]0x0393 + [char]0x00C7 + [char]0x201D), '-')   # ΓÇ”
    $t = $t.Replace(([string][char]0x00E2 + [char]0x20AC + [char]0x2013), '-')   # â€“
    $t = $t.Replace(([string][char]0x00E2 + [char]0x20AC + [char]0x2014), '-')   # â€”
    $t = $t.Replace(([string][char]0x00E2 + [char]0x20AC + [char]0x2122), "'")  # â€™
    $t = $t.Replace(([string][char]0x2013), '-')  # en-dash
    $t = $t.Replace(([string][char]0x2014), '-')  # em-dash
    $t = $t.Replace(([string][char]0x2212), '-')  # minus
    $t = $t.Replace(([string][char]0x00AD), '-')  # soft hyphen
    $t = $t.Replace(([string][char]0x2018), "'")
    $t = $t.Replace(([string][char]0x2019), "'")
    $t = $t.Replace(([string][char]0x201C), '"')
    $t = $t.Replace(([string][char]0x201D), '"')
    $t = $t.Replace(([string][char]0x2026), '...')
    $t = $t.Replace(([string][char]0x00A0), ' ')
    return $t
}

function Get-ClaudeNativeCommand {
    [CmdletBinding()]
    param()
    # Prefer claude.exe so a profile function/alias named `claude` cannot hide the CLI.
    $exe = Get-Command -Name 'claude.exe' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($exe) { return $exe }
    Get-Command -Name 'claude' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Get-ClaudeNativeHelp {
    [CmdletBinding()]
    param([string[]]$Path)

    $cmd = Get-ClaudeNativeCommand
    if (-not $cmd) { return $null }

    $argList = [System.Collections.Generic.List[string]]::new()
    if ($Path) { foreach ($p in @($Path)) { [void]$argList.Add([string]$p) } }
    [void]$argList.Add('--help')

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()
    try {
        $start = @{
            FilePath               = $cmd.Source
            ArgumentList           = @($argList)
            Wait                   = $true
            NoNewWindow            = $true
            PassThru               = $true
            RedirectStandardOutput = $stdoutFile
            RedirectStandardError  = $stderrFile
        }
        $null = Start-Process @start
        $stdout = Get-Content -LiteralPath $stdoutFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($stdout) { return $stdout }
        Get-Content -LiteralPath $stderrFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        $null
    } finally {
        Remove-Item -LiteralPath $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
    }
}

function Get-ClaudeHelpProvider {
    [CmdletBinding()]
    param()
    if ($script:HelpProvider) { return $script:HelpProvider }
    return {
        param([string[]]$Path)
        Get-ClaudeNativeHelp -Path $Path
    }
}

function ConvertFrom-ClaudeHelpText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )

    $commands  = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
    $options   = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
    $arguments = [System.Collections.Generic.List[object]]::new()
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return [pscustomobject]@{ Commands = $commands; Options = $options; Arguments = $arguments }
    }

    $Text = ConvertTo-ClaudePlainText -Text $Text

    $section = $null
    $lines = $Text -split '\r?\n'
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        if ($line -cmatch '^(Options|Commands|Arguments):') {
            $section = $Matches[1]
            $i++
            continue
        }
        if ($line -cmatch '^[A-Za-z][\w /-]{0,40}:\s*$' -and $line -notmatch '^\s') {
            $section = $null
            $i++
            continue
        }

        if ($section -eq 'Options' -and $line -cmatch '^\s{2}(-[\w-].*)$') {
            $blob = $Matches[1].TrimEnd()
            $j = $i + 1
            while ($j -lt $lines.Count) {
                $next = $lines[$j]
                if ($next -cmatch '^\s{2}-[\w-]') { break }
                if ($next -cmatch '^(Options|Commands|Arguments):') { break }
                if ($next -cmatch '^\s{4,}\S') {
                    $blob += ' ' + $next.Trim()
                    $j++
                    continue
                }
                break
            }

            $sigPattern = '^(?<sig>(?:-{1,2}[A-Za-z][\w-]*)(?:\s*,\s*(?:-{1,2}[A-Za-z][\w-]*))*(?:\s+(?:<[^>]+>|\[[^\[\]]+\]))?)'
            if (-not ($blob -cmatch $sigPattern)) {
                $i = $j
                continue
            }
            $sig  = $Matches['sig']
            $desc = $blob.Substring($sig.Length).Trim()

            $argToken = $null
            $requiredArg = $false
            if ($sig -cmatch '<([^<>]+)>') {
                $argToken = $Matches[1]
                $requiredArg = $true
            } elseif ($sig -cmatch '\[([^\[\]]+)\]') {
                $argToken = $Matches[1]
                $requiredArg = $false
            }

            $flags = [System.Collections.Generic.List[string]]::new()
            foreach ($m in [regex]::Matches($sig, '(?<![.\w])(-{1,2}[A-Za-z][\w-]*)')) {
                if (-not $flags.Contains($m.Groups[1].Value)) {
                    [void]$flags.Add($m.Groups[1].Value)
                }
            }
            if ($flags.Count -eq 0) { $i = $j; continue }

            $choices = [System.Collections.Generic.List[string]]::new()
            if ($desc -cmatch '\(choices:\s*([^)]+)\)') {
                foreach ($piece in ($Matches[1] -split ',')) {
                    $v = $piece.Trim()
                    if ($v -cmatch '(?i)^preset:') { continue }
                    $v = $v.Trim('"').Trim("'").Trim()
                    if ($v) { [void]$choices.Add($v) }
                }
            }
            if ($argToken -and $argToken -cmatch '^[A-Za-z]{2,12}(?:\|[A-Za-z]{2,12})+$') {
                foreach ($v in ($argToken -split '\|')) {
                    if (-not $choices.Contains($v)) { [void]$choices.Add($v) }
                }
            }
            foreach ($pm in [regex]::Matches($desc, '\(((?:[A-Za-z][\w-]*)(?:\s*,\s*(?:or\s+)?[A-Za-z][\w-]*)+)\)')) {
                $inner = $pm.Groups[1].Value -replace '\s+or\s+', ', '
                foreach ($v in ($inner -split ',')) {
                    $v = $v.Trim()
                    if ($v -and -not ($v -cmatch '^(or|and|e\.g\.?)$') -and -not $choices.Contains($v)) {
                        [void]$choices.Add($v)
                    }
                }
            }
            foreach ($flag in $flags) {
                $escaped = [regex]::Escape($flag)
                foreach ($m in [regex]::Matches($desc, "$escaped=([A-Za-z][\w-]*)")) {
                    $v = $m.Groups[1].Value
                    if (-not $choices.Contains($v)) { [void]$choices.Add($v) }
                }
            }
            $eg = [regex]::Match($desc, '(?i)\be\.g\.\s*(.+)$')
            if ($eg.Success -and $eg.Groups[1].Value -notmatch '\{') {
                foreach ($m in [regex]::Matches($eg.Groups[1].Value, '[''"]([A-Za-z][\w.-]*)[''"]')) {
                    $v = $m.Groups[1].Value
                    if ($v.Length -ge 2 -and $v -cmatch '^[A-Za-z][\w.-]*$' -and -not $choices.Contains($v)) {
                        [void]$choices.Add($v)
                    }
                }
            }

            $takesPath = [bool]($argToken -cmatch '(?i)path|file|dir|directory|config')
            $repeatable = [bool](($argToken -and $argToken -match '\.\.\.') -or ($desc -cmatch '(?i)repeatable'))
            $aliasArr = @($flags)

            foreach ($flag in $flags) {
                if (-not $options.ContainsKey($flag)) {
                    $options[$flag] = [pscustomobject]@{
                        Name        = $flag
                        Aliases     = $aliasArr
                        Arg         = $argToken
                        RequiredArg = $requiredArg
                        Choices     = @($choices)
                        TakesPath   = $takesPath
                        Repeatable  = $repeatable
                        Description = $desc
                    }
                }
            }

            $i = $j
            continue
        }

        if ($section -eq 'Arguments' -and $line -cmatch '^\s{2}([A-Za-z][\w-]*)\s{2,}(.*)$') {
            $argName = $Matches[1]
            $argDesc = $Matches[2].Trim()
            $j = $i + 1
            while ($j -lt $lines.Count -and $lines[$j] -cmatch '^\s{4,}\S' -and -not ($lines[$j] -cmatch '^\s{2}\S')) {
                $argDesc += ' ' + $lines[$j].Trim()
                $j++
            }
            $argChoices = [System.Collections.Generic.List[string]]::new()
            foreach ($pm in [regex]::Matches($argDesc, '\(((?:[A-Za-z][\w-]*)(?:\s*,\s*(?:or\s+)?[A-Za-z][\w-]*)+)\)')) {
                $inner = $pm.Groups[1].Value -replace '\s+or\s+', ', '
                foreach ($v in ($inner -split ',')) {
                    $v = $v.Trim()
                    if ($v -and -not ($v -cmatch '^(or|and|e\.g\.?)$') -and -not $argChoices.Contains($v)) {
                        [void]$argChoices.Add($v)
                    }
                }
            }
            [void]$arguments.Add([pscustomobject]@{
                Name        = $argName
                Choices     = @($argChoices)
                TakesPath   = [bool]($argName -cmatch '(?i)path|file|dir' -or $argDesc -cmatch '(?i)\b(path|file|directory)\b')
                Description = $argDesc
            })
            $i = $j
            continue
        }

        if ($section -eq 'Commands' -and $line -cmatch '^\s{2}([a-z][\w-]*(?:\|[a-z][\w-]*)*)(?:\s|$)') {
            $aliasBlob = $Matches[1]
            $rest = $line.Substring($Matches[0].Length).Trim()
            $rest = $rest -replace '^\[options\]\s*', ''
            $rest = $rest -replace '^\[[^\]]+\]\s*', ''
            $rest = $rest -replace '^<[^>]+>(?:\s+\S+)*\s*', ''
            foreach ($name in ($aliasBlob -split '\|')) {
                if (-not $commands.ContainsKey($name)) {
                    $commands[$name] = [pscustomobject]@{
                        Name        = $name
                        Description = $rest.Trim()
                    }
                }
            }
        }

        $i++
    }

    return [pscustomobject]@{
        Commands  = $commands
        Options   = $options
        Arguments = $arguments
    }
}

function Get-ClaudeHelpSpec {
    [CmdletBinding()]
    param([string[]]$Path)

    $key = if ($Path -and $Path.Count) { $Path -join ' ' } else { '' }
    if ($script:HelpCache.ContainsKey($key)) {
        return $script:HelpCache[$key]
    }

    $provider = Get-ClaudeHelpProvider
    $raw = & $provider $Path
    $spec = ConvertFrom-ClaudeHelpText -Text $raw
    $script:HelpCache[$key] = $spec
    return $spec
}

function Get-ClaudeTokensBeforeCursor {
    param($CommandAst, [int]$CursorPosition, [string]$WordToComplete)

    $tokens = [System.Collections.Generic.List[string]]::new()
    foreach ($el in $CommandAst.CommandElements) {
        if ($el.Extent.StartOffset -ge $CursorPosition) { break }
        $text = $el.Extent.Text
        if ($el.Extent.EndOffset -gt $CursorPosition) {
            $len = [Math]::Max(0, $CursorPosition - $el.Extent.StartOffset)
            $text = $text.Substring(0, [Math]::Min($len, $text.Length))
        }
        [void]$tokens.Add($text)
    }
    if ($tokens.Count -gt 0) { [void]$tokens.RemoveAt(0) }
    if ($tokens.Count -gt 0) {
        $last = $tokens[$tokens.Count - 1]
        if ($last -eq $WordToComplete -or ($WordToComplete -and $last.StartsWith($WordToComplete))) {
            [void]$tokens.RemoveAt($tokens.Count - 1)
        }
    }
    return , @($tokens)
}

function Resolve-ClaudeCommandPath {
    param([string[]]$Tokens)

    $path = [System.Collections.Generic.List[string]]::new()
    $i = 0
    while ($i -lt $Tokens.Count) {
        $tok = $Tokens[$i]
        if ([string]::IsNullOrWhiteSpace($tok) -or $tok -eq '--') {
            $i++
            continue
        }
        if ($tok.StartsWith('-')) {
            $name = $tok
            $inline = $null
            if ($tok -cmatch '^(--?[^=]+)=(.*)$') {
                $name = $Matches[1]
                $inline = $Matches[2]
            }
            $spec = Get-ClaudeHelpSpec -Path $path.ToArray()
            $opt = $null
            if ($spec.Options.ContainsKey($name)) { $opt = $spec.Options[$name] }
            $i++
            if ($null -eq $inline -and $opt -and $opt.Arg) {
                if ($i -lt $Tokens.Count -and -not $Tokens[$i].StartsWith('-')) {
                    $next = $Tokens[$i]
                    $nextIsCommand = $spec.Commands.ContainsKey($next)
                    if ($opt.RequiredArg -or -not $nextIsCommand) { $i++ }
                }
            }
            continue
        }

        $spec = Get-ClaudeHelpSpec -Path $path.ToArray()
        if ($spec.Commands.ContainsKey($tok)) {
            [void]$path.Add($tok)
        }
        $i++
    }
    return , @($path)
}

function Complete-ClaudeNativeArgument {
    [CmdletBinding()]
    param(
        $wordToComplete,
        $commandAst,
        $cursorPosition,
        [string[]]$Tokens
    )

    try {
        if ($PSBoundParameters.ContainsKey('Tokens')) {
            $typed = @($Tokens)
        } else {
            $typed = Get-ClaudeTokensBeforeCursor -CommandAst $commandAst -CursorPosition $cursorPosition -WordToComplete $wordToComplete
        }
        $cmdPath = Resolve-ClaudeCommandPath -Tokens $typed
        $spec = Get-ClaudeHelpSpec -Path $cmdPath

        $usedFlags = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
        foreach ($t in @($typed)) {
            if ($t -like '-*') {
                $n = if ($t -cmatch '^(--?[^=]+)=') { $Matches[1] } else { $t }
                [void]$usedFlags.Add($n)
                if ($spec.Options.ContainsKey($n)) {
                    foreach ($a in @($spec.Options[$n].Aliases)) { [void]$usedFlags.Add($a) }
                }
            }
        }

        $prefix = [string]$wordToComplete
        $assignFlag = $null
        if ($prefix -cmatch '^(--?[^=]+)=(.*)$') {
            $assignFlag = $Matches[1]
            $prefix = $Matches[2]
        }

        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

        $completeValuesFor = $null
        if ($assignFlag) {
            $completeValuesFor = $assignFlag
        } elseif (@($typed).Count -gt 0) {
            $prev = @($typed)[-1]
            if ($prev -like '-*' -and $prev -notmatch '=' -and $spec.Options.ContainsKey($prev) -and $spec.Options[$prev].Arg) {
                $completeValuesFor = $prev
            }
        }

        if ($completeValuesFor -and $spec.Options.ContainsKey($completeValuesFor)) {
            $opt = $spec.Options[$completeValuesFor]
            foreach ($choice in @($opt.Choices)) {
                if ($choice -like "$prefix*") {
                    $text = if ($assignFlag) { "$assignFlag=$choice" } else { $choice }
                    $tip = if ($opt.Description) { $opt.Description } else { $choice }
                    [void]$results.Add([System.Management.Automation.CompletionResult]::new(
                        $text, $choice,
                        [System.Management.Automation.CompletionResultType]::ParameterValue,
                        $tip
                    ))
                }
            }
            if ($opt.TakesPath) {
                foreach ($hit in [System.Management.Automation.CompletionCompleters]::CompleteFilename($prefix)) {
                    [void]$results.Add($hit)
                }
            }
            if ($results.Count -gt 0 -or $opt.Arg) { return $results }
        }

        if (-not $assignFlag) {
            foreach ($arg in @($spec.Arguments)) {
                foreach ($choice in @($arg.Choices)) {
                    if ($choice -like "$prefix*") {
                        $tip = if ($arg.Description) { $arg.Description } else { $choice }
                        [void]$results.Add([System.Management.Automation.CompletionResult]::new(
                            $choice, $choice,
                            [System.Management.Automation.CompletionResultType]::ParameterValue,
                            $tip
                        ))
                    }
                }
                if ($arg.TakesPath -and $prefix -notlike '-*') {
                    foreach ($hit in [System.Management.Automation.CompletionCompleters]::CompleteFilename($prefix)) {
                        [void]$results.Add($hit)
                    }
                }
            }
            foreach ($name in $spec.Commands.Keys) {
                if ($name -like "$prefix*") {
                    $c = $spec.Commands[$name]
                    $tip = if ($c.Description) { $c.Description } else { $name }
                    [void]$results.Add([System.Management.Automation.CompletionResult]::new(
                        $name, $name,
                        [System.Management.Automation.CompletionResultType]::Command,
                        $tip
                    ))
                }
            }
            foreach ($name in $spec.Options.Keys) {
                $opt = $spec.Options[$name]
                if (-not $opt.Repeatable -and $usedFlags.Contains($name)) { continue }
                if ($name -like "$prefix*") {
                    $tip = if ($opt.Description) { $opt.Description } else { $name }
                    [void]$results.Add([System.Management.Automation.CompletionResult]::new(
                        $name, $name,
                        [System.Management.Automation.CompletionResultType]::ParameterName,
                        $tip
                    ))
                }
            }
        }

        return $results
    } catch {
        return @()
    }
}

function Register-ClaudeArgumentCompleter {
    [CmdletBinding()]
    param()

    $cmd = Get-Command Complete-ClaudeNativeArgument -ErrorAction Stop
    $completer = {
        param($wordToComplete, $commandAst, $cursorPosition)
        & $cmd -wordToComplete $wordToComplete -commandAst $commandAst -cursorPosition $cursorPosition
    }.GetNewClosure()

    Register-ArgumentCompleter -Native -CommandName @('claude', 'claude.exe', 'Invoke-Claude') -ScriptBlock $completer
}

Export-ModuleMember -Function @(
    'ConvertFrom-ClaudeHelpText',
    'ConvertTo-ClaudePlainText',
    'Get-ClaudeHelpSpec',
    'Get-ClaudeNativeCommand',
    'Complete-ClaudeNativeArgument',
    'Register-ClaudeArgumentCompleter',
    'Set-ClaudeHelpProvider',
    'Get-ClaudeHelpProvider',
    'Reset-ClaudeHelpCache'
)
