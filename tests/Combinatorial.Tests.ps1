#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# -ForEach data is evaluated at discovery, before BeforeAll. Load axes here.
BeforeDiscovery {
    . (Join-Path $PSScriptRoot 'Helpers.ps1')
}

BeforeAll {
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $moduleRoot 'ClaudeCompletion.psd1') -Force
    . (Join-Path $PSScriptRoot 'Helpers.ps1')
}

Describe '2^n help-shape configurations' {
    It 'generates exactly 2^n configs and does not skip any index' {
        $axes = Get-ClaudeHelpAxes
        $configs = Get-ClaudeHelpConfigurations
        $expected = [int][Math]::Pow(2, $axes.Count)
        $configs.Count | Should -Be $expected
        $indexes = @($configs.Index | Sort-Object)
        $indexes[0] | Should -Be 0
        $indexes[-1] | Should -Be ($expected - 1)
        @($indexes | Select-Object -Unique).Count | Should -Be $expected
    }

    It 'axis list is the documented single source (n >= 1, unique names)' {
        $axes = Get-ClaudeHelpAxes
        $axes.Count | Should -BeGreaterThan 0
        @($axes | Select-Object -Unique).Count | Should -Be $axes.Count
    }
}

Describe 'parser invariants across every 2^n help shape' {
    It 'parses generated help shape <Index> without throwing and honors each axis' -ForEach (Get-ClaudeHelpConfigurations) {
        $help = New-FakeClaudeHelp -Config $_
        { ConvertFrom-ClaudeHelpText -Text $help } | Should -Not -Throw
        $spec = ConvertFrom-ClaudeHelpText -Text $help

        if ($_.HasCommands) {
            $spec.Commands.ContainsKey('plugin') | Should -BeTrue -Because "config $($_.Index) HasCommands"
            if ($_.CommandHasAlias) {
                $spec.Commands.ContainsKey('plugins') | Should -BeTrue -Because "config $($_.Index) CommandHasAlias"
            } else {
                $spec.Commands.ContainsKey('plugins') | Should -BeFalse -Because "config $($_.Index) no alias"
            }
            $spec.Commands.ContainsKey('Examples') | Should -BeFalse -Because "Examples: is not a command (config $($_.Index))"
        } else {
            $spec.Commands.Count | Should -Be 0 -Because "config $($_.Index) !HasCommands"
        }

        if ($_.HasOptions) {
            $spec.Options.ContainsKey('--scope') | Should -BeTrue -Because "config $($_.Index) HasOptions"
            $spec.Options.ContainsKey('--print') | Should -BeFalse -Because "must not steal flags from description (config $($_.Index))"
            $spec.Options.ContainsKey('--output-format') | Should -BeFalse -Because "must not steal flags from description (config $($_.Index))"
            $spec.Options.ContainsKey('-h') | Should -BeTrue -Because "-h must not be swallowed by -H (config $($_.Index))"
            $spec.Options.ContainsKey('-H') | Should -BeTrue -Because "-H is distinct from -h (config $($_.Index))"

            $scope = $spec.Options['--scope']
            if ($_.OptionHasAlias) {
                $spec.Options.ContainsKey('-s') | Should -BeTrue
                $scope.Aliases | Should -Contain '-s'
                $scope.Aliases | Should -Contain '--scope'
            } else {
                $spec.Options.ContainsKey('-s') | Should -BeFalse
            }

            if ($_.OptionHasRequiredArg) {
                $scope.RequiredArg | Should -BeTrue
                $scope.Arg | Should -Not -BeNullOrEmpty
            } else {
                $scope.RequiredArg | Should -BeFalse
            }

            if ($_.OptionHasChoices) {
                $scope.Choices | Should -Contain 'local'
                $scope.Choices | Should -Contain 'user'
            }

            if ($_.OptionRepeatable) {
                $scope.Repeatable | Should -BeTrue
            }
        } else {
            $spec.Options.Count | Should -Be 0 -Because "config $($_.Index) !HasOptions"
        }

        if ($_.HasArguments) {
            $spec.Arguments.Count | Should -Be 1
            $spec.Arguments[0].Name | Should -Be 'source'
            $spec.Arguments[0].Choices | Should -Contain 'codex'
            $spec.Arguments[0].Choices | Should -Contain 'gemini'
        } else {
            $spec.Arguments.Count | Should -Be 0
        }
    }
}

Describe 'completer against every 2^n help shape' {
    AfterEach {
        Reset-ClaudeHelpCache
        Set-ClaudeHelpProvider -Provider $null
    }

    It 'completes config <Index> from the generated help, not from a hardcoded flag list' -ForEach (Get-ClaudeHelpConfigurations) {
        $help = New-FakeClaudeHelp -Config $_
        Set-ClaudeHelpProvider -Provider { param($Path) $help }.GetNewClosure()
        Reset-ClaudeHelpCache

        $texts = Get-CompletionTexts -WordToComplete '' -Tokens @()

        if ($_.HasCommands) {
            $texts | Should -Contain 'plugin'
        } else {
            $texts | Should -Not -Contain 'plugin'
        }

        if ($_.HasOptions) {
            $texts | Should -Contain '--scope'
            $texts | Should -Not -Contain '--print'
        } else {
            $texts | Should -Not -Contain '--scope'
        }

        if ($_.HasArguments) {
            $texts | Should -Contain 'codex'
            $texts | Should -Contain 'gemini'
        } else {
            $texts | Should -Not -Contain 'codex'
        }

        if ($_.HasOptions -and $_.OptionHasRequiredArg -and $_.OptionHasChoices) {
            $choiceTexts = Get-CompletionTexts -WordToComplete '' -Tokens @('--scope')
            $choiceTexts | Should -Contain 'local'
            $choiceTexts | Should -Contain 'user'
        }
    }
}
