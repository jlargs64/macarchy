-- hollow colorscheme: base16 palette applied via mini.base16
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("hollow: mini.base16 not available", vim.log.levels.ERROR)
  return
end

base16.setup({
  palette = {
    base00 = "#16110f", -- background (charred bark)
    base01 = "#201915", -- lighter_background
    base02 = "#3a2c22", -- selection
    base03 = "#7a6552", -- muted (comments)
    base04 = "#8a7560", -- dark_foreground
    base05 = "#e8d5b5", -- foreground (candlelit parchment)
    base06 = "#f2e4c8", -- light_foreground
    base07 = "#fbf1dc", -- bright_foreground
    base08 = "#b8412f", -- red (dried blood)
    base09 = "#e8772e", -- orange (pumpkin)
    base0A = "#f0b54a", -- yellow (candle flame)
    base0B = "#8f9d4c", -- green (moss)
    base0C = "#82a898", -- cyan (ghost sage)
    base0D = "#6d8ca3", -- blue (moonlit fog)
    base0E = "#a878c2", -- magenta (witch violet)
    base0F = "#8a4b2a", -- brown (rust leaf)
  },
  use_cterm = false,
})

vim.g.colors_name = "hollow"
