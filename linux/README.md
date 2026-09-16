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

On a machine running face authentication, `pam_gaze` runs ahead of sudo's
password prompt, and a scan that fails costs anywhere from a fraction of a
second (camera busy) to around eight seconds (no face found).
`inventory.ini` raises `ansible_local_become_success_timeout` to absorb the
slow case; without it, escalating tasks intermittently fail as `UNREACHABLE`
with *Timed out waiting for become success*.

**Always pass `-K`.** It is tempting to warm a sudo timestamp first and drop
the flag, but that is a trap: Fedora scopes timestamps per tty
(`timestamp_type=tty`) and expires them after five minutes, so a long run
outlives its own credential. When the timestamp lapses mid-run, sudo
prompts, Ansible has no password to answer with, and `pam_gaze` fails on the
retry — surfacing as *Duplicate become password prompt encountered* rather
than a prompt anyone can respond to. With `-K`, a failed face scan simply
falls through to the password Ansible is already holding.

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
| `binsider` | Installs [binsider](https://github.com/orhun/binsider) for analysing ELF binaries |
| `bitwarden` | Installs Bitwarden from Flathub |
| `bottom` | Installs [bottom](https://github.com/ClementTsang/bottom) from the latest upstream release RPM |
| `calibre` | Installs the Calibre e-book library manager |
| `catppuccin_gnome_terminal` | Installs the Catppuccin GNOME Terminal profiles and defaults to Mocha |
| `discord` | Installs Discord from Flathub |
| `dnf_automatic` | Applies package updates unattended on a daily timer |
| `flatpak` | Installs Flatpak and enables the system-wide Flathub remote |
| `firefox` | Installs Firefox and force-installs Bitwarden and uBlock Origin |
| `gaze` | Installs [Gaze](https://github.com/GunduLabs/gaze) face authentication for the KDE lock screen, sudo and polkit |
| `git` | Installs Git and configures the user identity |
| `github_cli` | Installs GitHub CLI from Fedora's package repository |
| `github_copilot_cli` | Installs the native GitHub Copilot CLI |
| `github_copilot_app` | Installs the GitHub Copilot desktop app from GitHub's release RPM |
| `gitui` | Installs the [gitui](https://github.com/gitui-org/gitui) terminal UI for Git |
| `golang` | Installs the latest Go toolchain into `/usr/local/go` |
| `herdr` | Installs the [herdr](https://github.com/herdrdev/herdr) coding-agent runtime and the Omarchy keybinding profile |
| `jetbrains_mono` | Installs the JetBrainsMono Nerd Font |
| `jq` | Installs jq |
| `just` | Installs the [just](https://github.com/casey/just) command runner |
| `kde_launchers` | Pins Steam, Spotify, Discord, Bitwarden and Edge to the KDE Task Manager |
| `kde_orthocal` | Installs the Orthocal Plasma widget immediately left of the clock |
| `microsoft_edge` | Installs Microsoft Edge Stable, Bitwarden and uBlock Origin |
| `nerd_fonts_hack` | Installs Hack Nerd Font and sets it as the desktop monospace font |
| `no_notifications` | Disables GNOME event sounds |
| `nvm` | Installs Node Version Manager and Bash integration |
| `onedrive` | Syncs one or more OneDrive accounts, each as its own systemd user service |
| `onedrive_tray` | Builds [onedrive_tray](https://github.com/DanielBorgesOliveira/onedrive_tray) and supervises each OneDrive account from the system tray |
| `podman` | Installs **rootless** Podman and exposes a Docker-compatible socket |
| `ripgrep` | Installs [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) |
| `rpmfusion` | Enables the RPM Fusion free and nonfree repositories |
| `rust` | Installs Rust via rustup and keeps toolchains updated |
| `shellcheck` | Installs ShellCheck for linting this repo's shell scripts |
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
| `voxtype` | Installs [Voxtype](https://github.com/peteonrails/voxtype) voice-to-text with a KDE toggle shortcut |
| `wallpaper_randomizer` | Selects a random KDE wallpaper at startup and every 15 minutes |
| `wezterm` | Installs [WezTerm](https://wezterm.org) and its Lua configuration |
| `ydotool` | Runs the ydotool daemon so dictated text can be typed into the focused window |
| `yt_dlp` | Installs [yt-dlp](https://github.com/yt-dlp/yt-dlp) for downloading media |
| `zen_browser` | Installs [Zen Browser](https://zen-browser.app) to `/opt/zen` |
| `zen_browser_extensions` | Downloads extension XPIs into the Zen install |
| `zen_browser_policies` | Renders Zen's `policies.json` enterprise policy |
| `zsa_keyboard` | Installs udev rules so Oryx can flash ZSA keyboards from the browser |

## Role Dependencies

Declared in each role's `meta/main.yml`, so the single-role playbooks are
correct on their own. Ansible de-duplicates shared dependencies within a run.

```
starship, golang, rust, podman, zen_browser  ->  bashrcd
nvm                                           ->  git, bashrcd
kde_orthocal                                  ->  git, workstation
kde_launchers                                 ->  steam, spotify, discord, bitwarden, microsoft_edge
herdr                                         ->  workstation
voxtype                                       ->  workstation, ydotool
ydotool                                       ->  workstation
github_copilot_app                            ->  git
gitui                                         ->  git
starship, wezterm                            ->  nerd_fonts_hack
bitwarden, discord, spotify                  ->  flatpak
steam                                        ->  rpmfusion
surface_dial                                 ->  workstation
onedrive                                     ->  workstation
onedrive_tray                                ->  onedrive
zsa_keyboard                                 ->  workstation
zen_browser_extensions, zen_browser_policies -> zen_browser
wallpaper_randomizer                         -> workstation
jetbrains_mono                               -> workstation
```

## Manual Steps

Provisioning cannot complete these, so the roles prompt for them instead.

- **Gaze face enrolment.** Enrolment drives the webcam from an interactive
  prompt, so the `gaze` role only installs and wires up face authentication.
  Run `gaze add-face` (or use the Gaze GUI) to enrol a face; the playbook
  prints a reminder whenever the current user has none. Until a face exists
  every Gaze prompt falls through to the password stack.
- **Voxtype dictation.** Recording is push-to-talk on `ScrollLock`: hold to
  dictate, release to transcribe. Voxtype watches the keyboard directly
  through evdev rather than using a KDE global shortcut, because KWin emits
  no key-release events and a compositor shortcut could therefore only
  toggle. Reading evdev requires the `input` group, which the role grants —
  but group membership only applies to sessions started afterwards, so **log
  out and back in once** before the hotkey works. Set
  `voxtype_kde_shortcut_enabled: true` (with `voxtype_hotkey_mode: toggle`)
  to fall back to a `Meta+Shift+V` binding instead.

  Transcribed text is typed by **ydotool**, not `wtype`. KWin does not
  implement `virtual-keyboard-unstable-v1` for ordinary clients, so `wtype`
  fails with *Compositor does not support the virtual keyboard protocol* on
  every attempt and the text only ever reaches the clipboard. ydotool creates
  a virtual keyboard in the kernel through `/dev/uinput`, which the
  compositor cannot refuse. The clipboard remains the last driver in
  `voxtype_output_drivers`, so nothing is lost if injection fails.
- **OneDrive sign-in.** Authorisation is an interactive browser sign-in, so
  the `onedrive` role sets up the configuration and the service but cannot
  complete the sign-in itself. Run `setup-onedrive-personal.sh`, which signs
  in, runs an initial sync and enables the service. See
  [OneDrive](#onedrive).

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

## GitHub Copilot App

A desktop client for agent-driven development, built on Copilot CLI. Despite
the `github-app` path in its marketing URL, this is a native Tauri
application and not the OAuth integration GitHub also calls a GitHub App.

GitHub publishes no dnf repository and no GPG key for it — only release
assets on `github/app` — so the role pins a version and fetches the RPM
directly, installing with `disable_gpg_check` because the package is shipped
unsigned. Upstream's Tauri updater only offers the AppImage for Linux, so an
RPM install has no working in-app update path: bump
`github_copilot_app_version` to upgrade.

The download is around 460 MB and expands to roughly 1.3 GB, so the role
skips it entirely when the pinned version is already installed and deletes
the downloaded RPM afterwards.

It needs GTK3 and WebKitGTK 4.1, both current in Fedora 44. If Fedora retires
`webkit2gtk4.1` before upstream ships a GTK4 build, this breaks.

## OneDrive

Microsoft ships no OneDrive client for Linux, so this uses
[abraunegg/onedrive](https://github.com/abraunegg/onedrive) — a third-party
reimplementation against the Graph API, packaged by Fedora as `onedrive`.

Each account gets its own configuration directory, local sync directory and
systemd user service. Only a personal account is configured:

| Account | Configuration | Syncs to | Service |
| --- | --- | --- | --- |
| `personal` | `~/.config/onedrive-personal` | `~/OneDrive` | `onedrive-tray@personal.service` |

The per-account plumbing is kept even with a single account, because it costs
nothing and adding a second is then just another list entry. Neither unit the
package ships can do this: `onedrive.service` is hardcoded to a single
configuration directory, and the packaged `onedrive@.service` is a *system*
unit instanced by **user name** — it solves "many users, one account each",
not "one user, many accounts". The role therefore installs its own template
unit into `~/.config/systemd/user/onedrive@.service` that derives the
configuration directory from the instance name, so one unit file serves any
number of accounts.

### System tray

The client has no UI of its own, so `onedrive_tray` provides one: a tray icon
showing sync status, with start, stop, force-sync and "open folder" actions,
and a progress window on a left click.

The important thing to understand is that **the tray is a supervisor, not a
viewer**. It starts its own `onedrive` child and drives the icon by parsing
that child's output — it never talks to systemd. Since the client refuses to
run a second instance against the same configuration directory, the tray and
`onedrive@<account>.service` cannot both run. Exactly one supervisor is
enabled per account, chosen by `onedrive_supervisor` in
`group_vars/all/onedrive.yml`:

| Value | Unit | Runs |
| --- | --- | --- |
| `client` | `onedrive@<account>.service` | The client directly. Headless; needs no desktop session. |
| `tray` | `onedrive-tray@<account>.service` | `onedrive_tray`, which starts the client itself. Needs a graphical session. |

This workstation uses `tray`. Whichever role runs stops and disables the other
supervisor, so flipping the value and re-applying is enough to switch; the
tray unit also declares `Conflicts=onedrive@%i.service` so systemd refuses the
combination even if something enables both by hand.

The tray unit is ordered `PartOf=graphical-session.target` — it starts with the
desktop session and stops with it, rather than being left as an orphan at
logout.

Upstream ships no releases, no packages and nothing on Flathub, so the role
compiles it from a pinned commit with Qt 5. The commit it was built from is
recorded in `/usr/local/share/onedrive_tray/commit`, which is what keeps a
normal run from recompiling; bump `onedrive_tray_version` to rebuild.

> [!NOTE]
> The tray needs a system tray to dock into and exits when it finds none. It
> is therefore only useful in a desktop session — on a headless machine set
> `onedrive_supervisor: client`.

### Signing in

Authorisation is an interactive sign-in and cannot be automated. Note that
**no account name or email appears anywhere in the configuration** — the
client has no such option. A configuration directory binds to whichever
identity you sign in as, and stays bound to it. Getting the right account is
therefore entirely down to the sign-in step.

The role installs a helper per account that performs the sign-in, runs an
initial sync and enables the service once it succeeds:

```bash
setup-onedrive-personal.sh
```

A personal account (`@outlook.com`, `@hotmail.com`, any MSA) has to use
browser sign-in — Microsoft blocks the device-code flow for personal accounts
on unapproved applications. The browser reuses whatever Microsoft session it
already holds, so it can bind a different account without asking. If that
happens, rebind using a browser with no Microsoft session:

```bash
setup-onedrive-personal.sh --reauth --browser firefox
```

Confirm it bound to the account you expected — the sign-in output reports the
account type and drive:

```text
Account Type:         personal
Default Drive ID:     <drive-id>
```

The client writes a `refresh_token` into the configuration directory when this
succeeds. The role treats that file as the marker that an account is ready and
**only enables the service for accounts that have it** — an instance with no
token exits immediately, and systemd's start rate limiting would otherwise
leave the unit failed. The helper enables the service itself; re-running the
playbook does the same thing:

```bash
ansible-playbook playbooks/applications/onedrive_tray.yml -K
```

Accounts still waiting on a sign-in are named in the playbook output.

Check on a running account with:

```bash
systemctl --user status onedrive-tray@personal.service
journalctl --user -u onedrive-tray@personal.service -f
```

With `onedrive_supervisor: client`, use `onedrive@personal.service` in both
commands instead.

### Configuring accounts

`onedrive_accounts` defines the list. Adding an account, or changing where one
syncs to, needs nothing beyond this variable:

```yaml
onedrive_accounts:
  - name: personal
    sync_dir: "{{ workstation_home }}/OneDrive"
  - name: archive
    sync_dir: "{{ workstation_home }}/OneDrive - Archive"
    options:
      download_only: true
```

`options` accepts any key from the client's configuration file — see
`/usr/share/doc/onedrive/config` for the full list — and is merged over
`onedrive_common_options`. Only the options set here are written out, so the
generated config stays reviewable instead of being a copy of the shipped
example with one line changed.

Each account listed gets its own `setup-onedrive-<name>.sh` helper.

### Selective sync

By default the client downloads the **entire** drive. An account can instead
list the paths it wants in `sync_list`, which the role writes into the
account's configuration directory:

```yaml
onedrive_accounts:
  - name: personal
    sync_dir: "{{ workstation_home }}/OneDrive"
    sync_list:
      - /Books/
      - /Gaming/
    options:
      sync_root_files: true
```

Things worth knowing before relying on it:

- **It excludes everything it does not list**, and an exclusion always beats
  an inclusion. Omitting `sync_list` entirely syncs the whole drive; the role
  only writes the file for accounts that define one, because an empty file
  would sync nothing at all.
- **Anchor the rules.** `/Books/` is matched as a path. A bare `Books` makes
  the client scan every folder, online and local, looking for that name — the
  most expensive form of rule there is.
- **Loose files in the drive root match no rule.** `sync_root_files` covers
  them, and saves amending `sync_list` (and resyncing) each time one appears.
- **Filtering is client-side.** Graph supports no server-side selective sync,
  so the client still enumerates the whole remote tree on every run. What is
  saved is the file transfers, not the enumeration — expect the initial
  "nothing is happening" phase regardless.
- **Changes need a full resynchronisation** before they take effect. The
  playbook detects a changed `sync_list` and prints the command rather than
  running it, since a resync is heavy and prompts for confirmation:

```bash
setup-onedrive-personal.sh --resync
```

> [!NOTE]
> A resync is not destructive locally: anything that falls out of scope is
> left on disk untouched, simply no longer synchronised. Reclaim that space by
> deleting the excluded folders by hand. Local files that are *not* excluded
> by a rule but are missing online are treated as new content and uploaded.

> [!NOTE]
> Removing an account from `onedrive_accounts` stops it being configured, but
> does not stop or disable a service that is already running, nor remove its
> configuration directory, sync directory or helper script. Clean those up by
> hand:
> ```bash
> systemctl --user disable --now onedrive@<account>.service onedrive-tray@<account>.service
> rm -rf ~/.config/onedrive-<account> ~/.local/bin/setup-onedrive-<account>.sh
> ```

### Work or school accounts

A **work or school account is not configured**, because authorising one
against a Microsoft tenant did not succeed. Many tenants apply Conditional
Access policies that block unapproved third-party applications, and the
device-code flow specifically, in which case sign-in fails regardless of how
the client is configured — a tenant policy decision rather than something this
role can work around.

If this is revisited, the options are, in rough order of likelihood:

- `use_intune_sso: true` — authenticates through the Microsoft Identity
  Broker on an Intune-enrolled machine. Needs `microsoft-identity-broker` and
  `intune-portal`, which this repo does not install.
- `application_id: "<guid>"` — point the client at an application
  registration the tenant has approved. The registration needs the redirect
  URIs `http://127.0.0.1:53100/` and
  `https://login.microsoftonline.com/common/oauth2/nativeclient`, or sign-in
  fails with `AADSTS50011`.
- `use_device_auth: true` — sign in with a code at
  <https://microsoft.com/devicelogin> instead of a browser redirect, which
  also avoids binding the wrong account from an existing browser session.
  Valid only for Entra ID accounts; Microsoft blocks this flow for personal
  accounts.

## ZSA Keyboards

The `zsa_keyboard` role installs the udev rules that let
[Oryx](https://configure.zsa.io) flash a Moonlander, Voyager, Ergodox EZ or
Planck EZ from the browser, over WebHID and WebUSB, without running the
browser as root.

ZSA publishes a single `50-zsa.rules` that grants access through the
`plugdev` group. That file is vendored verbatim so it stays easy to re-diff
when ZSA revises it, but `plugdev` is a Debian convention: Fedora ships no
such group, and even once created, membership only applies to sessions
started afterwards. A companion `51-zsa-uaccess.rules` therefore tags the
same devices with systemd's `uaccess`, which `73-seat-late.rules` turns into
an ACL for whoever is logged in at the local seat. Access is granted as soon
as the keyboard appears and revoked at logout, with no group to join and no
re-login required. It is the same mechanism that already grants this user
access to Yubikeys and game controllers.

The bootloader needs its own rule. A Moonlander disconnects mid-flash and
re-enumerates as an STM32 DFU device (`0483:df11`), so a rule matching only
the keyboard's own `3297` vendor ID would cover the handshake but not the
write.

Set `zsa_keyboard_manage_uaccess: false` to follow ZSA's documentation
exactly, at the cost of needing a full logout before flashing works.

Snap-packaged browsers additionally need `sudo snap connect <browser>:raw-usb`.
That does not apply here: Edge is installed from Microsoft's dnf repository
by the `microsoft_edge` role, and this machine has no snap.

## Herdr

The role installs the pinned release binary and an Omarchy-style keybinding
profile using a `ctrl+space` prefix. That prefix deliberately differs from
WezTerm's `ctrl+;` leader: Herdr runs *inside* WezTerm, so a shared prefix
would be swallowed by the terminal and never reach Herdr.

Splits are bound so the keys agree across both tools even though the two name
them under opposite conventions — `v` puts panes side by side, `h` stacks them:

| Result | Herdr | WezTerm |
| --- | --- | --- |
| Side by side | `prefix+v` (`split_vertical`) | `LEADER+v` (`SplitHorizontal`) |
| Stacked | `prefix+h` (`split_horizontal`) | `LEADER+h` (`SplitVertical`) |

`herdr_transparent_background` (default `true`) sets `panel_bg = "reset"`, which
makes Herdr emit the terminal's default background rather than painting its own
— otherwise its chrome would sit on top of WezTerm's translucency and cancel it
out. Set `herdr_transparent_sidebar` to extend that to the sidebar and the
selected-row highlight, which are left opaque by default because they are what
separates the sidebar from the panes.

Config changes apply to a running server with `herdr server reload-config`; no
restart or session loss is involved.

## WezTerm

Upstream publishes no stable Fedora channel — their own Fedora instructions
point at the `wezfurlong/wezterm-nightly` COPR, so that is what the role uses.
Expect it to update often; builds land several times a day, and with
`dnf_automatic` enabled they will be applied on the daily timer.

The configuration goes to `~/.config/wezterm/wezterm.lua`. WezTerm checks that
path *before* `~/.wezterm.lua`, so an old dotfile in `$HOME` cannot shadow it.
WezTerm watches the file and reloads on save, so no restart is needed after the
role updates it.

The window background is translucent (`wezterm_background_opacity`, default
`0.8`). Cells that paint their own background — full-screen TUIs, highlighted
lines, `ls` colours — ignore that setting and follow
`wezterm_text_background_opacity` (default `0.7`) instead; it is held lower
because that layer composites on top of the already translucent window. Both
need a compositor, which Plasma on Wayland provides — without one, WezTerm
simply renders opaque.

Closing a window does not prompt for confirmation. WezTerm's default is to
ask whenever processes are still running, which is almost always — the shell
itself counts — so the prompt fired on nearly every close and restart. Set
`wezterm_confirm_window_close: true` to restore it. Note this governs the
window only: the `LEADER x` pane binding still confirms, since closing one
pane of several is easier to do by accident.

### Default Terminal

The role points KDE at WezTerm, so Dolphin's *Open Terminal* and anything else
going through KIO opens it rather than Konsole. Plasma ships no default of its
own, so without this KIO falls back to Konsole.

Two keys are written to `~/.config/kdeglobals`, because KIO's terminal launcher
prefers `TerminalService` and only falls back to `TerminalApplication` when it
is unset:

| Key | Value |
|-----|-------|
| `TerminalService` | `org.wezfurlong.wezterm.desktop` |
| `TerminalApplication` | `wezterm` |

Only those keys are touched — `kdeglobals` is shared with the rest of Plasma
and rewritten by KDE itself, so templating the whole file would fight it.
Already-running applications keep the old setting until they restart. Set
`wezterm_set_default_terminal: false` to leave the choice alone; Konsole stays
installed either way.

### Remote Multiplexer Domain

The role can declare a WezTerm multiplexer domain that attaches to the *live GUI
session* on another machine, so a local tab renders the same panes someone
sitting at that machine sees, and they survive a local restart. It is off by
default; set `wezterm_mux_host` to enable it:

| Variable | Default | Purpose |
| --- | --- | --- |
| `wezterm_mux_host` | `""` (disabled) | Host to attach to |
| `wezterm_mux_user` | current user | Account to SSH as |
| `wezterm_mux_name` | the host name | Domain name used by `wezterm connect` |

Connect with `wezterm connect <name>`, or press `LEADER+g` to attach from a
running window. Neither the domain nor that keybinding is emitted when no host
is set, because a declared but unreachable domain surfaces as a connection error
every time the domain list is opened.

It works by handing the domain a `proxy_command` instead of a local socket: `ssh
-T` (no pty, which would corrupt the binary mux protocol) runs `wezterm cli
proxy` on the far end. The GUI's socket name embeds its pid, so the newest
`gui-sock-*` is chosen at connect time rather than pinned, and the runtime
directory is resolved remotely via `$XDG_RUNTIME_DIR` rather than assuming a
uid. The remote host needs WezTerm installed and a GUI instance running.

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

### Shell scripts

`ansible-lint` does not look inside shell scripts, and this repo ships a
handful — the bootstrap script, the `~/.bashrc.d` snippets in `roles/*/files/`,
and script templates in `roles/*/templates/`. ShellCheck covers those. It is
installed by `bootstrap.sh` and by the `shellcheck` role, and is packaged by
Fedora as `ShellCheck`, not `shellcheck`.

```bash
shellcheck bootstrap.sh
shellcheck -s bash -e SC1091 roles/*/files/*.sh
```

The two flags on the second command are both needed:

- `-s bash` because the `~/.bashrc.d` snippets are sourced fragments with no
  shebang, which ShellCheck otherwise refuses to classify (SC2148).
- `-e SC1091` because those snippets source files that only exist at runtime
  (`~/.cargo/env`, `~/.nvm/nvm.sh`), which ShellCheck cannot follow at lint
  time. This suppresses an unavoidable *info*, not a real finding.

Shell **templates** (`*.sh.j2`) cannot be checked directly — Jinja control
tags are not valid shell. Check the rendered copy instead, after a playbook
run has written it out:

```bash
shellcheck ~/.local/bin/setup-onedrive-*.sh
```
