if vim.g.did_load_format_plugin then
  return
end
vim.g.did_load_format_plugin = true

local g = vim.g

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

g.formatters_by_ft = {
  lua = { "stylua" },
  python = { "ruff_format" },
  rust = { "rustfmt" },
  javascript = { "prettierd" },
  json = { "fixjson" },
  jinja = { "djlint" },
  htmldjango = { "djlint" },
  nix = { "nixpkgs_fmt" },
  go = { "gofmt" },
}

for _, lang in ipairs({
  "javascript",
  "typescript",
  "jsx",
  "tsx",
  "jsonc",
}) do
  g.formatters_by_ft[lang] = { "biome" }
end
for _, lang in ipairs({
  "markdown",
  "html",
  "css",
  "yaml",
  "scss",
  "vue",
}) do
  g.formatters_by_ft[lang] = { "prettierd" }
end

vim.keymap.set("", "gqb", function()
  local lf = require("largefiles")
  local buf = vim.api.nvim_get_current_buf()
  if lf.is_large_file(buf, false) == lf.FILE_TYPE.READ_ONLY then
    vim.notify_once("Large buf can't format", vim.log.levels.WARN)
    return
  end
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
