@{
    RootModule        = 'ClaudeCompletion.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '7493ca4c-d81c-4446-a1c1-269394b1a73c'
    Author            = 'Yorai Levi'
    CompanyName       = 'Yorai Levi'
    Copyright         = '(c) 2026 Yorai Levi. MIT License.'
    Description       = 'Native PowerShell tab completion for the claude CLI, generated dynamically from `claude --help`.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'ConvertFrom-ClaudeHelpText',
        'Get-ClaudeHelpSpec',
        'Complete-ClaudeNativeArgument',
        'Register-ClaudeArgumentCompleter',
        'Set-ClaudeHelpProvider',
        'Get-ClaudeHelpProvider',
        'Reset-ClaudeHelpCache'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Claude', 'ClaudeCode', 'TabCompletion', 'ArgumentCompleter', 'PowerShell')
            LicenseUri   = 'https://github.com/YoraiLevi/pwsh-claude-completion/blob/master/LICENSE'
            ProjectUri   = 'https://github.com/YoraiLevi/pwsh-claude-completion'
            ReleaseNotes = 'Initial release: help-driven native completer and 2^n combinatorial parser tests.'
        }
    }
}
