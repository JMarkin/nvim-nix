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
  on_require = {"camouflage"},
  keys = {
    { "<leader>ct", "<cmd>CamouflageToggle<cr>", desc = "Toggle Camouflage" },
    { "<leader>cr", "<cmd>CamouflageReveal<cr>", desc = "Reveal Line" },
    { "<leader>cy", "<cmd>CamouflageYank<cr>", desc = "Yank Value" },
    { "<leader>cf", "<cmd>CamouflageFollowCursor<cr>", desc = "Follow Cursor" },
  },
  after = function()
    require("camouflage").setup({
      pwned = {
        enabled = false,
        auto_check = true, -- Check on BufEnter
        check_on_save = true, -- Check on BufWritePost
        check_on_change = false, -- Check on TextChanged with debounce
        show_sign = false, -- Show sign column indicator
        show_virtual_text = true, -- Show virtual text with breach count
        show_line_highlight = true, -- Highlight the line
        sign_text = "!",
        sign_hl = "DiagnosticWarn",
        virtual_text_format = "PWNED (%s)",
        virtual_text_hl = "DiagnosticWarn",
        line_hl = "CamouflagePwned",
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
