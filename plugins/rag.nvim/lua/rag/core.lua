local sqlite = require("rag.db")
local cache_mod = require("rag.cache")
local json = vim.json
local http = require("rag.curl")

local function chunk_hash(chunk)
  return vim.fn.sha256(chunk)
end

local function chunk_file(full_text, file_name, cfg)
  local chunks = {}
  local start = 1
  local size = cfg.chunk_size
  while start <= #full_text do
    local stop = start + size - 1
    local chunk = full_text:sub(start, stop)
    table.insert(chunks, chunk)
    start = stop - cfg.overlap + 1
  end
  return chunks
end

local function rg_files()
  local ok, files = pcall(vim.fn.systemlist, "rg --files")
  if not ok then
    vim.notify("RAG: rg failed – " .. tostring(files), vim.log.levels.ERROR)
    return {}
  end
  return files
end

local function filter_by_size(files, cfg)
  local out = {}
  for _, f in ipairs(files) do
    local stat = vim.uv.fs_stat(f)
    if stat and stat.size <= cfg.max_file_size then
      table.insert(out, f)
    end
  end
  return out
end

local function get_project_id(filepath, cfg)
  local dir = filepath
  for _ = 1, cfg.repo_detection_depth do
    local git_dir = dir .. "/.git"
    local st = vim.uv.fs_stat(git_dir)
    if st then
      local root = dir
      while true do
        local parent = root .. "/.."
        local parent_stat = vim.uv.fs_stat(parent)
        if not parent_stat then
          break
        end
        root = parent
        if vim.uv.fs_stat(root .. "/.git") then
          break
        end
      end
      return root
    end
    local new_dir = dir:sub(1, #dir - 1)
    if not new_dir or new_dir == dir then
      break
    end
    dir = new_dir
  end
  return nil
end

local function embed(text, cfg)
  local h = chunk_hash(text)
  local cached = cache_mod.get(h)
  if cached then
    return cached
  end

  local payload = {
    model = cfg.embedding_model,
    input = text,
    encoding_format = "float",
  }
  local body = json.encode(payload)

  local data = http.post({
    url = cfg.base_url .. "/v1/embeddings",
    headers = {
      ["Authorization"] = "Bearer " .. cfg.api_key,
      ["Content-Type"] = "application/json",
    },
    body = body,
  })

  if not data then
    vim.notify("RAG: HTTP request error – ", vim.log.levels.ERROR)
    return nil
  end

  local embedding = data[1].embedding
  cache_mod.set(h, embedding)
  return embedding
end

local function open_db(cfg)
  cfg = cfg or require("rag.config").get_config()
  local db = sqlite.open(cfg.db_path)
  db:exec([[
    CREATE VIRTUAL TABLE IF NOT EXISTS rag_vectors
    USING vec0(
      chunk_id INTEGER PRIMARY KEY,
      embedding float[1536],
      +file_path TEXT,
      +chunk_text TEXT,
      +line_no INTEGER,
      +project_id TEXT
    );
  ]])
  return db
end

local function store_vector(db, file_path, chunk_id, embedding, chunk_text, line_no, project_id)
  db:exec(
    [[
    INSERT INTO rag_vectors
      (chunk_id, embedding, file_path, chunk_text, line_no, project_id)
    VALUES (?, ?, ?, ?, ?, ?);
  ]],
    chunk_id,
    embedding,
    file_path,
    chunk_text,
    line_no,
    project_id or ""
  )
end

local function search_vectors(db, query_vec, limit)
  local sql = [[
    SELECT file_path, chunk_id, chunk_text, line_no, vec_distance(embedding, ?) as distance
    FROM rag_vectors
    WHERE embedding match ?
    ORDER BY distance ASC
    LIMIT ?
  ]]
  local stmt = db:prepare(sql)
  stmt:bind(1, query_vec)
  stmt:bind(2, query_vec)
  stmt:bind(2, limit)

  local results = {}
  while stmt:step() == sqlite.ROWS do
    local row = {
      file_path = stmt:column_text(0),
      chunk_id = stmt:column_int(1),
      chunk_text = stmt:column_text(2),
      line_no = stmt:column_int(3),
      distance = stmt:column_double(4) or 0,
    }
    table.insert(results, row)
  end
  stmt:finalize()
  return results
end

local function readFileSync(path)
  local fd = assert(vim.uv.fs_open(path, "r", 438))
  local stat = assert(vim.uv.fs_fstat(fd))
  local data = assert(vim.uv.fs_read(fd, stat.size, 0))
  assert(vim.uv.fs_close(fd))
  return data
end

local function index_one_file(filepath, project_id, cfg)
  local stat = vim.uv.fs_stat(filepath)
  if not stat or stat.size > cfg.max_file_size then
    vim.notify("RAG: skipping " .. filepath .. " (size > max)", vim.log.levels.WARN)
    return
  end

  local lines = readFileSync(filepath)
  local chunks = chunk_file(lines, filepath, cfg)

  local db = open_db(cfg)
  for id, chunk in ipairs(chunks) do
    local embedding = embed(chunk, cfg)
    if embedding then
      local start_line = math.max(1, id * cfg.chunk_size - cfg.overlap)
      store_vector(db, filepath, id, embedding, chunk, start_line, project_id)
    end
  end
  db:close()

  vim.notify(string.format("RAG: indexed [%s] %s", project_id or "none", filepath), vim.log.levels.INFO)
end

local function index(full_reindex)
  local cfg = require("rag.config").get_config()
  local files = rg_files()
  local to_index = filter_by_size(files, cfg)

  if full_reindex then
    local db = sqlite.open(cfg.db_path)
    db:exec("DELETE FROM rag_vectors;")
    db:close()
  end

  local total = #to_index
  local processed = 0

  local function report()
    processed = processed + 1
    local pct = math.floor(processed / total * 100)
    vim.schedule(function()
      vim.notify(string.format("RAG: %d/%d files processed (%d%%)", processed, total, pct), vim.log.levels.INFO)
    end)
  end

  local proj_cache = {}
  for _, f in ipairs(to_index) do
    local proj = proj_cache[f]
    if not proj then
      proj = get_project_id(f, cfg)
      proj_cache[f] = proj
    end
    vim.schedule(function()
      index_one_file(f, proj, cfg)
      report()
    end)
  end
end

local function reindex()
  index(true)
end

local function search(query, n)
  local cfg = require("rag.config").get_config()

  n = n or 10
  local db = open_db(cfg)
  local query_vec = embed(query, cfg)
  if not query_vec then
    db:close()
    return
  end

  local hits = search_vectors(db, query_vec, n)
  db:close()

  local qf = {}
  for _, h in ipairs(hits) do
    local snippet = h.chunk_text:sub(1, 80)
    table.insert(qf, {
      filename = h.file_path,
      lnum = h.line_no,
      col = 1,
      text = string.format("%s:%d – %s … %s (dist=%0.3f)", h.file_path, h.line_no, snippet, h.distance),
    })
  end

  vim.fn.setqflist(qf, " ", { title = "RAG Search Results" })
  vim.cmd("copen")
  vim.notify(string.format("RAG: %d results shown", #qf), vim.log.levels.INFO)
end

local function update_on_bufwrite()
  local cfg = require("rag.config").get_config()

  local filepath = vim.fn.expand("%:p")
  if not filepath or filepath == "" then
    return
  end

  local stat = vim.uv.fs_stat(filepath)
  if not stat then
    return
  end
  if stat.size > cfg.max_file_size then
    return
  end

  local ignored = vim.fn.systemlist('rg --no-filename "' .. filepath .. '"')
  if #ignored > 0 then
    return
  end

  local proj_id = get_project_id(filepath, cfg)

  index_one_file(filepath, proj_id, cfg)
end

return {
  open_db = open_db,
  index = index,
  reindex = reindex,
  search = search,
  update_on_write = update_on_bufwrite,
}
