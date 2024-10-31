HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=3000
setopt autocd
bindkey -e
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify
setopt share_history
setopt extended_history
unsetopt beep
export EDITOR=nvim
export VISUAL=nvim
export FZF_DEFAULT_OPTS="--height 50% --reverse --border-label ' fzf ' --border --prompt '⚡  '"

eval "#(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun completions
[ -s "/home/thedevelophantom/.bun/_bun" ] && source "/home/thedevelophantom/.bun/_bun"

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# deno
fpath+=${ZDOTDIR:-~}/.zsh_functions
. "/home/phantom/.deno/env"

fpath=(~/.zsh $fpath)
autoload -Uz compinit
compinit -u

# php
export PATH="/home/phantom/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/phantom/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

# GO
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"


# Android SDK
export ANDROID_HOME="/home/phantom/Android/Sdk"
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

# sesh (session manager)
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


# Search history with fzf
bindkey '^R' fzf-history-widget

fzf-history-widget() {
  BUFFER=$(fc -l 1 | awk '{$1=""; print substr($0,2)}' | fzf --height 40% --reverse --border --preview 'echo {}')
  CURSOR=$#BUFFER
  zle reset-prompt
}

zle -N fzf-history-widget


#alias 

#git alias
alias g='git'
alias gs='git status'
alias lg='lazygit'
alias gcb='git checkout -b'

#npm alias
alias n='npm'
alias ns='npm start'
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nis='npm install --save'
alias nes="npx expo start"


alias c='clear'
alias d='docker'

alias v="nvim"
alias vim="nvim"

alias zed="zeditor"

# list all java versions ==> archlinux-java status
# setting java version ==> sudo archlinux-java set (version)


# google-cloud-sdk
export PATH="$PATH:/home/phantom/google-cloud-sdk/bin/"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/phantom/google-cloud-sdk/path.zsh.inc' ]; then . '/home/phantom/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/phantom/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/phantom/google-cloud-sdk/completion.zsh.inc'; fi


# Project Count Down

# Define the project_countdown function
project_countdown() {
    # Check if the current directory is a project directory
    if [ ! -f .deadline ]; then
        return  # Exit if there's no .deadline file
    fi

    # Read the deadline details from the .deadline file
    while IFS=": " read -r key value; do
        case "$key" in
            due_date)
                deadline="$value"
                ;;
            project_name)
                project_name="$value"
                ;;
            priority)
                priority="$value"
                ;;
        esac
    done < .deadline
    
    # Calculate days remaining
    days_left=$(( ( $(date -d "$deadline" +%s) - $(date +%s) ) / 86400 ))

    # Define colors
    RESET="\033[0m"
    GREEN="\033[32m"
    RED="\033[31m"
    YELLOW="\033[33m"
    BLUE="\033[34m"

    # Output the countdown message with appropriate coloring
    if (( days_left >= 0 )); then
        echo -e "${GREEN}🗓️ Project '$project_name' (Priority: $priority) deadline in ${days_left} days.${RESET}"
    else
        echo -e "${RED}⚠️ Project '$project_name' (Priority: $priority) deadline passed $(( -days_left )) days ago!${RESET}"
    fi
}

# Automatically call project_countdown when changing directories
chpwd() {
    project_countdown
}

# Call project_countdown initially if a .deadline file exists in the starting directory
if [ -f .deadline ]; then
    project_countdown
fi