return {
  {
    "mbbill/undotree",
    config = function()
      -- vim.keymap.set("n", "<leader>u U", ":UndotreeToggle<CR>", { noremap = true, silent = true },)
      vim.keymap.set(
        "n",
        "<leader>uU",
        vim.cmd.UndotreeToggle,
        { noremap = true, silent = true, desc = "Toggle Undotree" }
      )
    end,
  },
}
