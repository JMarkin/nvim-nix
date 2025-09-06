if vim.g.did_load_largefiles_plugin then
  return
end
vim.g.did_load_largefiles_plugin = true

local fn = require("funcs")
local lf = require("largefiles")

fn.augroup("largefiles", {
  vim.g.pre_load_events,
  {
    pattern = { "*" },
    callback = function(event)
      lf.optimize_buffer(event.buf, event.match)
    end,
  },
})
