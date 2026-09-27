-- catppuccin -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/catppuccin/neovim.lua @ 387fcf5
return {
  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },
}
