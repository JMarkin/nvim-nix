# Agent Guide for nvim-nix

This repository contains a Nix-based Neovim configuration with extensive plugin management and AI tooling integration.

## Project Overview

This is a **Nix-flaked Neovim configuration** that builds custom Neovim packages with pre-configured plugins and settings. The configuration emphasizes:

- **Nix package management** for reproducible builds
- **Extensive plugin ecosystem** with custom configurations
- **AI tooling integration** (Ollama, Airun, Gemini, etc.)
- **Multi-language support** with LSP configurations
- **Development-focused tooling** for coding workflows

## Essential Commands

### Nix Commands

```bash
# Build Neovim packages
nix build .#nvim           # Full Neovim with all plugins
nix build .#nvim-small     # Minimal Neovim with essential plugins  
nix build .#nvim-minimal   # Bare minimum Neovim

# Development shell with Lua/Nix tooling
nix develop               # Enter devShell with lua-language-server, nixd, stylua, luacheck

# Update flake inputs
nix flake update          # Update all plugin versions

# Install system-wide
nix profile install .     # Install default (nvim) package
nix profile install .#nvim-small  # Install minimal version
```

### Build/Development Commands

```bash
# Generate test data (from Makefile)
make tests-data           # Downloads large JSON/YAML files for testing

# Lua code formatting
stylua <file.lua>         # Format Lua files (config in .stylua.toml)

# Lua linting (in devShell)
luacheck <file.lua>       # Check Lua syntax and style
```

## Directory Structure

```
nvim-nix/
├── nvim/                 # Neovim configuration
│   ├── init.lua         # Main configuration file
│   ├── plugin/          # Plugin configurations
│   ├── lua/            # Custom Lua modules
│   │   └── ai/         # AI tooling modules
│   └── after/          # After-load configurations
├── nix/                # Nix package definitions
│   ├── neovim-overlay.nix  # Main overlay logic
│   ├── mkNeovim.nix    # Neovim builder function
│   └── lang/          # Language-specific configs
├── tests/             # Test files and data
└── flake.nix         # Nix flake definition
```

## Code Organization

### Neovim Configuration (`nvim/`)

- **`init.lua`**: Core configuration with global settings, options, and plugin loading
- **`plugin/`**: Individual plugin configurations (keymaps, settings, etc.)
- **`lua/`**: Custom Lua modules and utilities
- **`after/`**: After-load configurations and filetype plugins

### Plugin Structure

Plugins are organized by functionality:
- **AI tools**: `ai_avante.lua`, `ai/` directory with adapters and tools
- **Navigation**: `jumps.lua`, `window.lua`, `filemanager.lua`
- **Editing**: `format.lua`, `comment.lua`, `fold.lua`
- **UI**: `gui.lua`, `statusline.nix`, `colors/`
- **LSP**: `lspconfig.lua`, individual LSP configs in `lsp/`

### Nix Package Structure (`nix/`)

- **`neovim-overlay.nix`**: Main overlay that builds Neovim packages
- **`mkNeovim.nix`**: Builder function for creating Neovim derivations
- **`lang/`**: Language-specific plugin configurations
- Individual `.nix` files for specific features (treesitter, UI, etc.)

## Code Patterns and Conventions

### Lua Coding Style

- **Stylua formatting** (configured in `.stylua.toml`)
  - 2-space indentation
  - 120 column width
  - Double quotes preferred
  - Always use parentheses in function calls

- **Plugin loading pattern**:
```lua
if vim.g.did_load_plugin_name then return end
vim.g.did_load_plugin_name = true
-- plugin code here
```

- **Global variable usage**: Extensive use of `vim.g` for configuration
- **Option setting**: Use `vim.opt` for Neovim options
- **Autocommand patterns**: Use `vim.api.nvim_create_augroup` for grouping

### Nix Patterns

- **Plugin definitions**: Use `mkNvimPlugin` helper for building plugins
- **Overlay structure**: Follow the pattern in `neovim-overlay.nix`
- **Package variants**: Support `nvim`, `nvim-small`, `nvim-minimal`
- **Plugin categories**: `essential`, `coding`, `extra`, `ai-tools`

## Testing Approach

- **Test files**: Various language files in `tests/` directory for testing language support
- **Manual testing**: Primarily manual testing of Neovim functionality
- **Plugin testing**: Test individual plugin configurations
- **Build testing**: Verify Nix builds complete successfully

## AI Tooling Integration

### Supported AI Services

1. **Ollama** (local): Configured via `vim.g.ollama_*` variables
2. **Airun**: Remote AI service configuration
3. **Gemini**: Google AI integration
4. **OpenAI Compatible**: Generic API support

### AI Configuration Pattern

```lua
-- In ai/adapters.lua
M.service_name = function()
  return require("codecompanion.adapters").extend("service_type", {
    env = { /* environment variables */ },
    opts = { /* service options */ },
    schema = { /* model/configuration schema */ }
  })
end
```

## Important Gotchas

### Plugin Loading Order
- Plugins use guard patterns to prevent double-loading
- Order matters for keymap and autocommand setup
- Some plugins depend on others being loaded first

### Nix Dependencies
- Requires specific Nixpkgs version (nixos-unstable)
- Some plugins may need additional system dependencies
- Build times can be long due to compilation

### Configuration Scope
- Global variables (`vim.g.*`) control most behavior
- Some settings are UI-dependent (terminal vs GUI)
- Plugin configurations can override global settings

### Development Workflow
- Use `nix develop` for consistent development environment
- Test builds with `nix build .#nvim-small` for faster iteration
- Update plugins via `nix flake update`

## Development Environment Setup

1. **Enter development shell**:
   ```bash
   nix develop
   ```

2. **Link configuration for testing**:
   ```bash
   # From devShell, config is automatically linked to ~/.config/nvim-dev
   nvim -u ~/.config/nvim-dev/init.lua
   ```

3. **Format and lint**:
   ```bash
   stylua nvim/**/*.lua
   luacheck nvim/**/*.lua
   ```

## Project-Specific Context

This configuration is maintained by Jury Markin and includes:
- **Custom color schemes**: `ex-bamboo`, `ex-bluloco`, etc.
- **Personal workflow optimizations**: Specific keymaps and settings
- **bleeding-edge plugins**: Frequently updated via flake inputs
- **Multi-language development**: Support for Go, Python, Rust, JS, etc.
- **AI-assisted development**: Integrated tools for code generation and assistance

The configuration balances personal preferences with general usability, making it suitable for both the maintainer's workflow and as a reference for Nix-based Neovim setups.
