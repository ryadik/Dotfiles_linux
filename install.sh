#!/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ASTRO_NVIM_CONFIG_DIR="$DOTFILES_DIR/neovim/.config/nvim"

log_info()    { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
log_warn()    { echo -e "\033[0;33m[WARN]\033[0m $1"; }
log_error()   { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

log_info "Starting Linux dotfiles installation..."

# --- 1. System packages ---
log_info "Installing system packages..."
sudo apt update
sudo apt install -y \
  zsh git tmux curl wget stow fzf ripgrep fd-find \
  build-essential unzip figlet lolcat || log_error "apt install failed"

# bat: named batcat on Ubuntu/Debian
if ! command_exists bat; then
  sudo apt install -y bat 2>/dev/null || sudo apt install -y batcat 2>/dev/null
  if command_exists batcat && ! command_exists bat; then
    mkdir -p ~/.local/bin
    ln -sf "$(which batcat)" ~/.local/bin/bat
    log_success "bat symlinked from batcat"
  fi
fi

# fd: named fdfind on Ubuntu/Debian
if ! command_exists fd && command_exists fdfind; then
  mkdir -p ~/.local/bin
  ln -sf "$(which fdfind)" ~/.local/bin/fd
  log_success "fd symlinked from fdfind"
fi

# zoxide
if ! command_exists zoxide; then
  log_info "Installing zoxide..."
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# --- 2. eza ---
if ! command_exists eza; then
  log_info "Installing eza..."
  EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep tag_name | cut -d'"' -f4)
  wget -qO /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
  tar xzf /tmp/eza.tar.gz -C /tmp eza
  sudo mv /tmp/eza /usr/local/bin/eza && rm /tmp/eza.tar.gz
  log_success "eza ${EZA_VERSION} installed"
fi

# --- 3. lazygit ---
if ! command_exists lazygit; then
  log_info "Installing lazygit..."
  LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep tag_name | cut -d'"' -f4 | sed 's/v//')
  wget -qO /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
  tar xzf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo mv /tmp/lazygit /usr/local/bin/lazygit && rm /tmp/lazygit.tar.gz
  log_success "lazygit ${LG_VERSION} installed"
fi

# --- 4. neovim ---
nvim_needs_install() {
  ! command_exists nvim && return 0
  local ver major minor
  ver=$(nvim --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+')
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  # require >= 0.11.0 (AstroNvim requirement)
  [ "$major" -gt 0 ] || [ "$minor" -ge 11 ] && return 1
  return 0
}
if nvim_needs_install; then
  log_info "Installing neovim (latest stable)..."
  NVIM_VERSION=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" | grep tag_name | cut -d'"' -f4)
  wget -qO /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  sudo tar xzf /tmp/nvim.tar.gz -C /opt/
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm /tmp/nvim.tar.gz
  log_success "neovim ${NVIM_VERSION} installed"
fi

# --- 5. Antigen ---
if [ ! -f ~/.antigen/antigen.zsh ]; then
  log_info "Installing Antigen..."
  mkdir -p ~/.antigen
  curl -L git.io/antigen > ~/.antigen/antigen.zsh
  log_success "Antigen installed"
fi

# --- 6. Set zsh as default shell ---
ZSH_PATH=$(which zsh)
if [ "$SHELL" != "$ZSH_PATH" ]; then
  log_info "Setting zsh as default shell..."
  if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
  fi
  chsh -s "$ZSH_PATH" || log_warn "chsh failed — run manually: chsh -s $(which zsh)"
fi

# --- 7. AstroNvim template ---
if [ ! -d "$ASTRO_NVIM_CONFIG_DIR" ] || [ -z "$(ls -A "$ASTRO_NVIM_CONFIG_DIR" 2>/dev/null)" ]; then
  log_info "Cloning AstroNvim template..."
  git clone --depth 1 https://github.com/AstroNvim/template "$ASTRO_NVIM_CONFIG_DIR" || log_error "Failed to clone AstroNvim"
  rm -rf "$ASTRO_NVIM_CONFIG_DIR/.git"
  log_success "AstroNvim cloned"
else
  log_warn "AstroNvim config already exists — skipping clone"
fi

# --- 8. Make scripts executable ---
chmod +x "$DOTFILES_DIR/tmux/tmux_ws.sh" 2>/dev/null
chmod +x "$DOTFILES_DIR/zsh/zsh-aliases" 2>/dev/null

# --- 9. Stow dotfiles ---
log_info "Stowing dotfiles..."
stow --restow --target="$HOME" --dir="$DOTFILES_DIR" git tmux zsh neovim || log_error "stow failed"
log_success "Dotfiles stowed"

log_success "Done! Run: exec zsh"
