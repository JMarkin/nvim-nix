local is_large_file = require("largefiles").is_large_file
local methods = vim.lsp.protocol.Methods

local opts_l = { silent = true, noremap = true }

local M = {}

M.keys = {
  {
    "<leader>sd",
    function()
      require("fzf-lua").lsp_definitions()
    end,
    { desc = "Search: Definitions", table.unpack(opts_l) },
  },
  {
    "<leader>sS",
    function()
      require("fzf-lua").lsp_live_workspace_symbols()
    end,
    { desc = "Search: Symbols", table.unpack(opts_l) },
  },
  {
    "grr",
    function()
      require("fzf-lua").lsp_references({ ignore_current_line = true })
    end,
    { desc = "Search: references", table.unpack(opts_l) },
  },
  {
    "gd",
    vim.lsp.buf.definition,
    { desc = "GoTo: definition", table.unpack(opts_l) },
  },
  {
    "gD",
    vim.lsp.buf.declaration,
    { desc = "GoTo: declarations", table.unpack(opts_l) },
  },
  {
    "K",
    vim.lsp.buf.hover,
    { silent = true, desc = "Lang: hover doc", table.unpack(opts_l) },
  },
  {
    "grn",
    vim.lsp.buf.rename,
    { desc = "Lang: rename", table.unpack(opts_l) },
  },
  {
    "gE",
    vim.diagnostic.open_float,
    { desc = "Lang: diagnistic", table.unpack(opts_l) },
  },
  {
    "]e",
    function()
      vim.diagnostic.jump({ count = vim.v.count1, severity = vim.diagnostic.severity.ERROR })
    end,
    { desc = "Jump to the next ERROR diagnostic in the current buffer", table.unpack(opts_l) },
  },
  {
    "[e",
    function()
      vim.diagnostic.jump({ count = -vim.v.count1, severity = vim.diagnostic.severity.ERROR })
    end,
    { desc = "Jump to the previous ERROR diagnostic in the current buffer", table.unpack(opts_l) },
  },
}

local inlay_hints_group = vim.api.nvim_create_augroup("toggle_inlay_hints", { clear = false })

local function toggle_inlay_hints(bufnr)
  if bufnr == nil then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })

  if not enabled then
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = inlay_hints_group,
      desc = "Enable inlay hints",
      buffer = bufnr,
      callback = function()
        vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
      end,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = inlay_hints_group,
      desc = "Disable inlay hints",
      buffer = bufnr,
      callback = function()
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end,
    })
  else
    vim.api.nvim_clear_autocmds({
      buffer = bufnr,
      group = inlay_hints_group,
    })
  end
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
end

--- https://github.com/neovim/nvim-lspconfig/blob/f4619ab31fc4676001ea05ae8200846e6e7700c7/plugin/lspconfig.lua#L123
--- Sets up LSP keymaps and autocommands for the given buffer.
---@param client vim.lsp.Client
---@param bufnr integer
function M.on_attach(client, bufnr)
  if is_large_file(bufnr, true) then
    vim.bo[bufnr].tagfunc = nil
    return 0
  end

  if client:supports_method(methods.textDocument_inlayHint, bufnr) then
    vim.keymap.set(
      { "n" },
      "<leader>ti",
      toggle_inlay_hints,
      { buffer = bufnr, silent = true, desc = "Toggle Inlay hint", noremap = true }
    )
    toggle_inlay_hints(bufnr)
  end

  if client.name == "phoenix" or vim.b[bufnr].lsp_keymaps_set == 1 then
    return 1
  end

  local prev_keymaps = {}

  for _, keymap in ipairs(M.keys) do
    local name = keymap[1]
    if #keymap == 3 then
      table.insert(keymap, 1, "n")
    end

    if type(keymap[2]) == "table" then
      for _, mode in ipairs(keymap[2]) do
        table.insert(prev_keymaps, vim.fn.maparg(name, mode, false, true))
      end
    else
      table.insert(prev_keymaps, vim.fn.maparg(name, keymap[2], false, true))
    end

    keymap[4].buffer = bufnr

    vim.keymap.set(table.unpack(keymap))
  end

  if client:supports_method(methods.textDocument_codeAction, bufnr) then
    table.insert(prev_keymaps, vim.fn.maparg("gra", "n", false, true))
    table.insert(prev_keymaps, vim.fn.maparg("gra", "v", false, true))
    vim.keymap.set({ "n", "v" }, "gra", function()
      require("fzf-lua").lsp_code_actions({
        winopts = {
          relative = "cursor",
          width = 0.6,
          height = 0.6,
          row = 1,
          preview = { vertical = "up:70%" },
        },
      })
    end, { desc = "Code actions", silent = true })
  end

  vim.api.nvim_create_autocmd("LspDetach", {
    buffer = bufnr,
    callback = function()
      for _, keymap in ipairs(prev_keymaps) do
        pcall(vim.fn.mapset, keymap)
      end
      vim.b[bufnr].lsp_keymaps_set = 0
    end,
  })

  if not client:supports_method(methods.textDocument_hover, bufnr) then
    client.server_capabilities.hoverProvider = false
  end

  -- vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  vim.b[bufnr].lsp_keymaps_set = 1
  return 1
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

-- copy from blink.cmp
capabilities.textDocument = {
  foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  },
  completion = {
    dynamicRegistration = false,
    completionItem = {
      snippetSupport = true,
      commitCharactersSupport = false, -- todo:
      documentationFormat = { "markdown", "plaintext" },
      deprecatedSupport = true,
      preselectSupport = false, -- todo:
      tagSupport = { valueSet = { 1 } }, -- deprecated
      insertReplaceSupport = true, -- todo:
      resolveSupport = {
        properties = {
          "documentation",
          "detail",
          "additionalTextEdits",
          "command",
          "data",
        },
      },
      insertTextModeSupport = {
        -- todo: support adjustIndentation
        valueSet = { 1 }, -- asIs
      },
      labelDetailsSupport = true,
    },
    contextSupport = true,
    insertTextMode = 1,
    completionList = {
      itemDefaults = {
        "commitCharacters",
        "editRange",
        "insertTextFormat",
        "insertTextMode",
        "data",
      },
    },
  },
}

vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = vim.g.root_pattern,
  -- flags = {
  --   debounce_text_changes = 1000,
  -- },
})

local group = vim.api.nvim_create_augroup("my-lsp-config", { clear = true })

M.setup_autocmds = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "attach lsp event",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end
      if vim.b[args.buf].lsp_attached == nil then
        vim.b[args.buf].lsp_attached = {}
      elseif vim.b[args.buf].lsp_attached[client.id] ~= nil then
        return
      end

      client.server_capabilities.semanticTokensProvider = nil

      local attached = M.on_attach(client, args.buf)
      if not attached then
        local out = vim.lsp.buf_detach_client(args.buf, client.id)
        if out then
          vim.b[args.buf].lsp_attached[client.id] = nil
        end
        return
      end

      vim.b[args.buf].lsp_attached[client.id] = 1

      if not client:supports_method(vim.lsp.protocol.Methods.textDocument_completion, args.buf) then
        return
      end

      local chars = client.server_capabilities.completionProvider.triggerCharacters
      if chars then
        for i = string.byte("a"), string.byte("z") do
          if not vim.list_contains(chars, string.char(i)) then
            table.insert(chars, string.char(i))
          end
        end

        for i = string.byte("A"), string.byte("Z") do
          if not vim.list_contains(chars, string.char(i)) then
            table.insert(chars, string.char(i))
          end
        end
      end

      -- require("lsp.autocomplete").attach_completion(client, args.buf)
    end,
  })

  local timer = nil --[[uv_timer_t]]
  local function reset_timer()
    if timer then
      timer:stop()
      timer:close()
    end
    timer = nil
  end

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    desc = "Auto stop client when no buffer atttached",
    callback = function(args)
      local client_id = args.data.client_id
      local client = vim.lsp.get_clients({ client_id = client_id })[1]
      if not client or not vim.tbl_isempty(client.attached_buffers) then
        return
      end
      reset_timer()
      timer = assert(vim.loop.new_timer())
      timer:start(200, 0, function()
        reset_timer()
        vim.schedule(function()
          vim.lsp.stop_client(client_id, true)
        end)
      end)
    end,
  })
end

return M
