return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
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
          "lze"
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
  on_attach = function(client, buf)
    if vim.bo[buf].filetype == "lua" and vim.api.nvim_buf_get_name(buf):find("_spec") then
      vim.diagnostic.enable(false, { bufnr = buf })
      return
    end
  end,
}
