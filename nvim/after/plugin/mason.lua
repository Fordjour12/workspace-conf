local mason = require("mason")
mason.setup({})

local mason_lspconfig = require("mason-lspconfig")
mason-lspconfig.setup({
  ensure_installed = {},
  handlers = {
    lsp_zero.default_setup,
  },
})