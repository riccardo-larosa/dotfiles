# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting virtualenv)
source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR="cursor"

# Source shared dotfiles
[ -f ~/.aliases ] && source ~/.aliases
[ -f ~/.functions ] && source ~/.functions

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# nvm (lazy-loaded for fast shell startup)
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx pnpm
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  nvm "$@"
}
node() { nvm use default >/dev/null 2>&1; unset -f node; node "$@"; }
npm() { nvm use default >/dev/null 2>&1; unset -f npm; npm "$@"; }
npx() { nvm use default >/dev/null 2>&1; unset -f npx; npx "$@"; }
pnpm() { nvm use default >/dev/null 2>&1; unset -f pnpm; pnpm "$@"; }

# PATH additions
export PATH=$PATH:/Applications/Cursor.app/Contents/Resources/app/bin
export PATH=~/.npm-global/bin:$PATH

# uv (Python package manager)
. "$HOME/.local/bin/env"
eval "$(uv generate-shell-completion zsh)"
