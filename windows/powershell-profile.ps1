Import-Module posh-git -ErrorAction SilentlyContinue
# oh-my-posh init pwsh --config ~/omp.json | Invoke-Expression
oh-my-posh init pwsh | Invoke-Expression

function open {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    # Emulates macOS `open`: folders in Explorer, files with default app,
    # URLs in the browser, and `-a <App>` to launch a named application.
    if (-not $Args -or $Args.Count -eq 0) {
        Invoke-Item -LiteralPath (Get-Location).Path
        return
    }

    if ($Args[0] -eq '-a') {
        if ($Args.Count -lt 2) {
            Write-Error "open: -a requires an application name"
            return
        }
        $app = $Args[1]
        $rest = $Args | Select-Object -Skip 2
        if ($rest) {
            Start-Process -FilePath $app -ArgumentList $rest
        } else {
            Start-Process -FilePath $app
        }
        return
    }

    foreach ($target in $Args) {
        if ($target -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
            Start-Process $target
        } elseif (Test-Path -LiteralPath $target) {
            Invoke-Item -LiteralPath $target
        } else {
            Write-Error "open: '$target' : No such file or directory"
        }
    }
}
