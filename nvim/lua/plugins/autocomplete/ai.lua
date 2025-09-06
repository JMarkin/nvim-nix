local vectorcode_cacher = nil
local has_vc = nil

local vectorcacher = function()
  if has_vc ~= nil then
    return has_vc, vectorcode_cacher
  end

  local vectorcode_config
  has_vc, vectorcode_config = pcall(require, "vectorcode.config")
  if has_vc then
    vectorcode_cacher = vectorcode_config.get_cacher_backend()
  end

  return has_vc, vectorcode_cacher
end

-- roughly equate to 2000 tokens for LLM
local RAG_Context_Window_Size = 8000

local get_prompt = function(get_prompt_message, file_sep, fim_suf, fim_pref, fim_mid)
  get_prompt_message = get_prompt_message or function()
    return ""
  end
  return function(pref, suff)
    local prompt_message = get_prompt_message()

    local h_vc, vc = vectorcacher()
    if h_vc and vc then
      for _, file in ipairs(vc.query_from_cache(0)) do
        prompt_message = file_sep .. file.path .. "\n" .. file.document
      end
    end

    prompt_message = vim.fn.strcharpart(prompt_message, 0, RAG_Context_Window_Size)
    local msg = prompt_message .. fim_suf .. suff .. fim_pref .. pref .. fim_mid
    return msg
  end
end

local AiRun = {
  api_key = "AI_RUN_TOKEN",
  name = "AiRun",
  stream = true,
  end_point = vim.g.airun_endpoint,
  model = vim.g.airun_model,
  template = {
    prompt = get_prompt(nil, "<[file-sep]>", "<[fim-suffix]>", "<[fim-prefix]>", "<[fim-middle]>"),
    suffix = false,
  },
  optional = {
    stop = {
      "<|endoftext|>",
      "<|fim-prefix|>",
      "<|fim-middle|>",
      "<|fim-suffix|>",
      "<|fim-pad|>",
      "<|repo_name|>",
      "<|file-sep|>",
    },
    max_tokens = 300,
  },
}

local QwenCoder = {
  api_key = "TERM",
  name = "OPENCODER",
  stream = true,
  end_point = vim.g.ollama_completions_endpoint,
  model = "qwen2.5-coder:3b-instruct-q8_0",
  template = {
    prompt = get_prompt(nil, "<[file_sep]>", "<[fim_suffix]>", "<[fim_prefix]>", "<[fim_middle]>"),
    suffix = false,
  },
  optional = {
    max_tokens = 300,
  },
}

local attach = function(bufnr)
  local lsps = vim.lsp.get_clients({ name = "minuet", bufnr = bufnr })

  if #lsps and #lsps > 0 then
    vim.notify("Minuet LSP already attached to current buffer", vim.log.levels.INFO)
    return
  end

  require("minuet.lsp").start_server({ buf = bufnr })
end

local detach = function(bufnr)
  local lsps = vim.lsp.get_clients({ name = "minuet", bufnr = bufnr })

  if #lsps == 0 then
    vim.notify("Minuet LSP not attached to current buffer", vim.log.levels.INFO)
    return
  end

  for _, client in ipairs(lsps) do
    vim.lsp.buf_detach_client(bufnr, client.id)
  end

  vim.notify("Minuet LSP detached from current buffer", vim.log.levels.INFO)
end

local enable_auto_trigger = function(bufnr)
  local lsps = vim.lsp.get_clients({ name = "minuet", bufnr = bufnr })

  if #lsps == 0 then
    vim.b[bufnr].minuet_lsp_enable_auto_trigger = true
    attach()
    return
  end

  for _, client in ipairs(lsps) do
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  end

  vim.notify("Minuet LSP is enabled for auto triggering", vim.log.levels.INFO)
end

local disable_auto_trigger = function(bufnr)
  vim.b[bufnr].minuet_lsp_enable_auto_trigger = nil
  local lsps = vim.lsp.get_clients({ name = "minuet", bufnr = bufnr })

  if #lsps == 0 then
    return
  end

  for _, client in ipairs(lsps) do
    vim.lsp.completion.enable(false, client.id, bufnr)
    vim.notify("Minuet LSP is disabled for auto triggering", vim.log.levels.INFO)
  end
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    cmd = { "Minuet" },
    -- keys = {
    --   {
    --     "<C-x><C-z>",
    --     function()
    --       local bufnr = vim.api.nvim_get_current_buf()
    --       attach(bufnr)
    --       enable_auto_trigger(bufnr)
    --       vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "BufWinLeave" }, {
    --         once = true,
    --         callback = function()
    --           if vim.b[bufnr].minuet_lsp_enable_auto_trigger then
    --             disable_auto_trigger(bufnr)
    --             detach(bufnr)
    --           end
    --         end,
    --       })
    --     end,
    --     mode = "i",
    --   },
    -- },
    config = function()
      -- This uses the async cache to accelerate the prompt construction.
      -- There's also the require('vectorcode').query API, which provides
      -- more up-to-date information, but at the cost of blocking the main UI.
      require("minuet").setup({
        add_single_line_entry = true,
        n_completions = 2,
        -- I recommend you start with a small context window firstly, and gradually
        -- increase it based on your local computing power.
        context_window = 4096,
        after_cursor_filter_length = 30,
        debounce = 600,
        -- notify = "debug",
        provider = "openai_fim_compatible",
        provider_options = {
          openai_fim_compatible = AiRun,
          -- openai_fim_compatible = QwenCoder,
        },
        request_timeout = 10,
        -- virtualtext = {
        --     auto_trigger_ft = {},
        --     keymap = {
        --         -- accept whole completion
        --         accept = '<A-a>',
        --         -- accept one line
        --         accept_line = '<A-a>',
        --         -- accept n lines (prompts for number)
        --         -- e.g. "A-z 2 CR" will accept 2 lines
        --         accept_n_lines = '<A-z>',
        --         -- Cycle to prev completion item, or manually invoke completion
        --         prev = '<A-[>',
        --         -- Cycle to next completion item, or manually invoke completion
        --         next = '<A-]>',
        --         dismiss = '<A-e>',
        --     },
        -- },
        -- lsp = {
        --   enabled_ft = { "lua", "python" },
        -- },
      })
    end,
  },
}
