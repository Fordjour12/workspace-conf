# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=3000
setopt autocd extendedglob notify
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/thedevelophantom/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# ZSH_THEME="candy" or clean

plugin=(git zsh-autosuggestions)
source=$ZSH/oh-my-zsh.sh

#ZSH_THEME="robbyrussell"
ZSH_THEME="awesomepanda"


# Android SDK
export ANDROID_HOME=/home/thedevelophantom/Android/Sdk
export PATH=$PATH:ANDROID_HOME/platforms/
export PATH=$PATH:ANDROID_HOME/platform-tools/
export PATH=$PATH:ANDROID_HOME/cmdline-tools/latest/
export PATH=$PATH:ANDROID_HOME/emulator


# INTELIJ IDEA
export PATH="$PATH:/usr/local/idea-IC/bin"

# GO PATH
export PATH="$PATH:/usr/local/go/bin"
# GOBIN
export PATH="$PATH:$HOME/go/bin"

#/usr/local/flutter
export PATH="$PATH:/usr/local/flutter/bin"
#flutter alias
alias f='flutter'
alias fd='flutter doctor'
alias fp='flutter pub'
alias fpa='flutter pub add'
alias fpu='flutter pub upgrade'
alias fpg='flutter pub get'

#git alias
alias g='git'
alias gs='git status'
alias lg='lazygit'

#npm alias
alias n='npm'
alias ns='npm start'
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nis='npm install --save'
alias nes="npx expo start"

alias pr='pnpm dev'

alias c='clear'

alias d='docker'

alias v="nvim"  
alias vim="nvim"

alias rofi="rofi -show run"
alias spotify="flatpak run com.spotify.Client"

function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list | fzf --height 60% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

#FVM
export PATH="$PATH":"$HOME/.pub-cache/bin"

eval "$(zoxide init --cmd cd zsh)"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

eval "$(starship init zsh)"

eval "#(fzf --zsh)"

# bun completions
[ -s "/home/thedevelophantom/.bun/_bun" ] && source "/home/thedevelophantom/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

fpath+=${ZDOTDIR:-~}/.zsh_functions
export PATH=$HOME/.local/bin:$PATH