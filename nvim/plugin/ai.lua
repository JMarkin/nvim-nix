if vim.g.did_load_ai_plugin then
  return
end
vim.g.did_load_ai_plugin = true

local g = vim.g

g.ollama_host = vim.env.OLLAMA_HOST or "localhost"
g.ollama_port = vim.env.OLLAMA_PORT or "11434"
g.ollama_url = string.format("http://%s:%s", g.ollama_host, g.ollama_port)
g.ollama_generate_endpoint = string.format("%s/api/generate", g.ollama_url)
g.ollama_chat_endpoint = string.format("%s/api/chat", g.ollama_url)
g.ollama_completions_endpoint = string.format("%s/api/generate", g.ollama_url)

g.airun_url = vim.env.AI_RUN_URL
g.airun_endpoint = string.format("%s/v1", g.airun_url)
g.airun_chat_endpoint = string.format("%s/v1/chat", g.airun_url)
g.airun_model = vim.env.AI_RUN_MODEL
g.airun_autocomplete_model = vim.env.AI_RUN_AUOTOCOMPLETE_MODEL
g.airun_embedded_model = vim.env.AI_RUN_EMBEDDED_MODEL
