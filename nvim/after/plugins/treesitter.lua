local configs = require("nvim-treesitter.configs")
configs.setup({
  ensure_installed = { "lua", "javascript", "html", "css", "json", "typescript", "tsx", "python", 
  "bash", "cpp", "go", "yaml", "toml", "regex", "dockerfile", "svelte", "vue","dart"},
  sync_install = false,
  auto_instal = true,
  highlight = { enable = true, additional_vim_regex_highlighting = false },
  indent = { enable = true },
  autopairs = { enable = true },
  autotag = { enable = true },
})