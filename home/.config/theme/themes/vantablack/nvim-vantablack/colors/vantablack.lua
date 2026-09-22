-- vantablack colorscheme: base16 palette applied via mini.base16
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("vantablack: mini.base16 not available", vim.log.levels.ERROR)
  return
end

base16.setup({
  palette = {
    base00 = "#000000", -- background
    base01 = "#1a1a1a", -- lighter_background
    base02 = "#1a1a1a", -- selection
    base03 = "#7a7a7a", -- muted
    base04 = "#505050", -- dark_foreground
    base05 = "#ffffff", -- foreground
    base06 = "#ececec", -- light_foreground
    base07 = "#ffffff", -- bright_foreground
    base08 = "#a4a4a4", -- red
    base09 = "#b9b9b9", -- orange
    base0A = "#cecece", -- yellow
    base0B = "#b6b6b6", -- green
    base0C = "#b0b0b0", -- cyan
    base0D = "#8d8d8d", -- blue
    base0E = "#9b9b9b", -- magenta
    base0F = "#5c5c5c", -- brown
  },
  use_cterm = false,
})

vim.g.colors_name = "vantablack"
