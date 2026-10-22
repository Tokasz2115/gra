#!/usr/bin/env python3
"""Generuje grafikę pixel art do gry (postacie, kafelki trawy, dekoracje).

Uruchomienie z głównego folderu projektu:
    pip install pillow
    python tools/make_sprites.py

Wyniki trafiają do folderu assets/. Aby zmienić wygląd postaci,
edytuj słowniki SOLDIER i ZOMBIE_* poniżej i uruchom skrypt ponownie.
"""
import os
import random

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SPRITES = os.path.join(ROOT, "assets", "sprites")
TILES = os.path.join(ROOT, "assets", "tiles")
os.makedirs(SPRITES, exist_ok=True)
os.makedirs(TILES, exist_ok=True)

CW, CH = 32, 32          # płótno robocze jednej klatki postaci
CX = 16                  # oś symetrii postaci
OUTLINE = (20, 17, 15, 255)


def hx(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


BLOOD = hx("8a1c1c")
EYE_ZOMBIE = hx("e23b3b")
MOUTH_ZOMBIE = hx("4a0e0e")
GUN = hx("3c3f44")
GUN_HI = hx("6b7078")
STOCK = hx("6b4a2a")


class Canvas:
    def __init__(self, w=CW, h=CH):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.px = self.im.load()
        self.w, self.h = w, h

    def dot(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.dot(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.dot(x, y, c)


def add_outline(im):
    src = im.load()
    out = im.copy()
    dst = out.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        dst[x, y] = OUTLINE
                        break
    return out


# ---------------------------------------------------------------- postacie

SOLDIER = dict(
    head_w=6, head_h=6, torso_w=8, torso_h=7, leg_w=3, leg_h=5, leg_gap=2,
    arm_w=2, arm_h=6, raised=False, hair="helmet",
    skin=hx("e8b98a"), skin_sh=hx("c4936a"),
    shirt=hx("c2a867"), shirt_sh=hx("9c854d"), sleeve=hx("b39a5c"),
    pants=hx("5b6a8a"), pants_sh=hx("46536e"), boots=hx("2b2622"),
    belt=hx("6b4a2a"), hair_c=hx("4f6b3a"), hair_hi=hx("7c9a5a"),
    eye=hx("1a1a1a"), zombie=False, seed=1,
)

ZOMBIE_MAN = dict(
    head_w=6, head_h=6, torso_w=8, torso_h=7, leg_w=3, leg_h=5, leg_gap=2,
    arm_w=2, arm_h=7, raised=True, hair="short",
    skin=hx("a8c46a"), skin_sh=hx("86a24f"),
    shirt=hx("56627a"), shirt_sh=hx("434d60"), sleeve=hx("56627a"),
    pants=hx("6a5642"), pants_sh=hx("52422f"), boots=hx("2b2622"),
    hair_c=hx("2e2118"), eye=EYE_ZOMBIE, zombie=True, torn=True, seed=11,
)

ZOMBIE_WOMAN = dict(
    head_w=6, head_h=6, torso_w=6, torso_h=5, leg_w=2, leg_h=6, leg_gap=2,
    arm_w=2, arm_h=7, raised=True, hair="long", skirt=True,
    skin=hx("bcd27e"), skin_sh=hx("98ae5f"),
    shirt=hx("8e3b62"), shirt_sh=hx("6d2c4a"), sleeve=hx("8e3b62"),
    pants=hx("bcd27e"), pants_sh=hx("98ae5f"), boots=hx("3a2a2a"),
    hair_c=hx("6a3a2a"), eye=EYE_ZOMBIE, zombie=True, torn=True, seed=23,
)

ZOMBIE_CHILD = dict(
    head_w=6, head_h=6, torso_w=6, torso_h=4, leg_w=2, leg_h=4, leg_gap=2,
    arm_w=2, arm_h=5, raised=True, hair="tuft",
    skin=hx("c0da7a"), skin_sh=hx("9cb85c"),
    shirt=hx("c7a23a"), shirt_sh=hx("a3841f"), sleeve=hx("c7a23a"),
    pants=hx("3d5a80"), pants_sh=hx("2e4560"), boots=hx("2b2622"),
    hair_c=hx("d9b44a"), eye=EYE_ZOMBIE, zombie=True, torn=True, seed=37,
)

ZOMBIE_FAT = dict(
    head_w=6, head_h=5, torso_w=12, torso_h=8, leg_w=3, leg_h=4, leg_gap=4,
    arm_w=3, arm_h=6, raised=True, hair="bald", belly=True,
    skin=hx("9dbd62"), skin_sh=hx("7c9a49"),
    shirt=hx("d8d0a8"), shirt_sh=hx("b4ac84"), sleeve=hx("d8d0a8"),
    pants=hx("5a4a3a"), pants_sh=hx("45372a"), boots=hx("2b2622"),
    hair_c=hx("3a2a1f"), eye=EYE_ZOMBIE, zombie=True, torn=True, seed=53,
)


def make_person(sp, step):
    """Rysuje jedną klatkę animacji marszu (step 0 albo 1)."""
    c = Canvas()
    bottom = 29

    # nogi
    lw, gap, lh = sp["leg_w"], sp["leg_gap"], sp["leg_h"]
    leg_top = bottom - lh + 1
    for i, x0 in enumerate((CX - gap // 2 - lw, CX + gap // 2)):
        lift = 1 if (i == 0) == (step == 0) else 0
        yb = bottom - lift
        c.rect(x0, leg_top, x0 + lw - 1, yb, sp["pants"])
        c.rect(x0 + lw - 1, leg_top, x0 + lw - 1, yb, sp["pants_sh"])
        c.rect(x0, yb - 1, x0 + lw - 1, yb, sp["boots"])

    # tułów
    th, tw = sp["torso_h"], sp["torso_w"]
    t_top = leg_top - th
    tx0 = CX - tw // 2
    tx1 = tx0 + tw - 1
    c.rect(tx0, t_top, tx1, leg_top - 1, sp["shirt"])
    c.rect(tx1, t_top, tx1, leg_top - 1, sp["shirt_sh"])
    if sp.get("belt"):
        c.rect(tx0, leg_top - 1, tx1, leg_top - 1, sp["belt"])
    if sp.get("belly"):
        c.rect(tx0 + 1, leg_top - 2, tx1 - 1, leg_top - 1, sp["skin"])
        c.dot(CX, leg_top - 2, sp["skin_sh"])
    if sp.get("skirt"):
        c.rect(tx0 - 1, leg_top, tx1 + 1, leg_top + 1, sp["shirt"])
        c.rect(tx0 - 2, leg_top + 2, tx1 + 2, leg_top + 2, sp["shirt"])
        c.rect(tx1 + 1, leg_top, tx1 + 2, leg_top + 2, sp["shirt_sh"])

    # głowa
    hh, hw = sp["head_h"], sp["head_w"]
    h_top = t_top - hh
    hx0 = CX - hw // 2
    hx1 = hx0 + hw - 1
    c.rect(hx0, h_top, hx1, t_top - 1, sp["skin"])
    c.rect(hx1, h_top, hx1, t_top - 1, sp["skin_sh"])
    eye_y = h_top + hh // 2
    c.dot(hx0 + 1, eye_y, sp["eye"])
    c.dot(hx1 - 1, eye_y, sp["eye"])
    if sp["zombie"]:
        c.rect(CX - 1, h_top + hh - 2, CX, h_top + hh - 2, MOUTH_ZOMBIE)
    else:
        c.dot(CX - 1, h_top + hh - 2, sp["skin_sh"])
        c.dot(CX, h_top + hh - 2, sp["skin_sh"])

    # włosy / hełm
    hair = sp["hair"]
    hc = sp["hair_c"]
    if hair == "helmet":
        c.rect(hx0 - 1, h_top - 1, hx1 + 1, h_top + 1, hc)
        c.rect(hx0, h_top - 1, hx0 + 2, h_top - 1, sp["hair_hi"])
        c.rect(hx0 - 1, h_top + 1, hx1 + 1, h_top + 1, hc)
    elif hair == "short":
        c.rect(hx0, h_top, hx1, h_top + 1, hc)
        c.dot(hx0, h_top + 2, hc)
        c.dot(hx1, h_top + 2, hc)
    elif hair == "long":
        c.rect(hx0, h_top, hx1, h_top + 1, hc)
        c.rect(hx0 - 1, h_top + 1, hx0, t_top + 2, hc)
        c.rect(hx1, h_top + 1, hx1 + 1, t_top + 2, hc)
    elif hair == "tuft":
        c.rect(hx0, h_top, hx1, h_top, hc)
        c.dot(hx0 + 1, h_top - 1, hc)
        c.dot(hx0 + 3, h_top - 1, hc)
        c.dot(hx1, h_top + 1, hc)
    elif hair == "bald":
        c.dot(hx0 + 2, h_top, hc)
        c.dot(hx0 + 3, h_top, hc)

    # ręce
    aw, ah = sp["arm_w"], sp["arm_h"]
    for i, ax in enumerate((tx0 - aw, tx1 + 1)):
        swing = 1 if (i == 0) == (step == 0) else 0
        if sp["raised"]:
            ay = t_top - 2 + swing
            c.rect(ax, ay, ax + aw - 1, ay + ah - 1, sp["sleeve"])
            c.rect(ax, ay, ax + aw - 1, ay + min(3, ah - 3), sp["skin"])
        else:
            ay = t_top + 1 + swing
            c.rect(ax, ay, ax + aw - 1, ay + ah - 1, sp["sleeve"])
            c.rect(ax, ay + ah - 2, ax + aw - 1, ay + ah - 1, sp["skin"])
            c.rect(ax + aw - 1, ay, ax + aw - 1, ay + ah - 3, sp["shirt_sh"])

    # karabin
    if sp.get("rifle"):
        ry = t_top + 3
        c.rect(tx1 + 1, ry, tx1 + 3, ry + 1, STOCK)
        c.rect(tx1 + 4, ry, tx1 + 10, ry + 1, GUN)
        c.rect(tx1 + 4, ry, tx1 + 10, ry, GUN_HI)
        c.rect(tx1 + 5, ry + 2, tx1 + 5, ry + 3, GUN)
        c.dot(tx1 + 2, ry + 1, sp["skin"])
        c.dot(tx1 + 6, ry + 1, sp["skin"])

    # zombie: dziury w ubraniu, krew i postrzępiony dół koszuli
    if sp.get("torn"):
        rnd = random.Random(sp["seed"])
        for _ in range(4):
            c.dot(rnd.randint(tx0 + 1, tx1 - 1), rnd.randint(t_top + 1, leg_top - 2), sp["skin"])
        for _ in range(3):
            c.dot(rnd.randint(tx0, tx1 - 1), rnd.randint(t_top, leg_top - 2), BLOOD)
        if not sp.get("belly") and not sp.get("skirt"):
            for x in range(tx0, tx1 + 1):
                if rnd.random() < 0.35:
                    c.dot(x, leg_top - 1, (0, 0, 0, 0))
        c.dot(hx0 + 1, h_top + hh - 1, BLOOD)

    return add_outline(c.im)


def crop_box(frames):
    """Wspólny prostokąt przycinania: symetryczny względem osi postaci."""
    min_x, max_x, min_y, max_y = CW, 0, CH, 0
    for im in frames:
        bb = im.getbbox()
        min_x, max_x = min(min_x, bb[0]), max(max_x, bb[2])
        min_y, max_y = min(min_y, bb[1]), max(max_y, bb[3])
    half = max(CX - min_x, max_x - CX)
    return (CX - half, min_y, CX + half, max_y)


def save_character(name, spec):
    frames = [make_person(spec, 0), make_person(spec, 1)]
    box = crop_box(frames)
    fw, fh = box[2] - box[0], box[3] - box[1]
    sheet = Image.new("RGBA", (fw * 2, fh), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f.crop(box), (i * fw, 0))
    sheet.save(os.path.join(SPRITES, name + ".png"))
    return sheet


def make_pistol():
    c = Canvas(14, 10)
    c.rect(3, 2, 11, 4, GUN)
    c.rect(3, 2, 11, 2, GUN_HI)
    c.rect(4, 5, 6, 7, STOCK)
    c.dot(7, 5, GUN)
    im = add_outline(c.im)
    im = im.crop(im.getbbox())
    im.save(os.path.join(SPRITES, "pistol.png"))
    return im


# ------------------------------------------------------------ kafelki trawy

def make_tiles():
    rnd = random.Random(7)
    base = hx("3f6b36")
    dark = hx("355c2e")
    light = hx("4a7a3d")
    blade = hx("2c4f27")
    soil = hx("7a6340")
    stone = hx("8e9298")
    sheet = Image.new("RGBA", (16 * 4, 16), (0, 0, 0, 0))
    for v in range(4):
        t = Canvas(16, 16)
        t.rect(0, 0, 15, 15, base)
        p_dark = (0.10, 0.28, 0.12, 0.14)[v]
        p_light = (0.06, 0.05, 0.16, 0.07)[v]
        for y in range(16):
            for x in range(16):
                r = rnd.random()
                if r < p_dark:
                    t.dot(x, y, dark)
                elif r < p_dark + p_light:
                    t.dot(x, y, light)
        for _ in range(3 + v):
            x, y = rnd.randint(1, 14), rnd.randint(2, 14)
            t.dot(x, y, blade)
            t.dot(x, y - 1, blade)
        if v == 3:
            for _ in range(2):
                x, y = rnd.randint(1, 13), rnd.randint(1, 14)
                t.rect(x, y, x + 1, y, soil)
            x, y = rnd.randint(2, 12), rnd.randint(2, 13)
            t.rect(x, y, x + 1, y, stone)
        sheet.paste(t.im, (v * 16, 0))
    sheet.save(os.path.join(TILES, "tiles.png"))


# ---------------------------------------------------------------- dekoracje
# Każda dekoracja to komórka 16x24 piksele; rysunek jest przy dolnej krawędzi.

CELL_W, CELL_H = 16, 24
GRASS_DARK = hx("3f6e2e")
STEM = hx("3f7a30")


def flower(color, center):
    c = Canvas(CELL_W, CELL_H)
    for (x, y) in ((4, 19), (10, 17), (8, 21)):
        c.dot(x, y + 2, STEM)
        c.dot(x, y + 3, STEM)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            c.dot(x + dx, y + dy, color)
        c.dot(x, y, center)
    return c.im


def tuft():
    c = Canvas(CELL_W, CELL_H)
    cols = (GRASS_DARK, hx("4f8a38"), hx("6fae4e"))
    for i, (x, h) in enumerate(((5, 4), (7, 6), (9, 5), (11, 3), (8, 3))):
        for k in range(h):
            c.dot(x + (k // 3 if i % 2 else -(k // 3)), 22 - k, cols[(i + k) % 3])
    return c.im


def mushroom():
    c = Canvas(CELL_W, CELL_H)
    c.rect(7, 20, 8, 22, hx("e8dcc0"))
    c.rect(5, 18, 10, 19, hx("c8372d"))
    c.rect(6, 17, 9, 17, hx("c8372d"))
    c.dot(6, 18, hx("f4f0e6"))
    c.dot(9, 18, hx("f4f0e6"))
    c.dot(8, 17, hx("f4f0e6"))
    return add_outline(c.im)


def rock():
    c = Canvas(CELL_W, CELL_H)
    c.ellipse(8, 19, 5.5, 3.5, hx("8b8f96"))
    c.ellipse(7, 18, 3.5, 2, hx("a5a9b0"))
    c.rect(10, 20, 12, 21, hx("6d7076"))
    c.dot(5, 17, hx("c4c7cc"))
    return add_outline(c.im)


def bush():
    c = Canvas(CELL_W, CELL_H)
    c.ellipse(8, 18, 6.5, 4.5, hx("2f6a2c"))
    c.ellipse(6, 17, 3.5, 2.5, hx("3f8a3a"))
    c.ellipse(10, 17, 3, 2, hx("4a9a44"))
    for (x, y) in ((5, 19), (10, 20), (8, 16)):
        c.dot(x, y, hx("d23a3a"))
    return add_outline(c.im)


def tree():
    c = Canvas(CELL_W, CELL_H)
    c.rect(7, 16, 9, 22, hx("6b4a2a"))
    c.rect(9, 16, 9, 22, hx("523720"))
    c.ellipse(8, 9, 7, 7.5, hx("2f6a2c"))
    c.ellipse(7, 8, 5.5, 5.5, hx("3f8a3a"))
    c.ellipse(6, 6, 3, 3, hx("5aa84c"))
    for (x, y) in ((11, 12), (4, 12), (9, 14)):
        c.dot(x, y, hx("265a25"))
    return add_outline(c.im)


def make_decor():
    items = [
        flower(hx("e04848"), hx("f2d64a")),
        flower(hx("f2f2f2"), hx("f2c23a")),
        flower(hx("f2d64a"), hx("e08a2a")),
        flower(hx("f08ac0"), hx("f2d64a")),
        flower(hx("5a8cf0"), hx("f2f2f2")),
        tuft(), mushroom(), rock(), bush(), tree(),
    ]
    sheet = Image.new("RGBA", (CELL_W * len(items), CELL_H), (0, 0, 0, 0))
    for i, im in enumerate(items):
        sheet.paste(im, (i * CELL_W, 0))
    sheet.save(os.path.join(TILES, "decor.png"))


if __name__ == "__main__":
    sheets = {
        "soldier": save_character("soldier", SOLDIER),
        "zombie_man": save_character("zombie_man", ZOMBIE_MAN),
        "zombie_woman": save_character("zombie_woman", ZOMBIE_WOMAN),
        "zombie_child": save_character("zombie_child", ZOMBIE_CHILD),
        "zombie_fat": save_character("zombie_fat", ZOMBIE_FAT),
    }
    make_tiles()
    make_decor()
    print("pistol", make_pistol().size)
    for n, s in sheets.items():
        print(n, "klatka", s.size[0] // 2, "x", s.size[1])
