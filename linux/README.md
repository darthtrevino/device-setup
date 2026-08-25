# workstation-ansible

Ansible playbooks for provisioning my Fedora workstations.

Previously these were [Comtrya](https://comtrya.dev) manifests; Comtrya is no
longer maintained, so everything has been ported to Ansible roles.

## Supported Distributions

**Fedora (x86_64) only.** Earlier revisions of this repo also targeted Ubuntu
and Linux Mint; all `apt`-based branches have been removed. Everything here
assumes `dnf`, RPM packaging, and Fedora package names.

## Getting Started

```bash
# One time per machine: installs ansible-core, ansible-lint and collections
sudo ./bootstrap.sh

# Build the whole workstation (-K prompts once for your sudo password)
ansible-playbook playbooks/workstation.yml -K

# Or run a single role
ansible-playbook playbooks/podman.yml -K

# Preview without changing anything
ansible-playbook playbooks/workstation.yml -K --check --diff
```

## Layout

```
ansible.cfg          # inventory, roles_path, output formatting
bootstrap.sh         # installs ansible + collections on a fresh machine
inventory.ini        # [workstations] -> localhost, connection=local
group_vars/all/      # user paths (main.yml) and Zen Browser config (zen.yml)
playbooks/           # workstation.yml (everything) + one per role
roles/<role>/        # defaults/ files/ handlers/ meta/ tasks/ templates/
```

Roles are `snake_case` to satisfy `ansible-lint`'s `role-name` rule.

## Roles

| Role | Description |
|------|-------------|
| `bashrcd` | Ensures `~/.bashrc.d` exists and is sourced by `~/.bashrc` |
| `bottom` | Installs [bottom](https://github.com/ClementTsang/bottom) from the latest upstream release RPM |
| `catppuccin_gnome_terminal` | Installs the Catppuccin GNOME Terminal profiles and defaults to Mocha |
| `discord` | Installs Discord from RPM Fusion nonfree |
| `git` | Installs Git |
| `golang` | Installs the latest Go toolchain into `/usr/local/go` |
| `jq` | Installs jq |
| `just` | Installs the [just](https://github.com/casey/just) command runner |
| `nerd_fonts_hack` | Installs Hack Nerd Font and sets it as the desktop monospace font |
| `no_notifications` | Disables GNOME event sounds |
| `podman` | Installs **rootless** Podman and exposes a Docker-compatible socket |
| `rpmfusion` | Enables the RPM Fusion free and nonfree repositories |
| `rust` | Installs Rust via rustup and keeps toolchains updated |
| `starship` | Installs the [Starship](https://starship.rs) prompt |
| `task` | Installs the [Task](https://taskfile.dev) runner from Cloudsmith |
| `tealdeer` | Installs tealdeer and primes the tldr cache |
| `vim` | Installs Vim (`vim-enhanced`) |
| `vscode` | Installs Visual Studio Code from Microsoft's dnf repository |
| `zen_browser` | Installs [Zen Browser](https://zen-browser.app) to `/opt/zen` |
| `zen_browser_extensions` | Downloads extension XPIs into the Zen install |
| `zen_browser_policies` | Renders Zen's `policies.json` enterprise policy |

## Role Dependencies

Declared in each role's `meta/main.yml`, so the single-role playbooks are
correct on their own. Ansible de-duplicates shared dependencies within a run.

```
starship, golang, rust, podman, zen_browser  ->  bashrcd
discord                                      ->  rpmfusion
zen_browser_extensions, zen_browser_policies ->  zen_browser
```

## Notes on the Comtrya Port

- **Docker was replaced by rootless Podman.** No root daemon and no `docker`
  group; the `podman` role removes any Docker Engine packages, enables
  `podman.socket` in the user's systemd scope, and exports `DOCKER_HOST` so
  Docker-API clients keep working.
- **`bashrcd` is conditional.** Fedora's stock `~/.bashrc` already sources
  `~/.bashrc.d`, so the role only appends the loop when it is genuinely
  missing — otherwise every snippet would be sourced twice.
- **Zen policies are one template.** The Comtrya version shelled out to `jq`
  to merge two JSON files at apply time. `policies.json` is now rendered from
  a single template that shares the `zen_extensions` list with the extensions
  role, so extension GUIDs and XPI filenames cannot drift apart.
- **`vscode` and `task` use real dnf repositories** instead of one-off package
  downloads, so `dnf upgrade` keeps them current.
- **Idempotency.** Comtrya's `command.run` steps ran unconditionally; the
  Ansible equivalents are guarded with `creates:`, `stat` checks, or a
  `gsettings get` before `set`. Read-only probes set `check_mode: false` so
  `--check` runs report accurately.

## Linting

```bash
ansible-lint
```

The repo is clean at ansible-lint's `production` profile.
