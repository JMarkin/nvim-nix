{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = quicker-nvim;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "quicker.nvim",
        ft = "qf",
        on_require = "quicker",
        after= function()
          require("quicker").setup{
            keys = {
              {
                ">",
                function()
                  require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
                end,
                desc = "Expand quickfix context",
              },
              {
                "<",
                function()
                  require("quicker").collapse()
                end,
                desc = "Collapse quickfix context",
              },
            },
          }
        end,
        keys = {
          {
            "<space>Q",
            function()
              require("quicker").toggle()
            end,
            desc = "Toggle quickfix",
          },
          {
            "<space>l",
            function()
              require("quicker").toggle({ loclist = true })
            end,
            desc = "Toggle loclist",
          },
        },
      }
    '';
  }
  {
    plugin = nvim-bqf;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "${nvim-bqf.pname}",
        event="DeferredUIEnter",
        after= function()
          require("bqf").setup{
            auto_enable = true,
            auto_resize_height = true,
          }
        end,
      }
    '';
  }
]
