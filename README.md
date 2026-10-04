# dotfiles

My macOS dotfiles: zsh + powerlevel10k, tmux, Homebrew packages, and coding-agent config. [pi](https://www.npmjs.com/package/@earendil-works/pi-coding-agent) is the primary agent; Claude Code is also configured.

## Install

```bash
git clone https://github.com/riccardo-larosa/dotfiles.git ~/Projects/github/dotfiles
cd ~/Projects/github/dotfiles
./install.sh
```

The install script symlinks everything to `$HOME` and backs up any existing files to `~/.dotfiles_backup/`.

On a fresh machine, do things in this order:

1. Install Homebrew, then `brew bundle --file=Brewfile`.
2. Install the rest of the [prerequisites](#prerequisites) (oh-my-zsh, plugins, uv, nvm, pi).
3. `./install.sh`, then open a new shell.
4. Restore pi's packages: `pi update --extensions`. If you use herdr, also `herdr integration install pi`. See [pi](#pi).
5. Restore agent skills (see [Agent skills](#agent-skills-agents)).
6. `./doctor.sh` to confirm everything is wired up.

## Health check

```bash
./doctor.sh            # all checks; exit 1 if anything fails
./install.sh --check   # just the symlinks
```

`doctor.sh` checks that every link points into the repo (and flags files that replaced a link, which is how a tool rewriting a linked config file shows up), looks for dangling skill links, confirms the things `.zshrc` sources unguarded exist, checks pi's packages are installed on disk, runs `brew bundle check`, validates the JSON and shell syntax, and scans tracked files for secrets and credential or local-only files. It prints failures (`✗`, exit 1) and warnings (`!`, exit 0). It writes nothing, apart from Homebrew's own cache.

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
- pi — `npm i -g @earendil-works/pi-coding-agent` (needs Node; installs under the active nvm version)
- `jq` (used by `claude/statusline-command.sh`, `doctor.sh` and skill restore). macOS 15+ ships one; on older macOS run `brew install jq`

## What's included

| File | Purpose |
|------|---------|
| `zsh/.zshrc` | Main shell config — oh-my-zsh, p10k, lazy nvm, uv |
| `zsh/.zprofile` | PATH additions loaded at login |
| `zsh/.p10k.zsh` | Powerlevel10k theme config |
| `.aliases` | Shared aliases (navigation, git, ls, etc.) |
| `.functions` | Shell functions (`cdf` — cd to Finder window) |
| `.tmux.conf` | tmux prefix remapped to C-a, mouse, 256 colors |
| `pi/` | pi settings and local extensions, symlinked into `~/.pi/agent` (see [pi](#pi)) |
| `agents/` | Agent skills manifest `.skill-lock.json` (see below) |
| `claude/` | Claude Code config, symlinked into `~/.claude` (secondary, see below) |
| `NOTICES.md` | Provenance and license notices for third-party files |
| `Brewfile` | Homebrew packages (`brew bundle`) |
| `AGENTS.md` / `CLAUDE.md` | Repo map and conventions for AI assistants (`CLAUDE.md` imports `AGENTS.md`) |
| `.gitignore` | Keeps `.DS_Store`, `.claude/settings.local.json`, secrets out of git |
| `install.sh` | Symlinks dotfiles to $HOME (`--check` verifies without changing anything) |
| `doctor.sh` | Read-only health check: links, prerequisites, config, repo hygiene |

## pi

`install.sh` links these into `~/.pi/agent/`:

| Repo file | What it is |
|-----------|------------|
| `pi/settings.json` | Packages, default and enabled models, theme, shell |
| `pi/extensions/context-status.ts` | Context-window bar on its own footer line |
| `pi/extensions/statusline-pi.ts` | Custom footer: dir, branch, context, tok/s, cost, tool count, idle time, model. Adapted from luongnv89/pi-extensions, see [`NOTICES.md`](NOTICES.md) |

Extensions are linked one file at a time because `~/.pi/agent/extensions/` also holds `herdr-agent-state.ts`, which herdr generates and overwrites.

**Packages.** `pi/settings.json` declares them, and pi installs them itself:

- `npm:@plannotator/pi-extension`
- `https://github.com/davebcn87/pi-autoresearch`

On a new machine run `pi update --extensions`. I tested this against a directory holding only `settings.json`: pi installed both packages. Plannotator depends on `node-pty`, and npm warns that its install script isn't approved yet; I haven't verified plannotator runs after a restore.

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

`~/.agents/skills` is the source for skills shared by pi and Claude Code (`~/.claude/skills/*` and `~/.pi/agent/skills/*` are symlinks into it).

Every skill in there is third-party (obra/superpowers, mattpocock/skills, herdrdev/herdr, ...), so none are vendored. Only the manifest, `agents/.skill-lock.json`, is tracked; `install.sh` links it. It records each skill's source repo.

Restore on a new machine:

```bash
jq -r '.skills | to_entries[] | "\(.value.source) \(.key)"' ~/.agents/.skill-lock.json |
  while read -r src name; do npx -y skills add "$src" -g -a codex -s "$name" -y </dev/null; done
```

- `-a codex` is deliberate. Codex reads `~/.agents/skills` directly, so this installs only there. Without `-a`, the CLI symlinks every skill into ~60 other agents' dotdirs under `~/`. `-a claude-code` and `-a pi` write to `~/.claude/skills` and `~/.pi` instead.
- `</dev/null` is required, otherwise `npx` swallows the loop's input and only the first skill installs.
- **Restore is not a pin.** `skills add` installs the latest upstream version, not the one in `skillFolderHash`, so restored skills can differ from the ones you had.
- To expose a skill to Claude Code, symlink it: `ln -s ../../.agents/skills/<name> ~/.claude/skills/<name>`.
- Add a new skill with `npx skills add <repo> -g -a codex -s <name> -y`; the CLI updates the lock file (it writes through the symlink), then commit the change.

## Claude Code (also configured)

Secondary to pi. `install.sh` links `claude/settings.json`, `statusline-command.sh`, `usage-aggregator.py` and the skills in `claude/skills/` into `~/.claude`.

Not tracked: history, sessions, telemetry, caches, installed plugins (re-installed from `enabledPlugins` in `settings.json`), `hooks/herdr-agent-state.sh` (herdr overwrites it; reinstall with `herdr integration install claude`), and third-party skills (`mcp-builder`, `visual-explainer`, etc.).

Provenance and license notices for the skills in `claude/skills/` are in [`NOTICES.md`](NOTICES.md).

`claude/settings.json` has `/Users/riccardo.larosa` paths in `env.PATH`, the hook, and the statusline command. Edit them on a machine with a different username.

## Legacy (not actively used)

- `bash/` — old bash prompt and profile
- `sublime/` — Sublime Text settings
- `iterm/` — iTerm2 color scheme
