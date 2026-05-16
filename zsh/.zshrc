# --- Antigen ---
source ~/.antigen/antigen.zsh

antigen use oh-my-zsh
antigen theme robbyrussell

antigen bundles <<EOBUNDLES
  git
  marlonrichert/zsh-autocomplete
  command-not-found
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  hlissner/zsh-autopair
EOBUNDLES

antigen apply

# --- Zoxide ---
eval "$(zoxide init zsh)"

# --- Custom PATH ---
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"

# --- Editor ---
export EDITOR='nvim'

# --- Neovim ---
alias vim="nvim"
alias v="nvim"

# --- Tmux ---
alias tls="tmux ls"
alias tos="tmux attach -t"
alias tns="tmux new -s"
alias trs="tmux rename-session -t"
alias tks="tmux kill-session -t"
alias tws="${LINUX_DOTFILES_DIR:-$HOME/.dotfiles/linux}/tmux/tmux_ws.sh"

# --- Git ---
alias g="git"
alias gst="git status -sb"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gpom="git push origin master"
alias gpo="git push origin"
alias glog="git log --pretty=format:'%C(yellow)%h%C(reset) %C(green)%ar%C(reset) %C(bold blue)%an%C(reset) %C(red)%d%C(reset) %s' --graph --abbrev-commit --decorate"
alias gd="git diff"
alias gap="git add -p"
alias gaa="git add ."
alias gc="git commit"
alias gb="git branch"
alias gba="git branch -a"
alias gbd="git branch -D"
alias gca="git commit --amend"
alias gmc='git ls-files --unmerged | cut -f2 | uniq'
alias glh="git log --oneline | head -n 20"
alias grv="git remote -v"
alias gfo="git fetch origin"
alias gclr="git reset HEAD --hard ; git clean -fd"
alias gz="git archive -o snapshot.zip HEAD"
alias gt="git archive -o snapshot.tar.gz HEAD"
alias grp="git remote prune origin"
alias grhh="git reset HEAD --hard"
alias gsh="git stash"
alias gshp="git stash pop"
alias gconf="git config"
alias gconfL="git config --local"
alias g-set-local-pers-cred="gconfL user.name \"ryadik\" && gconfL user.email \"15162342h@gmail.com\""

# --- File System ---
alias ls="eza -a --icons"
alias ll="eza -al --icons --git"
alias tree="eza -T --icons"
alias lt="ll -a --tree --level=2 --git"
alias cat="bat --paging=never"
alias cat_p="bat"

# --- Lazygit ---
alias lg="lazygit"

# --- Dotfiles ---
alias dfs="stow --restow --target=$HOME --dir=${LINUX_DOTFILES_DIR:-$HOME/.dotfiles/linux} git tmux zsh neovim"
alias zsh-aliases="${LINUX_DOTFILES_DIR:-$HOME/.dotfiles/linux}/zsh/zsh-aliases"

# --- Zsh config ---
COMPLETION_WAITING_DOTS="true"
DEFAULT_USER="${USER}"
BAT_THEME="Visual Studio Dark+"
ENABLE_CORRECTION="true"

function reload() {
  echo "zsh reloading..."
  exec zsh
}

# Fuzzy file finder → open in nvim
f() {
  local selected
  selected=$(fd --type f --type d --hidden --follow --exclude ".git" . | fzf \
    --height 100% --layout=default --border=rounded --marker='✓' --pointer='►' \
    --color='fg:#c0caf5,bg:#1a1b26,hl:#bb9af7,fg+:#c0caf5,bg+:#292e42,hl+:#bb9af7,info:#7dcfff,prompt:#7dcfff,pointer:#7dcfff,marker:#bb9af7,preview-bg:#1f2335,border:#7dcfff' \
    --preview-window='right,55%,border-rounded' \
    --preview 'if [ -d {} ]; then eza -l --tree --git --git-ignore --color=always --icons=always --level=3 {}; else bat --style=numbers,changes --color=always --line-range :500 {}; fi' \
    --bind "ctrl-c:execute(tmux set-buffer {})+abort" \
    --header "ENTER: Open in nvim | CTRL-C: Copy path to tmux buffer")

  [ -n "$selected" ] && nvim $(echo "$selected" | tr '\n' ' ')
}

# Live ripgrep search → open in nvim at matched line
fr() {
  local selected
  selected=$(fzf --height 100% --layout=default --border=rounded --marker='✓' --pointer='►' --ansi \
    --color='fg:#c0caf5,bg:#1a1b26,hl:#bb9af7,fg+:#c0caf5,bg+:#292e42,hl+:#bb9af7,info:#7dcfff,prompt:#7dcfff,pointer:#7dcfff,marker:#bb9af7,preview-bg:#1f2335,border:#7dcfff' \
    --preview-window='right,55%,border-rounded,+{2}-10' \
    --header "Live content search — start typing..." \
    --prompt '> ' --delimiter ':' \
    --preview 'bat --style=numbers,changes --color=always --highlight-line {2} {1}' \
    --bind "change:reload:rg --hidden --column --line-number --no-heading --color=always --smart-case {q} . || true")

  if [ -n "$selected" ]; then
    local file=$(echo "$selected" | cut -d: -f1)
    local line=$(echo "$selected" | cut -d: -f2)
    nvim "+$line" "$file"
  fi
}
