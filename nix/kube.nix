{ pkgs
, inputs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  kubectl-nvim = inputs.kubectl-nvim.packages.${system}.kubectl-nvim;
in
[
  {
    plugin = kubectl-nvim;
    optional = true;
    config = /*lua*/''

      lze.load{
      "${kubectl-nvim.pname}",
      cmd = { 'Kubectl', 'Kubectx', 'Kubens' },
      on_require = {"kubectl"},
      keys = {
        { '<space>k', '<cmd>lua require("kubectl").toggle({tab=true})<cr>' },
        { '7', '<Plug>(kubectl.view_nodes)', ft = 'k8s_*' },
        { '8', '<Plug>(kubectl.view_overview)', ft = 'k8s_*' },
        { '<C-t>', '<Plug>(kubectl.view_top)', ft = 'k8s_*' },
      },
      after = function() 
        require("kubectl").setup()
      end,
      }
    '';
  }
]
