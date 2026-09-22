-- ristretto (custom, local plugin driving mini.base16)
return {
  { "nvim-mini/mini.base16", version = false, lazy = false, priority = 1001 },
  {
    dir = vim.fn.expand("~/.config/theme/themes/ristretto/nvim-ristretto"),
    name = "ristretto",
    lazy = false,
    priority = 1000,
    dependencies = { "nvim-mini/mini.base16" },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "ristretto" } },
}
