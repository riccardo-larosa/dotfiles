# dotfiles

My macOS dotfiles: zsh + powerlevel10k, [herdr](https://herdr.dev) for terminal workspaces, Homebrew packages, and coding-agent config. [pi](https://www.npmjs.com/package/@earendil-works/pi-coding-agent) is the primary agent; Claude Code is also configured.

## Install

```bash
git clone https://github.com/riccardo-larosa/dotfiles.git ~/Projects/github/dotfiles
cd ~/Projects/github/dotfiles
./install.sh
```

The install script symlinks everything to `$HOME` and backs up any existing files to `~/.dotfiles_backup/`.

On a fresh machine, do things in this order:

1. Install Homebrew, then `brew bundle --file=Brewfile`.
2. Install the rest of the [prerequisites](#prerequisites) (oh-my-zsh, plugins, uv, nvm, herdr, pi).
3. `./install.sh`, then open a new shell.
4. Restore pi's packages: `pi update --extensions`. Then `herdr integration install pi` (and `claude` if you use it). See [pi](#pi) and [herdr](#herdr).
5. Restore agent skills with `skills-update`. If `doctor.sh` says Codex doesn't load superpowers, run `/plugins` in `codex` and install it (see [Agent skills](#agent-skills-agents)).
6. `./doctor.sh` to confirm everything is wired up.

## Health check

```bash
./doctor.sh            # all checks; exit 1 if anything fails
./install.sh --check   # just the symlinks
```

`doctor.sh` checks that every link points into the repo (and flags files that replaced a link, which is how a tool rewriting a linked config file shows up), looks for dangling skill links, confirms the things `.zshrc` sources unguarded exist, checks herdr (on PATH, `herdr config check`, agent integrations) and pi's packages on disk, runs `brew bundle check`, validates the JSON and shell syntax, and scans tracked files for secrets and credential or local-only files. It prints failures (`✗`, exit 1) and warnings (`!`, exit 0). It writes nothing, apart from Homebrew's own cache.

It reads the link list from `install.sh`, so a new `link` line is checked automatically.

## Prerequisites

- [Homebrew](https://brew.sh/), then install packages with `brew bundle --file=Brewfile`
- [Oh My Zsh](https://ohmyz.sh/) — `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh)
- [MesloLGS Nerd Font](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md)
- [uv](https://docs.astral.sh/uv/getting-started/installation/) (Python)
- [nvm](https://github.com/nvm-sh/nvm#installing-and-updating) (Node)
- [herdr](https://herdr.dev) — `curl -fsSL https://herdr.dev/install.sh | sh` (or `brew install herdr`). This machine uses the installer, which puts the binary in `~/.local/bin` and self-updates with `herdr update`. Use one method only: `~/.local/bin` comes before Homebrew on PATH, so the installer copy would shadow a brew one
- pi — `npm i -g @earendil-works/pi-coding-agent` (needs Node; installs under the active nvm version)
- `jq` (used by `claude/statusline-command.sh`, `doctor.sh` and skill restore). macOS 15+ ships one; on older macOS run `brew install jq`

## What's included

| File | Purpose |
|------|---------|
| `zsh/.zshrc` | Main shell config — oh-my-zsh, p10k, lazy nvm, uv |
| `zsh/.zprofile` | PATH additions loaded at login |
| `zsh/.p10k.zsh` | Powerlevel10k theme config |
| `.aliases` | Shared aliases (navigation, git, ls, etc.) |
| `.functions` | Shell functions (`cdf` — cd to Finder window, `skills-update` — install or update agent skills) |
| `herdr/` | herdr config, symlinked into `~/.config/herdr` (see [herdr](#herdr)) |
| `pi/` | pi settings and local extensions, symlinked into `~/.pi/agent` (see [pi](#pi)) |
| `agents/` | Agent skills: the `.skill-lock.json` manifest and our own skills in `skills/` (see below) |
| `claude/` | Claude Code config, symlinked into `~/.claude` (secondary, see below) |
| `NOTICES.md` | Provenance and license notices for third-party files |
| `Brewfile` | Homebrew packages (`brew bundle`) |
| `AGENTS.md` / `CLAUDE.md` | Repo map and conventions for AI assistants (`CLAUDE.md` imports `AGENTS.md`) |
| `.gitignore` | Keeps `.DS_Store`, `.claude/settings.local.json`, secrets out of git |
| `install.sh` | Symlinks dotfiles to $HOME (`--check` verifies without changing anything) |
| `doctor.sh` | Read-only health check: links, prerequisites, config, repo hygiene |

## herdr

[herdr](https://herdr.dev) is the terminal workspace manager for the agents (workspaces, tabs, panes, agent state). It replaces tmux.

`install.sh` links `herdr/config.toml` into `~/.config/herdr/`. herdr writes that file itself (`herdr config reset-keys` edits it), and it writes through the symlink, so commit any diffs. Validate it with `herdr config check`; `doctor.sh` does this for you.

Not tracked: everything else in `~/.config/herdr/` is runtime state (sockets, logs, `session.json`, `session-snapshots/`, `release-notes.json`).

The integrations that report agent state are generated, not tracked. Run `herdr integration install pi` and `herdr integration install claude`. They write `~/.pi/agent/extensions/herdr-agent-state.ts` and `~/.claude/hooks/herdr-agent-state.sh`, and herdr overwrites both on update.

**tmux was dropped.** Its config is in git history (tag `v0.4-pi-first` and earlier). The tmux binary is still installed; remove it with `brew uninstall tmux`. The old config remapped the prefix to `C-a`; that has not been carried over to herdr.

## pi

`install.sh` links these into `~/.pi/agent/`:

| Repo file | What it is |
|-----------|------------|
| `pi/settings.json` | Packages, default and enabled models, theme, shell |
| `pi/AGENTS.md` | Global instructions for every project. It tells pi to read and apply the unslop skill |
| `pi/extensions/context-status.ts` | Context-window bar on its own footer line |
| `pi/extensions/statusline-pi.ts` | Custom footer: dir, branch, context, tok/s, cost, tool count, idle time, model. Adapted from luongnv89/pi-extensions, see [`NOTICES.md`](NOTICES.md) |

Extensions are linked one file at a time because `~/.pi/agent/extensions/` also holds `herdr-agent-state.ts`, which herdr generates and overwrites.

**Packages.** `pi/settings.json` declares them, and pi installs them itself:

- `npm:@plannotator/pi-extension`
- `https://github.com/davebcn87/pi-autoresearch`
- `git:github.com/obra/superpowers` (see [Agent skills](#agent-skills-agents))

On a new machine run `pi update --extensions`. I tested this against a directory holding only `settings.json`: pi installed both packages. Superpowers was added later and hasn't been through that test. Plannotator depends on `node-pty`, and npm warns that its install script isn't approved yet; I haven't verified plannotator runs after a restore.

`pi list` also installs any missing declared package as a side effect, so use it for inspection only when you're fine with that. `doctor.sh` checks the package directories on disk instead.

**herdr extension.** `herdr integration install pi` generates `extensions/herdr-agent-state.ts`. It is not tracked.

**settings.json is a live file.** pi writes it when you change models or add or remove packages, and it writes through the symlink (I tested this: the link survives). Those changes show up as diffs in this repo, so commit them. pi re-orders `packages` when it re-adds one.

**Never tracked:**

- `auth.json`: credentials.
- `trust.json`: your project paths.
- `models-store.json`, `sessions/`, `npm/`, `git/`, `bin/`: runtime state and restorable installs.
- `models.json`: your local llama.cpp provider. It has no secrets, but it's machine-specific.

pi also reads skills from `~/.agents/skills`; see below.

## Agent skills (`~/.agents`)

Every skill lives in one place, `~/.agents/skills`. pi and Codex read it directly. Claude Code reads only `~/.claude/skills`, so each skill gets a symlink there. `~/.pi/agent/skills` stays empty, because links there would duplicate what pi already reads. `doctor.sh` checks all three.

| Skills | Source | How they get into `~/.agents/skills` |
|---|---|---|
| Third-party (mattpocock/skills, herdrdev/herdr, cursor/plugins, anthropics/skills, ...) | `agents/.skill-lock.json` records each source repo. Contents are not vendored | `skills-update` |
| Our own | `agents/skills/` in this repo. Provenance is in [`NOTICES.md`](NOTICES.md) | `install.sh` links each one into `~/.agents/skills` and `~/.claude/skills` |

Restore or update third-party skills with `skills-update` from `.functions`:

```bash
skills-update            # install or update every skill in the lock file
skills-update unslop     # just the named skills
```

It runs `npx -y skills add <source> -g -a codex claude-code -s <name> -y` for each lock entry. The CLI installs the skill into `~/.agents/skills` and links it into `~/.claude/skills`. It also rewrites `skillFolderHash` in the lock file, so commit the diff after an update.

- Add a new skill with `npx skills add <repo> -g -a codex claude-code -s <name> -y`, then commit the lock diff (the CLI writes through the symlink).
- Always pass `-a codex claude-code`. `codex` installs into `~/.agents/skills`, and `claude-code` adds the link. Without `-a`, the CLI links into every agent it detects. On this machine that means extra links in `~/.pi/agent/skills`. Cursor, Gemini, Copilot and opencode read `~/.agents/skills`, so the CLI writes nothing for them.
- Don't use `npx skills update`. It reinstalls with `-g -y` and no `-a`, with the result above.
- `</dev/null` is required, otherwise `npx` swallows the loop's input and only the first skill installs.
- **Restore is not a pin.** `skills add` installs the latest upstream version, not the one in `skillFolderHash`, so restored skills can differ from the ones you had.

**Superpowers is not in the lock.** It ships a plugin for each agent, and each plugin adds a startup hook that loads `using-superpowers` into every session. The pi package also tells the model which pi tools replace Claude's `Skill`, `Task` and `TodoWrite`. Install it per agent:

- Claude Code: `superpowers@superpowers-marketplace` in `enabledPlugins` (`claude/settings.json`).
- pi: `git:github.com/obra/superpowers` in `pi/settings.json`. `pi update --extensions` restores it.
- Codex: run `/plugins` inside `codex` and install Superpowers. That installs it on your ChatGPT account. `codex plugin add superpowers@openai-curated` looks equivalent but doesn't work. Codex loads catalog plugins from the account (`remote_plugin` feature) and ignores the local install. The catalog copy I saw was 5.1.0 (upstream is 6.4.2) and had no startup hook.

Each agent updates its own copy. `doctor.sh` checks all three and warns if superpowers skills show up in the lock, where they would load twice.

**unslop is applied through global instructions.** It comes from [cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop) and sets `disable-model-invocation: true`, so pi and Claude Code don't load it on their own. `pi/AGENTS.md` tells pi to read it, and `claude/CLAUDE.md` imports it with `@~/.agents/skills/unslop/SKILL.md`. Both point at the installed copy, so `skills-update unslop` is the only upkeep.

## Claude Code (also configured)

Secondary to pi. `install.sh` links `claude/settings.json`, `CLAUDE.md` (global instructions), `statusline-command.sh` and `usage-aggregator.py` into `~/.claude`. Skills come from `~/.agents/skills` (see [Agent skills](#agent-skills-agents)).

Not tracked: history, sessions, telemetry, caches, installed plugins (re-installed from `enabledPlugins` in `settings.json`), `hooks/herdr-agent-state.sh` (herdr overwrites it; reinstall with `herdr integration install claude`), and `skills/synced/`. Claude Code keeps your claude.ai account skills there and rewrites the folder on sync, so they stay Claude-only.

`claude/settings.json` has no machine-specific paths. The herdr hook and the statusline command use `$HOME` (both run through a shell).

`env.PATH` is Homebrew plus system directories only. Claude passes `env` values through literally, so `$HOME` and `~` do not work there and it cannot name nvm or `~/.local/bin`. Claude's subprocesses therefore get Homebrew's `node@24` (declared in the `Brewfile`), not the nvm default.

`doctor.sh` warns if a `/Users/` path creeps back in. herdr regenerates its hook entry and may re-add an absolute path when its integration is reinstalled.

## Legacy (not actively used)

- `bash/` — old bash prompt and profile
- `sublime/` — Sublime Text settings
- `iterm/` — iTerm2 color scheme
