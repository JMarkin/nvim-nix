return {
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  },
  settings = {
    Lua = {},
  },
  on_init = function(client)
    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      telemetry = {
        enable = false,
      },
      hint = {
        enable = true,
      },
      diagnostics = {
        globals = {
          "vim",
          "lze",
        },
        libraryFiles = "Disable",
      },
      completion = {
        callSnippet = "Replace",
      },
      workspace = {
        checkThirdParty = false,
      },
    })
  end,
}
