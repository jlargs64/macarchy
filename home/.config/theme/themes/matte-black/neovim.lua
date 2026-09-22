-- matte-black -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/matte-black/neovim.lua @ 947e2fc (via local --src checkout, not curl)
return {
  {
    "tahayvr/matteblack.nvim",
    lazy = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "matteblack" } },
}
