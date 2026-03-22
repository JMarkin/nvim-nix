if vim.g.did_load_llama_plugin then
  return
end
vim.g.did_load_llama_plugin = true

local LLAMA = require("llama")
LLAMA.setup()
LLAMA.enable()

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
