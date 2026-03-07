#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  devconfig — .bashrc                                        ║
# ║  Integrates: tmux • Neovim • gtags • fzf • starship         ║
# ╚══════════════════════════════════════════════════════════════╝
# Source this from your ~/.bashrc:
#   [ -f ~/.devconfig/bashrc.bash ] && source ~/.devconfig/bashrc.bash

# ─── Guard: interactive only ─────────────────────────────────
[[ $- != *i* ]] && return

# ═════════════════════════════════════════════════════════════
#  1. ENVIRONMENT
# ═════════════════════════════════════════════════════════════

# Editor
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim

# Pager (use less with colors)
export PAGER="less"
export LESS="-R -F -X --mouse --wheel-lines=3"
export LESSHISTFILE="$HOME/.cache/lesshst"

# Man pages colored via less
export LESS_TERMCAP_mb=$'\e[1;31m'    # begin bold
export LESS_TERMCAP_md=$'\e[1;36m'    # begin blink (section headers)
export LESS_TERMCAP_me=$'\e[0m'       # end mode
export LESS_TERMCAP_so=$'\e[1;44;33m' # begin standout (status line)
export LESS_TERMCAP_se=$'\e[0m'       # end standout
export LESS_TERMCAP_us=$'\e[1;32m'    # begin underline
export LESS_TERMCAP_ue=$'\e[0m'       # end underline

# Locale
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# XDG (keep home dir clean)
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# GNU Global — multi-language gtags via pygments
export GTAGSLABEL=native-pygments

# PATH
_prepend_path() { [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }
_prepend_path "$HOME/.local/bin"
_prepend_path "$HOME/.cargo/bin"
_prepend_path "$HOME/go/bin"
_prepend_path "$HOME/.npm-global/bin"
_prepend_path "/usr/local/go/bin"
unset -f _prepend_path
export PATH

# ═════════════════════════════════════════════════════════════
#  2. SHELL OPTIONS
# ═════════════════════════════════════════════════════════════

# Better defaults
shopt -s checkwinsize     # Update LINES/COLUMNS after each command
shopt -s globstar         # ** matches recursively
shopt -s nocaseglob       # Case-insensitive globbing
shopt -s cdspell          # Auto-correct minor cd typos
shopt -s dirspell         # Auto-correct dir names during completion
shopt -s autocd           # Type dir name to cd into it
shopt -s cmdhist          # Multi-line commands as single history entry
shopt -s histappend       # Append to history, don't overwrite
shopt -s expand_aliases   # Expand aliases in non-interactive

# ═════════════════════════════════════════════════════════════
#  3. HISTORY — Shared across sessions, deduplicated
# ═════════════════════════════════════════════════════════════

HISTCONTROL=ignoreboth:erasedups    # No dupes, no leading-space commands
HISTIGNORE="?:??:exit:clear:cls:ls:ll:la:cd:pwd:bg:fg:history"
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT="%F %T  "            # Timestamps in history

# Share history across concurrent tmux panes / sessions
_devconfig_history_sync() {
    history -a   # Append current session to history file
    history -n   # Read new entries from history file
}
# Append to PROMPT_COMMAND without overwriting
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_devconfig_history_sync"

# ═════════════════════════════════════════════════════════════
#  4. COMPLETION
# ═════════════════════════════════════════════════════════════

# Load bash completion (if available)
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Better tab completion behavior
bind 'set show-all-if-ambiguous on'          # Show all matches immediately
bind 'set show-all-if-unmodified on'         # Show matches without second tab
bind 'set completion-ignore-case on'         # Case-insensitive
bind 'set colored-stats on'                  # Colored file type indicators
bind 'set mark-symlinked-directories on'     # Trailing / on symlinked dirs
bind 'set colored-completion-prefix on'      # Color the common prefix
bind 'set visible-stats on'                  # Append file type indicator
bind 'set skip-completed-text on'            # No duplication on completion

# Git completion
if [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
    __git_complete g __git_main
fi

# ═════════════════════════════════════════════════════════════
#  5. FZF — Fuzzy finder integration
# ═════════════════════════════════════════════════════════════

# fzf defaults (Catppuccin Mocha colors to match tmux/nvim)
export FZF_DEFAULT_OPTS=" \
  --height 60% --layout=reverse --border=rounded --margin=0,1 \
  --info=inline-right --prompt='  ' --pointer='▶' --marker='✓' \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --bind='ctrl-y:execute-silent(echo -n {+} | xclip -selection clipboard)+abort' \
  --bind='ctrl-/:toggle-preview' \
  --bind='ctrl-d:half-page-down,ctrl-u:half-page-up' \
"

# Use fd for file finding (respects .gitignore)
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v fdfind &>/dev/null; then
    # Debian/Ubuntu names it fdfind
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
fi

# File preview with bat (if available), else head
if command -v bat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {}' --preview-window=right:50%:wrap"
elif command -v batcat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'batcat --style=numbers --color=always --line-range :300 {}' --preview-window=right:50%:wrap"
else
    export FZF_CTRL_T_OPTS="--preview 'head -100 {}' --preview-window=right:50%:wrap"
fi

# Directory preview with tree
export FZF_ALT_C_OPTS="--preview 'tree -C -L 2 {}' --preview-window=right:50%"

# History search preview
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=up:3:hidden:wrap --bind='ctrl-/:toggle-preview'"

# Load fzf keybindings and completion
# Ctrl+T: paste file path  |  Ctrl+R: history search  |  Alt+C: cd to dir
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash 2>/dev/null)" || {
        # Fallback for older fzf versions
        [ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
        [ -f /usr/share/fzf/completion.bash ]   && source /usr/share/fzf/completion.bash
        [ -f ~/.fzf.bash ] && source ~/.fzf.bash
    }
fi

# ═════════════════════════════════════════════════════════════
#  6. ALIASES — Developer workflow
# ═════════════════════════════════════════════════════════════

# ── Editor ───────────────────────────────────────────────────
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias sv='sudo -E nvim'                    # Sudo nvim preserving env

# ── Navigation ───────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'                          # cd to previous dir

# ── Listing (use eza/exa if available, else enhanced ls) ─────
if command -v eza &>/dev/null; then
    alias ls='eza --icons=auto --group-directories-first'
    alias ll='eza -alh --icons=auto --group-directories-first --git'
    alias la='eza -a --icons=auto --group-directories-first'
    alias lt='eza --tree --level=3 --icons=auto --group-directories-first'
    alias ltg='eza --tree --level=3 --icons=auto --group-directories-first --git-ignore'
elif command -v exa &>/dev/null; then
    alias ls='exa --icons --group-directories-first'
    alias ll='exa -alh --icons --group-directories-first --git'
    alias la='exa -a --icons --group-directories-first'
    alias lt='exa --tree --level=3 --icons --group-directories-first'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -AlhF --color=auto'
    alias la='ls -A --color=auto'
fi

# ── Cat replacement (bat) ────────────────────────────────────
if command -v bat &>/dev/null; then
    alias cat='bat --style=plain --paging=never'
    alias catn='bat'                       # Full bat with line numbers
elif command -v batcat &>/dev/null; then
    alias cat='batcat --style=plain --paging=never'
    alias catn='batcat'
fi

# ── Grep (always colorize) ──────────────────────────────────
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ── Disk / system ────────────────────────────────────────────
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='ss -tulnp'
alias psg='ps aux | grep -v grep | grep -i'

# ── Safety nets ──────────────────────────────────────────────
alias rm='rm -I'                           # Confirm before removing 3+ files
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# ── tmux ─────────────────────────────────────────────────────
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new-session -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'
alias td='tmux detach'

# Auto-attach to 'dev' session or create it
tdev() {
    tmux has-session -t dev 2>/dev/null && tmux attach -t dev || tmux new-session -s dev
}

# ── Git ──────────────────────────────────────────────────────
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias glog='git log --oneline --graph --decorate -20'
alias gloga='git log --oneline --graph --decorate --all -30'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gst='git stash'
alias gstp='git stash pop'
alias gbl='git blame -w -C -C -C'         # Ignore whitespace, detect moves

# ── gtags (pairs with nvim gutentags) ────────────────────────
alias gtgen='gtags --gtagslabel=native-pygments'     # Generate tags in cwd
alias gtup='global -u'                               # Update tags
alias gtfind='global -x'                             # Find definition
alias gtref='global -rx'                             # Find references
alias gtgrep='global -gx'                            # Grep pattern
alias gtfiles='global -P'                            # List indexed files

# ── Docker (if available) ────────────────────────────────────
if command -v docker &>/dev/null; then
    alias dk='docker'
    alias dkps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
    alias dkimg='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"'
    alias dklog='docker logs -f'
    alias dkex='docker exec -it'
    alias dkprune='docker system prune -af --volumes'
fi

if command -v docker-compose &>/dev/null || docker compose version &>/dev/null 2>&1; then
    alias dc='docker compose'
    alias dcup='docker compose up -d'
    alias dcdown='docker compose down'
    alias dclogs='docker compose logs -f'
fi

# ── Kubernetes (if available) ────────────────────────────────
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias klog='kubectl logs -f'
    alias kex='kubectl exec -it'
fi

# ═════════════════════════════════════════════════════════════
#  7. FUNCTIONS — Developer utilities
# ═════════════════════════════════════════════════════════════

# ── fzf-powered file opener in nvim ──────────────────────────
fv() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || head -200 {}')
    [[ -n "$file" ]] && nvim "$file"
}

# ── fzf-powered ripgrep → nvim at line ───────────────────────
# Usage: rg-edit "pattern" or just frg
frg() {
    local result
    result=$(rg --color=always --line-number --no-heading "${@:-.}" |
        fzf --ansi --delimiter ':' \
            --preview 'bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}' \
            --preview-window='right:60%:+{2}/3')
    if [[ -n "$result" ]]; then
        local file line
        file=$(echo "$result" | cut -d: -f1)
        line=$(echo "$result" | cut -d: -f2)
        nvim "+$line" "$file"
    fi
}

# ── fzf-powered git log browser ──────────────────────────────
fgl() {
    git log --oneline --graph --color=always --decorate --all |
        fzf --ansi --no-sort --reverse --tiebreak=index \
            --preview 'git show --color=always $(echo {} | grep -oE "[a-f0-9]{7,}" | head -1)' \
            --bind 'enter:execute(git show --color=always $(echo {} | grep -oE "[a-f0-9]{7,}" | head -1) | less -R)'
}

# ── fzf-powered git branch checkout ──────────────────────────
fbr() {
    local branch
    branch=$(git branch -a --color=always | grep -v HEAD |
        fzf --ansi --preview 'git log --oneline --graph --color=always $(echo {} | sed "s/.* //" | sed "s#remotes/origin/##")' |
        sed 's/.* //' | sed 's#remotes/origin/##')
    [[ -n "$branch" ]] && git checkout "$branch"
}

# ── fzf-powered process killer ───────────────────────────────
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header='Select process(es) to kill' | awk '{print $2}')
    [[ -n "$pid" ]] && echo "$pid" | xargs kill -${1:-9}
}

# ── Quick project navigation ─────────────────────────────────
# Jump to project dirs (configure PROJECT_DIRS to your layout)
PROJECT_DIRS=("$HOME/projects" "$HOME/src" "$HOME/work" "$HOME/repos")

proj() {
    local dir
    dir=$(for d in "${PROJECT_DIRS[@]}"; do
        [[ -d "$d" ]] && find "$d" -maxdepth 2 -name ".git" -type d 2>/dev/null | xargs -I{} dirname {}
    done | sort -u | fzf --preview 'tree -C -L 2 {}')
    [[ -n "$dir" ]] && cd "$dir" && echo "→ $(pwd)"
}

# ── mkcd: create dir and cd into it ─────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }

# ── extract: universal archive extractor ─────────────────────
extract() {
    if [ ! -f "$1" ]; then
        echo "Error: '$1' is not a file" >&2
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1"   ;;
        *.tar.gz)  tar xzf "$1"   ;;
        *.tar.xz)  tar xJf "$1"   ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1"   ;;
        *.rar)     unrar x "$1"   ;;
        *.gz)      gunzip "$1"    ;;
        *.tar)     tar xf "$1"    ;;
        *.tbz2)    tar xjf "$1"   ;;
        *.tgz)     tar xzf "$1"   ;;
        *.zip)     unzip "$1"     ;;
        *.Z)       uncompress "$1";;
        *.7z)      7z x "$1"     ;;
        *)         echo "Error: cannot extract '$1'" >&2; return 1 ;;
    esac
}

# ── Quick server: serve current dir over HTTP ────────────────
serve() {
    local port="${1:-8000}"
    echo "Serving $(pwd) on http://0.0.0.0:$port"
    python3 -m http.server "$port"
}

# ── Weather ──────────────────────────────────────────────────
weather() { curl -s "wttr.in/${1:-}?format=3"; }

# ═════════════════════════════════════════════════════════════
#  8. TMUX AUTO-ATTACH
#  If we're on SSH and tmux is available, offer to attach
# ═════════════════════════════════════════════════════════════

if [[ -n "$SSH_CONNECTION" ]] && command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
    # Count existing sessions
    local session_count
    session_count=$(tmux list-sessions 2>/dev/null | wc -l)
    if [[ "$session_count" -gt 0 ]]; then
        echo -e "\033[0;36m tmux sessions available:\033[0m"
        tmux list-sessions 2>/dev/null
        echo -e "\033[0;36m  Run 'ta <name>' to attach, or 'tdev' for dev session\033[0m"
    fi
fi

# ═════════════════════════════════════════════════════════════
#  9. ZOXIDE — Smart directory jumper (if installed)
#     Replaces cd with intelligent directory jumping
#     Usage: z <partial-dir-name> to jump anywhere
# ═════════════════════════════════════════════════════════════

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash --cmd cd)"
fi

# ═════════════════════════════════════════════════════════════
#  10. STARSHIP PROMPT
#      Falls back to a built-in prompt if starship isn't installed
# ═════════════════════════════════════════════════════════════

if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
else
    # Fallback: informative colored prompt
    # Shows: user@host:~/path (git-branch) $
    _devconfig_parse_git() {
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --always 2>/dev/null)
        [[ -n "$branch" ]] && echo " ($branch)"
    }

    if [[ "$EUID" -eq 0 ]]; then
        PS1='\[\e[1;31m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0;33m\]$(_devconfig_parse_git)\[\e[0m\] \[\e[1;31m\]#\[\e[0m\] '
    else
        PS1='\[\e[1;32m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0;33m\]$(_devconfig_parse_git)\[\e[0m\] \$ '
    fi
fi

# ═════════════════════════════════════════════════════════════
#  11. LOCAL OVERRIDES
#      Put machine-specific config in ~/.bashrc.local
# ═════════════════════════════════════════════════════════════

[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
