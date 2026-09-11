#!/usr/bin/env python3
"""Regenerate every Android icon asset from the brand master.

Run from the repository root after changing docs/brand/fieldtally-icon.png:

    python3 tool/generate_icons.py

Three families come out of one image, because Android asks for three
different things and getting any of them wrong is only visible on a device:

* the adaptive icon (Android 8+), whose foreground is masked to a circle, a
  squircle or a rounded square depending on the launcher — so the mark has to
  sit well inside the central safe zone rather than fill the canvas;
* the legacy launcher icon, which is not masked and keeps the full artwork;
* the notification icon, which the system redraws as a flat white silhouette
  from the alpha channel alone — colour and interior detail are thrown away,
  so only the outer shape survives and the tally strokes are dropped.
"""

import math
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / 'docs/brand/fieldtally-icon.png'
ANDROID = ROOT / 'app/android/app/src/main/res'

BACKGROUND = (0x0E, 0x26, 0x24)
MARK = (0x5F, 0xD3, 0xC4)

# Densities, as multiples of the baseline.
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

# The adaptive safe zone is a 66dp circle inside a 108dp canvas — 0.611 of the
# half-canvas. Kept under it so a launcher masking tighter than the spec still
# leaves the triangle's corners alone.
SAFE_RADIUS = 0.56

# Notification icons are drawn inside 24dp with a little breathing room.
NOTIFICATION_FILL = 0.92

WORK = 1024


def alpha_of(image):
    """Alpha of the mark, from its distance to the background colour."""
    pixels = image.convert('RGB').load()
    width, height = image.size
    alpha = Image.new('L', (width, height))
    out = alpha.load()
    lo, hi = 35.0, 110.0
    for y in range(height):
        for x in range(width):
            distance = math.dist(pixels[x, y], BACKGROUND)
            value = (distance - lo) / (hi - lo)
            out[x, y] = 0 if value <= 0 else (255 if value >= 1 else int(value * 255))
    return alpha


def largest_component(alpha):
    """The mark's biggest connected shape: the triangle and its three nodes.

    The tally strokes inside it are separate shapes, and they are what turns
    into mud at 24dp once the system has flattened everything to one colour.
    """
    width, height = alpha.size
    solid = alpha.load()
    seen = bytearray(width * height)
    best = []

    for start in range(width * height):
        if seen[start] or solid[start % width, start // width] <= 128:
            continue
        queue = deque([start])
        seen[start] = 1
        component = []
        while queue:
            index = queue.popleft()
            x, y = index % width, index // width
            component.append(index)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    neighbour = ny * width + nx
                    if not seen[neighbour] and solid[nx, ny] > 128:
                        seen[neighbour] = 1
                        queue.append(neighbour)
        if len(component) > len(best):
            best = component

    kept = Image.new('L', (width, height), 0)
    out = kept.load()
    source = alpha.load()
    for index in best:
        x, y = index % width, index // width
        out[x, y] = source[x, y]
    return kept


def centred(alpha, target_radius=None, target_fill=None):
    """Centre the mark on a square canvas, scaled to a radius or a bounding box."""
    bbox = alpha.getbbox()
    cropped = alpha.crop(bbox)
    width, height = cropped.size
    pixels = cropped.load()

    if target_radius is not None:
        cx, cy = (width - 1) / 2, (height - 1) / 2
        reach = 0.0
        for y in range(height):
            for x in range(width):
                if pixels[x, y] > 8:
                    reach = max(reach, math.hypot(x - cx, y - cy))
        scale = (target_radius * WORK / 2) / reach
    else:
        scale = target_fill * WORK / max(width, height)

    resized = cropped.resize(
        (max(1, round(width * scale)), max(1, round(height * scale))),
        Image.LANCZOS,
    )
    canvas = Image.new('L', (WORK, WORK), 0)
    canvas.paste(
        resized,
        ((WORK - resized.width) // 2, (WORK - resized.height) // 2),
    )
    return canvas


def colourise(alpha, colour):
    image = Image.new('RGBA', alpha.size, colour + (0,))
    image.putalpha(alpha)
    return image


def write(image, folder, name, size):
    directory = ANDROID / folder
    directory.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.LANCZOS).save(directory / name)


def main():
    master = Image.open(MASTER).convert('RGB')
    alpha = alpha_of(master)

    foreground = colourise(centred(alpha, target_radius=SAFE_RADIUS), MARK)
    silhouette = colourise(
        centred(largest_component(alpha), target_fill=NOTIFICATION_FILL),
        (0xFF, 0xFF, 0xFF),
    )

    for density, factor in DENSITIES.items():
        write(foreground, f'mipmap-{density}', 'ic_launcher_foreground.png',
              round(108 * factor))
        write(master, f'mipmap-{density}', 'ic_launcher.png', round(48 * factor))
        write(master, f'mipmap-{density}', 'ic_launcher_round.png',
              round(48 * factor))
        write(silhouette, f'drawable-{density}', 'ic_notification.png',
              round(24 * factor))

    print('icons written under', ANDROID.relative_to(ROOT))


if __name__ == '__main__':
    main()
