# dotfiles
Lots of goodies collected over the years around the web. 
I tried to keep the names and links in the comments when possible.

## Prerequisites 
* [homebrew](https://brew.sh/) 
* upgrade mac OSX bash to latest: `brew install bash`
* coreutils: `brew install coreutils`
* bash_completion (remember to check permissions): `brew install bash-completion`
* hub completion: `brew install hub`
* git bash prompt: `brew install bash-git-prompt`

In latest MacOS Catalina 10.15.7+ the default shell is zsh so after installing homebrew
* oh-my-zsh with ```sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"```
* install [Powerlevel10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh)
* install [Menlo LGS Fonts](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k) 
* run ```p10k configure```
* install [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh)
* install [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md)
* in .zshrc add/edit ```plugins=( git zsh-syntax-highlighting zsh-autosuggestions)```

