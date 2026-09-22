# Workspace agent (`ws`)

Say what you want done to the desktop, in plain words, and a 14 MB on-device
model turns it into yabai, zellij and theme commands. Nothing leaves the machine.

```
ws "put slack on space 2 and switch to the kanagawa theme"   # prints what it would run
ws -x "focus helium"                                          # runs it
ws --voice                                                    # alt - w: press to listen, press again to run
```

## Pipeline

1. **Text in.** Typed, or a WAV from `ws --voice` (bound to `alt - w` in skhdrc; ffmpeg
   records the system default mic, `MACARCHY_MIC`, and [Handy](https://handy.computer)
   transcribes it headlessly with `handy --transcribe-file`). Handy itself is installed
   by `install.sh` (brew cask `handy`) and owns its own dictation hotkey, `alt - space`,
   separately from skhd. Feedback works like Handy's: a pill at the bottom of the screen
   (`macarchy-overlay`, built from `home/.config/macarchy/swift/`) shows listening,
   transcribing, then what was heard and what ran; the bar's mic glyph turns red while
   ws holds the mic, and a Tink/Pop sound marks start and stop.
2. **Vocabulary gate.** No desktop word in the sentence, no model call.
3. **Model.** Cactus Needle 3, fine-tuned on these tools (see
   `home/.config/macarchy/agent/finetune/README.md`). The sentence is tried whole and
   split on "and" / "then" / commas; whichever yields more valid calls wins. ~40 ms.
4. **Validation.** Unknown tool, missing required argument, bad enum, out-of-range
   number: dropped. Calls the engine flagged as "not a literal span" (e.g. "sixth" -> 6)
   are kept if they validate.
5. **Canonicalise.** App names fuzzy-match the apps yabai currently sees, so "gosti"
   from the speech recogniser becomes Ghostty; "the terminal" and "the browser" are
   aliases in `tools.py`. Theme names match `theme-list`.
6. **Execute** (or print). Dry-run is the default until `MACARCHY_AGENT_EXECUTE=true`.

## Tools

| Tool | Does |
|---|---|
| `focus_window(app)` | `yabai -m window --focus <id>`, falls back to `open -a` |
| `launch_app(app)` | `open -a` |
| `send_to_space(space, app?)` | `yabai -m window <id> --space N` (works without the scripting addition) |
| `focus_space(space)` | native ctrl-N via System Events key codes |
| `warp_window(direction, app?)` | `yabai -m window --warp` |
| `toggle_window(float/fullscreen/zoom/split)` | `yabai -m window --toggle ...` |
| `set_layout(bsp/stack/float)`, `balance_windows()` | `yabai -m space ...` |
| `set_theme(name)`, `next_theme()` | `theme-set`, `theme-next` |
| `zellij_new_tab(name?)`, `zellij_go_to_tab(n)`, `zellij_split_pane(right/down)` | `zellij -s <session> action ...` |

Zellij target: `$ZELLIJ_SESSION_NAME` when run inside zellij, otherwise the newest
live session. With several Ghostty windows open that is a guess.

## Files

```
home/.config/macarchy/agent/tools.py      the 13 tools; schemas for training AND runtime come from here
home/.config/macarchy/agent/ws.py         runner
home/.config/macarchy/agent/ws            launcher (uses ~/.local/share/macarchy/venv)
home/.config/macarchy/agent/finetune/     data generator, eval, how to train
~/.local/share/macarchy/models/workspace-agent.cact   the model (not in git; install.sh downloads or you copy it)
```

## Adding a tool

Add a `@needle.tool` function to `tools.py`, a phrase generator to `finetune/gen_data.py`,
an executor branch to `ws.py`, then regenerate data and retrain. Schemas are part of
the prompt, so any rename or description change also needs a retrain.
