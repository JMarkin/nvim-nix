local default = {
  base_url = "http://localhost:8012",
  api_key = "",
  org_id = "",
  embedding_model = "embeddings-code",
  db_path = vim.fn.stdpath("data") .. "/rag_index.db",
  cache_path = vim.fn.stdpath("data") .. "/rag_emb_cache.json",
  max_file_size = 10 * 1024 * 1024,
  chunk_size = 250,
  overlap = 50,
  workers = 4,
  repo_detection_depth = 2,
}

local M = {}
M._cfg = default

function M.setup(opts)
  M._cfg = vim.tbl_deep_extend("force", default, opts or {})
end

function M.get_config()
  return M._cfg
end

return M
