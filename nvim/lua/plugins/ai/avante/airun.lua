local M = {}

M.modify_config = function(cfg)
  cfg.provider = "airun"
  cfg.mode = "legacy"
  cfg.auto_suggestions_provider = "airun_autocomplete"
  cfg.providers.airun = {
    __inherited_from = "openai",
    endpoint = vim.g.airun_endpoint,
    api_key_name = "AI_RUN_TOKEN",
    model = vim.g.airun_model,
    disable_tools = true,
    allow_insecure = true,
    extra = {
      temperature = 0.7,
      max_tokens = 512,
    },
  }
  cfg.providers.airun_autocomplete = {
    __inherited_from = "openai",
    endpoint = vim.g.airun_endpoint,
    allow_insecure = true,
    api_key_name = "AI_RUN_TOKEN",
    model = vim.g.airun_autocomplete_model,
    disable_tools = true,
  }
  cfg.rag_service.enabled = true
  cfg.rag_service.llm = {
    provider = "airun",
    endpoint = vim.g.airun_endpoint,
    allow_insecure = true,
    api_key = "AI_RUN_TOKEN",
    model = vim.g.airun_model,
    extra = {
      temperature = 0.7,
      max_tokens = 512,
    },
  }
  cfg.rag_service.embed = {
    provider = "airun",
    endpoint = vim.g.airun_endpoint,
    allow_insecure = true,
    api_key = "AI_RUN_TOKEN",
    model = vim.g.ai_run_embedded_model,
    extra = {
      embed_batch_size = 16,
    },
  }

  return cfg
end

return M
