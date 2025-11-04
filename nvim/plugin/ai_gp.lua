if vim.g.did_load_gp_plugin or vim.g.did_load_ai_plugin then
  return
end
vim.g.did_load_gp_plugin = true

lze.load({
  "gp.nvim",
  event = "BufEnter",
  after = function()
    require("gp").setup({
      providers = {
        openai = {
          disable = true,
        },
        ollama = {
          disable = false,
          endpoint = vim.g.ollama_chat_endpoint,
        },
      },
      whisper = {
        disable = true,
      },
      agents = {
        {
          name = "GPT-OSS",
          chat = true,
          command = true,
          provider = "ollama",
          model = {
            model = "gpt-oss-safeguard:20b",
            num_ctx = 1024 * 8,
          },
          system_prompt = require("gp.defaults").code_system_prompt,
        },
        {
          name = "Gemma",
          chat = true,
          command = true,
          provider = "ollama",
          model = { model = "orieg/gemma3-tools:4b" },
          system_prompt = require("gp.defaults").code_system_prompt,
        },
        {
          name = "Cogito",
          chat = false,
          command = true,
          provider = "ollama",
          model = {
            model = "cogito:14b",
            num_ctx = 1024 * 8,
          },
          system_prompt = require("gp.defaults").code_system_prompt,
        },
        {
          name = "Amoral",
          chat = true,
          command = true,
          provider = "ollama",
          model = {
            model = "hf.co/mradermacher/amoral-gemma3-12B-v2-qat-i1-GGUF:Q4_K_M ",
            num_ctx = 1024 * 8,
          },
          system_prompt = require("gp.defaults").code_system_prompt,
        },
        {
          name = "Qwen3-Coder",
          chat = false,
          command = true,
          provider = "ollama",
          model = {
            model = "danielsheep/Qwen3-Coder-30B-A3B-Instruct-1M-Unsloth:UD-IQ3_XXS",
            num_ctx = 1024 * 8,
          },
          system_prompt = "Please return ONLY code snippets.\nSTART AND END YOUR ANSWER WITH:\n\n```",
        },
      },
      default_chat_agent = "GPT-OSS",
      default_command_agent = "Gemma",
      hooks = {
        -- GpImplement rewrites the provided selection/range based on comments in it
        Implement = function(gp, params)
          local template = "Having following from {{filename}}:\n\n"
            .. "```{{filetype}}\n{{selection}}\n```\n\n"
            .. "Please rewrite this according to the contained instructions."
            .. "\n\nRespond exclusively with the snippet that should replace the selection above."

          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
        UnitTests = function(gp, params)
          local template = "I have the following code from {{filename}}:\n\n"
            .. "```{{filetype}}\n{{selection}}\n```\n\n"
            .. "Please respond by writing table driven unit tests for the code above."
          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.vnew, agent, template)
        end,
        Explain = function(gp, params)
          local template = "I have the following code from {{filename}}:\n\n"
            .. "```{{filetype}}\n{{selection}}\n```\n\n"
            .. "Please respond by explaining the code above."
          local agent = gp.get_chat_agent()
          gp.Prompt(params, gp.Target.popup, agent, template)
        end,
        TranslateRu = function(gp, params)
          local chat_system_prompt = "You are a Translator, please translate to Russian."
          local agent = gp.get_chat_agent("GPT-OSS")
          gp.cmd.ChatNew(params, chat_system_prompt, agent)
        end,
        TranslateEn = function(gp, params)
          local chat_system_prompt = "You are a Translator, please translate to English."
          local agent = gp.get_chat_agent("GPT-OSS")
          gp.cmd.ChatNew(params, chat_system_prompt, agent)
        end,
        CodeReview = function(gp, params)
          local template = "I have the following code from {{filename}}:\n\n"
            .. "```{{filetype}}\n{{selection}}\n```\n\n"
            .. "Please analyze for code smells and suggest improvements."
          local agent = gp.get_chat_agent()
          gp.Prompt(params, gp.Target.enew("markdown"), agent, template)
        end,
        -- example of making :%GpChatNew a dedicated command which
        -- opens new chat with the entire current buffer as a context
        BufferChatNew = function(gp, _)
          -- call GpChatNew command in range mode on whole buffer
          vim.api.nvim_command("%" .. gp.config.cmd_prefix .. "ChatNew")
        end,
      },
    })
  end,
})
