-- last-horizon colorscheme: base16 palette applied via mini.base16
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("lasthorizon: mini.base16 not available", vim.log.levels.ERROR)
  return
end

base16.setup({
  palette = {
    base00 = "#0c0b0c", -- background
    base01 = "#0c0b0c", -- lighter_background (equals background in this palette)
    base02 = "#584e51", -- selection
    base03 = "#584e51", -- muted
    base04 = "#584e51", -- dark_foreground
    base05 = "#FAFCFB", -- foreground
    base06 = "#cfd3cd", -- light_foreground
    base07 = "#e2dddc", -- bright_foreground
    base08 = "#c38b7b", -- red
    base09 = "#6B5E73", -- orange: not in palette, reusing yellow per instructions
    base0A = "#6B5E73", -- yellow
    base0B = "#87a9b0", -- green
    base0C = "#a5a0b6", -- cyan
    base0D = "#b59790", -- blue
    base0E = "#c4d8e2", -- magenta
    base0F = "#584e51", -- brown: not in palette, reusing muted per instructions
  },
  use_cterm = false,
})

vim.g.colors_name = "lasthorizon"
