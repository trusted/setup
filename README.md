# Trusted Setup

Bootstraps a developer machine with the baseline tools required to work on Trusted projects.

**Supported platforms:** macOS · Ubuntu · Omarchy

## What it installs

- **Package management** — Homebrew (macOS), apt (Ubuntu), pacman/yay (Omarchy)
- **git** — version control
- **gh** — GitHub CLI (+ authenticates with GitHub)
- **mise** — version manager for Ruby, Node, etc.
- **Ruby** — latest stable via mise (global default for `bin/setup` scripts)
- **Node.js** — LTS via mise (global default)
- **Yarn** — via corepack (ships with Node.js)
- **op** — 1Password CLI for secrets management
- **CircleCI CLI** — CI/CD pipeline management
- **Build essentials** — compilers and headers for native extensions
- **Docker** — container runtime
- **Docker Compose** — multi-container orchestration
- **Colima** — container runtime for macOS (macOS only)
- **AWS CLI** — Amazon Web Services CLI (no auth configured)
- **AWS VPN Client** — VPN client for AWS
- **Private registries** — Bundler and Yarn credentials for private packages

## Quick start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/setup/main/setup.sh)"
```

Then clone and set up any project:

```bash
gh repo clone trusted/<project>
cd <project> && bin/setup
```

## Re-running

The script is idempotent. Run it again at any time to ensure your tools are up to date and apply new migrations.

Locally from the cloned repo at `~/Work/setup`:

```bash
bash ~/Work/setup/setup.sh
```

Via curl (fetches latest from GitHub):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/setup/main/setup.sh)"
```


## Diagnosing your environment

Run `doctor.sh` at any time to check that all expected tools are installed and no migrations are pending. It never changes anything — only reports:

```bash
bash ~/Work/setup/doctor.sh
```

## Migrations

One-time environment changes are tracked as migration scripts in `migrations/`. They run automatically at the end of setup and are only executed once per machine.

To re-run a specific migration:

```bash
bash ~/Work/setup/setup.sh --rerun <timestamp>
```

## How it works

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full design document.
