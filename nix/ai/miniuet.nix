{ inputs, pkgs, mkNvimPlugin, ... }:
{
  plugins = with pkgs.vimPlugins; [
    {
      plugin = vectorcode-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function()
            local cacher = require("vectorcode.config").get_cacher_backend()
            local utils = require("vectorcode.cacher").utils
            local bufnr = vim.api.nvim_get_current_buf()

            utils.async_check("config", function()
              cacher.register_buffer(bufnr, {
                n_query = 10,
              })
            end, nil)
          end,
          desc = "Register buffer for VectorCode",
        })
        lze.load {
          "${vectorcode-nvim.pname}",
          on_require = {"vectorcode", "vectorcode.config", "vectorcode.cacher"},
          after = function()
          require("vectorcode").setup(
            ---@type VectorCode.Opts
            {
              cli_cmds = {
                vectorcode = "${pkgs.vectorcode}/bin/vectorcode",
              },
              ---@type VectorCode.RegisterOpts
              async_opts = {
                debounce = 10,
                events = { "BufWritePost", "InsertEnter", "BufReadPost" },
                exclude_this = true,
                n_query = 1,
                notify = false,
                query_cb = require("vectorcode.utils").make_surrounding_lines_cb(-1),
                run_on_register = false,
              },
              async_backend = "lsp", -- or "lsp"
              exclude_this = true,
              n_query = 1,
              notify = true,
              timeout_ms = 5000,
              on_setup = {
                update = true, -- set to true to enable update when `setup` is called.
                lsp = true,
              },
              sync_log_env_var = false,
            }
            )
          end
        }
      '';
    }
    {
      plugin = minuet-ai-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''

        lze.load {
          "${minuet-ai-nvim.pname}",
          on_require = {"minuet"},
          after = function()
        local has_vc, vectorcode_config = pcall(require, 'vectorcode.config')
        local vectorcode_cacher = nil
        if has_vc then
            vectorcode_cacher = vectorcode_config.get_cacher_backend()
        end

        -- roughly equate to 2000 tokens for LLM
        local RAG_Context_Window_Size = 8000
        local prompt = function(pref, suff, _)
            local prompt_message = ""
            if has_vc then
                for _, file in ipairs(vectorcode_cacher.query_from_cache(0)) do
                    prompt_message = prompt_message .. '<|file_sep|>' .. file.path .. '\n' .. file.document
                end
            end

            prompt_message = vim.fn.strcharpart(prompt_message, 0, RAG_Context_Window_Size)

            return prompt_message .. '<|fim_prefix|>' .. pref .. '<|fim_suffix|>' .. suff .. '<|fim_middle|>'
        end

        local openai_fim_compatible = {
            api_key = 'TERM',
            name = 'Llama.cpp',
            end_point = 'http://localhost:51536/v1/completions',
            model = 'PLACEHOLDER',
            optional = {
                max_tokens = 60,
            },
            template = {
                prompt = prompt,
                suffix = false,
            },
            optional = {
                stop = {
                    "<|endoftext|>",
                    "<|fim_prefix|>",
                    "<|fim_middle|>",
                    "<|fim_suffix|>",
                    "<|fim_pad|>",
                    "<|repo_name|>",
                    "<|file_sep|>",
                    "<|im_start|>",
                    "<|im_end|>",
                    "/src/",
                    "#- coding: utf-8",
                    "# Path:",
                },
                max_tokens = 300,
            },
        }

        if vim.env.AI_RUN_URL ~= nil then
            openai_fim_compatible.api_key = "AI_RUN_API_KEY"
            openai_fim_compatible.end_point = vim.env.AI_RUN_URL + "v1/completions"
            openai_fim_compatible.name = "AI_RUN"
            openai_fim_compatible.model = "x5-airun-small-coder"
        end

        require('minuet').setup {
            provider = 'openai_fim_compatible',
            n_completions = 1, -- recommend for local model for resource saving
            -- I recommend beginning with a small context window size and incrementally
            -- expanding it, depending on your local computing power. A context window
            -- of 512, serves as an good starting point to estimate your computing
            -- power. Once you have a reliable estimate of your local computing power,
            -- you should adjust the context window to a larger value.
            context_window = 512,

            debounce = 300,
            provider_options = {
                openai_fim_compatible=openai_fim_compatible,
            },
          }
          end
        }
      '';
    }
  ];

  packages = with pkgs; [
    vectorcode
  ];
}

