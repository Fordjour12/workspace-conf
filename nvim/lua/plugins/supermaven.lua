if true then
  return {}
end

return {
  {
    "nvim-cmp",
    dependencies = {
      {
        "supermaven-inc/supermaven-nvim",
        opts = {},
        config = function(_, opts)
          require("supermaven-nvim").setup({
            keymaps = {

              accept_suggestion = "<Tab>",
              clear_suggestion = "<C-]>",
              accept_word = "<C-j>",
            },
            color = {
              suggestion_color = "#87B573",
              cterm = 244,
            },
            log_level = "info", -- set to "off" to disable logging completely
            disable_inline_completion = false, -- disables inline completion for use with cmp
            disable_keymaps = true, -- disables built in keymaps for more manual control
            condition = function()
              return false
            end, -- condition to check for stopping supermaven, `true` means to stop supermaven when the condition is true.
          })
        end,
      },
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, 1, {
        name = "supermaven",
        group_index = 1,
        priority = 100,
      })
    end,
  },
}
