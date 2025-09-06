local M = {}

local model = "hf.co/mradermacher/Qwen2.5-CoderX-14B-v0.5-GGUF:Q8_0"

M.modify_config = function(cfg)
  cfg.provider = "ollama"
  cfg.providers.ollama = {
    endpoint = vim.g.ollama_url,
    model = model,
    disabled_tools = { "python" },
    extra_request_body = {
      -- num_ctx = 1024 * 20,
      temperature = 0.5,
    },
  }
  cfg.rag_service.llm = {
    provider = "ollama",
    endpoint = vim.g.ollama_url,
    api_key = "",
    model = "phi4-mini:latest",
    extra = nil,
  }
  cfg.rag_service.embed = {
    provider = "ollama",
    endpoint = vim.g.ollama_url,
    api_key = "",
    model = "nomic-embed-text:latest",
    extra = {
      embed_batch_size = 10,
    },
  }
  return cfg
end

return M
