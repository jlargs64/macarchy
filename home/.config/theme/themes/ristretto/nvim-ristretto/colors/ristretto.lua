-- ristretto colorscheme: base16 palette applied via mini.base16
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("ristretto: mini.base16 not available", vim.log.levels.ERROR)
  return
end

base16.setup({
  palette = {
    base00 = "#2c2525", -- background
    base01 = "#3d2f2a", -- lighter_background
    base02 = "#403e41", -- selection
    base03 = "#72696a", -- muted
    base04 = "#72696a", -- dark_foreground
    base05 = "#e6d9db", -- foreground
    base06 = "#c3b7b8", -- light_foreground
    base07 = "#e6d9db", -- bright_foreground
    base08 = "#fd6883", -- red
    base09 = "#fb9a77", -- orange
    base0A = "#f9cc6c", -- yellow
    base0B = "#adda78", -- green
    base0C = "#85dacc", -- cyan
    base0D = "#f38d70", -- blue
    base0E = "#a8a9eb", -- magenta
    base0F = "#7d4d3b", -- brown
  },
  use_cterm = false,
})

vim.g.colors_name = "ristretto"
