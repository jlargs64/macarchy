-- hackerman -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/hackerman/neovim.lua @ 947e2fc (via local --src checkout, not curl)
return {
  {
    "bjarneo/hackerman.nvim",
    lazy = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "hackerman" } },
}
