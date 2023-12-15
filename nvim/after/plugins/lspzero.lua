local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({buffer = bufnr})
  lsp_zero.buffer_auto_format({buffer = bufnr})

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

