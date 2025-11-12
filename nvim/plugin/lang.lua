if vim.g.did_load_lang_plugin then
  return
end
vim.g.did_load_lang_plugin = true

vim.g.rustaceanvim = {
  tools = {},
  server = {
    on_attach = function(client, bufnr) end,
    default_settings = {
      ["rust-analyzer"] = {
        checkOnSave = true,
        completion = {
          autoimport = {
            enable = false,
          },
        },
        procMacro = {
          enable = true,
        },
        files = {
          excludeDirs = {
            ".direnv",
            "_build",
            ".dart_tool",
            ".flatpak-builder",
            ".git",
            ".gitlab",
            ".gitlab-ci",
            ".gradle",
            ".idea",
            ".next",
            ".project",
            ".scannerwork",
            ".settings",
            ".venv",
            "archetype-resources",
            "bin",
            "hooks",
            "node_modules",
            "po",
            "screenshots",
            "target",
          },
        },
      },
    },
  },
  -- DAP configuration
  dap = {},
}
