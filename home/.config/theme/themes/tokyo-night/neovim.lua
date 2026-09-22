-- tokyo-night -- ported from Omarchy github.com/basecamp/omarchy themes/tokyo-night/neovim.lua @ 45748a2812f42e32f915b053caf4074e150e2048
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}
