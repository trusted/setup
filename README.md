# Trusted Dev Setup

Bootstraps a developer machine with the baseline tools required to work on Trusted projects.

**Supported platforms:** MacOS · Ubuntu · Omarchy

## What it installs

- **package management** 
  - homebrew for MacOS 
  - apt updates for Ubuntu 
  - pacman/yay updates for Omarchy
- **git** — version control
- **gh** — GitHub CLI (+ authenticates with GitHub)
- **mise** — version manager for Ruby, Node, etc.
- **Ruby** — latest stable via mise (global default for `bin/setup` scripts)
- **op** — 1Password CLI for secrets management
- **Build essentials** — compilers and headers for native extensions
- **Docker** — container runtime
- **Docker Compose** — multi-container orchestration
- **Colima** — container runtime for macOS (macOS only)
- **AWS CLI** — Amazon Web Services CLI (no auth configured)
- **AWS VPN Client** — VPN client for AWS

## Quick start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/devsetup/main/setup.sh)"
```

Then clone and set up any project:

```bash
gh repo clone trusted/<project>
cd <project> && bin/setup
```

## Re-running

The script is idempotent. Run it again at any time to ensure your tools are up to date and apply new migrations.

Locally from the cloned repo at `~/Work/devsetup`:

```bash
bash ~/Work/devsetup/setup.sh
```

Via curl (fetches latest from GitHub):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/devsetup/main/setup.sh)"
```


## Diagnosing your environment

Run `doctor.sh` at any time to check that all expected tools are installed and no migrations are pending. It never changes anything — only reports:

```bash
bash ~/Work/devsetup/doctor.sh
```

## Migrations

One-time environment changes are tracked as migration scripts in `migrations/`. They run automatically at the end of setup and are only executed once per machine.

To re-run a specific migration:

```bash
bash ~/Work/devsetup/setup.sh --rerun <timestamp>
```

## How it works

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full design document.
