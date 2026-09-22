-- everforest -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/everforest/neovim.lua @ 947e2fc (via local --src checkout, not curl)
return {
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    opts = { background = "soft" },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "everforest" } },
}
