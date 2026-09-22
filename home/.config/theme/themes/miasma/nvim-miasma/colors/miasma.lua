-- miasma colorscheme: base16 palette applied via mini.base16
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("miasma: mini.base16 not available", vim.log.levels.ERROR)
  return
end

base16.setup({
  palette = {
    base00 = "#222222", -- background
    base01 = "#2c2c2c", -- lighter_background
    base02 = "#383838", -- selection
    base03 = "#666666", -- muted
    base04 = "#555555", -- dark_foreground
    base05 = "#c2c2b0", -- foreground
    base06 = "#8a8a7e", -- light_foreground
    base07 = "#c2c2b0", -- bright_foreground
    base08 = "#685742", -- red
    base09 = "#8d6242", -- orange
    base0A = "#b36d43", -- yellow
    base0B = "#5f875f", -- green
    base0C = "#c9a554", -- cyan
    base0D = "#78824b", -- blue
    base0E = "#bb7744", -- magenta
    base0F = "#463121", -- brown
  },
  use_cterm = false,
})

vim.g.colors_name = "miasma"
