#Requires -Version 7
<#
.SYNOPSIS
    Links the dotfiles in this folder and in ..\shared into place and runs post-install setup.
    Run after `winget configure -f windows\machine.dsc.winget` (and any windows\optional\*.dsc.winget add-ons).

.DESCRIPTION
    Existing files are moved to <file>.<timestamp>.bak before linking.
    Symbolic links require Developer Mode (enabled by machine.dsc.winget) or an elevated shell;
    use -Copy to copy files instead. Package feed configs are always copied.

.EXAMPLE
    .\windows\bootstrap.ps1 -GitName 'Jane Doe' -GitEmail 'jane@example.com'
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
    [switch]$SkipVSCodeExtensions,
    # Skip shared/git/auth.ps1 (gh logins + per-remote git routing).
    [switch]$SkipAuth
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$shared = (Resolve-Path (Join-Path $root '..\shared')).Path
$stamp = Get-Date -Format 'yyyyMMddHHmmss'

# Pick up tools installed by winget in this session.
$env:Path = @(
    [Environment]::GetEnvironmentVariable('Path', 'Machine'),
    [Environment]::GetEnvironmentVariable('Path', 'User'),
    $env:Path
) -join ';'

# Source is relative to this folder, or absolute. -CopyFile forces a copy even without -Copy.
function Install-Dotfile {
    param([string]$Source, [string]$Target, [switch]$CopyFile)

    $src = if ([IO.Path]::IsPathRooted($Source)) { $Source } else { Join-Path $root $Source }
    $doCopy = $Copy -or $CopyFile
    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue

    if (-not $doCopy -and $existing -and $existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $src) {
        Write-Host "ok      $Target"
        return
    }

    if ($existing) {
        if ($existing.LinkType) {
            Remove-Item -LiteralPath $Target -Force
        } elseif ($doCopy -and (Get-FileHash -LiteralPath $Target).Hash -eq (Get-FileHash -LiteralPath $src).Hash) {
            Write-Host "ok      $Target"
            return
        } else {
            $backup = "$Target.$stamp.bak"
            Move-Item -LiteralPath $Target -Destination $backup
            Write-Host "backup  $Target -> $backup"
        }
    }

    New-Item -ItemType Directory -Force -Path (Split-Path $Target) | Out-Null
    if ($doCopy) {
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

# --- package feed proxy (see shared/package-feeds) -------------------------------------------
# Always copied: `npm login` and `dotnet nuget add source` write credentials into these files,
# which must never land in the repo through a symlink.
$feeds = Join-Path $shared 'package-feeds'
Install-Dotfile (Join-Path $feeds 'npmrc') (Join-Path $env:USERPROFILE '.npmrc') -CopyFile
Install-Dotfile (Join-Path $feeds 'pip.conf') (Join-Path $env:APPDATA 'pip\pip.ini') -CopyFile
Install-Dotfile (Join-Path $feeds 'uv.toml') (Join-Path $env:APPDATA 'uv\uv.toml') -CopyFile
Install-Dotfile (Join-Path $feeds 'NuGet.Config') (Join-Path $env:APPDATA 'NuGet\NuGet.Config') -CopyFile

# --- git identity (kept out of the repo) ------------------------------------------------------
$gitLocal = Join-Path $env:USERPROFILE '.gitconfig.local'
if (-not (Test-Path -LiteralPath $gitLocal)) {
    if (-not $GitName) { $GitName = git config --global --includes user.name }
    if (-not $GitEmail) { $GitEmail = git config --global --includes user.email }
    if (-not $GitName) { $GitName = Read-Host 'git user.name' }
    if (-not $GitEmail) { $GitEmail = Read-Host 'git user.email' }

    Copy-Item -LiteralPath (Join-Path $shared 'git\gitconfig.local.example') -Destination $gitLocal
    git config --file $gitLocal user.name $GitName.Trim()
    git config --file $gitLocal user.email $GitEmail.Trim()
    Write-Host "created $gitLocal (add org credential sections from your old .gitconfig backup if needed)"
}

# --- dotfiles ---------------------------------------------------------------------------------
Install-Dotfile (Join-Path $shared 'git\gitconfig') (Join-Path $env:USERPROFILE '.gitconfig')
Install-Dotfile 'omp.json' (Join-Path $env:USERPROFILE 'omp.json')
Install-Dotfile 'powershell-profile.ps1' $ProfilePath
Install-Dotfile (Join-Path $shared 'vscode\settings.json') (Join-Path $env:APPDATA 'Code\User\settings.json')
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
        $lists = @(
            (Join-Path $shared 'vscode\extensions.txt'),
            # Windows-only extensions.
            (Join-Path $root 'vscode-extensions.txt'),
            # Optional, uncommitted list for org-specific/private extensions.
            (Join-Path $env:USERPROFILE '.vscode-extensions.local.txt'))
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

# --- GitHub accounts --------------------------------------------------------------------------
if (-not $SkipAuth) {
    & (Join-Path $shared 'git\auth.ps1')
}

Write-Host 'Bootstrap complete. Restart your terminal to load the new profile.'
