@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Completer scriptblocks close over module commands; Analyzer cannot see that.
        'PSUseDeclaredVarsMoreThanAssignments'
        # UTF-8 without BOM is the right default on Linux/macOS CI.
        'PSUseBOMForUnicodeEncodedFile'
        # Cache/provider setters are not file-system mutations worth -WhatIf.
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
