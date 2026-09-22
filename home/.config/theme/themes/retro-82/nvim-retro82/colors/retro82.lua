-- retro-82 colorscheme: base16 palette applied via mini.base16
local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("retro82: mini.base16 not available", vim.log.levels.ERROR)
  return
end

base16.setup({
  palette = {
    base00 = "#0b0a0f",
    base01 = "#15121c",
    base02 = "#221c2e",
    base03 = "#3a3148",
    base04 = "#6b5a80",
    base05 = "#f2c66d",
    base06 = "#fff0c0",
    base07 = "#ffffff",
    base08 = "#ff4f6d",
    base09 = "#ff9f43",
    base0A = "#f2c66d",
    base0B = "#7bff7b",
    base0C = "#3ef1ff",
    base0D = "#4fa8ff",
    base0E = "#ff59f0",
    base0F = "#c98cff",
  },
  use_cterm = false,
})

vim.g.colors_name = "retro82"
