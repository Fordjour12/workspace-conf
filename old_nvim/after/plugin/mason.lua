local mason = require("mason")
mason.setup({})

local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup({
  ensure_installed = {},
  handlers = {
  },
})
