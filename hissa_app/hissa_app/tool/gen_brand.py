"""Derives every brand asset from the single source logo.

Source: tool/logo.png — the Hissa wordmark, white on navy. Replace that file
and re-run to re-brand the whole app from one image.

Produces:
  assets/brand/hissa_wordmark.png   trimmed lockup, white, transparent
  assets/brand/hissa_mark.png       the H glyph alone, white, transparent
  web/favicon.png, web/icons/*      PWA icons
  android .../mipmap-*/ic_launcher.png             legacy icon (pre-API 26)
  android .../mipmap-*/ic_launcher_foreground.png  adaptive icon foreground,
                                                   also the API 31+ splash icon
  android .../drawable/hissa_launch.png            pre-API 31 launch screen

Re-run after replacing logo.png:
  python tool/gen_brand.dart.py
"""

import os
from PIL import Image
import numpy as np

SRC = os.path.join('tool', 'logo.png')

# Sampled from the source. Also the exact navy the loading screens use, so the
# handover from HTML loader to app is seamless.
BG = (20, 45, 112)
BG_HEX = '#142D70'

# The H, including its rising diagonal, ends before this column; "issa" starts
# after it. Derived from the gap analysis of the source, not guessed.
H_SPLIT = 718


def load_white_on_alpha(path):
    """White glyphs, transparent ground, antialiasing preserved."""
    rgb = np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    lum = rgb.mean(axis=2)
    lum_bg = float(np.mean(BG))
    alpha = np.clip((lum - lum_bg) / (255.0 - lum_bg), 0, 1)
    # The source ground is not perfectly flat (faint gradient + compression
    # noise), which leaves a haze of low alpha across the whole canvas and
    # defeats trimming. Floor it, then rescale so edge antialiasing survives.
    floor = 0.18
    alpha = np.clip((alpha - floor) / (1.0 - floor), 0, 1)
    out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    out[..., 0:3] = 255
    out[..., 3] = (alpha * 255).round().astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def trim(img):
    bbox = img.getchannel('A').point(lambda v: 255 if v > 96 else 0).getbbox()
    return img.crop(bbox)


def contain(img, box, pad_ratio):
    """Fit img inside a square of `box` px, leaving `pad_ratio` margin."""
    inner = int(box * (1 - 2 * pad_ratio))
    w, h = img.size
    scale = min(inner / w, inner / h)
    resized = img.resize((max(1, round(w * scale)), max(1, round(h * scale))),
                         Image.LANCZOS)
    canvas = Image.new('RGBA', (box, box), (0, 0, 0, 0))
    canvas.paste(resized,
                 ((box - resized.width) // 2, (box - resized.height) // 2),
                 resized)
    return canvas


def on_navy(img, box, pad_ratio, radius_ratio=0.0):
    """Composite onto the brand navy, optionally with rounded corners."""
    plate = Image.new('RGBA', (box, box), BG + (255,))
    plate.alpha_composite(contain(img, box, pad_ratio))
    if radius_ratio > 0:
        mask = Image.new('L', (box, box), 0)
        from PIL import ImageDraw
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, box - 1, box - 1], radius=int(box * radius_ratio), fill=255)
        plate.putalpha(mask)
    return plate


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f'  {path}  {img.size[0]}x{img.size[1]}')


def main():
    full = load_white_on_alpha(SRC)

    wordmark = trim(full)
    mark = trim(full.crop((0, 0, H_SPLIT, full.height)))

    print('brand assets:')
    save(wordmark, 'assets/brand/hissa_wordmark.png')
    save(mark, 'assets/brand/hissa_mark.png')

    # White-on-transparent copy of the mark for the Android launch drawable,
    # which paints its own navy behind it.
    save(contain(mark, 512, 0.22),
         'android/app/src/main/res/drawable/hissa_launch.png')

    print('web icons:')
    # Square app icons: the mark on navy. The wordmark is unreadable at 48px.
    save(on_navy(mark, 512, 0.22), 'web/icons/Icon-512.png')
    save(on_navy(mark, 192, 0.22), 'web/icons/Icon-192.png')
    # Maskable icons need a safe zone — Android crops to a circle.
    save(on_navy(mark, 512, 0.30), 'web/icons/Icon-maskable-512.png')
    save(on_navy(mark, 192, 0.30), 'web/icons/Icon-maskable-192.png')
    save(on_navy(mark, 64, 0.20), 'web/favicon.png')

    print('android launcher icons:')
    for folder, px in [('mipmap-mdpi', 48), ('mipmap-hdpi', 72),
                       ('mipmap-xhdpi', 96), ('mipmap-xxhdpi', 144),
                       ('mipmap-xxxhdpi', 192)]:
        # Legacy square icon, for launchers below API 26.
        save(on_navy(mark, px, 0.20),
             f'android/app/src/main/res/{folder}/ic_launcher.png')

    print('android adaptive foreground / splash icon:')
    # Adaptive icons are a 108dp canvas whose outer third can be cropped by
    # any launcher mask, so the glyph has to live in the middle. The API 31+
    # splash icon uses the same proportions (240dp canvas, 160dp visible),
    # which is why one asset serves both.
    for folder, dp in [('mipmap-mdpi', 108), ('mipmap-hdpi', 162),
                       ('mipmap-xhdpi', 216), ('mipmap-xxhdpi', 324),
                       ('mipmap-xxxhdpi', 432)]:
        save(contain(mark, dp, 0.21),
             f'android/app/src/main/res/{folder}/ic_launcher_foreground.png')


if __name__ == '__main__':
    main()
