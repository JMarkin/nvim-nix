return {
  {
    "ravitemer/mcphub.nvim",
    -- from nix
    dev = true,
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
    },
    cmd = "MCPHub", -- lazy load by default
    config = function()
      require("mcphub").setup()
    end,
  },
}
