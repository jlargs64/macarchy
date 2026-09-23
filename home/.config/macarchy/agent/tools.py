"""Tool definitions for the workspace agent.

The same functions feed three places: the training-data generator (schemas),
the fine-tune JSONL (`tools` field), and the runtime (`needle.Needle(tools=...)`).
Bodies only record the call; execution happens after validation in the runner.
"""

from typing import Literal

import needle
from needle.agent.tools import build_schema

# ----- vocabulary -----------------------------------------------------------
APPS = [
    "Ghostty",
    "Helium",
    "Chrome",
    "Safari",
    "Slack",
    "Discord",
    "Obsidian",
    "Finder",
    "Notes",
    "Spotify",
    "Music",
    "Mail",
    "Messages",
    "Code",
    "Cursor",
    "Zed",
    "Figma",
    "Xcode",
    "Preview",
    "Calendar",
    "Linear",
    "Notion",
    "Zoom",
]
APP_ALIASES = {
    "the terminal": "Ghostty",
    "terminal": "Ghostty",
    "my terminal": "Ghostty",
    "the browser": "Helium",
    "browser": "Helium",
    "vscode": "Code",
    "vs code": "Code",
    "the editor": "Code",
}
THEMES = ["catppuccin-mocha", "kanagawa-wave", "retro-82"]
THEME_ALIASES = {
    "catppuccin": "catppuccin-mocha",
    "mocha": "catppuccin-mocha",
    "kanagawa": "kanagawa-wave",
    "retro": "retro-82",
    "the 82 one": "retro-82",
}
SPACES = [1, 2, 3, 4, 5]
DIRECTIONS = ["west", "east", "north", "south"]
DIR_ALIASES = {"left": "west", "right": "east", "up": "north", "down": "south"}

Theme = Literal["catppuccin-mocha", "kanagawa-wave", "retro-82"]
Direction = Literal["west", "east", "north", "south"]
Layout = Literal["bsp", "stack", "float"]
WindowState = Literal["float", "fullscreen", "zoom", "split"]
SplitDir = Literal["right", "down"]

CALLS: list[dict] = []


def _rec(name, **kw):
    CALLS.append({"name": name, "arguments": {k: v for k, v in kw.items() if v is not None}})
    return {"ok": True}


# ----- windows (yabai) ------------------------------------------------------
@needle.tool
def focus_window(app: str):
    """Focus a running app's window.
    Args:
        app: app name
    """
    return _rec("focus_window", app=app)


@needle.tool
def launch_app(app: str):
    """Launch an app.
    Args:
        app: app name
    """
    return _rec("launch_app", app=app)


@needle.tool
def send_to_space(space: int, app: str | None = None):
    """Send a window to a numbered Space (desktop).
    Args:
        space: Space number 1-5
        app: app name; omit for focused window
    """
    return _rec("send_to_space", space=space, app=app)


@needle.tool
def focus_space(space: int):
    """Switch to a Space (desktop).
    Args:
        space: Space 1-5
    """
    return _rec("focus_space", space=space)


@needle.tool
def warp_window(direction: Direction, app: str | None = None):
    """Warp (swap) a window one tile in a compass direction.
    Args:
        direction: west, east, north or south
        app: app name; omit for focused window
    """
    return _rec("warp_window", direction=direction, app=app)


@needle.tool
def toggle_window(state: WindowState):
    """Toggle a state of the focused window.
    Args:
        state: float, fullscreen, zoom or split
    """
    return _rec("toggle_window", state=state)


@needle.tool
def set_layout(layout: Layout):
    """Set the Space's tiling layout.
    Args:
        layout: bsp, stack or float
    """
    return _rec("set_layout", layout=layout)


@needle.tool
def balance_windows():
    """Make all windows on the Space equal size."""
    return _rec("balance_windows")


# ----- theme ----------------------------------------------------------------
@needle.tool
def set_theme(name: Theme):
    """Set the desktop theme.
    Args:
        name: theme name
    """
    return _rec("set_theme", name=name)


@needle.tool
def next_theme():
    """Cycle to the next theme."""
    return _rec("next_theme")


# ----- terminal multiplexer (zellij) ----------------------------------------
@needle.tool
def zellij_new_tab(name: str | None = None):
    """Open a new terminal tab.
    Args:
        name: tab title; omit if none
    """
    return _rec("zellij_new_tab", name=name)


@needle.tool
def zellij_go_to_tab(index: int):
    """Go to a terminal tab by number.
    Args:
        index: tab number from 1
    """
    return _rec("zellij_go_to_tab", index=index)


@needle.tool
def zellij_split_pane(direction: SplitDir):
    """Split the terminal pane.
    Args:
        direction: right or down
    """
    return _rec("zellij_split_pane", direction=direction)


TOOLS = [
    focus_window,
    launch_app,
    send_to_space,
    focus_space,
    warp_window,
    toggle_window,
    set_layout,
    balance_windows,
    set_theme,
    next_theme,
    zellij_new_tab,
    zellij_go_to_tab,
    zellij_split_pane,
]
SCHEMAS = [build_schema(getattr(t, "__wrapped__", t)) for t in TOOLS]
SYSTEM = "macOS desktop control: windows, Spaces, theme, terminal tabs."

if __name__ == "__main__":
    import json

    print(json.dumps(SCHEMAS, indent=1))
