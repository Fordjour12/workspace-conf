return {
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    opts = function()
      vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { noremap = true, silent = true })
    end,
  },
}
