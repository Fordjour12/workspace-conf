local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({buffer = bufnr})

  -- set keybinds
  vim.keymap.set('n', 'gr', '<cmd>Telescope lsp_references<cr>', {buffer = bufnr}) 
  -- show definition, references
end)

lsp_zero.format_on_save({
   format_opts = {
       async = true,
       timeout = 1000,
   },
   servers = {
       ["tsserver"]={"javascript","typescript","typescriptreact","javascriptreact"},
       ["cssls"]={"css","scss","less"},
       ["html"]={"html"},
       ["jsonls"]={"json"},
       ["yamlls"]={"yaml"},
       ["vimls"]={"vim"},
       ["dockerls"]={"dockerfile"},
       ["gopls"]={"go"},
       ["svelte"]={"svelte"},
       ["emmet_ls"]={"html","svelte","css","scss","less"},
       ["prismals"]={"prisma"},
   }
})

lsp_zero.set_sign_icons(
    {
     Error = "", 
    Warning = "", 
    Hint = "", 
    Information = "" 
   }
)

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
  mapping = cmp.mapping.preset.insert({
    -- `Enter` key to confirm completion
    ['<CR>'] = cmp.mapping.confirm({select = false}),

    -- Ctrl+Space to trigger completion menu
    ['<C-Space>'] = cmp.mapping.complete(),

    -- Navigate between snippet placeholder
    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
    ['<C-b>'] = cmp_action.luasnip_jump_backward(),

    -- Scroll up and down in the completion documentation
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
  })
})


require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {},
  handlers = {
    lsp_zero.default_setup,
  },
})