-- need you need to install phpactor from their website(best way to get going)

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      phpactor = {
        enabled = true,
      },
    },
  },
}
