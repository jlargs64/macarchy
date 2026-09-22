-- white colorscheme: base16 palette applied via mini.base16 (light theme)
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("white: mini.base16 not available", vim.log.levels.ERROR)
  return
end

vim.o.background = "light"

base16.setup({
  palette = {
    base00 = "#ffffff", -- background (light)
    base01 = "#c0c0c0", -- lighter_background
    base02 = "#c0c0c0", -- selection
    base03 = "#808080", -- muted
    base04 = "#c0c0c0", -- dark_foreground
    base05 = "#000000", -- foreground (dark)
    base06 = "#000000", -- light_foreground
    base07 = "#000000", -- bright_foreground
    base08 = "#2a2a2a", -- red
    base09 = "#4a4a4a", -- orange: not in palette, reusing yellow per instructions
    base0A = "#4a4a4a", -- yellow
    base0B = "#3a3a3a", -- green
    base0C = "#3e3e3e", -- cyan
    base0D = "#1a1a1a", -- blue
    base0E = "#2e2e2e", -- magenta
    base0F = "#808080", -- brown: not in palette, reusing muted per instructions
  },
  use_cterm = false,
})

vim.g.colors_name = "white"
