-- ethereal colorscheme: base16 palette applied via mini.base16
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("ethereal: mini.base16 not available", vim.log.levels.ERROR)
  return
end

base16.setup({
  palette = {
    base00 = "#060B1E", -- background
    base01 = "#131a3a", -- lighter_background
    base02 = "#252e56", -- selection
    base03 = "#6d7db6", -- muted
    base04 = "#6d7db6", -- dark_foreground
    base05 = "#ffcead", -- foreground
    base06 = "#c9b8a6", -- light_foreground
    base07 = "#ffcead", -- bright_foreground
    base08 = "#ED5B5A", -- red
    base09 = "#eb8b54", -- orange
    base0A = "#E9BB4F", -- yellow
    base0B = "#92a593", -- green
    base0C = "#a3bfd1", -- cyan
    base0D = "#7d82d9", -- blue
    base0E = "#c89dc1", -- magenta
    base0F = "#75452a", -- brown
  },
  use_cterm = false,
})

vim.g.colors_name = "ethereal"
