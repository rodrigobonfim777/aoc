"""Gera sprites BGRA 16x16: quatro direcoes, cada uma com idle + seis passos.

Executar com Python e Pillow. Caminhada lateral extraida da referencia;
vistas de frente/costas adaptadas em pixels, pois nao aparecem na referencia.
"""

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
reference = Image.open(ROOT / 'assets/personagens-referencia.png').convert('RGBA')


def extract(box):
    sprite = reference.crop(box)
    width, height = sprite.size
    pixels = sprite.load()
    queue = deque()
    visited = set()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if not (0 <= x < width and 0 <= y < height) or (x, y) in visited:
            continue
        visited.add((x, y))
        r, g, b, _ = pixels[x, y]
        if max(r, g, b) > 26:
            continue
        pixels[x, y] = (0, 0, 0, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    sprite = sprite.crop(sprite.getbbox())
    target_width = round(sprite.width * 16 / sprite.height)
    sprite = sprite.resize((target_width, 16), Image.Resampling.NEAREST)
    canvas = Image.new('RGBA', (16, 16))
    canvas.paste(sprite, ((16 - target_width) // 2, 0))
    return canvas


def vertical(frame, back, female):
    result = frame.copy()
    draw = ImageDraw.Draw(result)
    draw.rectangle((0, 0, 15, 11), fill=(0, 0, 0, 0))
    ink = '#151921'
    hat = '#343944'
    light = '#555d69'
    skin = '#f0b78d'
    white = '#e0e3df'
    # Corpo listrado e bracos, mantendo as pernas dos quadros originais.
    draw.rectangle((5, 7, 10, 11), fill=ink)
    draw.line((5, 8, 10, 8), fill=white)
    draw.line((5, 10, 10, 10), fill=white)
    draw.line((4, 9, 4, 11), fill=skin)
    draw.line((11, 9, 11, 11), fill=skin)
    draw.rectangle((7, 6, 8, 7), fill=skin)
    if female:
        draw.rectangle((5, 4, 10, 6), fill='#c7cdd2')
        draw.line((4, 5, 3, 9), fill='#b5bec7', width=2)
        draw.line((3, 7, 2, 10), fill='#e0e4e5')
    if back:
        draw.rectangle((5, 4, 10, 5), fill='#c7cdd2' if female else '#272c35')
        draw.line((6, 6, 9, 6), fill='#e0e4e5' if female else '#333945')
    else:
        draw.rectangle((5, 4, 10, 5), fill=skin)
        draw.rectangle((6, 6, 9, 6), fill=skin)
        draw.line((5, 4, 10, 4), fill='#080c12')
        draw.point((6, 4), fill='#f6f0df')
        draw.point((9, 4), fill='#f6f0df')
    draw.line((6, 0, 9, 0), fill=ink)
    draw.rectangle((5, 1, 10, 2), fill=hat)
    draw.line((6, 1, 8, 1), fill=light)
    draw.line((4, 3, 11, 3), fill=ink)
    draw.line((5, 2, 10, 2), fill=light)
    return result


BOXES = {
    'pilantra': [(40, 177, 88, 271)] + [
        (39, 303, 87, 392), (105, 303, 154, 392),
        (171, 303, 222, 392), (239, 303, 287, 392),
        (302, 303, 353, 392), (366, 303, 419, 392),
    ],
    'patife': [(805, 177, 864, 271)] + [
        (802, 303, 865, 393), (874, 303, 936, 393),
        (944, 303, 1006, 393), (1012, 303, 1075, 393),
        (1080, 303, 1143, 393), (1150, 303, 1216, 393),
    ],
}

for name, boxes in BOXES.items():
    right = [extract(box) for box in boxes]
    directions = [
        right,
        [ImageOps.mirror(frame) for frame in right],
        [vertical(frame, True, name == 'patife') for frame in right],
        [vertical(frame, False, name == 'patife') for frame in right],
    ]
    right[0].save(ROOT / f'assets/{name}.png')
    (ROOT / f'assets/{name}.bgra').write_bytes(right[0].tobytes('raw', 'BGRA'))
    atlas = Image.new('RGBA', (7 * 16, 4 * 16))
    raw = bytearray()
    for direction, frames in enumerate(directions):
        for number, frame in enumerate(frames):
            atlas.paste(frame, (number * 16, direction * 16))
            raw.extend(frame.tobytes('raw', 'BGRA'))
    atlas.save(ROOT / f'assets/{name}_animacoes.png')
    (ROOT / f'assets/{name}_animacoes.bgra').write_bytes(raw)
