return {
  setup = function(user_opts)
    local cfg = require("rag.config")
    cfg.setup(user_opts)

    local core = require("rag.core")

    vim.api.nvim_create_user_command("RagIndex", function()
      core.index()
    end, {})

    vim.api.nvim_create_user_command("RagReindex", function()
      core.reindex()
    end, {})

    vim.api.nvim_create_user_command("RagSearch", function(opts)
      local query = opts.args
      local n = tonumber(opts.count) or 4
      core.search(query, n)
    end, {
      nargs = 1,
      complete = function()
        return { "main", "todo", "fixme" }
      end,
      desc = "RAG search – query will be embedded and nearest chunks shown in quickfix",
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function()
        core.update_on_write()
      end,
      desc = "RAG: update embedding on file write",
    })
  end,
}
