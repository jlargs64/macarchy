-- catppuccin-latte -- ported from Omarchy github.com/omacom/omarchy (quattro) themes/catppuccin-latte/neovim.lua @ 947e2fc (via local --src checkout, not curl)
return {
  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
    opts = {
			flavour = "latte",
		},
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-latte" } },
}
