# Changelog

All notable changes to this collection are documented here.

## 1.0.0

Initial release as an Ansible collection, ported from the previous Comtrya
manifests.

### Added

- Roles for shell tooling (`bashrcd`, `starship`, `bottom`, `jq`, `just`,
  `task`, `tealdeer`, `vim`), language toolchains (`golang`, `rust`),
  rootless containers (`podman`), fonts (`nerd_fonts_hack`), desktop
  applications (`discord`, `vscode`, `zen_browser` and friends), and host
  configuration (`git`, `rpmfusion`, `sshd`, `no_notifications`,
  `catppuccin_gnome_terminal`).
- `workstation` and `zen` carrier roles holding variables shared across
  roles, so that roles remain self-contained when consumed from another
  repository. Collections do not carry `group_vars`, so these must not be
  moved back there.

### Changed

- Dropped all Ubuntu, Linux Mint and Debian support. Fedora only.
- Replaced Docker with rootless Podman, exposing a Docker-compatible socket
  via `DOCKER_HOST` for tools that only speak the Docker API.
