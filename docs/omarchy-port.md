# Omarchy -> macarchy theme port

Pinned rev used throughout: `45748a2812f42e32f915b053caf4074e150e2048` (the
`OMARCHY_REV` in `theme-bg-fetch`). All three requested themes, plus every
theme checked for the mode list below, had `colors.toml` at this rev -- no
fallback to `master` was needed.

## colors.toml keys (tokyo-night, quoted verbatim)

`https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/tokyo-night/colors.toml`

```toml
mode = "dark"

accent = "#7aa2f7"
selection = "#292e42"
muted = "#414868"

background = "#1a1b26"
dark_background = "#13141c"
darker_background = "#0e0e14"
lighter_background = "#24283b"

foreground = "#a9b1d6"
dark_foreground = "#565f89"
light_foreground = "#b4bee6"
bright_foreground = "#c0caf5"

red = "#f7768e"
yellow = "#e0af68"
orange = "#eb927b"
green = "#9ece6a"
cyan = "#449dab"
blue = "#7aa2f7"
magenta = "#ad8ee6"
brown = "#75493d"

bright_red = "#ff7a93"
bright_yellow = "#ff9e64"
bright_green = "#b9f27c"
bright_cyan = "#0db9d7"
bright_blue = "#7da6ff"
bright_magenta = "#bb9af7"
```

Keys present across the format: `mode`; `accent`, `selection`, `muted`;
`background`/`dark_background`/`darker_background`/`lighter_background`;
`foreground`/`dark_foreground`/`light_foreground`/`bright_foreground`; 8 base
ANSI (`red yellow orange green cyan blue magenta brown`); 6 bright ANSI
(`bright_red bright_yellow bright_green bright_cyan bright_blue
bright_magenta` -- no `bright_orange`/`bright_brown`).

## Mapping table (`colors.sh` contract)

| macarchy var | Omarchy key | notes |
|---|---|---|
| `BG` | `background` | `#` stripped |
| `FG` | `foreground` | `#` stripped |
| `ACCENT` | `accent` | `#` stripped |
| `MUTED` | `muted` | `#` stripped |
| `RED` | `red` | normal ANSI |
| `GREEN` | `green` | normal ANSI |
| `YELLOW` | `yellow` | normal ANSI |
| `BLUE` | `blue` | normal ANSI |
| `MAGENTA` | `magenta` | normal ANSI |
| `CYAN` | `cyan` | normal ANSI |
| `ACCENT2` | `bright_blue`/`bright_cyan`/`bright_magenta` | **heuristic**, see below |
| `THEME_NAME` | (the arg) | |
| `NVIM_COLORSCHEME` | parsed from `neovim.lua`'s `colorscheme = "..."` | |

`orange` and `brown` (base) and the `*_background`/`*_foreground` shade
variants are not used -- the contract has no slot for them.

**ACCENT2 heuristic** (implemented in `theme-port` as `hexdist`/the
`D_BLUE`/`D_CYAN`/`D_MAGENTA` block): compute squared-RGB distance from
`ACCENT` to each of the *base* `blue`/`cyan`/`magenta`, pick the farthest,
emit that channel's **bright** variant (falling back to the base value if no
`bright_*` key exists). Rationale: mirrors the hand-authored themes, where
ACCENT2 reads as accent-adjacent-but-distinct (kanagawa-wave: ACCENT=blue,
ACCENT2=purple). This is a judgment call, not something the palette encodes
directly -- worth a human glance per theme.

## Ghostty 16-slot ANSI derivation

No attempt was made to map to a Ghostty *built-in* theme name (Omarchy's
exact palette isn't guaranteed to match Ghostty's shipped variant of the same
name). Instead, `theme-port` reproduces retro-82's documented rule
(`docs/theme-system.md`: "ANSI 8..15 are the canonical slots verbatim; ANSI
0..7 are the same hues darkened 15%"), extended to the 11 variables this
contract actually has:

- slot 0 = `BG` verbatim (already the darkest color)
- slots 1-6 = `RED GREEN YELLOW BLUE MAGENTA CYAN` each darkened 15%
  (`darken15`: integer `r*17/20` per channel, rounded)
- slot 7 = `FG` darkened 15%
- slot 8 = `MUTED` (bright black)
- slots 9-14 = `RED GREEN YELLOW BLUE MAGENTA CYAN` verbatim
- slot 15 = `FG` verbatim

Verified the 15%-darken formula against retro-82's hand-authored `ghostty`
file before implementing (e.g. `RED=ff4f6d` -> dim slot `1=d9435d`; `0xff *
0.85 = 216.75 -> 0xd9`, checks out for all three channels).

## What's fully mechanical vs needs a human look

| File | Mechanical? | Notes |
|---|---|---|
| `colors.sh` | Yes | Straight key copy + `#` strip. |
| `ghostty` | Yes, but **heuristic** | The darken rule is not Omarchy's own; it's macarchy's dim-slot convention reproduced from retro-82. No visual check was done. |
| `zellij.kdl` | Yes | Used retro-82's flat fg/bg/named-color shape (not the verbose upstream-Zellij-repo shape kanagawa-wave/catppuccin-mocha use), since none of these three ported palettes are in zellij's own theme collection. `orange` field <- `ACCENT2` (retro-82's convention). |
| `borders` | Yes | Identical boilerplate across every theme; nothing theme-specific to port. |
| `neovim.lua` | **Needs a human look** | Plugin repo + `colorscheme` name parsed correctly for all three (verified below), but the parser's `opts = { ... }` brace-matcher was exercised on inputs with *no* opts block (none of these three themes' plugin entries carry one) -- untested on a theme that does. |
| `ACCENT2` | **Needs a human look** | Heuristic, see above; for gruvbox and nord the chosen bright variant is byte-identical to the base color (their `colors.toml` sets `bright_*` == base for several slots), so ACCENT2 there is just MAGENTA again -- a human may prefer picking a different source. |
| Light themes | **Needs a human look** | Refused by default (`mode = "light"`); `--allow-light` produces output but the ghostty/zellij dim-vs-bright split and the wallpaper/sketchybar assumptions elsewhere in the theme system are dark-only. Not something `theme-port` can fix mechanically. |
| Background image / `theme-bg-fetch` wiring | **Not done** | `theme-port` does not fetch `backgrounds/` or add entries to `theme-bg-fetch`'s `MAP`; that's a separate, deliberate step per `docs/theme-system.md` (and needs a `THEMES/$theme` dir to exist under the *real* `~/.config/theme/themes`, which this task must not touch). |

## Ported themes: `colors.sh`

**tokyo-night** (`plugin: folke/tokyonight.nvim`, `NVIM_COLORSCHEME:
tokyonight-night`, `ACCENT2 <- bright_cyan`):

```sh
# tokyo-night palette (0x/# free hex) -- ported from Omarchy
# github.com/basecamp/omarchy themes/tokyo-night/colors.toml @ 45748a2812f42e32f915b053caf4074e150e2048
export THEME_NAME=tokyo-night
export NVIM_COLORSCHEME=tokyonight-night
export BG=1a1b26
export FG=a9b1d6
export ACCENT=7aa2f7
export ACCENT2=0db9d7
export MUTED=414868
export RED=f7768e
export GREEN=9ece6a
export YELLOW=e0af68
export BLUE=7aa2f7
export MAGENTA=ad8ee6
export CYAN=449dab
```

**gruvbox** (`plugin: ellisonleao/gruvbox.nvim`, `NVIM_COLORSCHEME: gruvbox`,
`ACCENT2 <- bright_magenta`, which equals base magenta in this palette):

```sh
# gruvbox palette (0x/# free hex) -- ported from Omarchy
# github.com/basecamp/omarchy themes/gruvbox/colors.toml @ 45748a2812f42e32f915b053caf4074e150e2048
export THEME_NAME=gruvbox
export NVIM_COLORSCHEME=gruvbox
export BG=282828
export FG=d4be98
export ACCENT=7daea3
export ACCENT2=d3869b
export MUTED=665c54
export RED=ea6962
export GREEN=a9b665
export YELLOW=d8a657
export BLUE=7daea3
export MAGENTA=d3869b
export CYAN=89b482
```

**nord** (`plugin: EdenEast/nightfox.nvim`, `NVIM_COLORSCHEME: nordfox` --
note this is *not* a plugin literally named "nord", `ACCENT2 <-
bright_magenta`, also equal to base here):

```sh
# nord palette (0x/# free hex) -- ported from Omarchy
# github.com/basecamp/omarchy themes/nord/colors.toml @ 45748a2812f42e32f915b053caf4074e150e2048
export THEME_NAME=nord
export NVIM_COLORSCHEME=nordfox
export BG=2e3440
export FG=d8dee9
export ACCENT=81a1c1
export ACCENT2=b48ead
export MUTED=4c566a
export RED=bf616a
export GREEN=a3be8c
export YELLOW=ebcb8b
export BLUE=81a1c1
export MAGENTA=b48ead
export CYAN=88c0d0
```

## `theme-plugins.lua` additions the owner must make

Current file (`dot_config/nvim/lua/plugins/theme-plugins.lua`) only declares
`catppuccin/nvim`, `rebelot/kanagawa.nvim`, `nvim-mini/mini.base16`. To keep
these three colorschemes installed independent of the active theme (same
`lazy = true` pattern, so `lazy-lock.json` doesn't churn on switch), add:

```lua
{ "folke/tokyonight.nvim", lazy = true },
{ "ellisonleao/gruvbox.nvim", lazy = true },
{ "EdenEast/nightfox.nvim", lazy = true },  -- nord uses nightfox's "nordfox" variant, not a nord-named plugin
```

## All 22 Omarchy theme names, dark/light (fetched, none skipped)

Directory listing:
`https://api.github.com/repos/basecamp/omarchy/contents/themes?ref=45748a2812f42e32f915b053caf4074e150e2048`
(22 entries). `mode` fetched from each theme's own `colors.toml` at the same
rev -- all 22 resolved, no fallback needed:

| Theme | mode |
|---|---|
| catppuccin-latte | light |
| catppuccin | dark |
| ethereal | dark |
| everforest | dark |
| flexoki-light | light |
| gruvbox | dark |
| hackerman | dark |
| kanagawa | dark |
| last-horizon | dark |
| lumon | dark |
| lupine | light |
| matte-black | dark |
| miasma | dark |
| nord | dark |
| osaka-jade | dark |
| retro-82 | dark |
| ristretto | dark |
| rose-pine | light |
| solitude | dark |
| tokyo-night | dark |
| vantablack | dark |
| white | light |

5 light (`catppuccin-latte`, `flexoki-light`, `lupine`, `rose-pine`,
`white`), 17 dark. Note `rose-pine` here is Omarchy's own entry named
`rose-pine` (not `-dawn`) but its `colors.toml` sets `mode = "light"` --
worth double-checking against the upstream repo if porting it, since
"rose-pine" commonly implies the dark variant elsewhere.

## Verification done

- `bash -n theme-port` -- clean.
- Ran for `tokyo-night`, `gruvbox`, `nord` into `port/themes/` -- all 5 files
  each, no errors.
- Ran with no args (usage + exit 1), a nonexistent theme name (clean
  fetch-failure message + exit 1), a light theme with no flag
  (`catppuccin-latte`, refused with exit 2), and a light theme with
  `--allow-light` (succeeded) -- **that last test wrote to `/tmp/` outside
  this sandbox by mistake; it was deleted immediately after** (`rm -rf
  /tmp/should-not-exist-check`), nothing under `$HOME` or outside `port/`
  was touched otherwise.
- Confirmed the `darken15` integer formula against retro-82's own
  hand-authored `ghostty` file (channel-for-channel match on RED/GREEN/CYAN).
- All curl fetches were plain `raw.githubusercontent.com`/`api.github.com`
  reads; no writes to any remote system, no git push, no brew.

## URLs fetched

- `https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/tokyo-night/colors.toml`
- `https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/tokyo-night/neovim.lua`
- `https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/gruvbox/colors.toml`
- `https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/gruvbox/neovim.lua`
- `https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/nord/colors.toml`
- `https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/nord/neovim.lua`
- `https://raw.githubusercontent.com/basecamp/omarchy/45748a2812f42e32f915b053caf4074e150e2048/themes/<name>/colors.toml`
  for all 22 names in the mode table above
- `https://api.github.com/repos/basecamp/omarchy/contents/themes?ref=45748a2812f42e32f915b053caf4074e150e2048`
