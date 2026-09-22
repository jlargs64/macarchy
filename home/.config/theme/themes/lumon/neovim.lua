-- lumon -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/lumon/neovim.lua @ 947e2fc (via local --src checkout, not curl)
return {
  {
    "omacom/lumon.nvim", -- was omacom-io/lumon.nvim (GitHub org renamed)
    lazy = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "lumon" } },
}
