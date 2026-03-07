# devconfig

Developer environment for remote servers — Neovim (NvChad v2.5) + tmux, optimized for large codebase navigation.

## One-line install

```bash
git clone https://github.com/YOUR_USERNAME/devconfig.git ~/.devconfig
cd ~/.devconfig && chmod +x setup.sh && ./setup.sh
```

Non-interactive (e.g. in a provisioning script):
```bash
./setup.sh --all
```

## What gets installed

### System dependencies (via apt/dnf/pacman/brew)
| Tool | Purpose |
|------|---------|
| neovim | Editor (0.10+) |
| tmux | Terminal multiplexer (3.4+) |
| universal-ctags | Tag generation for code navigation |
| GNU Global (gtags) | Cross-reference indexing (callers, callees, symbols) |
| pygments | Multi-language support for gtags (Python, JS, Rust, Go...) |
| ripgrep | Fast recursive grep |
| fd | Fast file finder |
| fzf | Fuzzy finder binary |
| Node.js | LSP server runtime |

### tmux plugins (via TPM)
| Plugin | Purpose | Key bindings |
|--------|---------|-------------|
| [tpm](https://github.com/tmux-plugins/tpm) | Plugin manager | `prefix + I` install, `prefix + U` update |
| [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | Sane defaults (UTF-8, history, etc.) | — |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank) | System clipboard (works over SSH via OSC 52) | `y` in copy-mode |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Save/restore sessions across reboots | `prefix + Ctrl-s` save, `prefix + Ctrl-r` restore |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-save sessions every 15 minutes | Automatic |

### Neovim plugins (via lazy.nvim)
~35 plugins including LSP, completion, debugging, and the navigation stack.

## Repo structure

```
devconfig/
├── setup.sh                  # Automated setup script
├── tmux.conf                 # tmux config (Catppuccin Mocha theme)
├── nvim/                     # Neovim config (overlays NvChad starter)
│   ├── init.lua              # Entry point
│   ├── .stylua.toml          # Lua formatter config
│   └── lua/
│       ├── chadrc.lua        # NvChad UI/theme settings
│       ├── options.lua       # Editor options + winbar + large file guard
│       ├── mappings.lua      # All keybindings
│       ├── plugins/
│       │   └── init.lua      # Plugin specifications (~35 plugins)
│       └── configs/
│           ├── cmp.lua       # Completion: LSP + ctags + buffer + path
│           ├── dap.lua       # Debug adapters (Python, Go, C/C++, JS)
│           ├── harpoon.lua   # File pinning (per-branch)
│           ├── lazy.lua      # lazy.nvim options
│           ├── lspconfig.lua # LSP server configs (12+ languages)
│           └── smart-splits.lua  # nvim ↔ tmux navigation
└── .gitignore
```

## setup.sh options

```
./setup.sh              # Interactive full install
./setup.sh --all        # Non-interactive full install
./setup.sh --deps       # Install system dependencies only
./setup.sh --nvim       # Install Neovim config only
./setup.sh --tmux       # Install tmux config only
./setup.sh --shell      # Configure shell environment only
./setup.sh --verify     # Check everything is working
./setup.sh --uninstall  # Remove everything (backs up first)
```

## Key bindings

### Navigation across nvim ↔ tmux (smart-splits)

| Keys | Action |
|------|--------|
| `Ctrl + h/j/k/l` | Navigate between nvim splits and tmux panes seamlessly |
| `Alt + h/j/k/l` | Resize nvim splits and tmux panes seamlessly |
| `Leader Leader + h/j/k/l` | Swap buffers between splits |

### Large codebase navigation

| Layer | Keys | What it does |
|-------|------|-------------|
| **Motion** | `s` + 2 chars | Flash: jump anywhere on screen |
| **Motion** | `S` | Flash: treesitter-aware select |
| **Structure** | `]f` / `[f` | Next/prev function |
| **Structure** | `]c` / `[c` | Next/prev class |
| **Outline** | `Space ao` | Toggle code outline sidebar (aerial) |
| **Breadcrumbs** | _(winbar)_ | Auto: Module > Class > Method |
| **LSP** | `gd` / `gr` / `gi` | Definition / references / implementations |
| **LSP** | `K` | Hover docs |
| **Gtags** | `Space gs` | Find all references to symbol |
| **Gtags** | `Space gd` | Find definition |
| **Gtags** | `Space gc` | Find functions calling this function |
| **Gtags** | `Space gC` | Find functions called by this function |
| **Gtags** | `Space gi` | Find files that include this file |
| **Harpoon** | `Space ha` | Pin current file |
| **Harpoon** | `Space 1-5` | Jump to pinned file 1-5 |
| **Harpoon** | `Space hh` | Toggle pinned files menu |
| **Fuzzy** | `Space ff` | Find files (Telescope) |
| **Fuzzy** | `Space fg` | Live grep (Telescope) |
| **Fuzzy** | `Space zf` | Find files (fzf-lua, faster on SSH) |
| **Fuzzy** | `Space zg` | Live grep (fzf-lua) |
| **Fuzzy** | `Space zt` | Search tags |
| **Projects** | `Space fp` | Recent projects |

### Completion (nvim-cmp)

| Keys | Action |
|------|--------|
| `Tab` / `Shift+Tab` | Cycle through suggestions |
| `Ctrl + Space` | Trigger completion manually |
| `Ctrl + n/p` | Next/prev item |
| `Ctrl + b/f` | Scroll docs |
| `Enter` | Confirm selected item |
| `Ctrl + e` | Dismiss completion |

Completion sources in priority order: **LSP** (clangd etc.) → **ctags/gtags** → **snippets** → **buffer words** → **paths**. Ghost text shows inline preview.

### tmux

| Keys | Action |
|------|--------|
| `Ctrl + a` | Prefix (replaces Ctrl+b) |
| `prefix + \|` | Vertical split |
| `prefix + -` | Horizontal split |
| `Shift + Left/Right` | Switch windows |
| `Alt + 1-9` | Jump to window N |
| `prefix + m` | Zoom pane |
| `prefix + r` | Reload config |
| `prefix + I` | Install TPM plugins |
| `prefix + U` | Update TPM plugins |
| `prefix + Ctrl-s` | Save session (resurrect) |
| `prefix + Ctrl-r` | Restore session (resurrect) |

## Supported languages

| Language | LSP | Formatter | Linter | Debug | Gtags |
|----------|-----|-----------|--------|-------|-------|
| C/C++ | clangd | clang-format | — | codelldb | native |
| Python | pyright | black + isort | ruff | debugpy | pygments |
| TypeScript/JS | ts_ls | prettier | eslint_d | js-debug | pygments |
| Rust | rust-analyzer | rustfmt | clippy | codelldb | pygments |
| Go | gopls | gofumpt | staticcheck | delve | pygments |
| Lua | lua_ls | stylua | — | — | pygments |
| Bash | bashls | shfmt | shellcheck | — | pygments |
| HTML/CSS | html/cssls | prettier | — | — | pygments |
| YAML/JSON | yamlls/jsonls | prettier | — | — | — |
| Docker | dockerls | — | — | — | — |
| Terraform | terraformls | terraform_fmt | — | — | — |

## Updating

```bash
cd ~/.devconfig
git pull
./setup.sh --nvim   # re-apply nvim config
./setup.sh --tmux   # re-apply tmux config
```

Inside Neovim: `:Lazy update` for plugins, `:MasonUpdate` for tools, `:TSUpdate` for parsers.

## Uninstalling

```bash
cd ~/.devconfig && ./setup.sh --uninstall
```

This backs up everything before removing, and tells you where the backups are.
