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
ansible-playbook playbooks/development/podman.yml -K

# Preview without changing anything
ansible-playbook playbooks/workstation.yml -K --check --diff
```

## Layout

```
ansible.cfg          # inventory, roles_path, output formatting
bootstrap.sh         # installs ansible + collections on a fresh machine
inventory.ini        # [workstations] -> localhost, connection=local
playbooks/           # workstation.yml + directed playbooks grouped by function
roles/<role>/        # defaults/ files/ handlers/ meta/ tasks/ templates/
```

Roles are `snake_case` to satisfy `ansible-lint`'s `role-name` rule.

### Playbook Areas

| Directory | Purpose |
|-----------|---------|
| `applications/` | Desktop applications |
| `browser_configuration/` | Browser installation, extensions, and policies |
| `development/` | Source control, language toolchains, containers, and development tools |
| `environment/` | System repositories, maintenance, access, fonts, and desktop behavior |
| `kde_extensions/` | KDE-specific desktop automation |
| `shell_utilities/` | Shell initialization and prompt configuration |
| `terminal_emulators/` | Terminal applications and their configuration |
| `utilities/` | General command-line utilities |

## Roles

| Role | Description |
|------|-------------|
| `bashrcd` | Ensures `~/.bashrc.d` exists and is sourced by `~/.bashrc` |
| `bitwarden` | Installs Bitwarden from Flathub |
| `bottom` | Installs [bottom](https://github.com/ClementTsang/bottom) from the latest upstream release RPM |
| `catppuccin_gnome_terminal` | Installs the Catppuccin GNOME Terminal profiles and defaults to Mocha |
| `discord` | Installs Discord from Flathub |
| `dnf_automatic` | Applies package updates unattended on a daily timer |
| `flatpak` | Installs Flatpak and enables the system-wide Flathub remote |
| `firefox` | Installs Firefox and force-installs Bitwarden and uBlock Origin |
| `gaze` | Installs [Gaze](https://github.com/GunduLabs/gaze) face authentication for the KDE lock screen, sudo and polkit |
| `git` | Installs Git and configures the user identity |
| `github_cli` | Installs GitHub CLI from Fedora's package repository |
| `github_copilot_cli` | Installs the native GitHub Copilot CLI |
| `golang` | Installs the latest Go toolchain into `/usr/local/go` |
| `herdr` | Installs the [herdr](https://github.com/herdrdev/herdr) coding-agent runtime |
| `jq` | Installs jq |
| `just` | Installs the [just](https://github.com/casey/just) command runner |
| `kde_launchers` | Pins Steam, Spotify, Discord, Bitwarden and Edge to the KDE Task Manager |
| `kde_orthocal` | Installs the Orthocal Plasma widget immediately left of the clock |
| `microsoft_edge` | Installs Microsoft Edge Stable, Bitwarden and uBlock Origin |
| `nerd_fonts_hack` | Installs Hack Nerd Font and sets it as the desktop monospace font |
| `no_notifications` | Disables GNOME event sounds |
| `nvm` | Installs Node Version Manager and Bash integration |
| `podman` | Installs **rootless** Podman and exposes a Docker-compatible socket |
| `rpmfusion` | Enables the RPM Fusion free and nonfree repositories |
| `rust` | Installs Rust via rustup and keeps toolchains updated |
| `sshd` | Enables and starts the OpenSSH server, and opens it in firewalld |
| `spotify` | Installs Spotify from Flathub |
| `starship` | Installs the [Starship](https://starship.rs) prompt and its configuration |
| `steam` | Installs Steam and native controller-device support |
| `surface_dial` | Installs the Surface Dial volume controller and user service |
| `task` | Installs the [Task](https://taskfile.dev) runner from Cloudsmith |
| `tealdeer` | Installs tealdeer and primes the tldr cache |
| `uv` | Installs Astral's Python package and project manager from Fedora |
| `vim` | Installs Vim (`vim-enhanced`) |
| `vscode` | Installs Visual Studio Code from Microsoft's dnf repository |
| `wallpaper_randomizer` | Selects a random KDE wallpaper at startup and every 15 minutes |
| `wezterm` | Installs [WezTerm](https://wezterm.org) and its Lua configuration |
| `zen_browser` | Installs [Zen Browser](https://zen-browser.app) to `/opt/zen` |
| `zen_browser_extensions` | Downloads extension XPIs into the Zen install |
| `zen_browser_policies` | Renders Zen's `policies.json` enterprise policy |

## Role Dependencies

Declared in each role's `meta/main.yml`, so the single-role playbooks are
correct on their own. Ansible de-duplicates shared dependencies within a run.

```
starship, golang, rust, podman, zen_browser  ->  bashrcd
nvm                                           ->  git, bashrcd
kde_orthocal                                  ->  git, workstation
kde_launchers                                 ->  steam, spotify, discord, bitwarden, microsoft_edge
herdr                                         ->  workstation
starship, wezterm                            ->  nerd_fonts_hack
bitwarden, discord, spotify                  ->  flatpak
steam                                        ->  rpmfusion
surface_dial                                 ->  workstation
zen_browser_extensions, zen_browser_policies -> zen_browser
wallpaper_randomizer                         -> workstation
```

## Manual Steps

Provisioning cannot complete these, so the roles prompt for them instead.

- **Gaze face enrolment.** Enrolment drives the webcam from an interactive
  prompt, so the `gaze` role only installs and wires up face authentication.
  Run `gaze add-face` (or use the Gaze GUI) to enrol a face; the playbook
  prints a reminder whenever the current user has none. Until a face exists
  every Gaze prompt falls through to the password stack.

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
  downloads, so `dnf upgrade` keeps them current. `task` deliberately does not
  run Cloudsmith's `setup.rpm.sh`: that script pins `sslcacert` to
  `/etc/pki/tls/certs/ca-bundle.crt`, a path Fedora's `ca-certificates` no
  longer provides, so every `dnf` transaction failed the repo with
  `Curl error (77)`. The role declares the repository itself and lets it use
  the system trust store. It also drops the empty `-noarch` and `-source`
  repositories the script created.
- **Idempotency.** Comtrya's `command.run` steps ran unconditionally; the
  Ansible equivalents are guarded with `creates:`, `stat` checks, or a
  `gsettings get` before `set`. Read-only probes set `check_mode: false` so
  `--check` runs report accurately.

## WezTerm

Upstream publishes no stable Fedora channel — their own Fedora instructions
point at the `wezfurlong/wezterm-nightly` COPR, so that is what the role uses.
Expect it to update often; builds land several times a day, and with
`dnf_automatic` enabled they will be applied on the daily timer.

The configuration goes to `~/.config/wezterm/wezterm.lua`. WezTerm checks that
path *before* `~/.wezterm.lua`, so an old dotfile in `$HOME` cannot shadow it.
WezTerm watches the file and reloads on save, so no restart is needed after the
role updates it.

## Unattended Updates

`dnf_automatic` keeps the machine patched without prompting. On Fedora 44 this
is the dnf5 plugin (`dnf5-plugin-automatic`), not the old standalone
`dnf-automatic`; it ships `/etc/dnf/automatic.conf` empty and keeps its defaults
in `/usr/share/dnf5/dnf5-plugins/automatic.conf`, so the role writes only the
keys it changes.

Updates are downloaded **and applied** daily (the packaged timer fires at 06:00
with an hour of jitter, and `Persistent=true` catches up after a machine that
was powered off). The system is never rebooted automatically — that stays a
deliberate act. This only ever upgrades *within* the installed Fedora release;
it cannot start a version upgrade.

`dnf-automatic.timer` also exists, but it is a symlink to `dnf5-automatic.timer`
rather than a second timer, so systemd treats them as one unit under two names.
The role acts on the real unit; `systemctl is-enabled dnf-automatic.timer`
reporting `alias` is expected.

Results go to the journal:

```bash
journalctl -u dnf5-automatic.service
systemctl list-timers dnf5-automatic.timer
```

## Linting

```bash
ansible-lint
```

The repo is clean at ansible-lint's `production` profile.
