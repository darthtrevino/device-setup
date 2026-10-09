#!/usr/bin/env bash
# macos/bootstrap.sh
#
# Brings a Mac to the baseline: Homebrew, Node (via nvm), the package feed proxy configs, the
# Brewfile, shared dotfiles, VS Code extensions and GitHub/git authentication.
#
# Usage:
#   ./macos/bootstrap.sh [--copy] [--skip-brew] [--skip-vscode-extensions] [--skip-auth]
#
#   --copy                     copy dotfiles instead of symlinking them into the repo
#   --skip-brew                do not run `brew bundle`
#   --skip-vscode-extensions   do not install VS Code extensions
#   --skip-auth                do not run shared/git/auth.ps1 (gh logins + per-remote git routing)
#
# Safe to re-run. Existing files are moved to <file>.<timestamp>.bak before being replaced.
#
# Written for the bash 3.2 that ships with macOS: no associative arrays, no mapfile.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
shared="${root}/shared"
stamp="$(date +%Y%m%d%H%M%S)"
nvm_version="v0.40.7"

copy=false
skip_brew=false
skip_vscode_extensions=false
skip_auth=false
for arg in "$@"; do
  case "${arg}" in
    --copy) copy=true ;;
    --skip-brew) skip_brew=true ;;
    --skip-vscode-extensions) skip_vscode_extensions=true ;;
    --skip-auth) skip_auth=true ;;
    -h | --help)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS. Use linux/ (Ansible) or windows/ instead." >&2
  exit 1
fi

# install_dotfile <src> <target> [copy]
# Symlinks target -> src (or copies it with --copy, or when the third argument is "copy").
install_dotfile() {
  local src="$1" target="$2" copy_file="${copy}"
  [[ "${3:-}" == copy ]] && copy_file=true

  if ! ${copy_file} && [[ -L "${target}" && "$(readlink "${target}")" == "${src}" ]]; then
    echo "ok      ${target}"
    return
  fi

  if [[ -L "${target}" ]]; then
    rm "${target}"
  elif [[ -e "${target}" ]]; then
    if ${copy_file} && cmp -s "${src}" "${target}"; then
      echo "ok      ${target}"
      return
    fi
    mv "${target}" "${target}.${stamp}.bak"
    echo "backup  ${target} -> ${target}.${stamp}.bak"
  fi

  mkdir -p "$(dirname "${target}")"
  if ${copy_file}; then
    cp "${src}" "${target}"
    echo "copied  ${target}"
  else
    ln -s "${src}" "${target}"
    echo "linked  ${target}"
  fi
}

# --- Homebrew -----------------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "${candidate}" ]]; then
      eval "$("${candidate}" shellenv)"
      break
    fi
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  # The installer also installs the Xcode Command Line Tools (git, clang) when missing.
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "${candidate}" ]] && eval "$("${candidate}" shellenv)" && break
  done
fi

# --- Package feed proxy -------------------------------------------------------------------------
# Before anything installs packages, so npm/pip/uv/NuGet all resolve through the proxy from the
# first run. Always copied: `npm login` and `dotnet nuget add source` write credentials into these
# files, which must never land in the repo through a symlink.
install_dotfile "${shared}/package-feeds/npmrc" "${HOME}/.npmrc" copy
install_dotfile "${shared}/package-feeds/pip.conf" "${HOME}/.config/pip/pip.conf" copy
install_dotfile "${shared}/package-feeds/uv.toml" "${HOME}/.config/uv/uv.toml" copy
install_dotfile "${shared}/package-feeds/NuGet.Config" "${HOME}/.nuget/NuGet/NuGet.Config" copy

# --- Node (nvm) ---------------------------------------------------------------------------------
# Same tool as the Linux nvm role. Installed before brew bundle because the Brewfile's `npm`
# entries need npm on PATH.
export NVM_DIR="${HOME}/.nvm"
if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
  echo "==> Installing nvm ${nvm_version}"
  # The installer adds the nvm loader to ~/.zshrc when it is not already there.
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | PROFILE="${HOME}/.zshrc" bash
fi
# nvm.sh is not written for `set -u`.
set +u
# shellcheck source=/dev/null
. "${NVM_DIR}/nvm.sh"
if [[ "$(nvm version 'lts/*')" == "N/A" ]]; then
  echo "==> Installing Node LTS"
  nvm install --lts
fi
nvm use 'lts/*' >/dev/null
set -u

# --- Brewfile -----------------------------------------------------------------------------------
if ! ${skip_brew}; then
  echo "==> brew bundle"
  brew bundle --file "${root}/macos/Brewfile"
fi

# --- git ----------------------------------------------------------------------------------------
# ~/.gitconfig.local holds the default identity and is never committed. Seed it from the current
# global identity before ~/.gitconfig is replaced.
git_local="${HOME}/.gitconfig.local"
if [[ ! -e "${git_local}" ]]; then
  git_name="$(git config --global --includes user.name || true)"
  git_email="$(git config --global --includes user.email || true)"
  [[ -n "${git_name}" ]] || read -r -p "git user.name: " git_name
  [[ -n "${git_email}" ]] || read -r -p "git user.email: " git_email
  cp "${shared}/git/gitconfig.local.example" "${git_local}"
  git config --file "${git_local}" user.name "${git_name}"
  git config --file "${git_local}" user.email "${git_email}"
  echo "created ${git_local}"
fi
install_dotfile "${shared}/git/gitconfig" "${HOME}/.gitconfig"

# --- VS Code ------------------------------------------------------------------------------------
install_dotfile "${shared}/vscode/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"

if ! ${skip_vscode_extensions}; then
  if command -v code >/dev/null 2>&1; then
    installed="$(code --list-extensions | tr '[:upper:]' '[:lower:]')"
    # ~/.vscode-extensions.local.txt: optional, uncommitted list for org-specific/private extensions.
    for list in "${shared}/vscode/extensions.txt" "${HOME}/.vscode-extensions.local.txt"; do
      [[ -f "${list}" ]] || continue
      while IFS= read -r ext || [[ -n "${ext}" ]]; do
        ext="$(echo "${ext}" | xargs)"
        [[ -z "${ext}" || "${ext}" == \#* ]] && continue
        lower="$(echo "${ext}" | tr '[:upper:]' '[:lower:]')"
        if ! grep -qxF "${lower}" <<<"${installed}"; then
          code --install-extension "${ext}"
        fi
      done <"${list}"
    done
  else
    echo "warning: VS Code CLI (code) not found; skipping extensions." >&2
  fi
fi

# --- GitHub accounts ----------------------------------------------------------------------------
if ! ${skip_auth}; then
  pwsh -NoProfile -File "${shared}/git/auth.ps1"
fi

echo "Bootstrap complete. Open a new terminal to pick up the changes."
