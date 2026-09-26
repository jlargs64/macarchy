"""Synthetic training data for the workspace agent.

Templated, deterministic, no network. Each JSONL line:
  {"query", "reasoning", "tools", "answers", "system"}
Run:  python finetune/gen_data.py --n 2000 --out finetune/data.jsonl
"""

import argparse
import json
import os
import random
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools import (
    APP_ALIASES,
    APPS,
    BG_ALIASES,
    DIR_ALIASES,
    DIRECTIONS,
    SCHEMAS,
    SPACES,
    SYSTEM,
    THEME_ALIASES,
    THEMES,
)

R = random.Random(42)
NUM_WORDS = {
    1: ["1", "1", "one", "one"],
    2: ["2", "2", "two", "two"],
    3: ["3", "3", "three", "three"],
    4: ["4", "4", "four", "four"],
    5: ["5", "5", "five", "five"],
    6: ["6", "six"],
    7: ["7", "seven"],
    8: ["8", "eight"],
    9: ["9", "nine"],
}
PREFIX = ["", "", "", "", "please ", "hey, ", "ok ", "yo ", "quick, "]
VERB_PREFIX = ["can you ", "could you ", "go ahead and ", "would you ", "i need you to "]
IMPERATIVE = re.compile(
    r"^(focus|switch|go|bring|show|jump|pull|give|put|open|launch|start|fire|boot|run|move|send|stick|throw|take|shove|push|swap|warp|shift|float|make|untile|toggle|pop|let|unfloat|tile|fullscreen|full|zoom|maximi[sz]e|unzoom|flip|rotate|change|stack|set|use|disable|turn|stop|balance|equalize|even|resize|cycle|apply|split|add|create|spin|try|flip|center|centre|uncenter|pick|choose|browse)\b"
)
ORD = {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth", 7: "seventh", 8: "eighth", 9: "ninth"}
SUFFIX = ["", "", "", "", " please", " for me", " now", " thanks", " real quick"]


def casing(s):
    return R.choice([s, s.lower(), s.lower(), s])


def app_mention(app):
    """Return (surface text, answer value). Direct mentions are copied verbatim
    (the model copies spans; the runner canonicalises). Aliases map to the app."""
    if R.random() < 0.15:
        alias = R.choice([a for a, c in APP_ALIASES.items() if c == app] or [app.lower()])
        return alias, app
    s = casing(app)
    return s, s


def space_mention(n):
    return R.choice(NUM_WORDS[n])


def wrap(q):
    pre = R.choice(PREFIX + VERB_PREFIX) if IMPERATIVE.match(q) else R.choice(PREFIX)
    q = pre + q + R.choice(SUFFIX)
    q = q.strip()
    if R.random() < 0.5:
        q = q[0].upper() + q[1:]
    return q


def native_reasoning(query, answers):
    """Mimic the base model's own think style:  'span' -> tool k 'v' k2 'v2'; ..."""
    if not answers:
        return f"No matching tool. None of the tools can serve '{query}'."
    parts = []
    for a in answers:
        args = " ".join(f"{k} '{v}'" for k, v in a["arguments"].items()) or "no args"
        parts.append(f"'{query}' -> {a['name']} {args}")
    return "; ".join(parts)


def ex(query, reasoning, answers, keep=False):
    if not keep:
        reasoning = native_reasoning(query, answers)
    return {"query": query, "reasoning": reasoning, "answers": answers}


# ----- single-call generators ----------------------------------------------
def g_focus_window():
    a, app = app_mention(R.choice(APPS))
    q = R.choice(
        [
            f"focus {a}",
            f"switch to {a}",
            f"go to {a}",
            f"bring {a} to the front",
            f"show me {a}",
            f"jump to {a}",
            f"pull up {a}",
            f"{a} to the front",
            f"give me {a}",
            f"put {a} in front",
            f"focus on {a}",
            f"raise {a}",
            f"activate {a}",
            f"bring up {a}",
            f"switch over to {a}",
            f"get me {a}",
            f"back to {a}",
            f"over to {a}",
        ]
    )
    return ex(q, f"focus_window app={app!r} from '{a}'", [{"name": "focus_window", "arguments": {"app": app}}])


def g_launch_app():
    a, app = app_mention(R.choice(APPS))
    q = R.choice(
        [
            f"open {a}",
            f"launch {a}",
            f"start {a}",
            f"open up {a}",
            f"fire up {a}",
            f"start up {a}",
            f"boot {a}",
            f"run {a}",
            f"open {a} for me",
            f"launch {a} please",
            f"start {a} up",
            f"spin up {a}",
            f"kick off {a}",
            f"get {a} running",
            f"open the {a} app",
        ]
    )
    return ex(q, f"launch_app app={app!r} from '{a}'", [{"name": "launch_app", "arguments": {"app": app}}])


def g_move_to_space():
    n = R.choice(SPACES)
    sm = space_mention(n)
    sp = R.choice(["space", "space", "desktop", "workspace"])
    if R.random() < 0.3:
        subj = R.choice(["this window", "this", "the current window", "the focused window", "that", "it"])
        q = R.choice(
            [
                f"move {subj} to {sp} {sm}",
                f"send {subj} to {sp} {sm}",
                f"put {subj} on {sp} {sm}",
                f"move {subj} to the {ORD[n]} {sp}",
                f"send {subj} to the {ORD[n]} {sp}",
                f"throw {subj} onto {sp} {sm}",
            ]
        )
        return ex(
            q,
            f"send_to_space space={n} from '{sm}'; no app named -> focused window",
            [{"name": "send_to_space", "arguments": {"space": n}}],
        )
    a, app = app_mention(R.choice(APPS))
    q = R.choice(
        [
            f"move {a} to {sp} {sm}",
            f"send {a} to {sp} {sm}",
            f"put {a} on {sp} {sm}",
            f"move {a} to the {ORD[n]} {sp}",
            f"send {a} over to the {ORD[n]} {sp}",
            f"put {a} on the {ORD[n]} {sp}",
            f"{a} goes on {sp} {sm}",
            f"stick {a} on {sp} {sm}",
            f"move {a} over to {sp} {sm}",
            f"throw {a} onto {sp} {sm}",
            f"take {a} to {sp} {sm}",
        ]
    )
    return ex(
        q,
        f"send_to_space app={app!r} from '{a}', space={n} from '{sm}'",
        [{"name": "send_to_space", "arguments": {"space": n, "app": app}}],
    )


def g_focus_space():
    n = R.choice(SPACES)
    sm = space_mention(n)
    sp = R.choice(["space", "space", "desktop", "workspace"])
    q = R.choice(
        [
            f"go to {sp} {sm}",
            f"switch to {sp} {sm}",
            f"show {sp} {sm}",
            f"jump to {sp} {sm}",
            f"{sp} {sm}",
            f"take me to {sp} {sm}",
            f"focus {sp} {sm}",
            f"over to {sp} {sm}",
            f"go to the {ORD[n]} {sp}",
            f"switch to the {ORD[n]} {sp}",
            f"the {ORD[n]} {sp}",
            f"{sp} number {sm}",
            f"go to {sp} number {sm}",
            f"bring up {sp} {sm}",
        ]
    )
    return ex(q, f"focus_space space={n} from '{sm}'", [{"name": "focus_space", "arguments": {"space": n}}])


def g_warp_window():
    d = R.choice(DIRECTIONS)
    dm = R.choice([d] + [k for k, v in DIR_ALIASES.items() if v == d] * 2)
    if R.random() < 0.5:
        subj = R.choice(["this window", "this", "the window", "the current window", "it", "the focused window"])
        q = R.choice(
            [
                f"move {subj} {dm}",
                f"shove {subj} {dm}",
                f"push {subj} to the {dm}",
                f"swap {subj} {dm}",
                f"warp {subj} {dm}",
                f"shift {subj} {dm}",
            ]
        )
        return ex(
            q,
            f"warp_window direction={d!r} from '{dm}'; no app -> focused window",
            [{"name": "warp_window", "arguments": {"direction": d}}],
        )
    a, app = app_mention(R.choice(APPS))
    q = R.choice(
        [
            f"move {a} {dm}",
            f"shove {a} {dm}",
            f"push {a} to the {dm}",
            f"swap {a} {dm}",
            f"put {a} on the {dm}",
            f"shift {a} {dm}",
            f"{a} to the {dm}",
        ]
    )
    return ex(
        q,
        f"warp_window app={app!r} from '{a}', direction={d!r} from '{dm}'",
        [{"name": "warp_window", "arguments": {"direction": d, "app": app}}],
    )


def g_toggle_window():
    s = R.choice(["float", "fullscreen", "zoom", "split"])
    q = {
        "float": R.choice(
            [
                "float this window",
                "make this window float",
                "untile this",
                "toggle float",
                "float it",
                "pop this window out of the tiling",
                "let this window float",
                "unfloat this window",
                "tile this window again",
                "toggle floating on this window",
            ]
        ),
        "fullscreen": R.choice(
            [
                "fullscreen this",
                "make this fullscreen",
                "toggle fullscreen",
                "go fullscreen",
                "full screen this window",
                "take this out of fullscreen",
                "fullscreen it",
            ]
        ),
        "zoom": R.choice(
            [
                "zoom this window",
                "maximize this",
                "toggle zoom",
                "make this one big",
                "zoom in on this window",
                "unzoom",
                "maximise the current window",
                "zoom it",
            ]
        ),
        "split": R.choice(
            [
                "flip the split",
                "toggle the split",
                "rotate the split",
                "change the split direction",
                "switch this split from horizontal to vertical",
                "flip this split",
                "toggle split",
            ]
        ),
    }[s]
    return ex(q, f"toggle_window state={s!r} from '{q}'", [{"name": "toggle_window", "arguments": {"state": s}}])


def g_center_window():
    if R.random() < 0.5:
        subj = R.choice(["this window", "this", "the window", "the current window", "it", "the focused window"])
        q = R.choice(
            [
                f"center {subj}",
                f"centre {subj}",
                f"put {subj} in the middle",
                f"center {subj} on the screen",
                f"uncenter {subj}",
                f"toggle centering on {subj}",
                f"give {subj} the centered column",
                f"stop centering {subj}",
                f"put {subj} back in its tile",
                "center",
                "toggle center",
                "centered column",
            ]
        )
        return ex(
            q, f"center_window from '{q}'; no app -> focused window", [{"name": "center_window", "arguments": {}}]
        )
    a, app = app_mention(R.choice(APPS))
    q = R.choice(
        [
            f"center {a}",
            f"centre {a}",
            f"put {a} in the middle",
            f"center {a} on the screen",
            f"give {a} the centered column",
            f"{a} in the middle",
            f"uncenter {a}",
            f"put {a} back in its tile",
        ]
    )
    return ex(q, f"center_window app={app!r} from '{a}'", [{"name": "center_window", "arguments": {"app": app}}])


def g_set_layout():
    l = R.choice(["bsp", "stack", "float"])
    q = {
        "bsp": R.choice(
            [
                "tile everything",
                "switch to bsp",
                "bsp layout",
                "tiling mode",
                "tile this space",
                "set layout to bsp",
                "go back to tiling",
                "use the tiled layout",
                "tiled layout please",
                "put this space in bsp",
                "tiled",
                "tiling",
                "turn tiling back on",
                "switch to tiling",
                "tile the windows",
                "make it tiled",
                "bsp",
                "back to bsp",
                "enable tiling",
                "use bsp",
            ]
        ),
        "stack": R.choice(
            [
                "stack the windows",
                "stack layout",
                "switch to stack mode",
                "stacking layout",
                "set layout to stack",
                "make this space a stack",
                "stack everything up",
                "use stack layout",
            ]
        ),
        "float": R.choice(
            [
                "float layout",
                "stop tiling",
                "turn off tiling",
                "set layout to float",
                "floating layout for this space",
                "disable tiling on this space",
                "no tiling here",
                "make this space float",
                "float everything on this space",
                "floating mode",
                "switch the space to floating",
                "untile the whole space",
            ]
        ),
    }[l]
    return ex(q, f"set_layout layout={l!r} from '{q}'", [{"name": "set_layout", "arguments": {"layout": l}}])


def g_balance():
    q = R.choice(
        [
            "balance the windows",
            "balance",
            "equalize the windows",
            "even out the windows",
            "make the windows equal size",
            "balance this space",
            "resize everything to be equal",
            "even them out",
            "balance the layout",
            "make all windows the same size",
        ]
    )
    return ex(q, "balance_windows; no arguments", [{"name": "balance_windows", "arguments": {}}])


def g_set_theme():
    t = R.choice(THEMES)
    tm = R.choice([t, t] + [k for k, v in THEME_ALIASES.items() if v == t])
    q = R.choice(
        [
            f"switch to the {tm} theme",
            f"set theme to {tm}",
            f"theme {tm}",
            f"use {tm}",
            f"change the theme to {tm}",
            f"go {tm}",
            f"switch theme to {tm}",
            f"make it {tm}",
            f"put on the {tm} theme",
            f"{tm} theme",
            f"apply {tm}",
        ]
    )
    return ex(q, f"set_theme name={t!r} from '{tm}'", [{"name": "set_theme", "arguments": {"name": t}}])


def g_next_theme():
    q = R.choice(
        [
            "next theme",
            "cycle the theme",
            "switch to the next theme",
            "rotate the theme",
            "change the theme",
            "different theme",
            "another theme",
            "flip the theme",
            "theme next",
            "give me a new theme",
            "swap themes",
            "try the next theme",
        ]
    )
    return ex(q, "next_theme; no specific theme named", [{"name": "next_theme", "arguments": {}}])


BG_NAMES = [
    "mountains",
    "forest",
    "ocean",
    "night",
    "city",
    "desert",
    "lake",
    "nebula",
    "waves",
    "sunset",
    "dunes",
    "canyon",
    "misty",
    "river",
    "snow",
    "coast",
    "meadow",
    "moon",
    "storm",
    "fog",
]


def g_set_background():
    bg = R.choice(["background", "background", "wallpaper", "wallpaper", "backdrop", "desktop picture"])
    kind = R.choices(["next", "prev", "number", "name"], weights=[4, 2, 3, 5])[0]
    if kind == "next":
        q = R.choice(
            [
                f"next {bg}",
                f"switch to the next {bg}",
                f"cycle the {bg}",
                f"change the {bg}",
                f"different {bg}",
                f"another {bg}",
                f"{bg} next",
                f"give me a new {bg}",
                f"flip the {bg}",
                f"rotate the {bg}",
                f"try the next {bg}",
            ]
        )
        return ex(
            q, f"set_background choice='next' from '{q}'", [{"name": "set_background", "arguments": {"choice": "next"}}]
        )
    if kind == "prev":
        pm = R.choice(["prev", "previous", "last"])
        q = R.choice(
            [
                f"{pm} {bg}",
                f"go back to the {pm} {bg}",
                f"switch to the {pm} {bg}",
                f"{bg} back one",
                f"put the {pm} {bg} back",
                f"back to the {pm} {bg}",
            ]
        )
        c = BG_ALIASES.get(pm, pm)
        return ex(
            q, f"set_background choice={c!r} from '{pm}'", [{"name": "set_background", "arguments": {"choice": c}}]
        )
    if kind == "number":
        i = R.choice(range(1, 10))
        im = R.choice(NUM_WORDS[i])
        q = R.choice(
            [
                f"{bg} {im}",
                f"set the {bg} to {im}",
                f"switch to {bg} {im}",
                f"use {bg} number {im}",
                f"{bg} number {im}",
                f"the {ORD[i]} {bg}",
                f"switch to the {ORD[i]} {bg}",
                f"pick {bg} {im}",
                f"go to {bg} {im}",
            ]
        )
        return ex(
            q,
            f"set_background choice={str(i)!r} from '{im}'",
            [{"name": "set_background", "arguments": {"choice": str(i)}}],
        )
    n = R.choice(BG_NAMES)
    q = R.choice(
        [
            f"set the {bg} to {n}",
            f"switch to the {n} {bg}",
            f"use the {n} {bg}",
            f"{n} {bg}",
            f"put on the {n} {bg}",
            f"{bg} {n}",
            f"change the {bg} to {n}",
            f"give me the {n} {bg}",
            f"the {n} one as the {bg}",
            f"make the {bg} the {n} one",
        ]
    )
    return ex(q, f"set_background choice={n!r} from '{n}'", [{"name": "set_background", "arguments": {"choice": n}}])


def g_pick_background():
    bg = R.choice(["background", "background", "wallpaper", "wallpaper", "backdrop"])
    q = R.choice(
        [
            f"pick a {bg}",
            f"choose a {bg}",
            f"open the {bg} picker",
            f"show me the {bg}s",
            f"let me pick a {bg}",
            f"browse {bg}s",
            f"{bg} picker",
            f"pick a new {bg}",
            f"choose a different {bg}",
            f"which {bg}s are there",
            f"let me choose the {bg}",
            f"show me the {bg} options",
        ]
    )
    return ex(q, "pick_background; no choice named", [{"name": "pick_background", "arguments": {}}])


TAB_NAMES = [
    "logs",
    "server",
    "tests",
    "git",
    "build",
    "notes",
    "db",
    "scratch",
    "api",
    "frontend",
    "backend",
    "deploy",
    "ssh",
    "docker",
    "watch",
    "dev",
    "prod",
    "editor",
    "shell",
    "misc",
    "work",
    "infra",
]


def g_new_tab():
    if R.random() < 0.35:
        q = R.choice(
            [
                "new tab",
                "open a new tab",
                "another tab",
                "new terminal tab",
                "give me a new tab",
                "add a tab",
                "open another tab",
                "spawn a tab",
                "new tab in zellij",
            ]
        )
        return ex(q, "zellij_new_tab; no name given", [{"name": "zellij_new_tab", "arguments": {}}])
    n = R.choice(TAB_NAMES)
    q = R.choice(
        [
            f"new tab called {n}",
            f"open a tab named {n}",
            f"new tab {n}",
            f"add a tab called {n}",
            f"open a new tab for {n}",
            f"make a {n} tab",
            f"tab called {n}",
            f"create a tab named {n}",
            f"spin up a tab called {n}",
            f"new terminal tab named {n}",
        ]
    )
    return ex(q, f"zellij_new_tab name={n!r} from '{n}'", [{"name": "zellij_new_tab", "arguments": {"name": n}}])


def g_go_to_tab():
    i = R.choice(range(1, 10))
    im = R.choice(NUM_WORDS[i])
    q = R.choice(
        [
            f"go to tab {im}",
            f"switch to tab {im}",
            f"tab {im}",
            f"jump to tab {im}",
            f"show tab {im}",
            f"focus tab {im}",
            f"terminal tab {im}",
            f"take me to tab {im}",
            f"go to the {ORD[i]} tab",
            f"switch to the {ORD[i]} tab",
            f"the {ORD[i]} tab",
        ]
    )
    return ex(q, f"zellij_go_to_tab index={i} from '{im}'", [{"name": "zellij_go_to_tab", "arguments": {"index": i}}])


def g_split_pane():
    d = R.choice(["right", "down"])
    q = {
        "right": R.choice(
            [
                "split the pane right",
                "split right",
                "vertical split",
                "split this pane to the right",
                "new pane on the right",
                "split side by side",
                "open a pane to the right",
                "split the terminal vertically",
                "pane to the right",
                "split horizontally into two columns",
            ]
        ),
        "down": R.choice(
            [
                "split the pane down",
                "split down",
                "horizontal split",
                "split this pane below",
                "new pane below",
                "split stacked",
                "open a pane underneath",
                "pane below",
                "split the terminal into top and bottom",
                "split downward",
            ]
        ),
    }[d]
    return ex(
        q,
        f"zellij_split_pane direction={d!r} from '{q}'",
        [{"name": "zellij_split_pane", "arguments": {"direction": d}}],
    )


SINGLE = [
    g_focus_window,
    g_launch_app,
    g_move_to_space,
    g_focus_space,
    g_warp_window,
    g_toggle_window,
    g_center_window,
    g_set_layout,
    g_balance,
    g_set_theme,
    g_next_theme,
    g_set_background,
    g_pick_background,
    g_new_tab,
    g_go_to_tab,
    g_split_pane,
]
WEIGHTS = [11, 10, 13, 10, 8, 6, 6, 7, 3, 9, 3, 8, 3, 8, 8, 5]

# ----- refusals -------------------------------------------------------------
REFUSALS = [
    "what's the weather in Lagos",
    "set a timer for 10 minutes",
    "play some jazz",
    "what time is it",
    "email Sarah about the invoice",
    "remind me to call mom",
    "how tall is Everest",
    "tell me a joke",
    "turn off the lights",
    "what's on my calendar tomorrow",
    "translate hello to french",
    "order a pizza",
    "what's 14 times 23",
    "who won the game last night",
    "add milk to the shopping list",
    "call an uber",
    "what does yabai stand for",
    "how do i exit vim",
    "write a haiku about tiling",
    "lock the door",
    "how many spaces do i have",
    "what theme am i using",
    "explain zellij modes",
    "delete all my files",
    "read me the news",
    "book a flight to tokyo",
    "set the thermostat to 70",
    "play the next song",
    "what's my ip address",
    "increase the volume",
    "take a screenshot",
    "shut down the computer",
    "how's the stock market",
    "is it going to rain",
    "convert 5 miles to km",
    "define serendipity",
    "text John I'm running late",
    "start a pomodoro",
    "mute the mic",
    "what's my battery at",
    "how do i install homebrew",
    "git push",
    "run the tests",
    "restart the wifi",
    "open the pod bay doors",
    "what year is it",
    "sing me a song",
    "find my phone",
    "rename this file",
    "empty the trash",
]


def g_refusal():
    q = R.choice(REFUSALS)
    return ex(wrap(q) if R.random() < 0.4 else q, "no desktop, theme or terminal tool applies", [])


# ----- composition ----------------------------------------------------------
CONNECTORS = [" and ", " and ", " and then ", ", then ", ", ", " then ", " and also ", ". then ", " after that "]


def multi(k):
    gens = R.sample(SINGLE, k)  # distinct tools per example
    parts = [g() for g in gens]
    q = parts[0]["query"]
    for p in parts[1:]:
        q += R.choice(CONNECTORS) + p["query"]
    reasoning = "; ".join(p["reasoning"] for p in parts)
    answers = [a for p in parts for a in p["answers"]]
    return ex(q, reasoning, answers, keep=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=2000)
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "data.jsonl"))
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    R.seed(args.seed)

    seen, rows = set(), []
    counts = {"single": 0, "multi2": 0, "multi3": 0, "refusal": 0}
    target = {"single": 0.58, "multi2": 0.20, "multi3": 0.07, "refusal": 0.15}
    attempts = 0
    while len(rows) < args.n and attempts < args.n * 20:
        attempts += 1
        kind = R.choices(list(target), weights=list(target.values()))[0]
        if kind == "single":
            e = R.choices(SINGLE, weights=WEIGHTS)[0]()
            e["query"] = wrap(e["query"])
        elif kind == "multi2":
            e = multi(2)
            e["query"] = wrap(e["query"])
        elif kind == "multi3":
            e = multi(3)
            e["query"] = wrap(e["query"])
        else:
            e = g_refusal()
        key = (e["query"].lower(), json.dumps(e["answers"], sort_keys=True))
        if key in seen:
            continue
        seen.add(key)
        counts[kind] += 1
        e["tools"] = SCHEMAS
        e["system"] = SYSTEM
        rows.append(e)

    R.shuffle(rows)
    with open(args.out, "w") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    per_tool = {}
    for r in rows:
        for a in r["answers"]:
            per_tool[a["name"]] = per_tool.get(a["name"], 0) + 1
    print(f"wrote {len(rows)} examples -> {args.out}")
    print("kinds:", counts)
    print("calls per tool:", dict(sorted(per_tool.items(), key=lambda x: -x[1])))


if __name__ == "__main__":
    main()
