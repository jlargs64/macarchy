#!/usr/bin/env python3
# hollow wallpaper: a harvest moon over a bare-tree ridge, bats, a lit
# jack-o'-lantern and falling leaves. Drawn with Pillow, seeded, so every run
# gives the same picture. theme-wallpaper calls it as: wallpaper.py OUT W H
# Everything that matters sits in the middle band, so a 21:9 display (which
# crops the 16:9 frame top and bottom) still sees the moon, trees and pumpkin.
# ruff: noqa: S311 -- seeded random for a repeatable picture, not for secrets
import math
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

out = sys.argv[1]
W = int(sys.argv[2]) if len(sys.argv) > 2 else 5120
H = int(sys.argv[3]) if len(sys.argv) > 3 else 2880
S = W / 5120  # every size below is authored at 5120 wide
rng = random.Random(1031)


def rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def glow(img, xy, r, color, blur, alpha=255):
    """Soft additive light: a blurred disc screened onto img."""
    layer = Image.new("RGB", img.size, (0, 0, 0))
    d = ImageDraw.Draw(layer)
    x, y = xy
    c = tuple(round(v * alpha / 255) for v in color)
    d.ellipse((x - r, y - r, x + r, y + r), fill=c)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    return ImageChops.screen(img, layer)


# --- sky: deep plum night down to an ember horizon -------------------------
stops = [
    (0.00, rgb("0b0810")),
    (0.40, rgb("1c1020")),
    (0.66, rgb("3d1a1e")),
    (0.80, rgb("7a3517")),
    (1.00, rgb("a8521c")),
]
col = Image.new("RGB", (1, H))
px = col.load()
for y in range(H):
    t = y / (H - 1)
    for (t0, c0), (t1, c1) in zip(stops, stops[1:], strict=False):
        if t <= t1:
            px[0, y] = lerp(c0, c1, (t - t0) / (t1 - t0))
            break
img = col.resize((W, H), Image.BILINEAR)

# faint stars, upper sky only
d = ImageDraw.Draw(img)
for _ in range(420):
    x, y = rng.uniform(0, W), rng.uniform(0, H * 0.45) ** 1.0
    b = rng.randint(90, 190)
    r = rng.choice([1, 1, 1, 2]) * S
    d.ellipse((x - r, y - r, x + r, y + r), fill=(b, b - 10, b - 25))

# --- harvest moon ------------------------------------------------------------
mx, my, mr = W * 0.70, H * 0.33, 330 * S
img = glow(img, (mx, my), mr * 2.6, rgb("7a3a14"), 260 * S)
img = glow(img, (mx, my), mr * 1.5, rgb("c9702a"), 120 * S)
moon = Image.new("L", (W, H), 0)
ImageDraw.Draw(moon).ellipse((mx - mr, my - mr, mx + mr, my + mr), fill=255)
face = Image.new("RGB", (W, H), rgb("f3c27c"))
fd = ImageDraw.Draw(face)
# maria: soft darker blotches, blurred into the disc
for _ in range(9):
    a = rng.uniform(0, 2 * math.pi)
    dist = rng.uniform(0, mr * 0.6)
    cx, cy = mx + math.cos(a) * dist, my + math.sin(a) * dist
    cr = rng.uniform(mr * 0.12, mr * 0.3)
    fd.ellipse((cx - cr, cy - cr, cx + cr, cy + cr), fill=rgb("d99a5a"))
face = face.filter(ImageFilter.GaussianBlur(16 * S))
img.paste(face, (0, 0), moon.filter(ImageFilter.GaussianBlur(2 * S)))

# --- thin clouds drifting across the moon -----------------------------------
clouds = Image.new("L", (W, H), 0)
cd = ImageDraw.Draw(clouds)
for cy, span, thick in [(my - 60 * S, 1500, 38), (my + 150 * S, 1900, 52), (H * 0.18, 2600, 44)]:
    cx = mx - span * S * 0.55
    for _ in range(14):
        w = rng.uniform(260, 520) * S
        h = thick * S * rng.uniform(0.6, 1.3)
        x = cx + rng.uniform(0, span * S)
        y = cy + rng.uniform(-20, 20) * S
        cd.ellipse((x - w, y - h, x + w, y + h), fill=rng.randint(60, 110))
clouds = clouds.filter(ImageFilter.GaussianBlur(40 * S))
img.paste(Image.new("RGB", (W, H), rgb("24121c")), (0, 0), clouds)

d = ImageDraw.Draw(img)


# --- bats ---------------------------------------------------------------------
def bat(cx, cy, s, flap):
    lift = flap * s
    pts = [
        (cx, cy - 0.12 * s),
        (cx + 0.18 * s, cy - 0.30 * s - lift * 0.4),
        (cx + 0.55 * s, cy - 0.45 * s - lift),
        (cx + 1.00 * s, cy - 0.20 * s - lift * 0.6),
        (cx + 0.78 * s, cy - 0.05 * s),
        (cx + 0.62 * s, cy + 0.10 * s),
        (cx + 0.40 * s, cy + 0.00 * s),
        (cx + 0.18 * s, cy + 0.16 * s),
        (cx, cy + 0.08 * s),
    ]
    mirror = [(2 * cx - x, y) for x, y in reversed(pts)]
    d.polygon(pts + mirror, fill=rgb("0c0709"))
    d.ellipse((cx - 0.09 * s, cy - 0.16 * s, cx + 0.09 * s, cy + 0.18 * s), fill=rgb("0c0709"))
    d.polygon(
        [(cx - 0.08 * s, cy - 0.12 * s), (cx - 0.05 * s, cy - 0.26 * s), (cx - 0.01 * s, cy - 0.13 * s)],
        fill=rgb("0c0709"),
    )
    d.polygon(
        [(cx + 0.08 * s, cy - 0.12 * s), (cx + 0.05 * s, cy - 0.26 * s), (cx + 0.01 * s, cy - 0.13 * s)],
        fill=rgb("0c0709"),
    )


for bx, by, bs, fl in [
    (0.64, 0.27, 120, 0.10),
    (0.755, 0.36, 80, -0.15),
    (0.70, 0.215, 55, 0.25),
    (0.52, 0.19, 42, 0.0),
    (0.84, 0.25, 36, 0.2),
    (0.46, 0.26, 28, -0.1),
]:
    bat(W * bx, H * by, bs * S, fl)


# --- hills ----------------------------------------------------------------------
def ridge(base, amps, color, seed):
    r = random.Random(seed)
    phases = [(a, f, r.uniform(0, 2 * math.pi)) for a, f in amps]
    pts = [(0, H)]
    step = max(4, int(8 * S))
    for x in range(0, W + step, step):
        y = base + sum(a * S * math.sin(x / W * f * 2 * math.pi + p) for a, f, p in phases)
        pts.append((x, y))
    pts.append((W, H))
    d.polygon(pts, fill=color)
    return lambda x: base + sum(a * S * math.sin(x / W * f * 2 * math.pi + p) for a, f, p in phases)


# low fog band behind the far hills
fog = Image.new("L", (W, H), 0)
ImageDraw.Draw(fog).rectangle((0, H * 0.70, W, H * 0.80), fill=70)
fog = fog.filter(ImageFilter.GaussianBlur(90 * S))
img.paste(Image.new("RGB", (W, H), rgb("c27a4a")), (0, 0), fog)
d = ImageDraw.Draw(img)

ridge(H * 0.76, [(70, 1.3), (35, 3.1), (12, 9)], rgb("2e1719"), 7)
near = ridge(H * 0.84, [(55, 0.9), (28, 2.4), (9, 11)], rgb("0d0808"), 11)

# --- bare trees -------------------------------------------------------------------
BARK = rgb("0a0606")


def branch(x, y, ang, length, width, depth, r):
    if depth == 0 or length < 6 * S:
        return
    # gnarl: walk the limb in a few kinked segments
    segs = 4
    cx, cy, a = x, y, ang
    for i in range(segs):
        a += r.uniform(-0.22, 0.22)
        nx = cx + math.cos(a) * length / segs
        ny = cy - math.sin(a) * length / segs
        w = max(1, width * (1 - 0.34 * i / segs))
        d.line((cx, cy, nx, ny), fill=BARK, width=int(w))
        d.ellipse((nx - w / 2, ny - w / 2, nx + w / 2, ny + w / 2), fill=BARK)
        cx, cy = nx, ny
    kids = 2 if depth > 5 else r.choice([2, 2, 3])
    for k in range(kids):
        spread = r.uniform(0.35, 0.75)
        na = a + spread * (1 if k % 2 else -1) + r.uniform(-0.15, 0.15)
        branch(cx, cy, na, length * r.uniform(0.62, 0.78), width * 0.66, depth - 1, r)


def tree(x, height, trunk, depth, lean, seed):
    r = random.Random(seed)
    y = near(x) + 45 * S
    # flared roots: a low curved skirt, not a tent
    skirt = []
    for i in range(21):
        t = i / 20 * 2 - 1  # -1..1 across the base
        skirt.append((x + t * trunk * 1.25, y - trunk * 0.9 * (1 - abs(t)) ** 2.2))
    d.polygon(skirt + [(x + trunk * 1.25, y + 30 * S), (x - trunk * 1.25, y + 30 * S)], fill=BARK)
    branch(x, y, math.pi / 2 + lean, height * S, trunk, depth, r)


tree(W * 0.13, 520, 90 * S, 9, 0.10, 3)  # the big gnarled one, left
tree(W * 0.30, 300, 42 * S, 8, -0.12, 5)
tree(W * 0.905, 380, 60 * S, 8, -0.08, 9)
tree(W * 0.555, 190, 26 * S, 7, 0.05, 13)

# ground fog hugging the near ridge, over the tree bases
fog = Image.new("L", (W, H), 0)
fgd = ImageDraw.Draw(fog)
for _ in range(40):
    x = rng.uniform(-200, W + 200) * 1.0
    y = near(min(max(x, 0), W)) + rng.uniform(-40, 60) * S
    w, h = rng.uniform(300, 700) * S, rng.uniform(30, 70) * S
    fgd.ellipse((x - w, y - h, x + w, y + h), fill=rng.randint(40, 80))
fog = fog.filter(ImageFilter.GaussianBlur(50 * S))
img.paste(Image.new("RGB", (W, H), rgb("6e4a52")), (0, 0), fog)
d = ImageDraw.Draw(img)

# --- jack-o'-lantern at the foot of the big tree ------------------------------------
px_, pr = W * 0.205, 95 * S
py_ = near(px_) - pr * 0.55
img = glow(img, (px_, py_), pr * 3.2, rgb("8a3a0c"), 150 * S)
d = ImageDraw.Draw(img)
for dx, rx in [(-0.55, 0.62), (0.55, 0.62), (-0.25, 0.7), (0.25, 0.7), (0, 0.72)]:
    shade = rgb("c4561a") if abs(dx) > 0.4 else rgb("dd6a22")
    cx = px_ + dx * pr
    d.ellipse((cx - rx * pr, py_ - pr * 0.82, cx + rx * pr, py_ + pr * 0.82), fill=shade)
d.polygon(
    [
        (px_ - 10 * S, py_ - pr * 0.78),
        (px_ + 12 * S, py_ - pr * 0.78),
        (px_ + 22 * S, py_ - pr * 1.12),
        (px_ + 6 * S, py_ - pr * 1.1),
    ],
    fill=rgb("3b2a12"),
)
FLAME = rgb("ffd27a")
d.polygon(
    [(px_ - 0.55 * pr, py_ - 0.08 * pr), (px_ - 0.35 * pr, py_ - 0.42 * pr), (px_ - 0.16 * pr, py_ - 0.08 * pr)],
    fill=FLAME,
)
d.polygon(
    [(px_ + 0.16 * pr, py_ - 0.08 * pr), (px_ + 0.35 * pr, py_ - 0.42 * pr), (px_ + 0.55 * pr, py_ - 0.08 * pr)],
    fill=FLAME,
)
d.polygon([(px_ - 0.08 * pr, py_ + 0.12 * pr), (px_, py_ - 0.04 * pr), (px_ + 0.08 * pr, py_ + 0.12 * pr)], fill=FLAME)
mouth = [(px_ - 0.6 * pr, py_ + 0.22 * pr)]
for i, x in enumerate([-0.42, -0.26, -0.1, 0.1, 0.26, 0.42]):
    mouth.append((px_ + x * pr, py_ + (0.36 if i % 2 == 0 else 0.26) * pr))
mouth += [(px_ + 0.6 * pr, py_ + 0.22 * pr), (px_ + 0.4 * pr, py_ + 0.55 * pr), (px_ - 0.4 * pr, py_ + 0.55 * pr)]
d.polygon(mouth, fill=FLAME)
img = glow(img, (px_, py_ + 0.1 * pr), pr * 0.7, rgb("7a3a08"), 30 * S)

# --- falling leaves ---------------------------------------------------------------
LEAVES = [rgb(h) for h in ("e8772e", "c4561a", "b8412f", "f0b54a", "8a4b2a", "d98a3a")]


def leaf(x, y, size, ang, color, blur):
    lw = int(size * 2.4)
    tile = Image.new("RGBA", (lw, lw), (0, 0, 0, 0))
    td = ImageDraw.Draw(tile)
    c = lw / 2
    td.polygon(
        [(c - size, c), (c - size * 0.2, c - size * 0.48), (c + size, c), (c - size * 0.2, c + size * 0.48)],
        fill=color + (235,),
    )
    td.line(
        (c - size * 1.15, c, c + size * 0.9, c), fill=tuple(v // 2 for v in color) + (235,), width=max(1, int(size / 9))
    )
    tile = tile.rotate(ang, resample=Image.BICUBIC, expand=False)
    if blur:
        tile = tile.filter(ImageFilter.GaussianBlur(blur))
    img.paste(tile, (int(x - c), int(y - c)), tile)


for _ in range(70):
    x = rng.uniform(0, W)
    y = rng.uniform(H * 0.12, H * 0.86)
    near_cam = rng.random() < 0.18
    size = rng.uniform(30, 48) * S if near_cam else rng.uniform(10, 22) * S
    blur = rng.uniform(3, 7) * S if near_cam else 0
    leaf(x, y, size, rng.uniform(0, 360), rng.choice(LEAVES), blur)

# a scatter of leaves on the ground
for _ in range(90):
    x = rng.uniform(0, W)
    y = near(x) + rng.uniform(20, 260) * S
    leaf(x, y, rng.uniform(8, 16) * S, rng.uniform(-30, 30), tuple(v // 3 for v in rng.choice(LEAVES)), 0)

# --- vignette ---------------------------------------------------------------------
vig = Image.new("L", (W // 8, H // 8), 0)
ImageDraw.Draw(vig).ellipse((-W // 40, -H // 30, W // 8 + W // 40, H // 8 + H // 30), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(W // 60)).resize((W, H), Image.BILINEAR)
img = Image.composite(img, Image.new("RGB", (W, H), (4, 2, 3)), vig)

img.save(out)
