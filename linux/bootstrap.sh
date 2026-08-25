#!/usr/bin/env bash
# bootstrap.sh
#
# One-time (but safe to re-run) bootstrap for a fresh Fedora workstation:
# installs Ansible itself plus the collections this repo's roles need, then
# does nothing else. Every other piece of workstation config (docker, zen,
# fonts, toolchains, ...) is a deliberate, directed playbook run from here on
# — this script's only job is "make `ansible-playbook` exist and work."
#
# Usage:
#   sudo ./bootstrap.sh
#
# Idempotent: re-running is safe, dnf/ansible-galaxy calls are no-ops if
# already satisfied.

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (sudo ./bootstrap.sh)" >&2
  exit 1
fi

echo "==> Installing ansible-core + supporting tools"
# Note: no `curl` here on purpose — Fedora ships curl-minimal, and asking for
# `curl` forces a package swap that can fail the bootstrap. Ansible's get_url
# module is used for downloads anyway.
#
# python3-dnf is pulled in explicitly so ansible.builtin.dnf keeps working even
# though Fedora is on dnf5; ansible-lint is here because roles in this repo are
# expected to stay lint-clean as more get added.
dnf install -y \
  ansible-core \
  ansible-lint \
  python3-dnf \
  python3-libdnf5 \
  git \
  vim-enhanced

echo "==> Installing Ansible collections used by this repo's roles"
# Installed to the shared system path (not root's own ~/.ansible), since this
# script runs via sudo but playbooks are run as the regular user (with
# `become:` per-task) — ansible's default COLLECTIONS_PATHS already includes
# /usr/share/ansible/collections as a fallback search location.
# ansible.posix:     users, groups, selinux, etc.
# community.general: dconf/gsettings-adjacent modules and misc helpers
ansible-galaxy collection install -p /usr/share/ansible/collections \
  ansible.posix \
  community.general

echo "==> Verifying local connectivity"
ansible localhost -i "$(dirname "$0")/inventory.ini" -m ping

echo
echo "Bootstrap complete. ansible --version:"
ansible --version
echo
echo "Next: run the whole workstation build, or a directed role, e.g.:"
echo "  ansible-playbook playbooks/workstation.yml -K"
echo "  ansible-playbook playbooks/docker.yml -K"
