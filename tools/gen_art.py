"""Gera a arte anime-chibi do Digialma em SVG e renderiza PNG (rsvg-convert).
Uso: python3 gen_art.py <pasta_saida>
"""
import colorsys, os, subprocess, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
PIXEL = False  # modo pixel art: olhos simplificados, sem brilhos finos

ELEM = {
    "fogo":   {"main": "#ff8a4c", "accent": "#ffd54a", "iris": "#ff5a1f", "belly": "#ffe2b8"},
    "agua":   {"main": "#5cb8ff", "accent": "#c8f4ff", "iris": "#1f7fff", "belly": "#e4f7ff"},
    "planta": {"main": "#6fd46a", "accent": "#d8ff8a", "iris": "#2e9e3a", "belly": "#efffd6"},
    "raio":   {"main": "#ffd84a", "accent": "#ffffff", "iris": "#e0a800", "belly": "#fff8d6"},
}
SPECIES = {"brasinha": "fogo", "gotinha": "agua", "brotinho": "planta", "faisquinho": "raio"}
FORMS = ["baby", "rookie", "champ_luz", "champ_sombra", "alma_luz", "alma_sombra"]

# Crianças parceiras (cabelo, pele, camisa, estilo de cabelo, óculos de proteção?)
TAMERS = [
    ("Léo",  "#3b2416", "#f5cfa8", "#e8484f", "spiky", True),
    ("Bia",  "#e25a8c", "#f7d6b8", "#3a7be0", "twin", False),
    ("Davi", "#1e2340", "#d9a77c", "#f2b632", "spiky", False),
    ("Nina", "#7b4bd6", "#f7d6b8", "#45b26b", "bob", True),
    ("Theo", "#e8b84a", "#f5cfa8", "#a35be0", "spiky", True),
    ("Lara", "#2b1b12", "#a8724d", "#f07fb0", "pony", False),
    ("Caio", "#c0442e", "#f5cfa8", "#2fb7b0", "spiky", False),
    ("Malu", "#f2e3c2", "#f7d6b8", "#ff8a3d", "twin", True),
]


def hx(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) / 255 for i in (0, 2, 4))


def tohex(rgb):
    return "#" + "".join(f"{max(0, min(255, round(v * 255))):02x}" for v in rgb)


def shade(c, l=0.0, s=0.0, h=0.0):
    r, g, b = hx(c)
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    return tohex(colorsys.hls_to_rgb((hh + h) % 1, max(0, min(1, ll + l)), max(0, min(1, ss + s))))


class SVG:
    def __init__(self, w=256, h=256):
        self.w, self.h = w, h
        self.defs = []
        self.body = []
        self.n = 0

    def uid(self, p="c"):
        self.n += 1
        return f"{p}{self.n}"

    def add(self, s):
        self.body.append(s)

    def cel(self, d, base, line, sh=None, hi=None, off=(-9, -10), lw=6, hi_ellipse=None):
        """Forma com cel-shading: sombra embaixo/direita, luz em cima, contorno colorido."""
        if base == "SCARF":
            sh = "SCARFSH"
        sh = sh or shade(base, -0.13, 0.05, -0.015)
        cid = self.uid()
        self.defs.append(f'<clipPath id="{cid}"><path d="{d}"/></clipPath>')
        self.add(f'<path d="{d}" fill="{sh}"/>')
        self.add(f'<g clip-path="url(#{cid})"><path d="{d}" fill="{base}" transform="translate({off[0]},{off[1]})"/>')
        if hi_ellipse:
            x, y, rx, ry = hi_ellipse
            self.add(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{hi or shade(base, 0.12)}" opacity="0.9"/>')
        self.add("</g>")
        self.add(f'<path d="{d}" fill="none" stroke="{line}" stroke-width="{lw}" stroke-linejoin="round" stroke-linecap="round"/>')

    def svg(self):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}">'
                f'<defs>{"".join(self.defs)}</defs>{"".join(self.body)}</svg>')


def blob(cx, cy, w, h, top=1.35, bot=0.95):
    return (f"M{cx - w},{cy} C{cx - w},{cy - h * top} {cx + w},{cy - h * top} {cx + w},{cy} "
            f"C{cx + w},{cy + h * bot} {cx - w},{cy + h * bot} {cx - w},{cy} Z")


def ell(cx, cy, rx, ry):
    return f"M{cx - rx},{cy} A{rx},{ry} 0 1 0 {cx + rx},{cy} A{rx},{ry} 0 1 0 {cx - rx},{cy} Z"


def star(cx, cy, r1, r2, n=4, rot=0):
    import math
    pts = []
    for i in range(n * 2):
        a = math.pi * i / n + rot
        r = r1 if i % 2 == 0 else r2
        pts.append(f"{cx + r * math.sin(a):.1f},{cy - r * math.cos(a):.1f}")
    return "M" + " L".join(pts) + " Z"


# ------------------------------------------------------------------ rosto
def eyes(s, hx_, hy, size, iris, line, evil=False, look=6):
    ex = [hx_ - size * 1.25 + look, hx_ + size * 1.25 + look]
    rx, ry = size * 0.82, size * 1.08
    for i, x in enumerate(ex):
        gid = s.uid("g")
        if PIXEL:
            rx2, ry2 = rx * 1.3, ry * 1.25
            if evil:
                slant = -1 if i == 0 else 1
                d = (f"M{x - rx2},{hy - ry2 * 0.1 + slant * ry2 * 0.45} L{x + rx2},{hy - ry2 * 0.1 - slant * ry2 * 0.45} "
                     f"L{x + rx2 * 0.8},{hy + ry2 * 0.75} Q{x},{hy + ry2 * 1.1} {x - rx2 * 0.8},{hy + ry2 * 0.75} Z")
                s.add(f'<path d="{d}" fill="#d81838"/>')
                s.add(f'<ellipse cx="{x}" cy="{hy + ry2 * 0.3}" rx="{rx2 * 0.32}" ry="{ry2 * 0.45}" fill="#200810"/>')
                s.add(f'<path d="{d}" fill="none" stroke="#200810" stroke-width="5"/>')
            else:
                s.add(f'<ellipse cx="{x}" cy="{hy}" rx="{rx2}" ry="{ry2}" fill="#181428"/>')
                s.add(f'<ellipse cx="{x}" cy="{hy + ry2 * 0.45}" rx="{rx2 * 0.7}" ry="{ry2 * 0.42}" fill="{shade(iris, 0.05, 0.1)}"/>')
                s.add(f'<ellipse cx="{x - rx2 * 0.28}" cy="{hy - ry2 * 0.38}" rx="{rx2 * 0.38}" ry="{ry2 * 0.32}" fill="#ffffff"/>')
                s.add(f'<circle cx="{x + rx2 * 0.35}" cy="{hy + ry2 * 0.3}" r="{rx2 * 0.18}" fill="#ffffff"/>')
            continue
        if evil:
            s.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a0010"/>'
                          f'<stop offset="1" stop-color="#ff2a4a"/></linearGradient>')
            # olho afiado: elipse cortada na diagonal
            slant = -1 if i == 0 else 1
            cid = s.uid()
            cut = (f"M{x - rx * 1.4},{hy - ry * 0.15 + slant * ry * 0.35} L{x + rx * 1.4},{hy - ry * 0.15 - slant * ry * 0.35} "
                   f"L{x + rx * 1.4},{hy + ry * 2} L{x - rx * 1.4},{hy + ry * 2} Z")
            s.defs.append(f'<clipPath id="{cid}"><path d="{cut}"/></clipPath>')
            s.add(f'<g clip-path="url(#{cid})"><ellipse cx="{x}" cy="{hy}" rx="{rx}" ry="{ry}" fill="url(#{gid})" stroke="{line}" stroke-width="4"/>'
                  f'<ellipse cx="{x + 1}" cy="{hy + ry * 0.2}" rx="{rx * 0.22}" ry="{ry * 0.5}" fill="#1a0006"/></g>')
            s.add(f'<path d="M{x - rx * 1.2},{hy - ry * 0.15 + slant * ry * 0.35} L{x + rx * 1.2},{hy - ry * 0.15 - slant * ry * 0.35}" '
                  f'stroke="{line}" stroke-width="5" stroke-linecap="round"/>')
            s.add(f'<circle cx="{x - rx * 0.3}" cy="{hy + ry * 0.25}" r="{size * 0.16}" fill="#fff" opacity="0.9"/>')
        else:
            s.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#140c24"/>'
                          f'<stop offset="0.55" stop-color="{shade(iris, -0.15)}"/><stop offset="1" stop-color="{shade(iris, 0.18, 0.1)}"/></linearGradient>')
            s.add(f'<ellipse cx="{x}" cy="{hy}" rx="{rx}" ry="{ry}" fill="url(#{gid})" stroke="#140c24" stroke-width="3.5"/>')
            s.add(f'<ellipse cx="{x}" cy="{hy + ry * 0.12}" rx="{rx * 0.42}" ry="{ry * 0.48}" fill="#0a0614" opacity="0.85"/>')
            # brilhos típicos de anime
            s.add(f'<ellipse cx="{x - rx * 0.32}" cy="{hy - ry * 0.38}" rx="{rx * 0.38}" ry="{ry * 0.3}" fill="#fff" transform="rotate(-20 {x - rx * 0.32} {hy - ry * 0.38})"/>')
            s.add(f'<circle cx="{x + rx * 0.35}" cy="{hy + ry * 0.4}" r="{size * 0.15}" fill="#fff"/>')
            s.add(f'<path d="M{x - rx * 0.5},{hy + ry * 0.62} Q{x},{hy + ry * 0.85} {x + rx * 0.5},{hy + ry * 0.62}" stroke="{shade(iris, 0.3, 0.2)}" stroke-width="2.5" fill="none" opacity="0.8"/>')
            # cílio superior grosso
            s.add(f'<path d="M{x - rx * 1.05},{hy - ry * 0.35} Q{x},{hy - ry * 1.35} {x + rx * 1.05},{hy - ry * 0.35}" stroke="#140c24" stroke-width="{max(3.5, size * 0.28)}" fill="none" stroke-linecap="round"/>')
    return ex


def blush(s, ex, hy, size):
    for x in ex:
        bx = x + (size * 0.9 if x == ex[1] else -size * 0.9)
        s.add(f'<ellipse cx="{bx}" cy="{hy + size * 1.25}" rx="{size * 0.7}" ry="{size * 0.32}" fill="#ff7aa8" opacity="0.55"/>')
        if PIXEL:
            continue
        for k in range(3):
            lx = bx - size * 0.35 + k * size * 0.35
            s.add(f'<path d="M{lx},{hy + size * 1.15} l{-size * 0.15},{size * 0.25}" stroke="#ff4f8a" stroke-width="2" stroke-linecap="round" opacity="0.7"/>')


def mouth(s, mx, my, size, kind, line):
    if kind == "w":
        s.add(f'<path d="M{mx - size * 0.6},{my} q{size * 0.3},{size * 0.45} {size * 0.6},0 q{size * 0.3},{size * 0.45} {size * 0.6},0" '
              f'stroke="{line}" stroke-width="3.5" fill="none" stroke-linecap="round"/>')
    elif kind == "open":
        s.add(f'<path d="M{mx - size * 0.65},{my - 2} Q{mx},{my + size * 1.1} {mx + size * 0.65},{my - 2} Z" fill="#7a1530" stroke="{line}" stroke-width="3.5" stroke-linejoin="round"/>')
        s.add(f'<path d="M{mx - size * 0.3},{my + size * 0.42} Q{mx},{my + size * 0.15} {mx + size * 0.3},{my + size * 0.42} Q{mx},{my + size * 0.7} {mx - size * 0.3},{my + size * 0.42} Z" fill="#ff7a95"/>')
        s.add(f'<path d="M{mx + size * 0.15},{my - 1} l{size * 0.12},{size * 0.3} l{size * 0.12},{-size * 0.3} Z" fill="#fff"/>')
    else:  # sorriso maldoso com presas
        s.add(f'<path d="M{mx - size * 0.8},{my - size * 0.15} Q{mx},{my + size * 0.75} {mx + size * 0.8},{my - size * 0.15}" stroke="{line}" stroke-width="4" fill="#5a0a20" stroke-linejoin="round"/>')
        for fx in (mx - size * 0.45, mx + size * 0.3):
            s.add(f'<path d="M{fx},{my + size * 0.05} l{size * 0.12},{size * 0.38} l{size * 0.12},{-size * 0.34} Z" fill="#fff" stroke="{line}" stroke-width="1.5"/>')


# ------------------------------------------------------------------ partes por elemento
def crest(s, el, cx, top, stage, c, line, path):
    acc = c["accent"]
    big = 1 + stage * 0.35
    if el == "fogo":
        d = (f"M{cx - 22 * big},{top + 8} C{cx - 30 * big},{top - 20 * big} {cx - 8 * big},{top - 30 * big} {cx - 6 * big},{top - 48 * big} "
             f"C{cx + 4 * big},{top - 30 * big} {cx + 10 * big},{top - 38 * big} {cx + 12 * big},{top - 56 * big} "
             f"C{cx + 30 * big},{top - 34 * big} {cx + 34 * big},{top - 12 * big} {cx + 22 * big},{top + 8} Z")
        col = "#ff5a2a" if path != "sombra" else "#8a1fd0"
        s.cel(d, col, line, sh=shade(col, -0.12), off=(-6, -8))
        inner = (f"M{cx - 10 * big},{top + 6} C{cx - 12 * big},{top - 12 * big} {cx + 2 * big},{top - 18 * big} {cx + 6 * big},{top - 32 * big} "
                 f"C{cx + 16 * big},{top - 14 * big} {cx + 14 * big},{top} {cx + 10 * big},{top + 6} Z")
        s.add(f'<path d="{inner}" fill="{acc if path != "sombra" else "#e08aff"}"/>')
    elif el == "agua":
        d = (f"M{cx - 14 * big},{top + 10} C{cx - 10 * big},{top - 26 * big} {cx + 18 * big},{top - 40 * big} {cx + 34 * big},{top - 38 * big} "
             f"C{cx + 24 * big},{top - 22 * big} {cx + 22 * big},{top - 4} {cx + 18 * big},{top + 10} Z")
        s.cel(d, acc if path != "sombra" else "#3a4e9e", line, off=(-5, -6))
        s.add(f'<path d="M{cx},{top} C{cx + 6 * big},{top - 16 * big} {cx + 16 * big},{top - 26 * big} {cx + 26 * big},{top - 32 * big}" stroke="{c["main"]}" stroke-width="3" fill="none" opacity="0.7"/>')
    elif el == "planta":
        s.add(f'<path d="M{cx},{top + 8} Q{cx - 2},{top - 14 * big} {cx + 4},{top - 24 * big}" stroke="#2e7d32" stroke-width="6" fill="none" stroke-linecap="round"/>')
        lc = acc if path != "sombra" else "#4a6b2a"
        for sign in (-1, 1):
            tipx = cx + 4 + sign * 34 * big
            tipy = top - 30 * big - (8 if sign > 0 else 0)
            d = (f"M{cx + 4},{top - 22 * big} C{cx + 4 + sign * 8 * big},{top - 46 * big} {tipx},{tipy - 14} {tipx},{tipy} "
                 f"C{tipx - sign * 10 * big},{top - 14 * big} {cx + 4 + sign * 10},{top - 12 * big} {cx + 4},{top - 22 * big} Z")
            s.cel(d, lc, line, off=(-4, -5), lw=5)
        if stage >= 2 and path == "luz":
            fx, fy = cx + 4, top - 26 * big
            for k in range(5):
                import math
                a = k * 2 * math.pi / 5
                s.add(f'<ellipse cx="{fx + 11 * math.sin(a):.1f}" cy="{fy - 11 * math.cos(a):.1f}" rx="8" ry="8" fill="#ff9ad0" stroke="{line}" stroke-width="3"/>')
            s.add(f'<circle cx="{fx}" cy="{fy}" r="7" fill="#ffe14a" stroke="{line}" stroke-width="3"/>')
    elif el == "raio":
        for sign in (-1, 1):
            bx = cx + sign * 24
            d = (f"M{bx - 7},{top + 10} L{bx + sign * 10 - 6},{top - 18 * big} L{bx + sign * 2},{top - 16 * big} "
                 f"L{bx + sign * 18},{top - 46 * big} L{bx + sign * 6 + 6},{top - 22 * big} L{bx + sign * 14},{top - 24 * big} L{bx + 9},{top + 10} Z")
            col = acc if path != "sombra" else "#6a6a8a"
            s.cel(d, col, line, sh=shade(c["main"], 0.05), off=(-5, -6), lw=5)
            s.add(f'<path d="{d}" fill="none" stroke="{c["main"]}" stroke-width="2" opacity="0.5"/>')


def tail(s, el, x, y, stage, c, line, path):
    k = 1 + stage * 0.3
    if el == "fogo":
        d = f"M{x},{y} C{x - 30 * k},{y + 6} {x - 44 * k},{y - 20 * k} {x - 38 * k},{y - 40 * k} C{x - 26 * k},{y - 26 * k} {x - 16 * k},{y - 12} {x + 6},{y - 16} Z"
        s.cel(d, c["main"] if path != "sombra" else shade(c["main"], -0.2), line, off=(-4, -4), lw=5)
        fl = f"M{x - 38 * k},{y - 40 * k} c-12,-10 -4,-30 8,-34 c-2,12 12,16 6,30 Z"
        s.cel(fl, c["accent"] if path != "sombra" else "#c070ff", line, off=(-3, -3), lw=4)
    elif el == "agua":
        d = f"M{x},{y} C{x - 26 * k},{y + 4} {x - 36 * k},{y - 8} {x - 46 * k},{y - 22 * k} L{x - 52 * k},{y + 8 * k} C{x - 36 * k},{y + 14 * k} {x - 20},{y + 16} {x + 4},{y + 10} Z"
        s.cel(d, c["main"] if path != "sombra" else shade(c["main"], -0.2), line, off=(-4, -4), lw=5)
    elif el == "planta":
        d = f"M{x},{y} C{x - 20 * k},{y - 2} {x - 34 * k},{y - 16 * k} {x - 52 * k},{y - 10 * k} C{x - 40 * k},{y + 8 * k} {x - 18},{y + 14} {x + 4},{y + 8} Z"
        s.cel(d, c["accent"] if path != "sombra" else "#5a7a30", line, off=(-4, -4), lw=5)
    else:
        d = (f"M{x},{y} L{x - 18 * k},{y - 10 * k} L{x - 12 * k},{y - 16 * k} L{x - 40 * k},{y - 36 * k} L{x - 22 * k},{y - 10 * k} "
             f"L{x - 28 * k},{y - 6 * k} L{x + 2},{y + 10} Z")
        s.cel(d, c["main"] if path != "sombra" else "#5a5a7a", line, off=(-4, -4), lw=5)


def wings(s, cx, cy, size, light, line):
    col = "#ffffff" if light else "#3a1a4a"
    for sign, op in ((-1, 1.0),):
        x0 = cx + sign * 10
        d = (f"M{x0},{cy} C{x0 + sign * size * 0.5},{cy - size * 1.1} {x0 + sign * size * 1.3},{cy - size * 1.2} {x0 + sign * size * 1.5},{cy - size * 0.8} "
             f"C{x0 + sign * size * 1.2},{cy - size * 0.6} {x0 + sign * size * 1.35},{cy - size * 0.35} {x0 + sign * size * 1.1},{cy - size * 0.2} "
             f"C{x0 + sign * size * 0.9},{cy - size * 0.05} {x0 + sign * size * 0.95},{cy + size * 0.2} {x0 + sign * size * 0.6},{cy + size * 0.2} Z")
        s.cel(d, col, line, sh=shade(col, -0.12) if light else "#24102e", off=(6, -8), lw=5)
        if light:
            for k in range(3):
                s.add(f'<path d="M{x0 + sign * size * (0.4 + k * 0.28)},{cy - size * (0.15 + k * 0.1)} q{sign * 8},{-size * 0.3} {sign * size * 0.25},{-size * 0.5}" stroke="#c8d8ff" stroke-width="3" fill="none" stroke-linecap="round"/>')


def horns(s, hx_, top, line, big=1.0):
    for sign in (-1, 1):
        bx = hx_ + sign * 30 * big
        d = f"M{bx - 9},{top + 16} C{bx - 4 + sign * 6},{top - 6} {bx + sign * 22},{top - 26 * big} {bx + sign * 30},{top - 32 * big} C{bx + sign * 14},{top - 8} {bx + 10},{top + 2} {bx + 9},{top + 16} Z"
        s.cel(d, "#4a2a5a", line, sh="#2a1238", off=(-3, -4), lw=4)


# ------------------------------------------------------------------ monstro
def monster(species, form):
    # canvas 300x256 para caber asas e cauda
    el = SPECIES[species]
    c = ELEM[el]
    stage = {"baby": 0, "rookie": 1}.get(form, 2 if form.startswith("champ") else 3)
    path = "luz" if form.endswith("luz") else ("sombra" if form.endswith("sombra") else "")
    main = c["main"] if path != "sombra" else shade(c["main"], -0.2, -0.15)
    line = shade(main, -0.38, 0.05) if path != "sombra" else "#1c0820"
    s = SVG(300, 300)
    cx = 150
    ground = 288

    # aura da Digialma
    if stage == 3 and not PIXEL:
        gid = s.uid("r")
        aura = c["accent"] if path == "luz" else "#b03aff"
        s.defs.append(f'<radialGradient id="{gid}"><stop offset="0" stop-color="{aura}" stop-opacity="0.55"/>'
                      f'<stop offset="1" stop-color="{aura}" stop-opacity="0"/></radialGradient>')
        s.add(f'<circle cx="{cx}" cy="184" r="118" fill="url(#{gid})"/>')

    if stage == 0:
        hx_, hy, hw, hh = cx, ground - 66, 68, 58
        tail(s, el, cx - 56, ground - 30, 0, c, line, path)
        d = blob(hx_, hy + 8, hw, hh, 1.45, 1.0)
        s.cel(d, main, line, off=(-11, -12), hi_ellipse=(hx_ - 30, hy - 40, 16, 9))
        top = hy + 8 - hh * 1.08
        crest(s, el, hx_, top + 6, 0, c, line, path)
        s.add(f'<path d="M{hx_ - 30},{ground - 4} q30,10 60,0" stroke="{shade(main, -0.25)}" stroke-width="4" fill="none" opacity="0.35"/>')
        ex = eyes(s, hx_, hy, 15, c["iris"], line)
        blush(s, ex, hy, 13)
        mouth(s, hx_ + 6, hy + 22, 11, "w", line)
        return s.svg()

    # tamanhos por estágio
    head_w, head_h = {1: (58, 52), 2: (62, 54), 3: (64, 56)}[stage]
    body_rx, body_ry = {1: (40, 36), 2: (46, 46), 3: (48, 48)}[stage]
    body_cy = ground - body_ry - 12
    hy = body_cy - body_ry - head_h * 0.45 + 18
    hx_ = cx + 6

    if stage >= 2 and path == "luz":
        wings(s, cx - 10, body_cy - 20, 64 if stage == 2 else 78, True, line)
    if stage >= 2 and path == "sombra":
        wings(s, cx - 10, body_cy - 20, 56 if stage == 2 else 72, False, line)
    tail(s, el, cx - body_rx + 8, body_cy + 20, stage, c, line, path)

    # pés
    for fx in (cx - body_rx * 0.5, cx + body_rx * 0.45):
        s.cel(ell(fx, ground - 10, 18 + stage * 2, 11), shade(main, -0.08), line, off=(-4, -4), lw=5)
        if stage >= 2:
            for k in (-7, 0, 7):
                s.add(f'<path d="M{fx + k + 6},{ground - 2} l4,4" stroke="{line}" stroke-width="3" stroke-linecap="round"/>')
    # corpo
    s.cel(blob(cx, body_cy + 8, body_rx, body_ry * 0.95, 1.25, 1.0), main, line, off=(-10, -8))
    s.cel(ell(cx + 6, body_cy + 14, body_rx * 0.58, body_ry * 0.62), c["belly"] if path != "sombra" else shade(c["belly"], -0.45, -0.3), line, off=(-5, -5), lw=4)
    if stage == 3:
        gem = "#7af0ff" if path == "luz" else "#ff2a6a"
        s.cel(star(cx + 6, body_cy + 10, 13, 6, 4), gem, line, off=(-3, -3), lw=3)
    # braços
    for sign in (-1, 1):
        ax = cx + sign * (body_rx - 4)
        d = ell(ax + sign * 4, body_cy - 2, 11 + stage * 2, 16 + stage * 2)
        s.cel(d, main, line, off=(-4, -4), lw=5)
        if stage >= 2:
            for k in (-6, 0, 6):
                s.add(f'<path d="M{ax + sign * 4 + k},{body_cy + 14 + stage * 2} l{sign * 2},6" stroke="{line}" stroke-width="3" stroke-linecap="round"/>')
    # lenço da criança (Digialma)
    if stage == 3:
        sc = "#e8484f"
        s.cel(f"M{cx - body_rx * 0.8},{body_cy - body_ry * 0.62} Q{cx + 6},{body_cy - body_ry * 0.25} {cx + body_rx * 0.85},{body_cy - body_ry * 0.65} "
              f"L{cx + body_rx * 0.8},{body_cy - body_ry * 0.42} Q{cx + 6},{body_cy - body_ry * 0.02} {cx - body_rx * 0.78},{body_cy - body_ry * 0.4} Z",
              "SCARF", line, off=(-3, -4), lw=4)
        s.cel(f"M{cx - body_rx * 0.6},{body_cy - body_ry * 0.5} l-30,22 l10,8 l-6,16 l34,-30 Z", "SCARF", line, off=(-3, -3), lw=4)

    # cabeça
    if stage >= 2 and path == "sombra":
        horns(s, hx_, hy - head_h * 1.02, line, 1 + (stage - 2) * 0.25)
    if stage >= 1 and path != "sombra":
        for sign in (-1, 1):
            exx = hx_ + sign * head_w * 0.72
            d = f"M{exx - 14},{hy - head_h * 0.6} L{exx + sign * 16},{hy - head_h * 1.45} L{exx + 14},{hy - head_h * 0.55} Z"
            s.cel(d, main, line, off=(-4, -4), lw=5)
            s.add(f'<path d="M{exx - 6},{hy - head_h * 0.68} L{exx + sign * 10},{hy - head_h * 1.22} L{exx + 6},{hy - head_h * 0.66} Z" fill="#ffb3c8" opacity="0.8"/>')
    s.cel(blob(hx_, hy + 6, head_w, head_h, 1.3, 1.0), main, line, off=(-10, -11), hi_ellipse=(hx_ - 26, hy - 34, 14, 8))
    top = hy + 6 - head_h * 1.05
    crest(s, el, hx_, top + 8, stage, c, line, path)
    evil = path == "sombra"
    esize = {1: 13.5, 2: 14, 3: 14.5}[stage]
    ex = eyes(s, hx_, hy - 2, esize, c["iris"], line, evil=evil)
    if evil:
        mouth(s, hx_ + 8, hy + 22, 11, "evil", line)
    else:
        blush(s, ex, hy - 2, esize * 0.9)
        mouth(s, hx_ + 7, hy + 20, 10, "open" if stage >= 1 else "w", line)
    # coroa / auréola
    if stage == 3:
        if path == "luz":
            s.add(f'<ellipse cx="{hx_}" cy="{top - 26}" rx="38" ry="10" fill="none" stroke="#b88a10" stroke-width="{14 if PIXEL else 7}"/>')
            s.add(f'<ellipse cx="{hx_}" cy="{top - 26}" rx="38" ry="10" fill="none" stroke="#ffe14a" stroke-width="{8 if PIXEL else 3}"/>')
        else:
            d = f"M{hx_ - 30},{top - 4} L{hx_ - 34},{top - 34} L{hx_ - 16},{top - 18} L{hx_},{top - 42} L{hx_ + 16},{top - 18} L{hx_ + 34},{top - 34} L{hx_ + 30},{top - 4} Z"
            s.cel(d, "#ffcf3a", "#3a1a00", off=(-3, -4), lw=4)
            s.add(f'<circle cx="{hx_}" cy="{top - 18}" r="5" fill="#ff2a6a"/>')
        for (sx, sy, r) in ([] if PIXEL else [(cx - 92, 114, 9), (cx + 88, 96, 7), (cx + 96, 194, 6), (cx - 80, 214, 5)]):
            s.add(f'<path d="{star(sx, sy, r, r * 0.3)}" fill="#fff8c0"/>')
    return s.svg()


# ------------------------------------------------------------------ criança
def tamer(i):
    name, hair, skin, shirt, style, goggles = TAMERS[i]
    line = "#2a1a2e"
    s = SVG(160, 220)
    cx, hy = 80, 84
    hl = shade(hair, -0.2)
    # cabelo de trás
    if style == "twin":
        for sign in (-1, 1):
            s.cel(f"M{cx + sign * 40},{hy - 10} C{cx + sign * 70},{hy} {cx + sign * 72},{hy + 50} {cx + sign * 58},{hy + 70} C{cx + sign * 50},{hy + 40} {cx + sign * 44},{hy + 20} {cx + sign * 36},{hy + 10} Z", hair, line, off=(-3, -3), lw=4)
    if style == "pony":
        s.cel(f"M{cx - 36},{hy - 30} C{cx - 80},{hy - 20} {cx - 74},{hy + 40} {cx - 56},{hy + 64} C{cx - 50},{hy + 30} {cx - 44},{hy} {cx - 30},{hy - 10} Z", hair, line, off=(-3, -3), lw=4)
    if style == "bob":
        s.cel(f"M{cx - 50},{hy - 10} C{cx - 56},{hy + 40} {cx - 48},{hy + 52} {cx - 30},{hy + 50} L{cx + 30},{hy + 50} C{cx + 48},{hy + 52} {cx + 56},{hy + 40} {cx + 50},{hy - 10} Z", hair, line, off=(-3, -3), lw=4)
    # corpo
    s.cel(f"M{cx - 26},{hy + 50} C{cx - 30},{hy + 90} {cx - 30},{hy + 100} {cx - 26},{hy + 106} L{cx + 26},{hy + 106} C{cx + 30},{hy + 100} {cx + 30},{hy + 90} {cx + 26},{hy + 50} Z", shirt, line, off=(-5, -5), lw=4)
    s.add(f'<path d="M{cx - 10},{hy + 52} L{cx},{hy + 64} L{cx + 10},{hy + 52}" fill="#fff" stroke="{line}" stroke-width="3" stroke-linejoin="round"/>')
    for sign in (-1, 1):
        s.cel(ell(cx + sign * 32, hy + 78, 8, 18), shirt, line, off=(-2, -2), lw=4)
        s.cel(ell(cx + sign * 34, hy + 98, 7, 7), skin, line, off=(-2, -2), lw=3)
    s.cel(f"M{cx - 25},{hy + 104} L{cx + 25},{hy + 104} L{cx + 24},{hy + 118} L{cx - 24},{hy + 118} Z", "#2d3a6a", line, off=(-2, -2), lw=4)
    for sign in (-1, 1):
        s.add(f'<rect x="{cx + sign * 13 - 7}" y="{hy + 116}" width="14" height="14" fill="{skin}" stroke="{line}" stroke-width="3"/>')
        s.cel(ell(cx + sign * 14 + 3, hy + 132, 13, 7), "#f4f4f8", line, off=(-2, -2), lw=4)
    # cabeça
    s.cel(blob(cx, hy + 6, 44, 42, 1.25, 1.05), skin, line, off=(-6, -6))
    # franja / cabelo
    if style == "spiky":
        d = (f"M{cx - 50},{hy + 4} L{cx - 62},{hy - 26} L{cx - 40},{hy - 30} L{cx - 50},{hy - 56} L{cx - 18},{hy - 50} L{cx - 10},{hy - 80} "
             f"L{cx + 14},{hy - 54} L{cx + 40},{hy - 70} L{cx + 38},{hy - 42} L{cx + 64},{hy - 36} L{cx + 50},{hy - 12} L{cx + 54},{hy + 6} "
             f"L{cx + 34},{hy - 8} L{cx + 26},{hy - 22} L{cx + 12},{hy - 6} L{cx},{hy - 24} L{cx - 14},{hy - 6} L{cx - 26},{hy - 22} L{cx - 36},{hy - 4} Z")
    else:
        d = (f"M{cx - 48},{hy + 10} C{cx - 56},{hy - 50} {cx + 56},{hy - 50} {cx + 48},{hy + 10} "
             f"L{cx + 36},{hy - 8} L{cx + 24},{hy + 2} L{cx + 14},{hy - 14} L{cx},{hy} L{cx - 14},{hy - 14} L{cx - 26},{hy + 2} L{cx - 36},{hy - 8} Z")
    s.cel(d, hair, line, sh=hl, off=(-6, -6), lw=4, hi_ellipse=(cx - 16, hy - 32, 14, 5))
    if style == "twin":
        for sign in (-1, 1):
            s.add(f'<circle cx="{cx + sign * 40}" cy="{hy - 14}" r="6" fill="#ff5a8a" stroke="{line}" stroke-width="3"/>')
    if goggles:
        s.add(f'<path d="M{cx - 44},{hy - 26} Q{cx},{hy - 44} {cx + 44},{hy - 26}" stroke="#4a3a2a" stroke-width="6" fill="none"/>')
        for gx in (cx - 18, cx + 18):
            s.add(f'<circle cx="{gx}" cy="{hy - 34}" r="12" fill="#6ad4ff" stroke="{line}" stroke-width="4"/>')
            s.add(f'<circle cx="{gx - 4}" cy="{hy - 38}" r="4" fill="#fff"/>')
    ex = eyes(s, cx, hy + 10, 9.5, "#5a3aa0" if i % 2 else "#2a6ad0", line, look=4)
    blush(s, ex, hy + 10, 8)
    mouth(s, cx + 4, hy + 30, 7, "open", line)
    return s.svg()


# ------------------------------------------------------------------ inimigo glitch
def glitch(el, boss):
    c = ELEM[el]
    W = 256 if boss else 200
    s = SVG(W, W)
    cx, cy = W * 0.5, W * 0.6
    r = W * 0.34
    base = "#3a2a5e"
    line = "#120a22"
    glow = c["main"]
    gid = s.uid("r")
    s.defs.append(f'<radialGradient id="{gid}"><stop offset="0" stop-color="{glow}" stop-opacity="0.45"/><stop offset="1" stop-color="{glow}" stop-opacity="0"/></radialGradient>')
    s.add(f'<circle cx="{cx}" cy="{cy}" r="{r * 1.35}" fill="url(#{gid})"/>')
    # corpo de fantasminha com base serrilhada
    d = (f"M{cx - r},{cy + r * 0.6} C{cx - r * 1.05},{cy - r * 1.3} {cx + r * 1.05},{cy - r * 1.3} {cx + r},{cy + r * 0.6} "
         f"L{cx + r * 0.66},{cy + r * 0.38} L{cx + r * 0.33},{cy + r * 0.7} L{cx},{cy + r * 0.4} L{cx - r * 0.33},{cy + r * 0.7} L{cx - r * 0.66},{cy + r * 0.38} Z")
    if boss:
        horns(s, cx, cy - r * 0.95, line, 1.4)
    s.cel(d, base, line, sh="#22183e", off=(8, -10), lw=6, hi_ellipse=(cx + r * 0.3, cy - r * 0.7, r * 0.25, r * 0.12))
    # quadradinhos de glitch
    import random
    rnd = random.Random(hash((el, boss)) & 0xffff)
    for _ in range(9 if boss else 6):
        x = rnd.uniform(cx - r * 1.2, cx + r * 1.1)
        y = rnd.uniform(cy - r * 1.1, cy + r * 0.6)
        sz = rnd.uniform(6, 14) * (W / 200)
        col = rnd.choice([glow, "#ff4fd8", "#4ffff0"])
        s.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{sz:.1f}" height="{sz * 0.6:.1f}" fill="{col}" opacity="0.85"/>')
    # olho único olhando para a esquerda
    ex, ey, er = cx - r * 0.2, cy - r * 0.25, r * 0.36
    s.add(f'<ellipse cx="{ex}" cy="{ey}" rx="{er}" ry="{er * 1.05}" fill="#fff" stroke="{line}" stroke-width="5"/>')
    s.add(f'<ellipse cx="{ex - er * 0.3}" cy="{ey + er * 0.05}" rx="{er * 0.55}" ry="{er * 0.62}" fill="{glow}" stroke="{line}" stroke-width="3"/>')
    s.add(f'<ellipse cx="{ex - er * 0.38}" cy="{ey + er * 0.08}" rx="{er * 0.18}" ry="{er * 0.42}" fill="#120a22"/>')
    s.add(f'<circle cx="{ex - er * 0.55}" cy="{ey - er * 0.25}" r="{er * 0.16}" fill="#fff"/>')
    # boca serrilhada
    mx, my = cx - r * 0.25, cy + r * 0.25
    s.add(f'<path d="M{mx - r * 0.35},{my} L{mx - r * 0.2},{my + r * 0.14} L{mx - r * 0.05},{my} L{mx + r * 0.1},{my + r * 0.14} L{mx + r * 0.25},{my}" '
          f'stroke="#ff4f8a" stroke-width="4" fill="none" stroke-linejoin="round"/>')
    if boss:
        d = f"M{cx - 34},{cy - r * 1.02} L{cx - 40},{cy - r * 1.42} L{cx - 18},{cy - r * 1.2} L{cx},{cy - r * 1.55} L{cx + 18},{cy - r * 1.2} L{cx + 40},{cy - r * 1.42} L{cx + 34},{cy - r * 1.02} Z"
        s.cel(d, "#ff3a6a", line, off=(-3, -4), lw=4)
    return s.svg()


def egg():
    s = SVG(120, 140)
    d = "M60,8 C20,8 8,80 12,100 C16,128 104,128 108,100 C112,80 100,8 60,8 Z"
    s.cel(d, "#fff6e6", "#5a3a6e", sh="#e8d8f0", off=(-8, -8), hi_ellipse=(42, 36, 10, 16))
    for (x, y, r, col) in ((40, 70, 12, "#b38cff"), (78, 52, 9, "#ff9ad0"), (70, 100, 13, "#7ad8ff"), (32, 104, 7, "#ffd84a")):
        s.add(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{col}" stroke="#5a3a6e" stroke-width="3"/>')
    return s.svg()


def poop():
    s = SVG(80, 70)
    line = "#3a2010"
    for (cy, rx, ry) in ((52, 32, 13), (36, 24, 11), (22, 15, 9)):
        s.cel(ell(40, cy, rx, ry), "#9a6a40", line, off=(-4, -4), lw=4)
    s.add('<path d="M40,14 q6,-12 0,-10" stroke="#3a2010" stroke-width="4" fill="#9a6a40"/>')
    s.add('<ellipse cx="32" cy="36" rx="3" ry="4" fill="#120a10"/><ellipse cx="46" cy="36" rx="3" ry="4" fill="#120a10"/>')
    s.add('<path d="M35,44 q4,4 8,0" stroke="#120a10" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
    return s.svg()


def render(name, svg, scale=1.0):
    p = os.path.join(OUT, name)
    with open(p + ".svg", "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", "-z", str(scale), "-o", p + ".png", p + ".svg"], check=True)
    os.remove(p + ".svg")


if __name__ == "__main__":
    SCARVES = [t[3] for t in TAMERS]
    for sp in SPECIES:
        for fm in FORMS:
            svg = monster(sp, fm)
            if fm.startswith("alma"):
                for i, col in enumerate(SCARVES):
                    render(f"m_{sp}_{fm}_{i}", svg.replace("SCARFSH", shade(col, -0.15)).replace("SCARF", col))
            else:
                render(f"m_{sp}_{fm}", svg)
    for i in range(len(TAMERS)):
        render(f"t_{i}", tamer(i))
    for el in ELEM:
        render(f"g_{el}", glitch(el, False))
        render(f"g_{el}_boss", glitch(el, True))
    render("egg", egg())
    render("poop", poop())
    print("ok")
