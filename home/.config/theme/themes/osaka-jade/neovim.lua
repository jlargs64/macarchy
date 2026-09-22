-- osaka-jade -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/osaka-jade/neovim.lua @ 947e2fc (via local --src checkout, not curl)
return {
  {
    "ribru17/bamboo.nvim",
    lazy = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "bamboo-multiplex" } },
}
