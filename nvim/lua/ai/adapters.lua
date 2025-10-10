local M = {
  opts = {
    allow_insecure = true,
    show_defaults = false,
  },
}

M.gemini = function()
  return require("codecompanion.adapters").extend("gemini", {
    env = {
      api_key = "GEMINI_API_KEY",
    },
  })
end
M.airun = function()
  return require("codecompanion.adapters").extend("openai_compatible", {
    env = {
      url = vim.env.AI_RUN_URL,
      api_key = "AI_RUN_TOKEN", -- optional: if your endpoint is authenticated
      chat_url = "/v1/chat/completions", -- optional: default value, override if different
      -- models_endpoint = "/v1/models", -- optional: attaches to the end of the URL to form the endpoint to retrieve models
    },
    schema = {
      model = {
        default = vim.env.AI_RUN_MODEL,
        choices = function(self)
          return {}
        end,
      },
      opts = {
        vision = false,
        tools = true,
      },
      -- num_ctx = {
      --   default = 131072,
      -- },
    },
  })
end

local function ollama_params(model_name, model)
  return function()
    return require("codecompanion.adapters").extend("ollama", {
      env = {
        url = vim.g.ollama_url,
      },
      headers = {
        ["Content-Type"] = "application/json",
      },
      parameters = {
        sync = true,
        keep_alive = "30m",
      },
      name = model_name,
      schema = {
        model = {
          default = model,
        },
        num_ctx = {
          default = 1024 * 32, -- 32768
        },
        temperature = {
          default = 0.5,
        },
      },
    })
  end
end

local function ollama_modify(model_name, model, func)
  local params_func = ollama_params(model_name, model)

  return function()
    local params = params_func()
    return func(params)
  end
end

M.ollama_deepseek = ollama_params("deepseek-r1", "deepseek-r1:14b-qwen-distill-q4_K_M")
M.ollama_deepcode = ollama_params("deepcode", "hf.co/lmstudio-community/DeepCoder-14B-Preview-GGUF:Q4_K_M")
M.ollama_gemma3 = ollama_params("gemma3", "hf.co/unsloth/gemma-3-12b-it-GGUF:Q4_K_M")
M.ollama_codegemma = ollama_params("codegemma", "codegemma:latest")

M.ollama_phimini = ollama_params("phimini", "phi4-mini:latest")

M.ollama_devstral = ollama_modify("devstral", "devstral:latest", function(params)
  params.schema.temperature.default = 0.15
  return params
end)

local function ollama_qwen(model_name, model)
  return ollama_modify(model_name, model, function(params)
    return params
  end)
end

M.ollama_qwencoder = ollama_qwen("qwen2.5", "hf.co/unsloth/Qwen2.5-Coder-7B-Instruct-128K-GGUF:Q4_K_M")
M.ollama_qwen = ollama_qwen("qwen3", "hf.co/unsloth/Qwen3-8B-128K-GGUF:Q6_K_XL")
M.ollama_qwenamall = ollama_qwen("qwen3-small", "qwen3:0.6b")
M.ollama_qwenlarge = ollama_qwen("qwen3-large", "qwen3:30b-a3b")

M.default_adapter = M.airun
return M
