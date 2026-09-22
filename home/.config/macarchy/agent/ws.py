#!/usr/bin/env python3
"""ws -- natural-language workspace agent for macarchy.

  ws "put slack on space 2 and switch to the kanagawa theme"   # dry-run: prints the calls
  ws -x "focus helium"                                          # execute
  ws --voice                                                    # press once: record, press again: transcribe + run (bound to alt - w)
  ws --wav clip.wav                                             # run from an existing 16 kHz mono WAV

Pipeline: text -> vocabulary gate -> Needle (tuned .cact) per clause -> schema validation
        -> canonicalise args against live yabai apps / theme-list -> yabai / zellij / theme-set.
Config (shell KEY=value, ~/.config/macarchy/config):
  MACARCHY_AGENT_MODEL    path to .cact  (default ~/.local/share/macarchy/models/workspace-agent.cact)
  MACARCHY_AGENT_EXECUTE  true|false     make execute the default instead of dry-run
  MACARCHY_MIC            ffmpeg avfoundation audio device, default ":0"
  MACARCHY_HANDY          path to the handy binary
"""
import difflib, json, os, re, shlex, signal, subprocess, sys, time, warnings
warnings.filterwarnings("ignore", message=".*confidence head.*")

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tools as T  # noqa: E402

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache", "macarchy")
OVERLAY = os.path.join(HOME, ".local", "share", "macarchy", "bin", "macarchy-overlay")  # built by ../swift/build
CFG_FILE = os.path.join(HOME, ".config", "macarchy", "config")
KEYCODES = {1: 18, 2: 19, 3: 20, 4: 21, 5: 23, 6: 22, 7: 26, 8: 28, 9: 25}   # ctrl+<n> Space switching
CONNECTORS = re.compile(r"\s*(?:,\s*(?:and\s+|then\s+)?|\band then\b|\bthen\b|\band also\b|\bafter that\b|\band\b|\.\s+)\s*", re.I)
VOCAB = set("""focus switch go bring show jump pull give put open launch start fire boot run move send stick throw take
shove push swap warp shift float untile toggle pop unfloat tile fullscreen zoom maximize maximise unzoom flip rotate change
stack set use disable turn stop balance equalize even resize cycle apply split add create spin tab pane theme space desktop
workspace window windows layout bsp tiling tiled left right up down west east north south terminal browser next""".split())
VOCAB |= {a.lower() for a in T.APPS} | {t.lower() for t in T.THEMES} | set(T.THEME_ALIASES) | set(T.APP_ALIASES)


def cfg():
    out = {"MACARCHY_AGENT_MODEL": os.path.join(HOME, ".local/share/macarchy/models/workspace-agent.cact"),
           "MACARCHY_AGENT_EXECUTE": "false", "MACARCHY_MIC": ":default",
           "MACARCHY_HANDY": "/Applications/Handy.app/Contents/MacOS/handy"}
    if os.path.exists(CFG_FILE):
        for line in open(CFG_FILE):
            m = re.match(r"\s*(?:export\s+)?([A-Z_]+)=(.*)", line.split("#")[0])
            if m:
                out[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    for k in out:
        out[k] = os.environ.get(k, out[k])
    return out


def sh(*cmd, check=False):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if check and r.returncode:
        raise RuntimeError(f"{' '.join(cmd)}: {r.stderr.strip()}")
    return r.stdout


def notify(title, body):
    subprocess.run(["osascript", "-e", f'display notification {json.dumps(body)} with title {json.dumps(title)}'],
                   capture_output=True)


# ----- live state -----------------------------------------------------------
def windows():
    try:
        return json.loads(sh("yabai", "-m", "query", "--windows") or "[]")
    except Exception:
        return []


def themes():
    out = sh("theme-list").split()
    return out or T.THEMES


def canon_app(name, wins):
    if not name:
        return None
    key = name.strip().lower().rstrip(".")
    if key in T.APP_ALIASES:
        return T.APP_ALIASES[key]
    live = sorted({w["app"] for w in wins})
    pool = live + [a for a in T.APPS if a not in live]
    exact = [a for a in pool if a.lower() == key]
    if exact:
        return exact[0]
    close = difflib.get_close_matches(key, [a.lower() for a in pool], n=1, cutoff=0.6)
    if close:
        return next(a for a in pool if a.lower() == close[0])
    return name.strip()   # unknown app: pass through, `open -a` will complain


def canon_theme(name):
    key = (name or "").strip().lower()
    if key in T.THEME_ALIASES:
        return T.THEME_ALIASES[key]
    avail = themes()
    if key in avail:
        return key
    close = difflib.get_close_matches(key, avail, n=1, cutoff=0.5)
    return close[0] if close else None


def window_for(app, wins):
    """Window id for app (prefer current space), or the focused window when app is None."""
    if app is None:
        f = [w for w in wins if w.get("has-focus")]
        return f[0]["id"] if f else None
    cands = [w for w in wins if w["app"].lower() == app.lower()]
    cur = [w for w in cands if w.get("is-visible")]
    pick = cur or cands
    return pick[0]["id"] if pick else None


# ----- validation -----------------------------------------------------------
SCHEMAS = {s["name"]: s for s in T.SCHEMAS}


def valid(call):
    s = SCHEMAS.get(call.get("name"))
    if not s:
        return False
    props = s["parameters"].get("properties", {})
    args = call.get("arguments") or {}
    for req in s["parameters"].get("required", []):
        if req not in args or args[req] in ("", None):
            return False
    for k, v in args.items():
        p = props.get(k)
        if p is None:
            return False
        if "enum" in p and v not in p["enum"]:
            return False
        if p.get("type") == "integer":
            if not isinstance(v, int) or not (1 <= v <= 9):
                return False
    return True


# ----- model ----------------------------------------------------------------
_agent = None


def agent(model):
    global _agent
    if _agent is None:
        import needle
        w = model if os.path.exists(model) else None
        if w is None:
            print(f"warning: model {model} not found, using base Needle 3", file=sys.stderr)
        _agent = needle.Needle(tools=T.TOOLS, system=T.SYSTEM, weights=w, auto_date=False)
    return _agent


def app_in(text, wins):
    """An app named in the text, if any (live windows first, then the known list, then aliases)."""
    low = " " + re.sub(r"[^a-z0-9 ]", " ", text.lower()) + " "
    for alias, app in T.APP_ALIASES.items():
        if f" {alias} " in low:
            return app
    names = sorted({w["app"] for w in wins} | set(T.APPS), key=len, reverse=True)
    for n in names:
        if f" {n.lower()} " in low:
            return n
    words = [w for w in low.split() if len(w) > 3]
    for w in words:
        close = difflib.get_close_matches(w, [n.lower() for n in names], n=1, cutoff=0.75)
        if close:
            return next(n for n in names if n.lower() == close[0])
    return None


def infer(text, model, wins=()):
    a = agent(model)
    a.reset()
    r = a.complete(text)
    calls = list(r.get("function_calls") or []) + list(r.get("suppressed_calls") or [])
    calls = [c for c in calls if valid(c)]
    # the model sometimes drops the app in "put helium on space 2"; refill from the clause
    for c in calls:
        if c["name"] in ("send_to_space", "warp_window") and not (c.get("arguments") or {}).get("app"):
            named = app_in(text, wins)
            if named and not re.search(r"\b(this|it|the (current|focused) window|that)\b", text.lower()):
                c.setdefault("arguments", {})["app"] = named
    return calls, r.get("reasoning", "")


def plan(text, model, wins=()):
    """Whole sentence vs per-clause; keep whichever yields more valid calls."""
    text = text.strip().rstrip(".!")
    words = set(re.findall(r"[a-z0-9-]+", text.lower()))
    if not words & VOCAB:
        return [], "no workspace vocabulary in the request"
    whole, why = infer(text, model, wins)
    clauses = [c for c in CONNECTORS.split(text) if c and len(c.split()) >= 1]
    if len(clauses) > 1:
        per = []
        for c in clauses:
            calls, _ = infer(c, model, wins)
            per.extend(calls)
        if len(per) > len(whole):
            return per, why + " | split into clauses"
    return whole, why


# ----- execution ------------------------------------------------------------
def execute(call, wins):
    n, a = call["name"], dict(call.get("arguments") or {})
    if "app" in a:
        a["app"] = canon_app(a["app"], wins)
    if n == "focus_window":
        wid = window_for(a["app"], wins)
        return ["yabai", "-m", "window", "--focus", str(wid)] if wid else ["open", "-a", a["app"]]
    if n == "launch_app":
        return ["open", "-a", a["app"]]
    if n == "send_to_space":
        wid = window_for(a.get("app"), wins)
        if wid is None:
            raise RuntimeError(f"no window for {a.get('app') or 'focus'}")
        return ["yabai", "-m", "window", str(wid), "--space", str(a["space"])]
    if n == "focus_space":
        kc = KEYCODES[a["space"]]
        return ["osascript", "-e", f'tell application "System Events" to key code {kc} using control down']
    if n == "warp_window":
        wid = window_for(a.get("app"), wins)
        cmd = ["yabai", "-m", "window"] + ([str(wid)] if wid and a.get("app") else []) + ["--warp", a["direction"]]
        return cmd
    if n == "toggle_window":
        flag = {"float": "float", "fullscreen": "zoom-fullscreen", "zoom": "zoom-parent", "split": "split"}[a["state"]]
        cmd = ["yabai", "-m", "window", "--toggle", flag]
        return cmd + ["--grid", "4:4:1:1:2:2"] if flag == "float" else cmd
    if n == "set_layout":
        return ["yabai", "-m", "space", "--layout", a["layout"]]
    if n == "balance_windows":
        return ["yabai", "-m", "space", "--balance"]
    if n == "set_theme":
        t = canon_theme(a["name"])
        if not t:
            raise RuntimeError(f"unknown theme {a['name']}")
        return ["theme-set", t]
    if n == "next_theme":
        return ["theme-next"]
    if n.startswith("zellij_"):
        sess = zellij_session()
        base = ["zellij"] + (["-s", sess] if sess else []) + ["action"]
        if n == "zellij_new_tab":
            return base + ["new-tab"] + (["--name", a["name"]] if a.get("name") else [])
        if n == "zellij_go_to_tab":
            return base + ["go-to-tab", str(a["index"])]
        if n == "zellij_split_pane":
            return base + ["new-pane", "-d", a["direction"]]
    raise RuntimeError(f"no executor for {n}")


def zellij_session():
    if os.environ.get("ZELLIJ_SESSION_NAME"):
        return os.environ["ZELLIJ_SESSION_NAME"]
    out = sh("zellij", "list-sessions", "-n", "-s") or sh("zellij", "list-sessions", "-n")
    live = [l.split()[0] for l in out.splitlines() if l.strip() and "EXITED" not in l]
    return live[-1] if live else None   # newest; ambiguous with several windows open


# ----- voice ----------------------------------------------------------------
def _kill(pid, wait=3.0):
    """SIGINT, then SIGTERM, then SIGKILL. Returns once the process is gone."""
    for sig, patience in ((signal.SIGINT, wait), (signal.SIGTERM, 1.0), (signal.SIGKILL, 1.0)):
        try:
            os.kill(pid, sig)
        except ProcessLookupError:
            return
        deadline = time.time() + patience
        while time.time() < deadline:
            time.sleep(0.05)
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                return


def _fix_wav(wav):
    """A recorder that was killed hard leaves the RIFF sizes at 0. Rewrite the header from the data length."""
    import wave
    try:
        with wave.open(wav) as w:
            if w.getnframes() > 0:
                return
    except Exception:
        pass
    try:
        data = open(wav, "rb").read()
        if not data.startswith(b"RIFF"):
            return
        i = data.find(b"data")
        pcm = data[i + 8:] if i >= 0 else data[44:]
        with wave.open(wav, "wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(16000); w.writeframes(pcm)
    except Exception:
        pass


def _ding(name):
    """Audible cue, since the notification may be silenced: Tink when the mic opens, Pop when it closes."""
    subprocess.Popen(["afplay", f"/System/Library/Sounds/{name}.aiff"], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


_ov = None  # the result pill for this run, an open pipe to macarchy-overlay


def _ov_say(state, title, detail=""):
    """Update the bottom-of-screen pill (like Handy's). Falls back to a notification if it is not built."""
    global _ov
    if not os.path.exists(OVERLAY):
        notify("ws", title if not detail else f"{title}\n{detail}")
        return
    if _ov is None or _ov.poll() is not None:
        _ov = subprocess.Popen([OVERLAY, "--ttl", "3.5"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, text=True)
    try:
        d = detail.replace("\n", "\\n")  # the pill takes one state per line
        _ov.stdin.write(f"{state}\t{title}\t{d}\n"); _ov.stdin.flush()
    except (BrokenPipeError, OSError):
        pass


def voice(c):
    import fcntl
    os.makedirs(CACHE, exist_ok=True)
    pidf, wav = os.path.join(CACHE, "ws-rec.pid"), os.path.join(CACHE, "ws-rec.wav")
    lock = open(os.path.join(CACHE, "ws-rec.lock"), "w")
    fcntl.flock(lock, fcntl.LOCK_EX)  # a doubled keypress (key repeat, two skhd events) waits here instead of racing
    if os.path.exists(pidf):
        pid, started, ov_pid = 0, 0.0, 0
        try:
            parts = (open(pidf).read().split() + ["0", "0", "0"])[:3]
            pid, started, ov_pid = int(parts[0]), float(parts[1]), int(parts[2])
        except ValueError:
            pass
        if time.time() - started < 0.6:
            return None  # the same press arriving twice; keep recording
        if pid:
            _kill(pid)
        if ov_pid:
            try: os.kill(ov_pid, signal.SIGTERM)
            except ProcessLookupError: pass
        os.remove(pidf)
        subprocess.run(["pkill", "-INT", "-f", f"ffmpeg .* {re.escape(wav)}$"], capture_output=True)  # strays from any earlier bug
        subprocess.run(["sketchybar", "--trigger", "ws_listen", "LISTENING=0"], capture_output=True)
        _ding("Pop")
        _fix_wav(wav)
        _ov_say("busy", "Transcribing…")
        return transcribe(c, wav)
    p = subprocess.Popen(["ffmpeg", "-nostdin", "-loglevel", "quiet", "-f", "avfoundation", "-i", c["MACARCHY_MIC"],
                          "-ac", "1", "-ar", "16000", "-y", wav], stdin=subprocess.DEVNULL)
    ov_pid = 0
    if os.path.exists(OVERLAY):  # the pill outlives this process; the next press kills it
        ov = subprocess.Popen([OVERLAY, "listen", "Listening…", "alt-w again to run"], start_new_session=True,
                              stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        ov_pid = ov.pid
    else:
        notify("ws", "listening… press again to run")
    open(pidf, "w").write(f"{p.pid} {time.time()} {ov_pid}")
    subprocess.run(["sketchybar", "--trigger", "ws_listen", "LISTENING=1"], capture_output=True)
    _ding("Tink")
    return None


def transcribe(c, wav):
    out = sh(c["MACARCHY_HANDY"], "--transcribe-file", wav, "--json")
    m = re.search(r"\{.*\"text\".*\}", out, re.S)
    return json.loads(m.group(0))["text"] if m else ""


# ----- main -----------------------------------------------------------------
def main(argv):
    import argparse
    ap = argparse.ArgumentParser(prog="ws", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("text", nargs="*")
    ap.add_argument("-x", "--execute", action="store_true", help="run the calls (default: dry-run)")
    ap.add_argument("-n", "--dry-run", action="store_true", help="force dry-run even if config says execute")
    ap.add_argument("--voice", action="store_true", help="toggle mic recording; on stop, transcribe and run")
    ap.add_argument("--wav", help="transcribe this WAV and run")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)
    c = cfg()
    execute_mode = (a.execute or c["MACARCHY_AGENT_EXECUTE"].lower() in ("1", "true", "yes")) and not a.dry_run

    if a.voice:
        text = voice(c)
        if text is None:
            return 0
    elif a.wav:
        text = transcribe(c, a.wav)
    else:
        text = " ".join(a.text)
    if not text.strip():
        print("nothing heard", file=sys.stderr)
        if a.voice:
            _ov_say("fail", "Nothing heard", f"mic {c['MACARCHY_MIC']} recorded silence, or you did not speak")
            if _ov: _ov.stdin.close()
        return 1

    wins = windows()
    calls, why = plan(text, c["MACARCHY_AGENT_MODEL"], wins)
    lines, results = [], []
    for call in calls:
        try:
            cmd = execute(call, wins)
        except Exception as e:
            lines.append(f"skip {call['name']}: {e}"); continue
        if execute_mode:
            r = subprocess.run(cmd, capture_output=True, text=True)
            ok = r.returncode == 0
            lines.append(("ran  " if ok else "FAIL ") + shlex.join(cmd) + ("" if ok else f"  -> {r.stderr.strip()[:80]}"))
        else:
            lines.append("would " + shlex.join(cmd))
        results.append({"call": call, "cmd": cmd})
    if a.json:
        print(json.dumps({"text": text, "reasoning": why, "calls": calls, "commands": [r["cmd"] for r in results]}, indent=1))
    else:
        print(f"heard: {text}")
        print(f"think: {why}")
        print("\n".join(lines) if lines else "no action")
    if a.voice or a.wav:
        failed = any(l.startswith(("FAIL", "skip")) for l in lines)
        body = "\n".join(l[:90] for l in lines) or "no action"
        _ov_say("fail" if failed or not calls else "ok", ("heard: " if execute_mode else "dry-run, heard: ") + text, body)
        if _ov: _ov.stdin.close()  # the pill fades a few seconds after this
    return 0 if calls else 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
