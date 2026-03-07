#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  devconfig — Automated Setup for Remote Dev Servers         ║
# ║  NvChad v2.5 + tmux + gtags + smart-splits                 ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./setup.sh              # Full install (interactive)
#   ./setup.sh --all        # Full install (non-interactive, assume yes)
#   ./setup.sh --nvim       # Only Neovim config
#   ./setup.sh --tmux       # Only tmux config
#   ./setup.sh --deps       # Only install dependencies
#   ./setup.sh --uninstall  # Remove everything (with backups)

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/devconfig-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/devconfig-setup-$(date +%Y%m%d-%H%M%S).log"
AUTO_YES=false

# ─── Helpers ─────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[  OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[FAIL]${NC} $*"; }
step()    { echo -e "\n${CYAN}${BOLD}══ $* ══${NC}"; }

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }

confirm() {
    if $AUTO_YES; then return 0; fi
    local msg="${1:-Continue?}"
    echo -en "${YELLOW}${msg} [Y/n] ${NC}"
    read -r reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

cmd_exists() { command -v "$1" &>/dev/null; }

# ─── Detect OS / Package Manager ────────────────────────────
detect_pkg_manager() {
    if cmd_exists apt-get; then
        PKG_MGR="apt"
        PKG_INSTALL="sudo apt-get install -y"
        PKG_UPDATE="sudo apt-get update -qq"
    elif cmd_exists dnf; then
        PKG_MGR="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update || true"
    elif cmd_exists yum; then
        PKG_MGR="yum"
        PKG_INSTALL="sudo yum install -y"
        PKG_UPDATE="true"
    elif cmd_exists pacman; then
        PKG_MGR="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
    elif cmd_exists brew; then
        PKG_MGR="brew"
        PKG_INSTALL="brew install"
        PKG_UPDATE="brew update"
    elif cmd_exists apk; then
        PKG_MGR="apk"
        PKG_INSTALL="sudo apk add"
        PKG_UPDATE="sudo apk update"
    else
        error "No supported package manager found"
        exit 1
    fi
    info "Detected package manager: ${BOLD}$PKG_MGR${NC}"
}

# ─── Backup existing configs ────────────────────────────────
backup_configs() {
    step "Backing up existing configs"
    mkdir -p "$BACKUP_DIR"

    local backed_up=false

    if [ -d "$HOME/.config/nvim" ]; then
        cp -r "$HOME/.config/nvim" "$BACKUP_DIR/nvim"
        success "Backed up ~/.config/nvim"
        backed_up=true
    fi

    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$BACKUP_DIR/tmux.conf"
        success "Backed up ~/.tmux.conf"
        backed_up=true
    fi
    if [ -f "$HOME/.config/tmux/tmux.conf" ]; then
        mkdir -p "$BACKUP_DIR/tmux"
        cp "$HOME/.config/tmux/tmux.conf" "$BACKUP_DIR/tmux/tmux.conf"
        success "Backed up ~/.config/tmux/tmux.conf"
        backed_up=true
    fi

    if [ -f "$HOME/.config/starship.toml" ]; then
        cp "$HOME/.config/starship.toml" "$BACKUP_DIR/starship.toml"
        success "Backed up starship.toml"
        backed_up=true
    fi

    if [ -d "$HOME/.local/share/nvim" ]; then
        info "Neovim data dir exists (will be cleaned for fresh install)"
        backed_up=true
    fi

    if $backed_up; then
        success "Backups saved to: ${BOLD}$BACKUP_DIR${NC}"
    else
        info "No existing configs to back up"
        rm -rf "$BACKUP_DIR"
    fi
}

# ═════════════════════════════════════════════════════════════
#  DEPENDENCY INSTALLATION
# ═════════════════════════════════════════════════════════════
install_deps() {
    step "Installing system dependencies"

    detect_pkg_manager

    info "Updating package index..."
    eval "$PKG_UPDATE" >> "$LOG_FILE" 2>&1

    # ── Core tools ───────────────────────────────────────────
    local core_pkgs=""
    case "$PKG_MGR" in
        apt)
            core_pkgs="git curl wget unzip build-essential"
            ;;
        dnf|yum)
            core_pkgs="git curl wget unzip gcc gcc-c++ make"
            ;;
        pacman)
            core_pkgs="git curl wget unzip base-devel"
            ;;
        brew)
            core_pkgs="git curl wget"
            ;;
        apk)
            core_pkgs="git curl wget unzip build-base"
            ;;
    esac

    info "Installing core tools..."
    eval "$PKG_INSTALL $core_pkgs" >> "$LOG_FILE" 2>&1 || warn "Some core packages may have failed"
    success "Core tools"

    # ── Neovim ───────────────────────────────────────────────
    if ! cmd_exists nvim; then
        info "Installing Neovim..."
        case "$PKG_MGR" in
            apt)
                # Try snap for latest, fallback to apt
                if cmd_exists snap; then
                    sudo snap install nvim --classic >> "$LOG_FILE" 2>&1 && success "Neovim (via snap)" || {
                        eval "$PKG_INSTALL neovim" >> "$LOG_FILE" 2>&1
                        success "Neovim (via apt)"
                    }
                else
                    # Download AppImage as fallback
                    info "Installing Neovim AppImage..."
                    curl -sLo /tmp/nvim.appimage "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage" 2>> "$LOG_FILE"
                    chmod u+x /tmp/nvim.appimage
                    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
                    success "Neovim (AppImage)"
                fi
                ;;
            dnf)
                eval "$PKG_INSTALL neovim" >> "$LOG_FILE" 2>&1
                success "Neovim"
                ;;
            pacman)
                eval "$PKG_INSTALL neovim" >> "$LOG_FILE" 2>&1
                success "Neovim"
                ;;
            brew)
                brew install neovim >> "$LOG_FILE" 2>&1
                success "Neovim"
                ;;
            apk)
                eval "$PKG_INSTALL neovim" >> "$LOG_FILE" 2>&1
                success "Neovim"
                ;;
        esac
    else
        local nvim_ver
        nvim_ver=$(nvim --version | head -1)
        success "Neovim already installed: $nvim_ver"
    fi

    # ── tmux ─────────────────────────────────────────────────
    if ! cmd_exists tmux; then
        info "Installing tmux..."
        case "$PKG_MGR" in
            apt)    eval "$PKG_INSTALL tmux" >> "$LOG_FILE" 2>&1 ;;
            dnf)    eval "$PKG_INSTALL tmux" >> "$LOG_FILE" 2>&1 ;;
            pacman) eval "$PKG_INSTALL tmux" >> "$LOG_FILE" 2>&1 ;;
            brew)   brew install tmux >> "$LOG_FILE" 2>&1 ;;
            apk)    eval "$PKG_INSTALL tmux" >> "$LOG_FILE" 2>&1 ;;
        esac
        success "tmux"
    else
        success "tmux already installed: $(tmux -V)"
    fi

    # ── Search tools ─────────────────────────────────────────
    local search_pkgs=""
    case "$PKG_MGR" in
        apt)    search_pkgs="ripgrep fd-find fzf" ;;
        dnf)    search_pkgs="ripgrep fd-find fzf" ;;
        pacman) search_pkgs="ripgrep fd fzf" ;;
        brew)   search_pkgs="ripgrep fd fzf" ;;
        apk)    search_pkgs="ripgrep fd fzf" ;;
    esac

    info "Installing search tools (ripgrep, fd, fzf)..."
    eval "$PKG_INSTALL $search_pkgs" >> "$LOG_FILE" 2>&1 || warn "Some search tools may need manual install"
    success "Search tools"

    # ── Node.js (for LSP servers) ────────────────────────────
    if ! cmd_exists node; then
        info "Installing Node.js..."
        if cmd_exists curl; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x 2>/dev/null | sudo -E bash - >> "$LOG_FILE" 2>&1
            eval "$PKG_INSTALL nodejs" >> "$LOG_FILE" 2>&1
        else
            eval "$PKG_INSTALL nodejs npm" >> "$LOG_FILE" 2>&1
        fi
        success "Node.js"
    else
        success "Node.js already installed: $(node --version)"
    fi

    # ── Universal Ctags ──────────────────────────────────────
    if ! cmd_exists ctags; then
        info "Installing Universal Ctags..."
        case "$PKG_MGR" in
            apt)    eval "$PKG_INSTALL universal-ctags" >> "$LOG_FILE" 2>&1 ;;
            dnf)    eval "$PKG_INSTALL ctags" >> "$LOG_FILE" 2>&1 ;;
            pacman) eval "$PKG_INSTALL ctags" >> "$LOG_FILE" 2>&1 ;;
            brew)   brew install universal-ctags >> "$LOG_FILE" 2>&1 ;;
            apk)    eval "$PKG_INSTALL ctags" >> "$LOG_FILE" 2>&1 ;;
        esac
        success "Universal Ctags"
    else
        success "Ctags already installed"
    fi

    # ── GNU Global (gtags) ───────────────────────────────────
    if ! cmd_exists gtags; then
        info "Installing GNU Global (gtags)..."
        case "$PKG_MGR" in
            apt)    eval "$PKG_INSTALL global" >> "$LOG_FILE" 2>&1 ;;
            dnf)    eval "$PKG_INSTALL global-ctags" >> "$LOG_FILE" 2>&1 ;;
            pacman) eval "$PKG_INSTALL global" >> "$LOG_FILE" 2>&1 ;;
            brew)   brew install global >> "$LOG_FILE" 2>&1 ;;
            apk)    eval "$PKG_INSTALL global" >> "$LOG_FILE" 2>&1 ;;
        esac
        success "GNU Global"
    else
        success "GNU Global already installed: $(gtags --version | head -1)"
    fi

    # ── Python + Pygments (for multi-language gtags) ─────────
    if ! cmd_exists python3; then
        info "Installing Python3..."
        case "$PKG_MGR" in
            apt)    eval "$PKG_INSTALL python3 python3-pip python3-venv" >> "$LOG_FILE" 2>&1 ;;
            dnf)    eval "$PKG_INSTALL python3 python3-pip" >> "$LOG_FILE" 2>&1 ;;
            pacman) eval "$PKG_INSTALL python python-pip" >> "$LOG_FILE" 2>&1 ;;
            brew)   brew install python >> "$LOG_FILE" 2>&1 ;;
            apk)    eval "$PKG_INSTALL python3 py3-pip" >> "$LOG_FILE" 2>&1 ;;
        esac
    fi

    info "Installing Pygments (multi-language gtags support)..."
    python3 -m pip install --user --quiet pygments 2>> "$LOG_FILE" || \
        pip3 install --user --quiet pygments 2>> "$LOG_FILE" || \
        warn "Pygments install failed — gtags will only support C/C++/Java natively"
    success "Python3 + Pygments"

    # ── Clipboard (for SSH) ──────────────────────────────────
    case "$PKG_MGR" in
        apt)    eval "$PKG_INSTALL xclip" >> "$LOG_FILE" 2>&1 || true ;;
        dnf)    eval "$PKG_INSTALL xclip" >> "$LOG_FILE" 2>&1 || true ;;
        pacman) eval "$PKG_INSTALL xclip" >> "$LOG_FILE" 2>&1 || true ;;
    esac

    # ── Starship prompt ──────────────────────────────────────
    if ! cmd_exists starship; then
        info "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes >> "$LOG_FILE" 2>&1 && \
            success "Starship" || warn "Starship install failed — fallback prompt will be used"
    else
        success "Starship already installed: $(starship --version)"
    fi

    # ── Modern CLI tools (optional, enhance the experience) ──
    info "Installing optional CLI tools (bat, eza, zoxide)..."
    case "$PKG_MGR" in
        apt)
            eval "$PKG_INSTALL bat" >> "$LOG_FILE" 2>&1 || true
            # eza: may need a PPA or cargo on older Ubuntu
            eval "$PKG_INSTALL eza" >> "$LOG_FILE" 2>&1 || true
            ;;
        dnf)
            eval "$PKG_INSTALL bat eza" >> "$LOG_FILE" 2>&1 || true
            ;;
        pacman)
            eval "$PKG_INSTALL bat eza" >> "$LOG_FILE" 2>&1 || true
            ;;
        brew)
            brew install bat eza >> "$LOG_FILE" 2>&1 || true
            ;;
        apk)
            eval "$PKG_INSTALL bat" >> "$LOG_FILE" 2>&1 || true
            ;;
    esac

    # zoxide (smart cd replacement)
    if ! cmd_exists zoxide; then
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash >> "$LOG_FILE" 2>&1 && \
            success "zoxide" || warn "zoxide install failed — cd will work normally"
    else
        success "zoxide already installed"
    fi

    success "All dependencies installed"
}

# ═════════════════════════════════════════════════════════════
#  SHELL ENVIRONMENT
# ═════════════════════════════════════════════════════════════
setup_shell_env() {
    step "Configuring shell environment"

    # Determine shell rc file
    local shell_rc=""
    if [ -n "${ZSH_VERSION:-}" ] || [ "$SHELL" = "$(which zsh 2>/dev/null)" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ "$SHELL" = "$(which bash 2>/dev/null)" ]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.profile"
    fi

    local marker="# >>> devconfig >>>"
    local marker_end="# <<< devconfig <<<"

    # Remove old devconfig block if exists
    if [ -f "$shell_rc" ] && grep -q "$marker" "$shell_rc"; then
        sed -i "/$marker/,/$marker_end/d" "$shell_rc"
        info "Removed old devconfig block from $shell_rc"
    fi

    # Source our bashrc from the user's shell rc
    cat >> "$shell_rc" << SHELLEOF
$marker
# devconfig shell environment — do not edit this block
[ -f "$SCRIPT_DIR/bashrc.bash" ] && source "$SCRIPT_DIR/bashrc.bash"
$marker_end
SHELLEOF

    success "Shell rc updated: $shell_rc → sources bashrc.bash"

    # Install Starship config
    mkdir -p "$HOME/.config"
    if [ -f "$HOME/.config/starship.toml" ]; then
        cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
        info "Backed up existing starship.toml"
    fi
    cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    success "Installed starship.toml (Catppuccin Mocha theme)"

    info "Run ${BOLD}source $shell_rc${NC} or reconnect to apply"
}

# ═════════════════════════════════════════════════════════════
#  TMUX SETUP
# ═════════════════════════════════════════════════════════════
setup_tmux() {
    step "Setting up tmux"

    # Install config
    cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
    success "Installed tmux.conf"

    # Install TPM (Tmux Plugin Manager)
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm_dir" ]; then
        info "Installing TPM (Tmux Plugin Manager)..."
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" >> "$LOG_FILE" 2>&1
        success "TPM installed"
    else
        info "TPM already installed, updating..."
        (cd "$tpm_dir" && git pull --quiet) >> "$LOG_FILE" 2>&1
        success "TPM updated"
    fi

    # Install tmux plugins non-interactively
    info "Installing tmux plugins..."
    info "  - tmux-sensible (sane defaults)"
    info "  - tmux-yank (system clipboard over SSH/OSC52)"
    info "  - tmux-resurrect (save/restore sessions)"
    info "  - tmux-continuum (auto-save every 15min)"

    # TPM's install script
    if [ -f "$tpm_dir/bin/install_plugins" ]; then
        "$tpm_dir/bin/install_plugins" >> "$LOG_FILE" 2>&1 || warn "Plugin install needs tmux running; press prefix+I inside tmux"
        success "Tmux plugins installed"
    else
        warn "Start tmux and press ${BOLD}prefix + I${NC} (Ctrl-a, then I) to install plugins"
    fi

    echo ""
    info "${BOLD}Tmux plugin summary:${NC}"
    info "  ${GREEN}tpm${NC}              — Plugin manager (prefix+I to install, prefix+U to update)"
    info "  ${GREEN}tmux-sensible${NC}    — UTF-8, larger history, better defaults"
    info "  ${GREEN}tmux-yank${NC}        — Clipboard: copies to system clipboard (works over SSH via OSC52)"
    info "  ${GREEN}tmux-resurrect${NC}   — Save sessions: prefix+Ctrl-s / Restore: prefix+Ctrl-r"
    info "  ${GREEN}tmux-continuum${NC}   — Auto-saves every 15min, auto-restores on tmux start"
}

# ═════════════════════════════════════════════════════════════
#  NEOVIM / NVCHAD SETUP
# ═════════════════════════════════════════════════════════════
setup_nvim() {
    step "Setting up Neovim + NvChad v2.5"

    local nvim_config="$HOME/.config/nvim"
    local nvim_data="$HOME/.local/share/nvim"
    local nvim_state="$HOME/.local/state/nvim"
    local nvim_cache="$HOME/.cache/nvim"

    # Clean previous installation
    if [ -d "$nvim_config" ]; then
        info "Removing old Neovim config..."
        rm -rf "$nvim_config"
    fi
    if [ -d "$nvim_data" ]; then
        info "Removing old Neovim data (plugins will be re-downloaded)..."
        rm -rf "$nvim_data"
    fi
    rm -rf "$nvim_state" "$nvim_cache"

    # Clone NvChad starter
    info "Cloning NvChad starter template..."
    git clone --depth 1 https://github.com/NvChad/starter "$nvim_config" >> "$LOG_FILE" 2>&1
    rm -rf "$nvim_config/.git" "$nvim_config"/*.png
    success "NvChad starter cloned"

    # Overlay our config
    info "Installing custom configuration..."
    cp "$SCRIPT_DIR/nvim/init.lua"     "$nvim_config/init.lua"
    cp "$SCRIPT_DIR/nvim/.stylua.toml" "$nvim_config/.stylua.toml"

    # lua/ files
    cp "$SCRIPT_DIR/nvim/lua/chadrc.lua"   "$nvim_config/lua/chadrc.lua"
    cp "$SCRIPT_DIR/nvim/lua/options.lua"   "$nvim_config/lua/options.lua"
    cp "$SCRIPT_DIR/nvim/lua/mappings.lua"  "$nvim_config/lua/mappings.lua"

    # plugins/
    mkdir -p "$nvim_config/lua/plugins"
    cp "$SCRIPT_DIR/nvim/lua/plugins/init.lua" "$nvim_config/lua/plugins/init.lua"

    # configs/
    mkdir -p "$nvim_config/lua/configs"
    for cfg in "$SCRIPT_DIR/nvim/lua/configs/"*.lua; do
        cp "$cfg" "$nvim_config/lua/configs/"
    done

    success "Custom config installed"

    # Create tags cache directory
    mkdir -p "$HOME/.cache/nvim/tags"
    success "Tags cache directory created"

    # Run headless Neovim to install plugins
    info "Installing Neovim plugins (this may take 1-2 minutes)..."
    if nvim --headless "+Lazy! sync" +qa >> "$LOG_FILE" 2>&1; then
        success "Plugins installed via lazy.nvim"
    else
        warn "Plugin install had issues — they will auto-install on first nvim launch"
    fi

    # Install Mason packages headlessly
    info "Installing LSP servers, formatters, linters via Mason..."
    if nvim --headless "+MasonInstallAll" "+sleep 30" +qa >> "$LOG_FILE" 2>&1; then
        success "Mason packages queued for installation"
    else
        info "Mason packages will install on first launch — run :MasonInstallAll in Neovim"
    fi

    # Install treesitter parsers
    info "Installing Treesitter parsers..."
    if nvim --headless "+TSUpdateSync" +qa >> "$LOG_FILE" 2>&1; then
        success "Treesitter parsers installed"
    else
        info "Treesitter parsers will install on first launch — run :TSUpdate in Neovim"
    fi
}

# ═════════════════════════════════════════════════════════════
#  UNINSTALL
# ═════════════════════════════════════════════════════════════
uninstall() {
    step "Uninstalling devconfig"

    warn "This will remove Neovim config, tmux config, and TPM."
    if ! confirm "Are you sure?"; then
        info "Cancelled"
        exit 0
    fi

    # Backup first
    backup_configs

    # Remove nvim
    rm -rf "$HOME/.config/nvim"
    rm -rf "$HOME/.local/share/nvim"
    rm -rf "$HOME/.local/state/nvim"
    rm -rf "$HOME/.cache/nvim"
    success "Removed Neovim config and data"

    # Remove tmux
    rm -f "$HOME/.tmux.conf"
    rm -rf "$HOME/.tmux/plugins"
    success "Removed tmux config and plugins"

    # Remove starship config
    rm -f "$HOME/.config/starship.toml"
    success "Removed starship config"

    # Remove shell env block
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc" ] && grep -q ">>> devconfig >>>" "$rc"; then
            sed -i '/>>> devconfig >>>/,/<<< devconfig <<</d' "$rc"
            success "Cleaned devconfig block from $rc"
        fi
    done

    echo ""
    success "Uninstall complete. Backups are in: $BACKUP_DIR"
    info "System packages (neovim, tmux, ctags, global, etc.) were NOT removed."
    info "Remove them manually if desired."
}

# ═════════════════════════════════════════════════════════════
#  VERIFY INSTALLATION
# ═════════════════════════════════════════════════════════════
verify() {
    step "Verifying installation"

    local all_ok=true

    for tool in nvim tmux node npm rg ctags gtags fzf python3 git starship; do
        if cmd_exists "$tool"; then
            success "$tool: $(command -v $tool)"
        else
            if [[ "$tool" == "starship" ]]; then
                warn "$tool: NOT FOUND (fallback prompt will be used)"
            else
                warn "$tool: NOT FOUND"
                all_ok=false
            fi
        fi
    done

    # Optional enhanced tools
    echo ""
    info "${BOLD}Optional tools:${NC}"
    for tool in bat batcat eza zoxide; do
        if cmd_exists "$tool"; then
            success "  $tool: $(command -v $tool)"
        fi
    done

    # Check pygments
    if python3 -c "import pygments" 2>/dev/null; then
        success "  pygments: installed"
    else
        warn "  pygments: NOT FOUND (gtags will be limited to C/C++/Java)"
        all_ok=false
    fi

    # Check configs
    echo ""
    info "${BOLD}Config files:${NC}"
    [ -f "$HOME/.tmux.conf" ]                && success "  tmux.conf: present"        || { warn "  tmux.conf: MISSING"; all_ok=false; }
    [ -f "$HOME/.config/nvim/init.lua" ]     && success "  nvim config: present"      || { warn "  nvim config: MISSING"; all_ok=false; }
    [ -d "$HOME/.tmux/plugins/tpm" ]         && success "  TPM: installed"            || { warn "  TPM: MISSING"; all_ok=false; }
    [ -d "$HOME/.cache/nvim/tags" ]          && success "  Tags cache: ready"         || { warn "  Tags cache: MISSING"; all_ok=false; }
    [ -f "$HOME/.config/starship.toml" ]     && success "  starship.toml: present"    || warn "  starship.toml: MISSING (optional)"
    [ -f "$SCRIPT_DIR/bashrc.bash" ]         && success "  bashrc.bash: present"      || { warn "  bashrc.bash: MISSING"; all_ok=false; }

    # Check GTAGSLABEL
    echo ""
    if [ "${GTAGSLABEL:-}" = "native-pygments" ]; then
        success "GTAGSLABEL=native-pygments (multi-language gtags active)"
    else
        warn "GTAGSLABEL not set — run: source ~/.bashrc (or ~/.zshrc)"
    fi

    echo ""
    if $all_ok; then
        success "${BOLD}All checks passed!${NC}"
    else
        warn "Some checks failed — see warnings above"
    fi
}

# ═════════════════════════════════════════════════════════════
#  MAIN
# ═════════════════════════════════════════════════════════════
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           devconfig — Developer Environment             ║"
    echo "║     NvChad v2.5 • tmux • gtags • smart-splits          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  (none)        Interactive full install"
    echo "  --all         Non-interactive full install"
    echo "  --deps        Install system dependencies only"
    echo "  --nvim        Install Neovim/NvChad config only"
    echo "  --tmux        Install tmux config only"
    echo "  --bash        Install bashrc + starship config only"
    echo "  --shell       Configure shell environment only (alias for --bash)"
    echo "  --verify      Verify installation"
    echo "  --uninstall   Remove everything (with backups)"
    echo "  --help        Show this help"
}

full_install() {
    backup_configs
    install_deps
    setup_shell_env
    setup_tmux
    setup_nvim
    verify

    echo ""
    step "Setup Complete!"
    echo ""
    info "Next steps:"
    info "  1. ${BOLD}source ~/.bashrc${NC}  (or ~/.zshrc) to load env vars"
    info "  2. ${BOLD}tmux${NC}             start tmux"
    info "  3. ${BOLD}nvim${NC}             launch Neovim (plugins auto-install)"
    info "  4. Inside tmux: ${BOLD}prefix + I${NC} to install tmux plugins"
    info "  5. Inside nvim:  ${BOLD}:MasonInstallAll${NC} if tools didn't auto-install"
    echo ""
    info "Navigation cheat sheet:"
    info "  ${GREEN}Ctrl+hjkl${NC}        Navigate nvim splits ↔ tmux panes"
    info "  ${GREEN}Alt+hjkl${NC}         Resize nvim splits ↔ tmux panes"
    info "  ${GREEN}Space gs/gd/gc${NC}   Gtags: symbol/definition/callers"
    info "  ${GREEN}Space 1-5${NC}        Harpoon: jump to pinned files"
    info "  ${GREEN}Space ao${NC}         Code outline sidebar"
    info "  ${GREEN}s + 2 chars${NC}      Flash jump anywhere on screen"
    echo ""
    info "Log file: $LOG_FILE"
    if [ -d "$BACKUP_DIR" ]; then
        info "Backups:  $BACKUP_DIR"
    fi
}

main() {
    print_banner

    case "${1:-}" in
        --all)
            AUTO_YES=true
            full_install
            ;;
        --deps)
            install_deps
            ;;
        --nvim)
            backup_configs
            setup_nvim
            ;;
        --tmux)
            backup_configs
            setup_tmux
            ;;
        --bash|--shell)
            setup_shell_env
            ;;
        --verify)
            verify
            ;;
        --uninstall)
            uninstall
            ;;
        --help|-h)
            print_usage
            ;;
        "")
            if confirm "Install everything (dependencies + tmux + Neovim)?"; then
                full_install
            else
                echo ""
                print_usage
            fi
            ;;
        *)
            error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
