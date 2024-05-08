return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },

    config = function()
      -- Harpoon
      local harpoon = require 'harpoon'

      -- REQUIRED
      harpoon:setup()
      -- REQUIREDequire 'harpoon'

      vim.keymap.set('n', '<leader>a', function()
        harpoon:list():append()
      end, { desc = '[Add Harpoon] Mark' })
      vim.keymap.set('n', '<leader>i', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = '[Toggle] Harpoon Quick Menu' })

      vim.keymap.set('n', '<leader>1', function()
        harpoon:list():select(1)
      end)
      vim.keymap.set('n', '<leader>2', function()
        harpoon:list():select(2)
      end)
      vim.keymap.set('n', '<leader>3', function()
        harpoon:list():select(3)
      end)
      vim.keymap.set('n', '<leader>4', function()
        harpoon:list():select(4)
      end)
      vim.keymap.set('n', '<leader>5', function()
        harpoon:list():select(5)
      end)
      vim.keymap.set('n', '<leader>6', function()
        harpoon:list():select(6)
      end)
      vim.keymap.set('n', '<leader>7', function()
        harpoon:list():select(7)
      end)
    end,
  },
}
