"""Genera los assets de pixel art del combate final (vida, temporizador, resumen).

Usa solo colores de la paleta del juego y reutiliza siluetas ya aprobadas
(ui_energia_jugador.png y ui_icono_check.png). Ejecutar desde la raíz del proyecto:
    python tools/gen_combate_assets.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
UI = ROOT / "assets" / "art" / "ui"
FX = ROOT / "assets" / "art" / "effects"

DARK = (0x2A, 0x20, 0x2E, 255)
CREAM = (0xE6, 0xD8, 0xBB, 255)
SAND = (0xD8, 0xCB, 0xB3, 255)
GOLD = (0xE1, 0xB1, 0x5E, 255)
GOLD_L = (0xF0, 0xC0, 0x64, 255)
RED = (0xAF, 0x5F, 0x4B, 255)
RED_D = (0x6D, 0x34, 0x2F, 255)
CLEAR = (0, 0, 0, 0)


def gem_mask() -> Image.Image:
    return Image.open(UI / "ui_energia_jugador.png").convert("RGBA")


def edge_pixels(mask: Image.Image) -> set:
    w, h = mask.size
    edge = set()
    for y in range(h):
        for x in range(w):
            if mask.getpixel((x, y))[3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or mask.getpixel((nx, ny))[3] == 0:
                    edge.add((x, y))
                    break
    return edge


def energia_vacia() -> None:
    """Casilla vacía: la silueta de la gema, apagada."""
    src = gem_mask()
    out = Image.new("RGBA", src.size, CLEAR)
    edge = edge_pixels(src)
    for y in range(src.height):
        for x in range(src.width):
            if src.getpixel((x, y))[3] == 0:
                continue
            out.putpixel((x, y), DARK if (x, y) in edge else (0x2A, 0x20, 0x2E, 110))
    out.save(UI / "ui_energia_vacia.png")


def energia_rompe() -> None:
    """4 fotogramas: destello, fragmentos que se separan, se encogen y chispas."""
    src = gem_mask()
    w, h = src.size
    cx, cy = w / 2 - 0.5, h / 2 - 0.5
    sheet = Image.new("RGBA", (w * 4, h), CLEAR)
    pixels = [(x, y) for y in range(h) for x in range(w) if src.getpixel((x, y))[3] > 0]

    # 0: destello crema con una grieta oscura
    f0 = Image.new("RGBA", (w, h), CLEAR)
    for x, y in pixels:
        f0.putpixel((x, y), CREAM)
    for i in range(h // 3, h - h // 4):
        px = int(cx + (i - cy) * 0.35)
        if f0.getpixel((px, i))[3]:
            f0.putpixel((px, i), DARK)
    sheet.paste(f0, (0, 0))

    def pieces(shift: int, keep_every: int, color_a, color_b) -> Image.Image:
        f = Image.new("RGBA", (w, h), CLEAR)
        for x, y in pixels:
            if keep_every > 1 and (x + y) % keep_every:
                continue
            dx = shift if x >= cx else -shift
            dy = shift if y >= cy else -shift
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                f.putpixel((nx, ny), color_a if (x + y) % 2 == 0 else color_b)
        return f

    sheet.paste(pieces(2, 1, GOLD, CREAM), (w, 0))
    sheet.paste(pieces(4, 2, GOLD, CREAM), (w * 2, 0))
    f3 = Image.new("RGBA", (w, h), CLEAR)
    for i, (dx, dy) in enumerate([(-7, -6), (7, -5), (-6, 7), (8, 6), (0, -9), (1, 9)]):
        x, y = int(cx + dx), int(cy + dy)
        if 0 <= x < w and 0 <= y < h:
            f3.putpixel((x, y), GOLD_L if i % 2 else CREAM)
    sheet.paste(f3, (w * 3, 0))
    sheet.save(UI / "ui_energia_rompe_4f.png")


def temporizador_marco() -> None:
    """Marco 9-slice de la barra de tiempo (24x16, márgenes de 4 px)."""
    w, h = 24, 16
    im = Image.new("RGBA", (w, h), CLEAR)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], fill=DARK)
    d.rectangle([1, 1, w - 2, h - 2], outline=SAND)
    d.rectangle([2, 2, w - 3, h - 3], fill=(0x2A, 0x20, 0x2E, 235))
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        im.putpixel((x, y), CLEAR)
    im.save(UI / "ui_temporizador_marco_9slice.png")


def icono_reloj() -> None:
    """Reloj de 24x24: aro dorado, esfera crema y agujas."""
    s = 24
    im = Image.new("RGBA", (s, s), CLEAR)
    c = (s - 1) / 2
    for y in range(s):
        for x in range(s):
            r = math.hypot(x - c, y - c)
            if r <= 11.4:
                if r > 10.2:
                    im.putpixel((x, y), DARK)
                elif r > 8.2:
                    im.putpixel((x, y), GOLD)
                else:
                    im.putpixel((x, y), CREAM)
    d = ImageDraw.Draw(im)
    d.line([(12, 12), (12, 5)], fill=DARK)          # minutero
    d.line([(12, 12), (16, 14)], fill=DARK)         # horario
    d.line([(11, 12), (11, 5)], fill=DARK)
    for x, y in ((12, 3), (12, 20), (3, 12), (20, 12)):
        im.putpixel((x, y), DARK)
    im.putpixel((12, 12), RED_D)
    im.putpixel((11, 12), RED_D)
    im.save(UI / "ui_icono_reloj.png")


def icono_cruz() -> None:
    """Gemelo rojo de ui_icono_check.png."""
    src = Image.open(UI / "ui_icono_check.png").convert("RGBA")
    out = Image.new("RGBA", src.size, CLEAR)
    for y in range(src.height):
        for x in range(src.width):
            p = src.getpixel((x, y))
            if p[3] == 0:
                continue
            out.putpixel((x, y), DARK if p[:3] == DARK[:3] else RED)
    d = ImageDraw.Draw(out)
    for off in (0, 1):
        d.line([(10 + off, 10), (21 + off, 21)], fill=CREAM, width=1)
        d.line([(21 + off, 10), (10 + off, 21)], fill=CREAM, width=1)
    out.save(UI / "ui_icono_cruz.png")


def vineta_peligro() -> None:
    """Viñeta roja de bordes (160x90) para la tensión del último tramo."""
    w, h = 160, 90
    im = Image.new("RGBA", (w, h), CLEAR)
    levels = (0, 40, 85, 130, 175)
    for y in range(h):
        for x in range(w):
            nx = (x - w / 2) / (w / 2)
            ny = (y - h / 2) / (h / 2)
            d = max(abs(nx), abs(ny)) * 0.55 + math.hypot(nx, ny) * 0.45
            t = min(1.0, max(0.0, (d - 0.55) / 0.5))
            step = int(t * (len(levels) - 1) + 0.5)
            a = levels[step]
            if step == 1 and (x + y) % 2:   # tramado entre niveles, estilo pixel art
                a = 0
            if a:
                im.putpixel((x, y), (RED[0], RED[1], RED[2], a))
    im.save(FX / "fx_peligro_vineta.png")


if __name__ == "__main__":
    energia_vacia()
    energia_rompe()
    temporizador_marco()
    icono_reloj()
    icono_cruz()
    vineta_peligro()
    print("Assets de combate generados en", UI, "y", FX)
