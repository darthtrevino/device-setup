# macOS workstation

Part of [device-setup](../README.md). Packages come from Homebrew; git, package feed and VS Code
configuration is shared with the Linux and Windows setups from [`../shared`](../shared).

## Rebuilding a Mac

```sh
git clone https://github.com/darthtrevino/device-setup.git
cd device-setup
./macos/bootstrap.sh
```

`bootstrap.sh`, in order:

1. Installs Homebrew if it is missing (which also installs the Xcode Command Line Tools).
2. Copies the package feed proxy configs (`../shared/package-feeds`), so everything after this
   resolves npm/pip/uv/NuGet packages through the proxy.
3. Installs [nvm](https://github.com/nvm-sh/nvm) and the current Node LTS (the Brewfile's `npm`
   entries need npm).
4. Runs `brew bundle --file macos/Brewfile`.
5. Seeds `~/.gitconfig.local` from your current git identity and links `~/.gitconfig`.
6. Links the VS Code settings and installs the shared extensions plus `~/.vscode-extensions.local.txt`.
7. Runs `../shared/git/auth.ps1` (PowerShell is in the Brewfile).

Options: `--copy` (copy dotfiles instead of linking), `--skip-brew`, `--skip-vscode-extensions`,
`--skip-auth`. Safe to re-run.

## Updating the Brewfile

```sh
brew bundle check --verbose --file macos/Brewfile   # what is missing on this Mac
brew bundle cleanup --file macos/Brewfile           # what is installed but not listed (dry run)
```
