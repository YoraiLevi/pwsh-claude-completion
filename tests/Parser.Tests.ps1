#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $moduleRoot 'ClaudeCompletion.psd1') -Force
}

Describe 'ConvertFrom-ClaudeHelpText bad paths' {
    It 'returns empty spec for null or blank help (does not throw)' {
        $nullSpec = ConvertFrom-ClaudeHelpText -Text $null
        $emptySpec = ConvertFrom-ClaudeHelpText -Text ''
        $wsSpec = ConvertFrom-ClaudeHelpText -Text "   `n"
        $nullSpec.Commands.Count | Should -Be 0
        $nullSpec.Options.Count | Should -Be 0
        $emptySpec.Options.Count | Should -Be 0
        $wsSpec.Arguments.Count | Should -Be 0
    }

    It 'does not treat Examples: as a command' {
        $help = @"
Commands:
  add [options] <name>  Add a server

  Examples:
    claude mcp add x
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Commands.ContainsKey('add') | Should -BeTrue
        $spec.Commands.ContainsKey('Examples') | Should -BeFalse
    }

    It 'does not treat Commander help [command] as a subcommand when -h/--help exists' {
        $help = @"
Options:
  -h, --help                            Display help for command
Commands:
  add [options] <name> <commandOrUrl> [args...]  Add an MCP server
  help [command]                        display help for command
  list                                  List configured MCP servers
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Commands.ContainsKey('add') | Should -BeTrue
        $spec.Commands.ContainsKey('list') | Should -BeTrue
        $spec.Commands.ContainsKey('help') | Should -BeFalse
        $spec.Options.ContainsKey('-h') | Should -BeTrue
        $spec.Options.ContainsKey('--help') | Should -BeTrue
    }

    It 'keeps a real help subcommand when -h/--help are absent' {
        $help = @"
Commands:
  help     Show the user manual
  list     List items
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Commands.ContainsKey('help') | Should -BeTrue
        $spec.Commands.ContainsKey('list') | Should -BeTrue
    }

    It 'does not steal flags mentioned only in a description' {
        $help = @"
Options:
  --fallback-model <model>   Fallback model (only works with --print)
  --bare                     Mentions --settings, --mcp-config, --system-prompt[-file]
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Options.ContainsKey('--fallback-model') | Should -BeTrue
        $spec.Options.ContainsKey('--bare') | Should -BeTrue
        $spec.Options.ContainsKey('--print') | Should -BeFalse
        $spec.Options.ContainsKey('--settings') | Should -BeFalse
        $spec.Options.ContainsKey('--mcp-config') | Should -BeFalse
        $spec.Options.ContainsKey('-file') | Should -BeFalse
        $spec.Options['--bare'].Arg | Should -BeNullOrEmpty
    }

    It 'keeps -h and -H as distinct flags (case-sensitive)' {
        $help = @"
Options:
  -H, --header <header...>   Set a header
  -h, --help                 Display help
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Options.ContainsKey('-h') | Should -BeTrue
        $spec.Options.ContainsKey('-H') | Should -BeTrue
        $spec.Options['-h'].Aliases | Should -Contain '--help'
        $spec.Options['-H'].Aliases | Should -Contain '--header'
    }

    It 'reads (choices: ...) and --flag=value from the owning option only' {
        $help = @"
Options:
  --output-format <format>   Output format (choices: "text", "json", "stream-json")
  --tmux                     Use tmux. use --tmux=classic for traditional tmux.
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Options['--output-format'].Choices | Should -Be @('text', 'json', 'stream-json')
        $spec.Options['--tmux'].Choices | Should -Contain 'classic'
        $spec.Options['--tmux'].RequiredArg | Should -BeFalse
    }

    It 'joins wrapped option description lines onto the same option' {
        $help = @"
Options:
  --exclude-dynamic-system-prompt-sections
      Move per-machine sections from the system prompt.
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Options.ContainsKey('--exclude-dynamic-system-prompt-sections') | Should -BeTrue
        $spec.Options['--exclude-dynamic-system-prompt-sections'].Description | Should -Match 'per-machine'
    }
}

Describe 'Complete-ClaudeNativeArgument' {
    AfterEach {
        Reset-ClaudeHelpCache
        Set-ClaudeHelpProvider -Provider $null
    }

    It 'returns empty (does not throw) when the help provider fails' {
        Set-ClaudeHelpProvider -Provider { throw 'no claude' }
        $hits = @(Complete-ClaudeNativeArgument -wordToComplete '--' -Tokens @())
        $hits.Count | Should -Be 0
    }

    It 'hides a used non-repeatable flag and its alias' {
        Set-ClaudeHelpProvider -Provider {
            @"
Options:
  -p, --print    Print and exit
  --verbose      Verbose
"@
        }
        Reset-ClaudeHelpCache
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '--' -Tokens @('-p') | ForEach-Object { $_.CompletionText })
        $texts | Should -Not -Contain '--print'
        $texts | Should -Not -Contain '-p'
        $texts | Should -Contain '--verbose'
    }

    It 'keeps a used repeatable flag visible' {
        Set-ClaudeHelpProvider -Provider {
            @"
Options:
  --add-dir <directories...>   Extra dirs (repeatable)
  --verbose                    Verbose
"@
        }
        Reset-ClaudeHelpCache
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '--' -Tokens @('--add-dir', 'src') | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain '--add-dir'
        $texts | Should -Contain '--verbose'
    }

    It 'does not treat the next subcommand as an optional flag value' {
        Set-ClaudeHelpProvider -Provider {
            param($Path)
            if (-not $Path) {
                return @"
Options:
  -d, --debug [filter]   Debug
Commands:
  mcp                    MCP
"@
            }
            if ($Path -contains 'mcp') {
                return @"
Commands:
  list                   List servers
"@
            }
            return ''
        }
        Reset-ClaudeHelpCache
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '' -Tokens @('--debug', 'mcp') | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain 'list'
    }

    It 'completes --flag=value from choices' {
        Set-ClaudeHelpProvider -Provider {
            @"
Options:
  --output-format <format>   Format (choices: "text", "json")
"@
        }
        Reset-ClaudeHelpCache
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '--output-format=j' -Tokens @() | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain '--output-format=json'
        $texts | Should -Not -Contain '--output-format=text'
    }

    It 'after a subcommand, empty Tab offers sibling commands, not -h/--help or Commander help' {
        Set-ClaudeHelpProvider -Provider {
            param($Path)
            if (-not $Path) {
                return @"
Commands:
  mcp                    Configure MCP
Options:
  -h, --help             Display help for command
"@
            }
            return @"
Options:
  -h, --help                            Display help for command
Commands:
  add [options] <name>                  Add a server
  help [command]                        display help for command
  list                                  List servers
"@
        }
        Reset-ClaudeHelpCache
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '' -Tokens @('mcp') | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain 'add'
        $texts | Should -Contain 'list'
        $texts | Should -Not -Contain 'help'
        $texts | Should -Not -Contain '--help'
        $texts | Should -Not -Contain '-h'
    }

    It 'prefix - after a subcommand offers -h/--help, not add' {
        Set-ClaudeHelpProvider -Provider {
            param($Path)
            if (-not $Path) {
                return @"
Commands:
  mcp                    Configure MCP
"@
            }
            return @"
Options:
  -h, --help                            Display help for command
Commands:
  add                                   Add a server
  list                                  List servers
"@
        }
        Reset-ClaudeHelpCache
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '-' -Tokens @('mcp') | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain '-h'
        $texts | Should -Contain '--help'
        $texts | Should -Not -Contain 'add'
        $texts | Should -Not -Contain 'list'
    }

    It 'leaf command empty Tab still offers flags so Tab does not fall through to files' {
        Set-ClaudeHelpProvider -Provider {
            param($Path)
            $key = if ($Path) { $Path -join ' ' } else { '' }
            if ($key -eq '') { return "Commands:`n  mcp    MCP`n" }
            if ($key -eq 'mcp') { return "Commands:`n  add    Add`n" }
            return @"
Options:
  -t, --transport <transport>  Transport type
  -h, --help                   Display help for command
"@
        }
        Reset-ClaudeHelpCache
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '' -Tokens @('mcp', 'add') | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain '--transport'
        $texts | Should -Contain '-t'
        $texts | Should -Not -Contain 'add'
        $texts | Should -Not -Contain 'mcp'
    }

    It 'cache is keyed by command path' {
        $calls = [System.Collections.Generic.List[string]]::new()
        Set-ClaudeHelpProvider -Provider {
            param($Path)
            $key = if ($Path) { $Path -join ' ' } else { '' }
            [void]$calls.Add($key)
            if ($key -eq '') {
                return "Commands:`n  mcp    MCP`n"
            }
            return "Commands:`n  list   List`n"
        }
        Reset-ClaudeHelpCache
        $null = Get-ClaudeHelpSpec -Path @()
        $null = Get-ClaudeHelpSpec -Path @()
        $null = Get-ClaudeHelpSpec -Path @('mcp')
        $null = Get-ClaudeHelpSpec -Path @('mcp')
        $calls.Count | Should -Be 2
        $calls | Should -Contain ''
        $calls | Should -Contain 'mcp'
    }
}
