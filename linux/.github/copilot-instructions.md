# Copilot Instructions for workstation-ansible

This repository contains Ansible playbooks and roles for provisioning Fedora
workstations. It was previously a set of [Comtrya](https://comtrya.dev)
manifests; Comtrya is unmaintained and the port is complete — do not add new
Comtrya recipes.

## Target Systems

**Fedora on x86_64, and nothing else.** Ubuntu/Linux Mint/Debian support has
been deliberately removed. Do not reintroduce `apt`, `.deb` handling, PPAs, or
`ansible_distribution` branches for Debian-family systems. Assume `dnf`, RPM
packaging, glibc, and Fedora package names (`vim-enhanced`, not `vim`).

## Repository Structure

Standard Ansible layout:

```
ansible.cfg          # inventory, roles_path, output formatting
bootstrap.sh         # installs ansible-core/ansible-lint/collections
inventory.ini        # [workstations] -> localhost ansible_connection=local
group_vars/all/      # shared variables
playbooks/           # workstation.yml + functional subdirectories
roles/<role>/        # defaults/ files/ handlers/ meta/ tasks/ templates/
```

Every role gets a matching single-role playbook in the appropriate functional
subdirectory under `playbooks/`, and is added to `playbooks/workstation.yml`
in the correct order.

## Conventions

### Naming

- Role directories are `snake_case` (`zen_browser`, not `zen-browser`) to
  satisfy ansible-lint's `role-name` rule. Playbook filenames match the role.
- Variables defined in a role must be prefixed with the role name
  (`rust_rustup_home`, `zen_browser_flatpak`) per `var-naming[no-role-prefix]`.
  Variables shared across roles belong in `group_vars/all/`.
- Play and task names start with a capital letter (`name[casing]`).

### Privilege Escalation

`become` is off by default in `ansible.cfg`. Playbooks run as the workstation
user and set `become: true` only on the individual tasks that need root. Run
playbooks with `-K`. Never write a role that assumes it runs wholly as root.

### Packages

Use `ansible.builtin.dnf`. Prefer a real repository (`yum_repository` +
`rpm_key`) over downloading a one-off `.rpm`, so `dnf upgrade` keeps things
current. Use `disable_gpg_check: true` only for release RPMs that ship their
own key (RPM Fusion) or upstream GitHub release artifacts.

### Containers

Rootless **Podman**, never Docker. No root daemon, no `docker` group. A
Docker-compatible socket is exposed via `DOCKER_HOST` for tools that only
speak the Docker API.

### Idempotency

Comtrya's `command.run` ran unconditionally; Ansible equivalents must not.
Guard `command`/`shell` with `creates:`, a preceding `stat`, or a read of
current state (`gsettings get` before `gsettings set`). Read-only probe tasks
should set `changed_when: false` **and** `check_mode: false` so `--check` runs
evaluate their conditionals correctly.

Prefer real modules over shelling out: `get_url` over `curl`, `unarchive` over
`tar`, `template` over `jq` merges, `blockinfile` over appending with `cat`.

### Shell Integration

Roles that need shell setup drop a single file into `~/.bashrc.d/` and depend
on the `bashrcd` role via `meta/main.yml`. Do not append to `~/.bashrc`
directly. Note that Fedora's stock `~/.bashrc` already sources `~/.bashrc.d`,
so `bashrcd` only adds the loop when it is actually missing.

### Comments

Explain *why*, not *what* — especially where a Fedora quirk, an upstream bug,
or a deliberate deviation from the obvious approach drove the implementation.

## Validation

```bash
ansible-lint                                     # must stay clean (production profile)
ansible-playbook --syntax-check playbooks/<area>/<p>.yml
ansible-playbook playbooks/<area>/<p>.yml -K --check --diff
```
