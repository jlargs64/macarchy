-- solitude -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/solitude/neovim.lua @ 947e2fc (via local --src checkout, not curl)
return {
  {
    "ficd0/ashen.nvim", -- was ficcdaf/ashen.nvim (GitHub user renamed)
    lazy = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "ashen" } },
}
