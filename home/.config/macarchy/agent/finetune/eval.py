"""Score a Needle model (base or tuned .cact) on held-out + hand-written prompts.

  python finetune/eval.py                                   # base weights
  python finetune/eval.py --weights finetune/workspace-agent.cact
Uses reset()+complete() per prompt (single step, no execution), exact match on calls.
"""

import argparse
import json
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import needle
import tools as T

HARD = [
    (
        "put ghostty on space 3 and switch to the kanagawa theme",
        [
            {"name": "send_to_space", "arguments": {"space": 3, "app": "ghostty"}},
            {"name": "set_theme", "arguments": {"name": "kanagawa-wave"}},
        ],
    ),
    ("focus chrome", [{"name": "focus_window", "arguments": {"app": "chrome"}}]),
    ("move slack to space 2", [{"name": "send_to_space", "arguments": {"space": 2, "app": "slack"}}]),
    ("open a new tab called logs", [{"name": "zellij_new_tab", "arguments": {"name": "logs"}}]),
    ("set theme to retro-82", [{"name": "set_theme", "arguments": {"name": "retro-82"}}]),
    ("what's the weather in Lagos", []),
    (
        "open obsidian and helium, then send helium to space 2",
        [
            {"name": "launch_app", "arguments": {"app": "obsidian"}},
            {"name": "launch_app", "arguments": {"app": "helium"}},
            {"name": "send_to_space", "arguments": {"space": 2, "app": "helium"}},
        ],
    ),
    (
        "balance the windows and go fullscreen",
        [{"name": "balance_windows", "arguments": {}}, {"name": "toggle_window", "arguments": {"state": "fullscreen"}}],
    ),
    ("throw the terminal onto desktop four", [{"name": "send_to_space", "arguments": {"space": 4, "app": "Ghostty"}}]),
    (
        "stack mode and next theme",
        [{"name": "set_layout", "arguments": {"layout": "stack"}}, {"name": "next_theme", "arguments": {}}],
    ),
    (
        "split right, then go to tab 3",
        [
            {"name": "zellij_split_pane", "arguments": {"direction": "right"}},
            {"name": "zellij_go_to_tab", "arguments": {"index": 3}},
        ],
    ),
    ("remind me to water the plants", []),
    ("push slack to the left", [{"name": "warp_window", "arguments": {"direction": "west", "app": "slack"}}]),
    ("go to space 4", [{"name": "focus_space", "arguments": {"space": 4}}]),
    ("center this window", [{"name": "center_window", "arguments": {}}]),
    ("put slack in the middle", [{"name": "center_window", "arguments": {"app": "slack"}}]),
    ("next wallpaper", [{"name": "set_background", "arguments": {"choice": "next"}}]),
    ("use the mountains background", [{"name": "set_background", "arguments": {"choice": "mountains"}}]),
    ("pick a background", [{"name": "pick_background", "arguments": {}}]),
]


def norm(calls):
    out = []
    for c in calls or []:
        args = {k: (v.lower() if isinstance(v, str) else v) for k, v in (c.get("arguments") or {}).items()}
        if args.get("app") in ("terminal", "the terminal"):
            args["app"] = "ghostty"
        out.append({"name": c.get("name"), "arguments": args})
    return json.dumps(sorted(out, key=lambda c: json.dumps(c, sort_keys=True)), sort_keys=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", default=None)
    ap.add_argument("--data", default=os.path.join(os.path.dirname(__file__), "data.jsonl"))
    ap.add_argument("--n", type=int, default=150)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--show-fails", type=int, default=12)
    ap.add_argument(
        "--include-suppressed",
        action="store_true",
        help="also count calls the engine generated but suppressed as ungrounded",
    )
    args = ap.parse_args()

    agent = needle.Needle(tools=T.TOOLS, system=T.SYSTEM, weights=args.weights, auto_date=False)
    rows = [json.loads(l) for l in open(args.data)]
    random.Random(args.seed).shuffle(rows)
    cases = [(r["query"], r["answers"]) for r in rows[: args.n]] + HARD

    hits, fails, ms = 0, [], []
    for q, want in cases:
        agent.reset()
        t = time.time()
        try:
            r = agent.complete(q)
            got = list(r.get("function_calls") or [])
            if args.include_suppressed:
                got += r.get("suppressed_calls") or []
        except Exception as e:
            got = [{"name": "ERROR", "arguments": {"e": str(e)[:80]}}]
        ms.append((time.time() - t) * 1000)
        if norm(got) == norm(want):
            hits += 1
        else:
            fails.append((q, want, got))
    n = len(cases)
    print(f"weights: {args.weights or 'base'}")
    print(
        f"exact match (case-insensitive args): {hits}/{n} = {hits / n:.1%}   median latency {sorted(ms)[n // 2]:.0f} ms"
    )
    hard_hits = sum(1 for q, w in HARD if not any(f[0] == q for f in fails))
    print(f"hand-written hard set: {hard_hits}/{len(HARD)}")
    for q, want, got in fails[: args.show_fails]:
        print(f"\n  Q: {q}\n  want: {json.dumps(want)}\n  got:  {json.dumps(got)}")


if __name__ == "__main__":
    main()
