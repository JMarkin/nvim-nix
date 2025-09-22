if vim.g.did_load_dashboard_plugin then
  return
end
vim.g.did_load_dashboard_plugin = true

local M = {
  neofetch = "",
  version = "",
  plugins = "",
}

local function draw_footer(dashboard)
  local footer = {
    M.version,
    M.plugins,
  }
  if type(M.neofetch) ~= "string" then
    table.insert(
      footer,
      string.format("%s\t%s", M.neofetch[1]["result"]["prettyName"], M.neofetch[2]["result"]["release"])
    )
    local uptime = M.neofetch[3]["result"]["uptime"] / 1000
    local h = uptime / 3600
    local m = 60 - (math.ceil(h) - h) * 60
    local s = 60 - math.floor((math.ceil(m) - m) * 60)
    m = math.floor(m)
    h = math.floor(h)
    table.insert(footer, string.format("uptime: %sh %sm %ss", h, m, s))
  end
  dashboard.section.footer.val = footer
  vim.cmd.AlphaRedraw()
end

local function fetch(dashboard)
  local neofetch = vim.fn.executable("fastfetch")
  if neofetch == 0 then
    return
  end
  local cmd = "fastfetch"
  local args = { "--structure", "OS:Kernel:Uptime", "--format", "json" }

  local t = ""
  local stdout = function(error, data)
    if data then
      t = t .. data
    end
  end
  local on_exit = function(...)
    if #t > 0 then
      M.neofetch = vim.json.decode(t)
    end
    local timer = vim.uv.new_timer()

    timer:start(
      20,
      0,
      vim.schedule_wrap(function()
        draw_footer(dashboard)
      end)
    )
  end
  vim.system({ cmd, table.unpack(args) }, {
    text = true,
    stdout = stdout,
  }, on_exit)
end

local height = tonumber(vim.api.nvim_command_output("echo &lines")) or 0

local dashboard = require("alpha.themes.dashboard")

dashboard.autostart = true
dashboard.config.layout[1].val = 1

dashboard.section.buttons.val = {
  dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
  dashboard.button("f", " " .. " Find file", ":FzfLua files<cr>"),
  dashboard.button("a", "󰊳 " .. " AI", function()
      require("avante.api").zen_mode()
  end),
  dashboard.button("s", " " .. " Search", ":FzfLua grep_project<cr>"),
  dashboard.button(
    "r",
    "󰄉 " .. " Recent files",
    ":lua require('fzf-lua').oldfiles({ cwd_only=true })<cr>"
  ),
  dashboard.button("g", "󰄉 " .. " Diff", ":DiffviewOpen <cr>"),
  dashboard.button("c", " " .. " Config", ":e .nvim.lua <CR>"),
  dashboard.button("q", " " .. " Quit", ":qa<CR>"),
}

-- set highlight
for _, button in ipairs(dashboard.section.buttons.val) do
  button.opts.hl = "AlphaButtons"
  button.opts.hl_shortcut = "AlphaShortcut"
end
dashboard.section.header.opts.hl = "AlphaHeader"
dashboard.section.buttons.opts.hl = "AlphaButtons"
dashboard.section.footer.opts.hl = "AlphaFooter"

if height > 40 then
  local header = require("banner").get_by_day()
  dashboard.section.header.val = header
  fetch(dashboard)
else
  dashboard.section.header.val = ""
end

require("alpha").setup(dashboard.opts)
