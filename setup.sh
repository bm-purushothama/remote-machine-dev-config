#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  devconfig — Setup for Remote Dev Servers                   ║
# ║  NvChad v2.5 + tmux + gtags + smart-splits + bashrc         ║
# ╚══════════════════════════════════════════════════════════════╝
#
# NOTE: This script does NOT install system packages.
#       It checks for required dependencies and fails with
#       instructions if any are missing. Install them first
#       using your system package manager.
#
# Usage:
#   ./setup.sh              # Full setup (interactive)
#   ./setup.sh --all        # Full setup (non-interactive)
#   ./setup.sh --check      # Only check dependencies
#   ./setup.sh --nvim       # Only Neovim config
#   ./setup.sh --tmux       # Only tmux config
#   ./setup.sh --bash       # Only bashrc + starship config
#   ./setup.sh --verify     # Verify installation
#   ./setup.sh --uninstall  # Remove everything (with backups)

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
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
hint()    { echo -e "        ${DIM}$*${NC}"; }

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }

confirm() {
    if $AUTO_YES; then return 0; fi
    local msg="${1:-Continue?}"
    echo -en "${YELLOW}${msg} [Y/n] ${NC}"
    read -r reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

cmd_exists() { command -v "$1" &>/dev/null; }

# ─── Detect package manager (for hint messages only) ────────
detect_pkg_manager() {
    if cmd_exists apt-get; then   PKG_MGR="apt"
    elif cmd_exists dnf; then     PKG_MGR="dnf"
    elif cmd_exists yum; then     PKG_MGR="yum"
    elif cmd_exists pacman; then  PKG_MGR="pacman"
    elif cmd_exists brew; then    PKG_MGR="brew"
    elif cmd_exists apk; then     PKG_MGR="apk"
    else                          PKG_MGR="unknown"
    fi
}

# Return the install command hint for a given package
pkg_hint() {
    local pkg="$1"
    case "$PKG_MGR" in
        apt)    echo "sudo apt install $pkg" ;;
        dnf)    echo "sudo dnf install $pkg" ;;
        yum)    echo "sudo yum install $pkg" ;;
        pacman) echo "sudo pacman -S $pkg" ;;
        brew)   echo "brew install $pkg" ;;
        apk)    echo "sudo apk add $pkg" ;;
        *)      echo "<your-pkg-manager> install $pkg" ;;
    esac
}

# ═════════════════════════════════════════════════════════════
#  DEPENDENCY CHECK — Does NOT install anything
# ═════════════════════════════════════════════════════════════
check_deps() {
    step "Checking required dependencies"

    detect_pkg_manager
    info "Detected package manager: ${BOLD}$PKG_MGR${NC}"
    echo ""

    local missing_required=()
    local missing_optional=()
    local install_hints=()

    # ── Required tools ───────────────────────────────────────
    # Format: "command|package_name_apt|package_name_pacman|description"
    declare -A REQUIRED_TOOLS=(
        [git]="Core: version control"
        [nvim]="Core: Neovim editor (>= 0.10)"
        [tmux]="Core: terminal multiplexer (>= 3.2)"
        [node]="Core: Node.js runtime (for LSP servers)"
        [npm]="Core: Node package manager"
        [python3]="Core: Python 3 (for pygments/gtags)"
        [rg]="Search: ripgrep (fast recursive grep)"
        [fzf]="Search: fuzzy finder"
        [ctags]="Navigation: Universal Ctags (tag generation)"
        [gtags]="Navigation: GNU Global (cross-reference indexing)"
        [curl]="Core: HTTP client (for plugin downloads)"
        [make]="Build: required for telescope-fzf-native"
    )

    # Package name mappings per package manager
    declare -A PKG_NAMES_APT=(
        [git]=git [nvim]=neovim [tmux]=tmux [node]=nodejs [npm]=npm
        [python3]=python3 [rg]=ripgrep [fzf]=fzf [ctags]=universal-ctags
        [gtags]=global [curl]=curl [make]=build-essential
    )
    declare -A PKG_NAMES_DNF=(
        [git]=git [nvim]=neovim [tmux]=tmux [node]=nodejs [npm]=npm
        [python3]=python3 [rg]=ripgrep [fzf]=fzf [ctags]=ctags
        [gtags]=global-ctags [curl]=curl [make]=make
    )
    declare -A PKG_NAMES_PACMAN=(
        [git]=git [nvim]=neovim [tmux]=tmux [node]=nodejs [npm]=npm
        [python3]=python [rg]=ripgrep [fzf]=fzf [ctags]=ctags
        [gtags]=global [curl]=curl [make]=base-devel
    )
    declare -A PKG_NAMES_BREW=(
        [git]=git [nvim]=neovim [tmux]=tmux [node]=node [npm]=node
        [python3]=python3 [rg]=ripgrep [fzf]=fzf [ctags]=universal-ctags
        [gtags]=global [curl]=curl [make]=make
    )

    # Select the right mapping
    local -n pkg_map
    case "$PKG_MGR" in
        apt)          pkg_map=PKG_NAMES_APT ;;
        dnf|yum)      pkg_map=PKG_NAMES_DNF ;;
        pacman)       pkg_map=PKG_NAMES_PACMAN ;;
        brew)         pkg_map=PKG_NAMES_BREW ;;
        *)            pkg_map=PKG_NAMES_APT ;;  # fallback
    esac

    info "${BOLD}Required:${NC}"
    for tool in git curl make nvim tmux node npm python3 rg fzf ctags gtags; do
        local desc="${REQUIRED_TOOLS[$tool]}"
        if cmd_exists "$tool"; then
            success "  $tool  ${DIM}($desc)${NC}"
        else
            error "  $tool  ${DIM}($desc)${NC}"
            missing_required+=("$tool")
            local pkg_name="${pkg_map[$tool]:-$tool}"
            install_hints+=("$pkg_name")
        fi
    done

    # ── fd (has different binary names) ──────────────────────
    echo ""
    if cmd_exists fd; then
        success "  fd  ${DIM}(Search: fast file finder)${NC}"
    elif cmd_exists fdfind; then
        success "  fd  ${DIM}(Search: fast file finder — as 'fdfind')${NC}"
    else
        error "  fd  ${DIM}(Search: fast file finder)${NC}"
        missing_required+=("fd")
        case "$PKG_MGR" in
            apt)    install_hints+=("fd-find") ;;
            dnf)    install_hints+=("fd-find") ;;
            pacman) install_hints+=("fd") ;;
            brew)   install_hints+=("fd") ;;
            *)      install_hints+=("fd-find") ;;
        esac
    fi

    # ── Pygments (Python package) ────────────────────────────
    if python3 -c "import pygments" 2>/dev/null; then
        success "  pygments  ${DIM}(Python: multi-language gtags support)${NC}"
    else
        error "  pygments  ${DIM}(Python: multi-language gtags support)${NC}"
        missing_required+=("pygments")
    fi

    # ── Optional tools ───────────────────────────────────────
    echo ""
    info "${BOLD}Optional (recommended):${NC}"

    declare -A OPTIONAL_TOOLS=(
        [starship]="Prompt: beautiful cross-shell prompt"
        [bat]="Viewer: cat replacement with syntax highlighting"
        [eza]="Listing: modern ls replacement with icons"
        [zoxide]="Navigation: smart cd that learns your habits"
    )

    for tool in starship bat eza zoxide; do
        local desc="${OPTIONAL_TOOLS[$tool]}"
        if cmd_exists "$tool"; then
            success "  $tool  ${DIM}($desc)${NC}"
        else
            # Also check alternative names
            if [[ "$tool" == "bat" ]] && cmd_exists batcat; then
                success "  bat  ${DIM}($desc — as 'batcat')${NC}"
            else
                warn "  $tool  ${DIM}($desc) — not found${NC}"
                missing_optional+=("$tool")
            fi
        fi
    done

    # ── Report ───────────────────────────────────────────────
    echo ""

    if [[ ${#missing_required[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}════════════════════════════════════════════════════════${NC}"
        error "${BOLD}Missing ${#missing_required[@]} required package(s): ${missing_required[*]}${NC}"
        echo -e "${RED}${BOLD}════════════════════════════════════════════════════════${NC}"
        echo ""
        info "Install them using your package manager before running setup:"
        echo ""

        # Deduplicate install hints
        local unique_pkgs
        unique_pkgs=$(printf '%s\n' "${install_hints[@]}" | sort -u | tr '\n' ' ')

        # Print the install command
        case "$PKG_MGR" in
            apt)    echo -e "  ${GREEN}sudo apt update && sudo apt install -y ${unique_pkgs}${NC}" ;;
            dnf)    echo -e "  ${GREEN}sudo dnf install -y ${unique_pkgs}${NC}" ;;
            yum)    echo -e "  ${GREEN}sudo yum install -y ${unique_pkgs}${NC}" ;;
            pacman) echo -e "  ${GREEN}sudo pacman -S ${unique_pkgs}${NC}" ;;
            brew)   echo -e "  ${GREEN}brew install ${unique_pkgs}${NC}" ;;
            apk)    echo -e "  ${GREEN}sudo apk add ${unique_pkgs}${NC}" ;;
            *)      echo -e "  ${GREEN}<pkg-manager> install ${unique_pkgs}${NC}" ;;
        esac

        # Pygments
        if [[ " ${missing_required[*]} " =~ " pygments " ]]; then
            echo ""
            echo -e "  ${GREEN}pip3 install --user pygments${NC}"
            hint "Or: python3 -m pip install --user pygments"
        fi

        echo ""
        error "Setup cannot proceed until required dependencies are installed."
        echo ""
        return 1
    fi

    success "${BOLD}All required dependencies are present!${NC}"

    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        echo ""
        info "Optional tools you may want to install for the best experience:"
        echo ""
        for tool in "${missing_optional[@]}"; do
            case "$tool" in
                starship)
                    echo -e "  ${GREEN}curl -sS https://starship.rs/install.sh | sh${NC}"
                    hint "Beautiful prompt (bashrc falls back to built-in prompt without it)"
                    ;;
                bat)
                    echo -e "  ${GREEN}$(pkg_hint bat)${NC}"
                    hint "Syntax-highlighted cat replacement (used by fzf previews)"
                    ;;
                eza)
                    echo -e "  ${GREEN}$(pkg_hint eza)${NC}"
                    hint "Modern ls with icons and git integration"
                    ;;
                zoxide)
                    echo -e "  ${GREEN}curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash${NC}"
                    hint "Smart cd that learns your frequently visited directories"
                    ;;
            esac
        done
        echo ""
    fi

    return 0
}

# ═════════════════════════════════════════════════════════════
#  BACKUP
# ═════════════════════════════════════════════════════════════
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
#  SHELL / BASHRC SETUP
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
    if [ -f "$HOME/.config/starship.toml" ] && [ ! -f "$BACKUP_DIR/starship.toml" ] 2>/dev/null; then
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

    # Install TPM
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
    if [ -f "$tpm_dir/bin/install_plugins" ]; then
        "$tpm_dir/bin/install_plugins" >> "$LOG_FILE" 2>&1 || warn "Press ${BOLD}prefix + I${NC} inside tmux to install plugins"
        success "Tmux plugins installed"
    else
        warn "Start tmux and press ${BOLD}prefix + I${NC} (Ctrl-a, then I) to install plugins"
    fi

    echo ""
    info "${BOLD}Tmux plugins:${NC}"
    info "  ${GREEN}tpm${NC}              Plugin manager  (prefix+I install, prefix+U update)"
    info "  ${GREEN}tmux-sensible${NC}    Sane defaults   (UTF-8, larger history, etc.)"
    info "  ${GREEN}tmux-yank${NC}        Clipboard       (copies over SSH via OSC 52)"
    info "  ${GREEN}tmux-resurrect${NC}   Sessions        (prefix+Ctrl-s save, prefix+Ctrl-r restore)"
    info "  ${GREEN}tmux-continuum${NC}   Auto-save       (saves every 15min, auto-restores)"
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

    # Clean previous
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

    cp "$SCRIPT_DIR/nvim/lua/chadrc.lua"   "$nvim_config/lua/chadrc.lua"
    cp "$SCRIPT_DIR/nvim/lua/options.lua"   "$nvim_config/lua/options.lua"
    cp "$SCRIPT_DIR/nvim/lua/mappings.lua"  "$nvim_config/lua/mappings.lua"

    mkdir -p "$nvim_config/lua/plugins"
    cp "$SCRIPT_DIR/nvim/lua/plugins/init.lua" "$nvim_config/lua/plugins/init.lua"

    mkdir -p "$nvim_config/lua/configs"
    for cfg in "$SCRIPT_DIR/nvim/lua/configs/"*.lua; do
        cp "$cfg" "$nvim_config/lua/configs/"
    done

    success "Custom config installed"

    # Create tags cache
    mkdir -p "$HOME/.cache/nvim/tags"
    success "Tags cache directory created"

    # Install plugins headlessly
    info "Installing Neovim plugins (this may take 1-2 minutes)..."
    if nvim --headless "+Lazy! sync" +qa >> "$LOG_FILE" 2>&1; then
        success "Plugins installed via lazy.nvim"
    else
        warn "Plugins will auto-install on first nvim launch"
    fi

    # Mason packages
    info "Queuing LSP servers, formatters, linters via Mason..."
    if nvim --headless "+MasonInstallAll" "+sleep 30" +qa >> "$LOG_FILE" 2>&1; then
        success "Mason packages queued"
    else
        info "Run ${BOLD}:MasonInstallAll${NC} on first launch"
    fi

    # Treesitter parsers
    info "Installing Treesitter parsers..."
    if nvim --headless "+TSUpdateSync" +qa >> "$LOG_FILE" 2>&1; then
        success "Treesitter parsers installed"
    else
        info "Run ${BOLD}:TSUpdate${NC} on first launch"
    fi
}

# ═════════════════════════════════════════════════════════════
#  UNINSTALL
# ═════════════════════════════════════════════════════════════
uninstall() {
    step "Uninstalling devconfig"

    warn "This will remove Neovim config, tmux config, bashrc integration, and TPM."
    if ! confirm "Are you sure?"; then
        info "Cancelled"
        exit 0
    fi

    backup_configs

    rm -rf "$HOME/.config/nvim"
    rm -rf "$HOME/.local/share/nvim"
    rm -rf "$HOME/.local/state/nvim"
    rm -rf "$HOME/.cache/nvim"
    success "Removed Neovim config and data"

    rm -f "$HOME/.tmux.conf"
    rm -rf "$HOME/.tmux/plugins"
    success "Removed tmux config and plugins"

    rm -f "$HOME/.config/starship.toml"
    success "Removed starship config"

    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc" ] && grep -q ">>> devconfig >>>" "$rc"; then
            sed -i '/>>> devconfig >>>/,/<<< devconfig <<</d' "$rc"
            success "Cleaned devconfig block from $rc"
        fi
    done

    echo ""
    success "Uninstall complete. Backups are in: $BACKUP_DIR"
    info "System packages (neovim, tmux, ctags, etc.) were NOT removed."
}

# ═════════════════════════════════════════════════════════════
#  VERIFY
# ═════════════════════════════════════════════════════════════
verify() {
    step "Verifying installation"

    local all_ok=true

    info "${BOLD}Tools:${NC}"
    for tool in nvim tmux node npm rg ctags gtags fzf python3 git; do
        if cmd_exists "$tool"; then
            success "  $tool: $(command -v "$tool")"
        else
            warn "  $tool: NOT FOUND"
            all_ok=false
        fi
    done

    # fd check
    if cmd_exists fd; then
        success "  fd: $(command -v fd)"
    elif cmd_exists fdfind; then
        success "  fd: $(command -v fdfind) (as fdfind)"
    else
        warn "  fd: NOT FOUND"
        all_ok=false
    fi

    # Optional
    echo ""
    info "${BOLD}Optional tools:${NC}"
    for tool in starship bat batcat eza zoxide; do
        cmd_exists "$tool" && success "  $tool: $(command -v "$tool")"
    done

    # Pygments
    if python3 -c "import pygments" 2>/dev/null; then
        success "  pygments: installed"
    else
        warn "  pygments: NOT FOUND (gtags limited to C/C++/Java)"
        all_ok=false
    fi

    # Config files
    echo ""
    info "${BOLD}Config files:${NC}"
    [ -f "$HOME/.tmux.conf" ]                && success "  tmux.conf: present"        || { warn "  tmux.conf: MISSING"; all_ok=false; }
    [ -f "$HOME/.config/nvim/init.lua" ]     && success "  nvim config: present"      || { warn "  nvim config: MISSING"; all_ok=false; }
    [ -d "$HOME/.tmux/plugins/tpm" ]         && success "  TPM: installed"            || { warn "  TPM: MISSING"; all_ok=false; }
    [ -d "$HOME/.cache/nvim/tags" ]          && success "  Tags cache: ready"         || { warn "  Tags cache: MISSING"; all_ok=false; }
    [ -f "$HOME/.config/starship.toml" ]     && success "  starship.toml: present"    || warn "  starship.toml: MISSING (optional)"
    [ -f "$SCRIPT_DIR/bashrc.bash" ]         && success "  bashrc.bash: present"      || { warn "  bashrc.bash: MISSING"; all_ok=false; }

    # GTAGSLABEL
    echo ""
    if [ "${GTAGSLABEL:-}" = "native-pygments" ]; then
        success "GTAGSLABEL=native-pygments (multi-language gtags active)"
    else
        warn "GTAGSLABEL not set — run: ${BOLD}source ~/.bashrc${NC}"
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
    echo "  (none)        Interactive full setup"
    echo "  --all         Non-interactive full setup"
    echo "  --check       Check dependencies only (install nothing)"
    echo "  --nvim        Setup Neovim/NvChad config only"
    echo "  --tmux        Setup tmux config only"
    echo "  --bash        Setup bashrc + starship config only"
    echo "  --verify      Verify existing installation"
    echo "  --uninstall   Remove everything (with backups)"
    echo "  --help        Show this help"
    echo ""
    echo "This script does NOT install system packages."
    echo "Run --check first to see what's needed."
}

full_setup() {
    # Check deps first — abort if missing
    if ! check_deps; then
        echo ""
        error "Aborting setup. Install the missing packages above and re-run."
        exit 1
    fi

    backup_configs
    setup_shell_env
    setup_tmux
    setup_nvim
    verify

    echo ""
    step "Setup Complete!"
    echo ""
    info "Next steps:"
    info "  1. ${BOLD}source ~/.bashrc${NC}  (or ~/.zshrc) to load shell config"
    info "  2. ${BOLD}tmux${NC}             start tmux"
    info "  3. ${BOLD}nvim${NC}             launch Neovim"
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
            full_setup
            ;;
        --check)
            check_deps
            ;;
        --nvim)
            if ! check_deps; then exit 1; fi
            backup_configs
            setup_nvim
            ;;
        --tmux)
            if ! check_deps; then exit 1; fi
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
            if confirm "Setup everything (tmux + Neovim + bashrc)?"; then
                full_setup
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
