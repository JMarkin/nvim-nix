# Agent Guide for nvim-nix

This repository contains a Nix-based Neovim configuration with extensive plugin management and AI tooling integration.

## Essential Commands

### Nix Commands
```bash
nix build .#nvim           # Full Neovim with all plugins
nix build .#nvim-small     # Minimal Neovim with essential plugins
nix build .#nvim-minimal   # Bare minimum Neovim
nix develop                # Enter devShell with lua-language-server, nixd, stylua, luacheck
nix flake update           # Update all plugin versions
```

### Build/Development Commands
```bash
stylua <file.lua>          # Format Lua files (config in .stylua.toml)
```

## Code Style Guidelines

### Lua Coding Style
- **Stylua formatting**: 2-space indentation, 120 column width, double quotes, always use parentheses in function calls
- **Plugin loading pattern**: Use guard pattern `if vim.g.did_load_plugin_name then return end; vim.g.did_load_plugin_name = true`
- **Global variables**: Extensive use of `vim.g` for configuration
- **Option setting**: Use `vim.opt` for Neovim options
- **Autocommands**: Use `vim.api.nvim_create_augroup` for grouping
- **No comments**: NEVER add comments unless explicitly requested

### Nix Patterns
- **Plugin definitions**: Use `mkNvimPlugin` helper for building plugins
- **Overlay structure**: Follow the pattern in `neovim-overlay.nix`
- **Package variants**: Support `nvim`, `nvim-small`, `nvim-minimal`
- **Plugin categories**: `essential`, `coding`, `extra`, `ai-tools`

## Testing
- **Test files**: Various language files in `tests/` directory for testing language support
- **Manual testing**: Test individual plugin configurations
- **Build testing**: Verify Nix builds complete successfully

## Important Gotchas
- Plugins use guard patterns to prevent double-loading
- Order matters for keymap and autocommand setup
- Use `nix develop` for consistent development environment
- Test builds with `nix build .#nvim-small` for faster iteration
