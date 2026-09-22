-- lupine colorscheme: base16 palette applied via mini.base16 (light theme)
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("lupine: mini.base16 not available", vim.log.levels.ERROR)
  return
end

vim.o.background = "light"

base16.setup({
  palette = {
    base00 = "#fafafa", -- background (light)
    base01 = "#f5f5f5", -- lighter_background
    base02 = "#d0d0d0", -- selection
    base03 = "#9e9e9e", -- muted
    base04 = "#757575", -- dark_foreground
    base05 = "#212121", -- foreground (dark)
    base06 = "#424242", -- light_foreground
    base07 = "#000000", -- bright_foreground
    base08 = "#c900c4", -- red
    base09 = "#026fde", -- orange
    base0A = "#026fde", -- yellow
    base0B = "#4a2fd0", -- green
    base0C = "#0c67de", -- cyan
    base0D = "#3264eb", -- blue
    base0E = "#8a4ad7", -- magenta
    base0F = "#013a6f", -- brown
  },
  use_cterm = false,
})

vim.g.colors_name = "lupine"
