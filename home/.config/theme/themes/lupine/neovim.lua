-- lupine (custom, local plugin driving mini.base16)
return {
  { "nvim-mini/mini.base16", version = false, lazy = false, priority = 1001 },
  {
    dir = vim.fn.expand("~/.config/theme/themes/lupine/nvim-lupine"),
    name = "lupine",
    lazy = false,
    priority = 1000,
    dependencies = { "nvim-mini/mini.base16" },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "lupine" } },
}
