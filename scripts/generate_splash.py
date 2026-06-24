"""
CASAIMO Splash Screen — 5s MP4 Animation
Format : 1080x1920 (9:16), 30 FPS
Output : C:/casaimo/assets/animations/splash.mp4
Dépendances : opencv-python (cv2) + Pillow + numpy — déjà installés
"""

import math
import os
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ── Paramètres ────────────────────────────────────────────────────────────────
W, H   = 1080, 1920
FPS    = 30
DURATION = 5.0
TOTAL  = int(FPS * DURATION)

OUTPUT    = r"C:\casaimo\assets\animations\splash.mp4"
LOGO_PATH = r"C:\casaimo\assets\images\logo1.png"

FONT_BOLD  = r"C:\Windows\Fonts\segoeuib.ttf"
FONT_LIGHT = r"C:\Windows\Fonts\segoeuil.ttf"

# Couleurs brand CASAIMO
BG_TOP      = (18,  66,  35)
BG_BOT      = (8,   20,  12)
GREEN_GLOW  = (34, 197,  94)   # #22C55E
WHITE       = (255, 255, 255)
GREY_LIGHT  = (180, 210, 190)


# ── Fonctions d'easing ────────────────────────────────────────────────────────
def clamp01(x):       return max(0.0, min(1.0, x))
def remap(t, a, b):   return clamp01((t - a) / (b - a)) if b != a else 0.0
def ease_out3(t):     return 1 - (1 - t) ** 3
def ease_in_out(t):   return t * t * (3 - 2 * t)
def elastic_out(t):
    if t <= 0: return 0.0
    if t >= 1: return 1.0
    c4 = (2 * math.pi) / 3
    return pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1


# ── Helpers de dessin ─────────────────────────────────────────────────────────
def make_bg():
    """Gradient vertical vert foncé → presque noir."""
    arr = np.zeros((H, W, 3), dtype=np.uint8)
    for y in range(H):
        t = y / H
        r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
        arr[y, :] = [r, g, b]
    return Image.fromarray(arr, "RGB")


def add_glow(img, cx, cy, radius, color, max_alpha):
    """Halo lumineux radial flou derrière le logo."""
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    steps = 12
    for i in range(steps, 0, -1):
        r = int(radius * i / steps)
        a = int(max_alpha * ((steps - i + 1) / steps) ** 2)
        d.ellipse([cx - r, cy - r, cx + r, cy + r],
                  fill=(*color, a))
    blurred = glow.filter(ImageFilter.GaussianBlur(radius=22))
    base = img.convert("RGBA")
    return Image.alpha_composite(base, blurred).convert("RGB")


def paste_logo(img, logo_rgba, cx, cy, size, alpha):
    if size < 2 or alpha <= 0:
        return img
    logo = logo_rgba.resize((size, size), Image.LANCZOS)
    r, g, b, a = logo.split()
    a = a.point(lambda v: int(v * alpha))
    logo.putalpha(a)
    base = img.convert("RGBA")
    base.paste(logo, (cx - size // 2, cy - size // 2), logo)
    return base.convert("RGB")


def text_layer(img, text, font_path, size, color, cy, alpha, dy=0):
    """Texte centré horizontalement, à la hauteur cy + dy."""
    try:
        font = ImageFont.truetype(font_path, size)
    except Exception:
        font = ImageFont.load_default()
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    bb = font.getbbox(text)
    tw = bb[2] - bb[0]
    th = bb[3] - bb[1]
    x = (W - tw) // 2
    y = cy + dy - th // 2
    r, g, b = color
    d.text((x, y), text, font=font, fill=(r, g, b, int(255 * alpha)))
    base = img.convert("RGBA")
    return Image.alpha_composite(base, layer).convert("RGB")


def draw_separator(img, cy, width, color, alpha):
    layer = img.convert("RGBA")
    d = ImageDraw.Draw(layer)
    x0 = (W - width) // 2
    x1 = x0 + width
    r, g, b = color
    d.line([(x0, cy), (x1, cy)], fill=(r, g, b, int(255 * alpha)), width=2)
    return layer.convert("RGB")


def add_particles(img, t, count=22):
    """Particules lumineuses flottantes."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = np.random.RandomState(7)
    sx = rng.randint(60, W - 60, count)
    sy = rng.randint(100, H - 100, count)
    sp = rng.uniform(0.4, 1.5, count)
    ph = rng.uniform(0, 2 * math.pi, count)
    sz = rng.randint(2, 5, count)
    for i in range(count):
        px = int(sx[i] + math.sin(t * sp[i] + ph[i]) * 35)
        py = int((sy[i] - t * sp[i] * 14) % H)
        a  = int(35 + 25 * math.sin(t * sp[i] * 1.8 + ph[i]))
        s  = sz[i]
        d.ellipse([px - s, py - s, px + s, py + s],
                  fill=(*GREEN_GLOW, max(0, a)))
    base = img.convert("RGBA")
    return Image.alpha_composite(base, layer).convert("RGB")


def blend_black(img, alpha):
    """Fondu vers/depuis le noir."""
    if alpha <= 0:  return img
    if alpha >= 1:  return Image.new("RGB", (W, H), (0, 0, 0))
    arr = np.array(img).astype(float)
    return Image.fromarray((arr * (1 - alpha)).astype(np.uint8))


# ── Positionnements fixes ─────────────────────────────────────────────────────
LOGO_CY    = int(H * 0.36)
LOGO_SIZE  = 270
TITLE_CY   = int(H * 0.565)
SEP_CY     = TITLE_CY + 68
SLOGAN_CY  = int(H * 0.638)
DOTS_CY    = SLOGAN_CY + 58


# ── Construction d'une frame ──────────────────────────────────────────────────
def build_frame(frame_idx, logo_rgba):
    t = frame_idx / FPS

    # Timings (secondes) des différentes phases
    fade_in_p   = ease_out3(remap(t,  0.00, 0.55))
    logo_scale  = elastic_out(remap(t, 0.30, 1.25))
    logo_fade   = ease_out3(remap(t,  0.30, 0.80))
    title_p     = ease_out3(remap(t,  1.10, 1.85))
    sep_p       = ease_out3(remap(t,  1.65, 2.15))
    slogan_p    = ease_out3(remap(t,  1.95, 2.80))
    fade_out_p  = ease_in_out(remap(t, 4.40, 5.00))

    # ── Fond
    img = make_bg()

    # ── Particules
    if fade_in_p > 0.15:
        img = add_particles(img, t)

    # ── Halo extérieur
    glow_pulse = 1 + 0.06 * math.sin(t * 3.8)
    outer_a = int(38 * logo_fade)
    if outer_a > 0:
        img = add_glow(img, W // 2, LOGO_CY, int(430 * glow_pulse), GREEN_GLOW, outer_a)

    # ── Halo principal
    inner_a = int(90 * logo_fade)
    if inner_a > 0:
        img = add_glow(img, W // 2, LOGO_CY, int(275 * glow_pulse), GREEN_GLOW, inner_a)

    # ── Logo
    size_now = max(2, int(LOGO_SIZE * logo_scale))
    img = paste_logo(img, logo_rgba, W // 2, LOGO_CY, size_now, logo_fade)

    # ── Titre "CASAIMO"
    if title_p > 0:
        dy = int(35 * (1 - title_p))
        img = text_layer(img, "CASAIMO", FONT_BOLD, 100, WHITE, TITLE_CY, title_p, dy)

    # ── Séparateur
    if sep_p > 0:
        img = draw_separator(img, SEP_CY, int(230 * sep_p), GREEN_GLOW, sep_p * 0.85)

    # ── Slogan
    if slogan_p > 0:
        dy = int(28 * (1 - slogan_p))
        img = text_layer(img, "Votre logement en toute simplicité",
                         FONT_LIGHT, 38, GREY_LIGHT, SLOGAN_CY, slogan_p * 0.9, dy)

    # ── Points décoratifs sous le slogan
    if slogan_p > 0.6:
        a_dots = int(255 * (slogan_p - 0.6) / 0.4 * 0.55)
        layer = img.convert("RGBA")
        d = ImageDraw.Draw(layer)
        for dx in (-30, 0, 30):
            d.ellipse([(W // 2 + dx - 4, DOTS_CY - 4),
                       (W // 2 + dx + 4, DOTS_CY + 4)],
                      fill=(*GREEN_GLOW, a_dots))
        img = layer.convert("RGB")

    # ── Fade-in / fade-out
    if fade_in_p < 1.0:
        img = blend_black(img, 1.0 - fade_in_p)
    if fade_out_p > 0:
        img = blend_black(img, fade_out_p)

    return np.array(img)


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)

    print(f"Chargement du logo  : {LOGO_PATH}")
    try:
        logo_rgba = Image.open(LOGO_PATH).convert("RGBA")
    except Exception as e:
        print(f"  AVERTISSEMENT: logo non chargé ({e}) — cercle de remplacement")
        logo_rgba = Image.new("RGBA", (400, 400), (0, 0, 0, 0))
        d = ImageDraw.Draw(logo_rgba)
        d.ellipse([20, 20, 380, 380], fill=(*GREEN_GLOW, 255))

    print(f"Génération de {TOTAL} frames ({W}×{H} @ {FPS}fps) ...")

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(OUTPUT, fourcc, float(FPS), (W, H))

    if not writer.isOpened():
        print("ERREUR: impossible d'ouvrir le VideoWriter. Vérifiez les codecs.")
        return

    for i in range(TOTAL):
        if i % FPS == 0:
            print(f"  {i // FPS}s / {int(DURATION)}s ...")
        frame_rgb = build_frame(i, logo_rgba)
        frame_bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)
        writer.write(frame_bgr)

    writer.release()
    size_mb = os.path.getsize(OUTPUT) / 1e6
    print(f"\n✓ Vidéo générée : {OUTPUT}")
    print(f"  Durée : {DURATION}s | {W}×{H} | {FPS}fps | {size_mb:.1f} MB")


if __name__ == "__main__":
    main()
