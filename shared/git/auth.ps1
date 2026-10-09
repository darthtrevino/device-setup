#Requires -Version 7
<#
.SYNOPSIS
    Signs the GitHub CLI into the personal, Enterprise Managed User (EMU) and GHE.com accounts and
    writes the private git config that routes each remote to the right identity and token.

.DESCRIPTION
    Accounts that are already signed in are reused; missing ones open a browser login.

    Runs on Windows, macOS and Linux (PowerShell 7). Called by every platform's bootstrap; rerun it
    on its own after joining a new EMU org.

    Generated files (never committed; rerun this script instead of editing them). Credential helpers
    embed the absolute path of gh, so GUI git clients work without gh on their PATH:
      ~/.gitconfig.gh           included first by shared/git/gitconfig. Base gh credential helper for
                                github.com and gist.github.com.
      ~/.gitconfig.darthtrevino personal identity + token, for github.com remotes.
      ~/.gitconfig.overrides    included last. Routes EMU org remotes on github.com to
                                ~/.gitconfig.emu and sets the GHE.com credential helper.
      ~/.gitconfig.emu          default identity (from ~/.gitconfig.local) + EMU account token.

    Each credential helper asks gh for a specific account's token (`gh auth token --user`), so
    pushes work regardless of which gh account is active.

.EXAMPLE
    ./shared/git/auth.ps1                        # discover everything from existing gh logins
    ./shared/git/auth.ps1 -GheHost contoso.ghe.com
#>
[CmdletBinding()]
param(
    [string]$PersonalUser = 'darthtrevino',
    # Commit identity for github.com remotes outside the EMU orgs.
    [string]$PersonalName = 'Chris Trevino',
    [string]$PersonalEmail = '113544+darthtrevino@users.noreply.github.com',
    # EMU login (e.g. jdoe_contoso). Defaults to the signed-in github.com account with an "_" suffix.
    [string]$EmuUser,
    # Orgs whose github.com remotes use the EMU identity. Defaults to the EMU account's orgs.
    [string[]]$EmuOrg,
    # GHE.com host (e.g. contoso.ghe.com). Defaults to the signed-in *.ghe.com host.
    [string]$GheHost,
    [switch]$SkipEmu,
    [switch]$SkipGhe,
    # Absolute path to gh. Defaults to the package-managed install for this platform.
    [string]$GhPath
)

$ErrorActionPreference = 'Stop'
$home_ = $HOME
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$tokenVars = 'GH_TOKEN', 'GITHUB_TOKEN', 'GH_ENTERPRISE_TOKEN', 'GITHUB_ENTERPRISE_TOKEN'

if ($IsWindows) {
    # Pick up tools installed by winget in this session.
    $env:Path = @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [Environment]::GetEnvironmentVariable('Path', 'User'),
        $env:Path
    ) -join ';'
}
# Prefer the package-managed gh over whatever is first on PATH: the path is baked into the generated
# config, and tools such as the Copilot app put private copies of gh on PATH.
$gh = if ($GhPath) { $GhPath } else {
    @(
        "$env:ProgramFiles\GitHub CLI\gh.exe",
        '/opt/homebrew/bin/gh',
        '/usr/local/bin/gh',
        '/usr/bin/gh'
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
}
if (-not $gh) { $gh = (Get-Command gh -ErrorAction Stop).Source }

function Get-GhLogins {
    $json = & $gh auth status --json hosts 2>$null | ConvertFrom-Json
    foreach ($h in $json.hosts.PSObject.Properties) {
        foreach ($a in $h.Value | Where-Object { $_.state -eq 'success' -and $_.tokenSource -notin $tokenVars }) {
            [pscustomobject]@{ Host = $h.Name; Login = $a.login; Active = $a.active }
        }
    }
}

function Invoke-GhLogin {
    param([string]$Hostname, [string]$Prompt)
    Write-Host "login   $Prompt"
    # gh may offer to run `gh auth setup-git`, which would rewrite (and un-symlink) ~/.gitconfig.
    $scratch = New-TemporaryFile
    $env:GIT_CONFIG_GLOBAL = $scratch.FullName
    try {
        # Start-Process keeps the console attached so the browser flow stays interactive.
        $p = Start-Process $gh -NoNewWindow -Wait -PassThru -ArgumentList @(
            'auth', 'login', '--hostname', $Hostname, '--git-protocol', 'https', '--web', '--skip-ssh-key')
        if ($p.ExitCode) { throw "gh auth login failed for $Hostname" }
    } finally {
        Remove-Item Env:GIT_CONFIG_GLOBAL
        Remove-Item -LiteralPath $scratch.FullName -Force
    }
}

# Resolves (logging in if needed) a stored (not env var) account on $Hostname matching $Match.
function Connect-GhAccount {
    param([string]$Hostname, [scriptblock]$Match, [string]$Prompt)
    $found = @(Get-GhLogins | Where-Object { $_.Host -eq $Hostname } | Where-Object $Match)
    if (-not $found) {
        Invoke-GhLogin $Hostname $Prompt
        $found = @(Get-GhLogins | Where-Object { $_.Host -eq $Hostname } | Where-Object $Match)
        if (-not $found) { throw "No account matching '$Prompt' is signed in to $Hostname." }
    }
    if ($found.Count -gt 1) {
        throw "Multiple accounts on $Hostname match ($($found.Login -join ', ')); pass the login explicitly."
    }
    Write-Host "ok      $Hostname $($found[0].Login)"
    $found[0].Login
}

function Get-HelperCommand {
    param([string]$Hostname, [string]$Login)
    $exe = $gh -replace '\\', '/'
    "!f() { [ `"`$1`" = get ] || exit 0; t=`$('$exe' auth token -h $Hostname -u $Login) || exit 0; " +
        "echo username=$Login; echo password=`$t; }; f"
}

function Add-Credential {
    param([string]$File, [string]$Hostname, [string]$Login)
    $section = "credential.https://$Hostname"
    git config --file $File "$section.username" $Login
    git config --file $File --add "$section.helper" ''
    git config --file $File --add "$section.helper" (Get-HelperCommand $Hostname $Login)
}

function Save-GeneratedFile {
    param([string]$Source, [string]$Target)
    $header = "# Generated by shared/git/auth.ps1 - rerun it instead of editing this file.`n"
    $content = $header + (Get-Content -LiteralPath $Source -Raw)
    Remove-Item -LiteralPath $Source -Force
    if (Test-Path -LiteralPath $Target) {
        if ((Get-Content -LiteralPath $Target -Raw) -eq $content) {
            Write-Host "ok      $Target"
            return
        }
        Move-Item -LiteralPath $Target -Destination "$Target.$stamp.bak"
        Write-Host "backup  $Target -> $Target.$stamp.bak"
    }
    Set-Content -LiteralPath $Target -Value $content -NoNewline
    Write-Host "wrote   $Target"
}

# Token env vars override the keyring and would hide the other accounts.
$savedTokens = @{}
foreach ($v in $tokenVars) {
    $val = [Environment]::GetEnvironmentVariable($v)
    if ($val) { $savedTokens[$v] = $val; [Environment]::SetEnvironmentVariable($v, $null) }
}

try {
    # Logins make the new account active; restore the previous one afterwards.
    $previouslyActive = @(Get-GhLogins | Where-Object Active)

    # --- personal account (used by ~/.gitconfig.<user> for all other github.com remotes) -------
    $null = Connect-GhAccount 'github.com' { $_.Login -eq $PersonalUser } "github.com as $PersonalUser"

    # Base helper for remotes no includeIf matches (gists, and clones before a remote exists).
    $ghFile = New-TemporaryFile
    $exe = $gh -replace '\\', '/'
    foreach ($h in 'github.com', 'gist.github.com') {
        git config --file $ghFile.FullName --add "credential.https://$h.helper" ''
        git config --file $ghFile.FullName --add "credential.https://$h.helper" "!'$exe' auth git-credential"
    }
    Save-GeneratedFile $ghFile.FullName (Join-Path $home_ '.gitconfig.gh')

    $personal = New-TemporaryFile
    git config --file $personal.FullName user.name $PersonalName
    git config --file $personal.FullName user.email $PersonalEmail
    Add-Credential $personal.FullName 'github.com' $PersonalUser
    Save-GeneratedFile $personal.FullName (Join-Path $home_ ".gitconfig.$PersonalUser")

    $overrides = New-TemporaryFile
    $emuFile = Join-Path $home_ '.gitconfig.emu'

    # --- Enterprise Managed User account on github.com -----------------------------------------
    if (-not $SkipEmu) {
        $match = if ($EmuUser) { { $_.Login -eq $EmuUser } } else { { $_.Login -like '*_*' } }
        $EmuUser = Connect-GhAccount 'github.com' $match "github.com EMU account$(if ($EmuUser) { " $EmuUser" })"

        if (-not $EmuOrg) {
            $env:GH_TOKEN = & $gh auth token --hostname github.com --user $EmuUser
            try { $EmuOrg = @(& $gh api user/orgs --paginate --jq '.[].login') } finally { Remove-Item Env:GH_TOKEN }
        }
        if (-not $EmuOrg) { throw "$EmuUser belongs to no orgs; pass -EmuOrg." }

        foreach ($org in $EmuOrg | Sort-Object -Unique) {
            foreach ($url in "https://github.com/$org/**", "git@github.com:$org/**", "ssh://git@github.com/$org/**") {
                git config --file $overrides.FullName --add "includeIf.hasconfig:remote.*.url:$url.path" '~/.gitconfig.emu'
            }
        }
        Write-Host "orgs    $($EmuOrg -join ', ')"

        $local = Join-Path $home_ '.gitconfig.local'
        $emu = New-TemporaryFile
        foreach ($key in 'user.name', 'user.email') {
            $value = git config --file $local $key 2>$null
            if ($value) { git config --file $emu.FullName $key $value }
        }
        Add-Credential $emu.FullName 'github.com' $EmuUser
        Save-GeneratedFile $emu.FullName $emuFile
    }

    # --- GitHub Enterprise Cloud with data residency (*.ghe.com) -------------------------------
    if (-not $SkipGhe) {
        if (-not $GheHost) {
            $GheHost = @(Get-GhLogins | Where-Object Host -like '*.ghe.com' | Select-Object -ExpandProperty Host -Unique) |
                Select-Object -First 1
        }
        if (-not $GheHost) { $GheHost = (Read-Host 'GHE.com host (e.g. contoso.ghe.com)').Trim() }
        $GheHost = $GheHost -replace '^https?://', '' -replace '/.*$', ''

        $gheUser = Connect-GhAccount $GheHost { $true } $GheHost
        Add-Credential $overrides.FullName $GheHost $gheUser
    }

    Save-GeneratedFile $overrides.FullName (Join-Path $home_ '.gitconfig.overrides')

    foreach ($a in $previouslyActive) {
        & $gh auth switch --hostname $a.Host --user $a.Login 2>$null | Out-Null
    }
} finally {
    foreach ($v in $savedTokens.Keys) { [Environment]::SetEnvironmentVariable($v, $savedTokens[$v]) }
}

Write-Host 'Auth complete.'
