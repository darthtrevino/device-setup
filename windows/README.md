# windows-setup

One-stop shop for restoring a Windows development workstation.

## Layout

```
devbox/
├── machine.dsc.winget              # WinGet Configuration: apps, Windows settings, VS workloads, WSL, fonts
├── visualstudio.vsconfig           # Visual Studio workloads/components consumed by machine.dsc.winget
├── bootstrap.ps1                   # Links the dotfiles below into place + post-install setup
├── powershell-profile.ps1          # -> $PROFILE (PowerShell 7)
├── omp.json                        # -> ~/omp.json (Oh My Posh theme)
├── gitconfig                       # -> ~/.gitconfig (includes ~/.gitconfig.local)
├── gitconfig.darthtrevino          # -> ~/.gitconfig.darthtrevino (identity for github.com remotes)
├── gitconfig.local.example         # template for ~/.gitconfig.local (identity, org credentials)
├── vscode-settings.json            # -> %APPDATA%\Code\User\settings.json
├── vscode-extensions.txt           # installed by bootstrap.ps1
└── windows-terminal-settings.json  # -> Windows Terminal settings.json
```

Personal and org-specific settings are kept **out of this public repo**:

- `~/.gitconfig.local`: git `user.name`/`user.email`, Azure Repos / GHE credential blocks, `safe.directory` entries.
- `~/.vscode-extensions.local.txt` (optional): private/internal VS Code extensions, one ID per line.

## Rebuilding a workstation

```powershell
git clone https://github.com/darthtrevino/windows-setup.git
cd windows-setup
winget configure -f devbox\machine.dsc.winget --accept-configuration-agreements
# open a new PowerShell 7 terminal, then:
.\devbox\bootstrap.ps1
```

Elevated units (marked 🛡 in winget output) run in a single elevated process, so expect one UAC prompt.
A reboot may be needed afterwards for WSL and Developer Mode.

`bootstrap.ps1` symlinks the dotfiles (existing files are backed up as `*.<timestamp>.bak`), creates
`~/.gitconfig.local` (prompting for name/email if needed), installs `posh-git`, and installs VS Code
extensions. Use `-Copy` to copy instead of symlink. It is safe to re-run.

To check a machine against the desired state without changing anything:

```powershell
winget configure test -f devbox\machine.dsc.winget
```

## What `machine.dsc.winget` configures

- **Windows settings:** Developer Mode, long path support, dark mode, visible file extensions,
  sudo for Windows, Windows PowerShell execution policy (`RemoteSigned`).
- **Packages:** shell, git, editors/IDEs, AI tooling, language SDKs, CLI utilities, cloud/data tools.
  Framework dependencies, org-managed agents, and Microsoft 365 apps are deliberately excluded;
  see the header comment in the file for the list and how to opt in.
- **Visual Studio 2026 Enterprise** workloads from `visualstudio.vsconfig`.
- **WSL** with the Ubuntu distribution.
- **Meslo Nerd Font** for Oh My Posh / Windows Terminal.

## Updating

```powershell
# Refresh the Visual Studio workload list (run from an elevated prompt)
& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe" export `
  --installPath "C:\Program Files\Microsoft Visual Studio\18\Enterprise" `
  --config devbox\visualstudio.vsconfig --quiet

# Find installed packages not yet captured
winget export -o $env:TEMP\apps.json
```
