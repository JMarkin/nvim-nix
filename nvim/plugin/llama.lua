if vim.g.did_load_llama_plugin then
  return
end
vim.g.did_load_llama_plugin = true

local LLAMA = require("llama")

local base_url = vim.env.LLAMA_CPP_BASE_URL or "http://127.0.0.1:8012"
LLAMA.setup({
  endpoint_fim = base_url .. "/infill",
  endpoint_inst = base_url .. "/v1/chat/completions",
  model_fim = "fim-small",
  model_inst = "qwen3.5-35b",
  api_key = vim.env.LLAMA_CPP_API_KEY or "",
  n_prefix = 256,
  n_suffix = 64,
  n_predict = 128,
  stop_strings = {},
  t_max_prompt_ms = 500,
  t_max_predict_ms = 1000,
  show_info = 2,
  auto_fim = true,
  max_line_suffix = 8,
  max_cache_keys = 256,
  ring_n_chunks = 16,
  ring_chunk_size = 64,
  ring_scope = 1024,
  ring_update_ms = 500,
  keymap_fim_trigger = "<c-x><a-z>",
  keymap_fim_accept_full = "<a-f>",
  keymap_fim_accept_line = "<a-z>",
  keymap_fim_accept_word = "<a-w>",
  keymap_inst_trigger = "<leader>li",
  keymap_inst_rerun = "<leader>lr",
  keymap_inst_continue = "<leader>lc",
  keymap_inst_accept = "<Tab>",
  keymap_inst_cancel = "<Esc>",
  enable_at_startup = false,
})

vim.api.nvim_create_user_command("LlamaEnable", function()
  LLAMA.enable()
end, {})
vim.api.nvim_create_user_command("LlamaDisable", function()
  LLAMA.disable()
end, {})
vim.api.nvim_create_user_command("LlamaToggle", function()
  LLAMA.toggle()
end, {})
vim.api.nvim_create_user_command("LlamaToggleAutoFim", function()
  LLAMA.toggle_auto_fim()
end, {})
vim.api.nvim_create_user_command("LlamaInstruct", function(opts)
  LLAMA.inst(opts.line1, opts.line2)
end, { range = true })
vim.api.nvim_create_user_command("LlamaInstructContinue", function()
  LLAMA.inst_continue()
end, {})
