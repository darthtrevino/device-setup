#Requires -Version 7
<#
.SYNOPSIS
    Links the dotfiles in this folder into place and runs post-install setup.
    Run after `winget configure -f devbox\machine.dsc.winget`.

.DESCRIPTION
    Existing files are moved to <file>.<timestamp>.bak before linking.
    Symbolic links require Developer Mode (enabled by machine.dsc.winget) or an elevated shell;
    use -Copy to copy files instead.

.EXAMPLE
    .\devbox\bootstrap.ps1 -GitName 'Jane Doe' -GitEmail 'jane@example.com'
#>
[CmdletBinding()]
param(
    # Copy files instead of creating symbolic links.
    [switch]$Copy,
    # Used to create ~/.gitconfig.local when it does not exist. Defaults to the current global
    # git identity, otherwise prompts.
    [string]$GitName,
    [string]$GitEmail,
    [string]$ProfilePath = $PROFILE.CurrentUserCurrentHost,
    [switch]$SkipVSCodeExtensions
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMddHHmmss'

# Pick up tools installed by winget in this session.
$env:Path = @(
    [Environment]::GetEnvironmentVariable('Path', 'Machine'),
    [Environment]::GetEnvironmentVariable('Path', 'User'),
    $env:Path
) -join ';'

function Install-Dotfile {
    param([string]$Source, [string]$Target)

    $src = Join-Path $root $Source
    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue

    if ($existing -and $existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $src) {
        Write-Host "ok      $Target"
        return
    }

    if ($existing) {
        if ($existing.LinkType) {
            Remove-Item -LiteralPath $Target -Force
        } else {
            $backup = "$Target.$stamp.bak"
            Move-Item -LiteralPath $Target -Destination $backup
            Write-Host "backup  $Target -> $backup"
        }
    }

    New-Item -ItemType Directory -Force -Path (Split-Path $Target) | Out-Null
    if ($Copy) {
        Copy-Item -LiteralPath $src -Destination $Target
        Write-Host "copied  $Target"
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $Target -Target $src | Out-Null
        } catch {
            throw "Could not create symlink '$Target'. Enable Developer Mode, run elevated, or use -Copy. $_"
        }
        Write-Host "linked  $Target"
    }
}

# --- git identity (kept out of the repo) ------------------------------------------------------
$gitLocal = Join-Path $env:USERPROFILE '.gitconfig.local'
if (-not (Test-Path -LiteralPath $gitLocal)) {
    if (-not $GitName) { $GitName = git config --global --includes user.name }
    if (-not $GitEmail) { $GitEmail = git config --global --includes user.email }
    if (-not $GitName) { $GitName = Read-Host 'git user.name' }
    if (-not $GitEmail) { $GitEmail = Read-Host 'git user.email' }

    Copy-Item -LiteralPath (Join-Path $root 'gitconfig.local.example') -Destination $gitLocal
    git config --file $gitLocal user.name $GitName.Trim()
    git config --file $gitLocal user.email $GitEmail.Trim()
    Write-Host "created $gitLocal (add org credential sections from your old .gitconfig backup if needed)"
}

# --- dotfiles ---------------------------------------------------------------------------------
Install-Dotfile 'gitconfig' (Join-Path $env:USERPROFILE '.gitconfig')
Install-Dotfile 'gitconfig.darthtrevino' (Join-Path $env:USERPROFILE '.gitconfig.darthtrevino')
Install-Dotfile 'omp.json' (Join-Path $env:USERPROFILE 'omp.json')
Install-Dotfile 'powershell-profile.ps1' $ProfilePath
Install-Dotfile 'vscode-settings.json' (Join-Path $env:APPDATA 'Code\User\settings.json')
Install-Dotfile 'windows-terminal-settings.json' `
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')

# --- PowerShell modules -----------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name posh-git)) {
    Write-Host 'install posh-git'
    Install-Module posh-git -Scope CurrentUser -Force
}

# --- VS Code extensions -----------------------------------------------------------------------
if (-not $SkipVSCodeExtensions) {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        # Optional, uncommitted list for org-specific/private extensions.
        $lists = @((Join-Path $root 'vscode-extensions.txt'), (Join-Path $env:USERPROFILE '.vscode-extensions.local.txt'))
        $installed = @(code --list-extensions)
        $wanted = Get-Content -LiteralPath ($lists | Where-Object { Test-Path -LiteralPath $_ }) |
            ForEach-Object Trim | Where-Object { $_ -and -not $_.StartsWith('#') }
        foreach ($ext in $wanted | Where-Object { $_ -notin $installed }) {
            code --install-extension $ext
        }
    } else {
        Write-Warning 'VS Code CLI (code) not found; skipping extensions.'
    }
}

Write-Host 'Bootstrap complete. Restart your terminal to load the new profile.'
