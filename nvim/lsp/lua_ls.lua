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
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath("config")
        and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      telemetry = {
        enable = false,
      },
      hint = {
        enable = true,
      },
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = {
          "vim",
        },
        libraryFiles = "Disable",
      },
      completion = {
        callSnippet = "Replace",
      },
      workspace = {
        checkThirdParty = false,
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.expand("$VIM/lazy")] = true,
          [vim.fn.expand("$VIMRUNTIME")] = true,
          [vim.fn.expand("~/.config/nvim/lua")] = true,
        },
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
