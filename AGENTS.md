# nix Neovim Configuration Assistant

This project uses nix for managing Neovim configurations and plugins.

## Project Overview
This repository provides a framework for managing Neovim configurations using Nix. It leverages Nix's powerful package management and functional approach to create reproducible, performant Neovim setups.

## Goals
- Assist with writing and troubleshooting nix config files
- Provide explanations and examples for nix plugin management  
- Help optimize Neovim performance and plugin loading using nix principles
- Support migration from legacy configurations to nix format

## Core Concepts
- **Reproducibility**: All Neovim setups are fully reproducible across different environments
- **Modularity**: Configuration is broken into logical modules (plugins, keymaps, settings)
- **Performance**: Optimized plugin loading with lazy evaluation where appropriate
- **Maintainability**: Clear separation of concerns between Nix definitions and Lua configuration

## Guidelines
- Focus on clear modular configuration snippets
- Suggest idiomatic usage of Lua within Neovim config
- Prioritize performance-aware plugin setup
- Support migration from legacy configurations to nix format
- Use Nix's declarative approach for consistent environment setup

## Common Tasks & Examples

### Plugin Management
- Configure Lua plugins through Nix expressions
- Manage plugin dependencies with proper versioning
- Set up plugin-specific configurations using Nix overlays

### Keymap and Autocommands
- Create custom keymaps in a modular way
- Implement autocommands for enhanced functionality
- Handle plugin-specific keybindings properly

### Performance Optimization
- Lazy-load non-critical plugins
- Profile startup times using built-in Nix profiling tools
- Optimize plugin initialization order

### Debugging
- Troubleshoot startup errors related to plugin loading
- Debug configuration issues using Nix development shells
- Resolve compatibility issues between plugins and Neovim versions

### Documentation
- Write documentation comments within config files
- Generate project documentation using Nix tooling
- Maintain clear separation between Nix and Lua configurations

## Project Structure
```
.
├── default.nix          # Main Nix expression
├── flake.nix            # Flake definition for reproducible builds
├── plugins/             # Plugin configurations and definitions
├── config/              # Neovim configuration files
├── nix/                 # Nix package and overlay definitions
└── README.md            # Documentation
```

## Best Practices
1. **Use flakes** - Leverage Nix Flakes for reproducible builds
2. **Lazy Loading** - Load plugins only when needed
3. **Version Pinning** - Pin plugin versions for stability
4. **Modular Design** - Separate concerns between Nix expressions and Lua code
5. **Testing** - Test configurations in isolated environments
6. **Documentation** - Document both Nix expressions and Lua configurations

## Migration Strategy
When migrating from legacy configurations:
1. Extract existing plugin list
2. Translate plugin configurations to Nix expressions
3. Convert keymaps and autocommands to modular Lua files
4. Test in Nix development shell
5. Gradually transition while maintaining functionality
