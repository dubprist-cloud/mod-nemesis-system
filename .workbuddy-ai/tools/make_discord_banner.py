"""Render the Discord announcement banner for mod-nemesis-system.

Produces a 1600x900 PNG that mirrors the addon's own palette (dark panel, gold chrome,
ember accents) and shows a faithful mockup of the tracker window next to the pitch.

Run:
    python make_discord_banner.py [output.png]
"""

import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

W, H = 1600, 900

BG_TOP = (22, 15, 34)
BG_MID = (9, 8, 14)
BG_BOT = (26, 11, 16)
PANEL = (16, 15, 24)
GOLD = (184, 148, 64)
GOLD_HI = (242, 199, 89)
TEXT = (232, 232, 238)
MUTED = (140, 140, 155)
EMBER = (200, 60, 40)

FONTS = "C:/Windows/Fonts/"
RANK_COLORS = {
    1: (89, 191, 89),
    2: (217, 217, 89),
    3: (230, 153, 64),
    4: (230, 77, 64),
    5: (179, 102, 242),
}


def font(name, size):
    return ImageFont.truetype(FONTS + name, size)


F_TITLE = font("georgiab.ttf", 92)
F_SUB = font("georgiab.ttf", 38)
F_OVER = font("segoeuib.ttf", 13)
F_TAG = font("segoeui.ttf", 20)
F_FEAT = font("segoeui.ttf", 19)
F_FOOT = font("segoeui.ttf", 15)
F_WIN_TITLE = font("segoeuib.ttf", 21)
F_WIN_SUB = font("segoeui.ttf", 12)
F_BTN = font("segoeuib.ttf", 11)
F_ROW = font("segoeuib.ttf", 15)
F_AFFIX = font("segoeui.ttf", 11)
F_RANK = font("segoeuib.ttf", 14)
F_SMALL = font("segoeui.ttf", 12)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def background():
    img = Image.new("RGB", (W, H), BG_MID)
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        c = lerp(BG_TOP, BG_MID, t / 0.5) if t < 0.5 else lerp(BG_MID, BG_BOT, (t - 0.5) / 0.5)
        d.line([(0, y), (W, y)], fill=c)
    return img


def glow(cx, cy, radius, color, peak):
    layer = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    steps = 48
    for i in range(steps, 0, -1):
        t = i / steps
        r = radius * t
        a = peak * (1.0 - t) ** 2
        d.ellipse([cx - r, cy - r * 0.82, cx + r, cy + r * 0.82],
                  fill=tuple(int(v * a / 255.0) for v in color))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.16))


def add_light(img, layer, amount=1.0):
    if amount != 1.0:
        layer = layer.point(lambda v: int(v * amount))
    return ImageChops.add(img, layer)


def vignette(img, strength=0.52):
    sw, sh = 96, 54
    small = Image.new("L", (sw, sh), 0)
    px = small.load()
    for y in range(sh):
        for x in range(sw):
            nx = (x / (sw - 1.0)) * 2 - 1
            ny = (y / (sh - 1.0)) * 2 - 1
            dist = min(1.0, (nx * nx * 0.85 + ny * ny * 1.05) ** 0.5)
            px[x, y] = int(255 * strength * (dist ** 2.8))
    mask = small.resize((W, H), Image.BICUBIC)
    return Image.composite(Image.new("RGB", (W, H), (0, 0, 0)), img, mask)


def tracked(d, xy, s, f, fill, spacing=0, centered=False):
    x, y = xy
    if centered:
        x -= (tracked_len(d, s, f, spacing) / 2.0)
    for ch in s:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + spacing
    return x


def tracked_len(d, s, f, spacing=0):
    return sum(d.textlength(ch, font=f) + spacing for ch in s) - spacing


def diamond(d, cx, cy, r, fill):
    d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=fill)


ROWS = [
    ("Гримвольф", 5, "Вампиризм · Ярость"),
    ("Теньлуны", 5, "Свирепость · Несокрушимость · Регенерация"),
    ("Каражан", 4, "Стремительность · Антимагия"),
    ("Морозный", 5, "Ярость · Регенерация · Вампиризм"),
    ("Аргент", 4, "Свирепость · Стремительность"),
    ("НочнаяТень", 3, "Вампиризм · Антимагия"),
    ("Стальной", 4, "Несокрушимость · Ярость"),
    ("Пепел", 3, "Регенерация · Свирепость"),
    ("Вьюга", 2, "Стремительность"),
]
TIERS = {1: "Marked", 2: "Hated", 3: "Relentless", 4: "Legendary", 5: "Mythic"}

CONTROLS = [
    ("Обновить", 76), ("Точка", 52), ("Все", 40), ("Свои", 40), ("Группа", 52), ("Гильдия", 58),
    ("Все зоны", 64), ("Эта карта", 68), ("Топ", 38), ("<", 20), ("1/1", 30), (">", 20),
]
GAPS = [8, 12, 4, 4, 4, 12, 4, 12, 10, 4, 4, 4]


def tracker_window(img, x0, y0, w, h):
    d = ImageDraw.Draw(img, "RGBA")

    d.rectangle([x0, y0, x0 + w, y0 + h], fill=PANEL + (255,))
    d.rectangle([x0, y0, x0 + w, y0 + h], outline=GOLD + (200,), width=1)

    d.text((x0 + 20, y0 + 15), "Nemesis Tracker", font=F_WIN_TITLE, fill=GOLD_HI)
    d.text((x0 + w - 20, y0 + 22), "0.6.2", font=F_WIN_SUB, fill=MUTED, anchor="ra")
    d.line([(x0 + 20, y0 + 50), (x0 + w - 20, y0 + 50)], fill=GOLD + (115,))

    bx, by = x0 + 20, y0 + 62
    for i, (label, bw) in enumerate(CONTROLS):
        active = label in ("Все", "Все зоны")
        bg = GOLD + (102,) if active else (10, 10, 17, 242)
        brd = GOLD_HI + (242,) if active else GOLD + (166,)
        d.rectangle([bx, by, bx + bw, by + 24], fill=bg, outline=brd, width=1)
        d.text((bx + bw / 2.0, by + 12), label, font=F_BTN, fill=TEXT, anchor="mm")
        bx += bw + GAPS[i]

    row_h = 42
    ry = y0 + 98
    for i, (name, rank, affixes) in enumerate(ROWS):
        top = ry + i * row_h
        color = RANK_COLORS[rank]
        d.rectangle([x0 + 20, top + 6, x0 + 23, top + 30], fill=color + (255,))
        d.text((x0 + 33, top + 3), name, font=F_ROW, fill=TEXT)
        d.text((x0 + 33, top + 22), affixes, font=F_AFFIX, fill=MUTED)
        d.text((x0 + w - 20, top + 3), "R%d · %s" % (rank, TIERS[rank]),
               font=F_RANK, fill=color, anchor="ra")
        if i < len(ROWS) - 1:
            d.line([(x0 + 20, top + 38), (x0 + w - 20, top + 38)], fill=(255, 255, 255, 12))

    sep = ry + len(ROWS) * row_h + 12
    d.line([(x0 + 20, sep), (x0 + w - 20, sep)], fill=GOLD + (115,))
    own = sep + 12
    d.text((x0 + 20, own), "37.", font=F_RANK, fill=GOLD_HI)
    d.text((x0 + 56, own), "Твой персонаж", font=F_RANK, fill=GOLD_HI)
    d.text((x0 + w - 20, own), "4 / 2 / 2 / R3", font=F_RANK, fill=GOLD_HI, anchor="ra")


FEATURES = [
    "5 рангов: от Marked до Mythic",
    "7 аффиксов, случайный набор на каждом ранге",
    "Месть — каждому, кого она убила",
    "Аддон: карта, миникарта, путевые точки",
    "Топ охотников месяца прямо в игре",
]


def right_column(img, x):
    d = ImageDraw.Draw(img, "RGBA")

    tracked(d, (x, 208), "МОДУЛЬ ДЛЯ AZEROTHCORE 3.3.5A", F_OVER, (156, 126, 74), 3.2)

    d.text((x - 4, 232), "NEMESIS", font=F_TITLE, fill=GOLD_HI)
    tracked(d, (x + 2, 358), "SYSTEM", F_SUB, GOLD, 11)
    d.text((x + 2, 428), "Восстань. Охоть. Расти в ранге. Отомсти.", font=F_TAG, fill=TEXT)

    d.line([(x, 480), (W - 70, 480)], fill=GOLD + (140,))

    for i, line in enumerate(FEATURES):
        y = 508 + i * 40
        diamond(d, x + 6, y + 11, 5, GOLD_HI + (255,))
        d.text((x + 26, y), line, font=F_FEAT, fill=(206, 206, 214))

    d.text((x, 726), "Живёт, пока растёт: 6 часов без убийств — и она исчезает.",
           font=F_FOOT, fill=MUTED)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "nemesis-discord-banner.png"

    img = background()
    img = add_light(img, glow(430, 470, 560, EMBER, 96), 0.62)
    img = add_light(img, glow(1240, 330, 380, GOLD, 70), 0.55)
    img = vignette(img)

    tracker_window(img, 70, 170, 740, 540)
    right_column(img, 880)

    d = ImageDraw.Draw(img, "RGBA")
    d.line([(70, 828), (W - 70, 828)], fill=GOLD + (90,))
    tracked(d, (W / 2.0, 842), "MOD-NEMESIS-SYSTEM", F_SMALL, (110, 104, 122), 4.0, centered=True)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    img.save(out, "PNG", optimize=True)
    print("wrote %s  (%dx%d, %d bytes)" % (out, img.width, img.height, os.path.getsize(out)))


if __name__ == "__main__":
    main()
