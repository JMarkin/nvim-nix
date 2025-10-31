local ts = require("typescript-tools")
local provider = require("typescript-tools.tsserver_provider")

ts.setup({
    tsserver_path = '/nix/store/4cq3wmf291dix18bj8k4p2l267aq73hq-typescript-language-server-5.0.1/bin/typescript-language-server'
})

vim.print(provider:get_executable_path())
