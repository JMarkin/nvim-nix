if vim.g.did_load_secrets_plugin then
  return
end
vim.g.did_load_secrets_plugin = true

vim.g.sensitive_patterns = {
  "PASS",
  "TOKEN",
  "PRIVATE",
  "ACCESS_KEY",
  "SECRET",
  "API_KEY",
  "authority-data",
  "key-data",
  "certificate-data",
}

lze.load({
  "camouflage-nvim",
  event = vim.g.pre_load_events,
  on_require = { "camouflage" },
  keys = {
    { "<leader>ct", "<cmd>CamouflageToggle<cr>", desc = "Toggle Camouflage" },
    { "<leader>cr", "<cmd>CamouflageReveal<cr>", desc = "Reveal Line" },
    { "<leader>cy", "<cmd>CamouflageYank<cr>", desc = "Yank Value" },
    { "<leader>cf", "<cmd>CamouflageFollowCursor<cr>", desc = "Follow Cursor" },
  },
  after = function()
    require("camouflage").setup({
      auto_enable = false, -- Auto-enable on supported files
      pwned = {
        enabled = false,
      },
      project_config = {
        enabled = false,
      },
    })

    require("camouflage").on("variable_detected", function(bufnr, var)
      for _, pattern in ipairs(vim.g.sensitive_patterns) do
        if var.key:upper():match(pattern) then
          return true
        end
      end
      return false
    end)
  end,
})
