---@type vim.lsp.Config
return {
  settings = {
    yaml = {
      format = { enable = true },
      schemaStore = {
        enable = false,
      },
      schemas = require("schemastore").yaml.schemas(),
    },
    redhat = {
      telemetry = {
        enabled = false,
      },
    },
  },
}
