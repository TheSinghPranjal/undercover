"""Draws the Find the Imposter app icon (hooded imposter with a glowing "?")."""

import math
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1]
S = 4  # supersampling
W, H = 1024, 1400  # design canvas; the hood's shoulders run past y=1024
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"


def px(v):
    return int(round(v * S))


def vgrad(size, top, bottom):
    w, h = size
    g = Image.new("RGBA", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        g.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(4)))
    return g.resize((w, h))


def radial(size, center, radius, inner, outer):
    w, h = size
    small = (w // 8, h // 8)
    g = Image.new("RGBA", small)
    cx, cy, r = center[0] / 8, center[1] / 8, radius / 8
    for y in range(small[1]):
        for x in range(small[0]):
            t = min(math.hypot(x - cx, y - cy) / r, 1)
            g.putpixel((x, y), tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(4)))
    return g.resize((w, h), Image.BICUBIC)


def ellipse_mask(size, box, blur=0):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).ellipse([px(v) for v in box], fill=255)
    return m.filter(ImageFilter.GaussianBlur(px(blur))) if blur else m


def hex4(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def hood_layer(m=0):
    """Hood on a canvas widened by [m] design px each side (for Android)."""

    def xb(box):
        return (box[0] + m, box[1], box[2] + m, box[3])

    size = (px(W + 2 * m), px(H))
    layer = Image.new("RGBA", size, (0, 0, 0, 0))

    # Hood silhouette: dome + shoulders + a soft peak.
    shape = Image.new("L", size, 0)
    d = ImageDraw.Draw(shape)
    # One smooth outline: half-width as a function of y. A round dome that
    # flares into a cloak with no kinks where they meet.
    top, neck, dome_w = 175.0, 480.0, 255.0

    def half_width(y):
        if y <= neck:
            t = (neck - y) / (neck - top)
            return dome_w * math.sqrt(max(0.0, 1 - t * t)) ** 0.9
        t = (y - neck) / 520
        return dome_w + 235 * (1 - math.exp(-t * t * 2.2)) + 40 * t

    ys = [top + i * (H - top) / 600 for i in range(601)]
    outline = [(512 + m + half_width(y), y) for y in ys]
    outline += [(512 + m - half_width(y), y) for y in reversed(ys)]
    d.polygon([(px(x), px(y)) for x, y in outline], fill=255)
    shape = shape.filter(ImageFilter.GaussianBlur(px(1)))

    # Drop shadow under the hood.
    shadow = Image.new("RGBA", size, hex4("#3A1E9A", 0))
    shadow.putalpha(shape.filter(ImageFilter.GaussianBlur(px(22))).point(lambda v: v * 0.45))
    layer.alpha_composite(shadow, (0, px(14)))

    body = vgrad(size, hex4("#9A70FF"), hex4("#5B2FD6"))
    # Light from the top-left, shade on the right.
    body.alpha_composite(Image.composite(
        Image.new("RGBA", size, hex4("#C8B0FF", 150)),
        Image.new("RGBA", size, (0, 0, 0, 0)),
        ellipse_mask(size, xb((250, 200, 520, 640)), blur=70)))
    body.alpha_composite(Image.composite(
        Image.new("RGBA", size, hex4("#3B1C9E", 120)),
        Image.new("RGBA", size, (0, 0, 0, 0)),
        ellipse_mask(size, xb((640, 300, 920, 1100)), blur=80)))
    body.putalpha(shape)
    layer.alpha_composite(body)

    # Face opening: rim, then dark void.
    rim = Image.new("RGBA", size, hex4("#431FB0"))
    rim.putalpha(ellipse_mask(size, xb((318, 318, 706, 772)), blur=4))
    layer.alpha_composite(rim)
    face_box = xb((340, 345, 684, 752))
    void = radial(size, (px(512 + m), px(520)), px(230), hex4("#2A1F66"), hex4("#0E0A22"))
    void.putalpha(ellipse_mask(size, face_box, blur=2))
    layer.alpha_composite(void)

    # Glowing "?".
    font = ImageFont.truetype(FONT, px(300))
    q = Image.new("L", size, 0)
    ImageDraw.Draw(q).text((px(512 + m), px(560)), "?", font=font, fill=255, anchor="mm")
    glow = Image.new("RGBA", size, hex4("#B79CFF", 0))
    glow.putalpha(q.filter(ImageFilter.GaussianBlur(px(26))).point(lambda v: min(255, v * 1.6)))
    layer.alpha_composite(glow)
    white = Image.new("RGBA", size, (255, 255, 255, 0))
    white.putalpha(q)
    layer.alpha_composite(white)
    return layer


def background():
    size = (px(1024), px(1024))
    bg = radial(size, (px(512), px(430)), px(760), hex4("#FBF8FF"), hex4("#C7B2FF"))
    return bg


def sparks(img, center, angles, color, length, width, radius):
    d = ImageDraw.Draw(img)
    for a in angles:
        r = math.radians(a)
        x0 = center[0] + math.cos(r) * radius
        y0 = center[1] - math.sin(r) * radius
        x1 = center[0] + math.cos(r) * (radius + length)
        y1 = center[1] - math.sin(r) * (radius + length)
        d.line([(px(x0), px(y0)), (px(x1), px(y1))], fill=color, width=px(width))
        for x, y in ((x0, y0), (x1, y1)):
            d.ellipse([px(x - width / 2), px(y - width / 2), px(x + width / 2), px(y + width / 2)], fill=color)


def decorate(img, m=0):
    yellow = hex4("#FFC23D")
    sparks(img, (512 + m, 470), [128, 142, 156], yellow, 70, 26, 330)
    sparks(img, (512 + m, 470), [52, 38, 24], yellow, 70, 26, 330)


def finish(img, name, size=1024):
    img.resize((size, size), Image.LANCZOS).save(f"{OUT}/{name}")


hood = hood_layer()

# Full icon (iOS + legacy Android): opaque, no alpha.
full = background()
full.alpha_composite(hood.crop((0, 0, px(1024), px(1024))))
decorate(full)
finish(full.convert("RGB"), "app_icon.png")

# Android adaptive: background + foreground shrunk into the 66% safe zone.
finish(background().convert("RGB"), "app_icon_background.png")
fg = Image.new("RGBA", (px(1024), px(1024)), (0, 0, 0, 0))
k = 0.72
M = 300  # wider art so the shrunk cloak still runs off both edges
art = hood_layer(M)
decorate(art, M)
scaled = art.resize((int(art.width * k), int(art.height * k)), Image.LANCZOS)
anchor = (512, 540)  # this design point stays put
fg.alpha_composite(
    scaled, (px(anchor[0] - (anchor[0] + M) * k), px(anchor[1] - anchor[1] * k)))
finish(fg, "app_icon_foreground.png")
