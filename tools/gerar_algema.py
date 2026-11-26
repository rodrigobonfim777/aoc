"""Exporta o ícone de algema transparente na resolução final do jogo."""

from collections import deque
from pathlib import Path

from PIL import Image


ASSETS = Path(__file__).resolve().parents[1] / 'assets'
SIZE = 32


def remove_background(sprite):
    width, height = sprite.size
    pixels = sprite.load()
    edge = [(x, y) for x in range(width) for y in (0, height - 1)]
    edge += [(x, y) for y in range(height) for x in (0, width - 1)]
    # Os dois aros e a abertura da corrente têm fundo cercado pelo contorno.
    holes = [(int(width * x), int(height * y)) for x, y in
             ((.25, .61), (.75, .61), (.50, .31))]
    pending = deque(edge + holes)
    seen = bytearray(width * height)
    while pending:
        x, y = pending.popleft()
        if not 0 <= x < width or not 0 <= y < height:
            continue
        index = y * width + x
        if seen[index]:
            continue
        seen[index] = 1
        red, green, blue, alpha = pixels[x, y]
        white = min(red, green, blue) >= 225 and max(red, green, blue) - min(red, green, blue) <= 25
        if alpha < 128 or white:
            pixels[x, y] = (0, 0, 0, 0)
            pending.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))


def main():
    with Image.open(ASSETS / 'algema-referencia.png') as source:
        sprite = source.convert('RGBA')
    remove_background(sprite)
    bounds = sprite.getbbox()
    if not bounds:
        raise ValueError('O ícone da algema ficou vazio.')
    sprite = sprite.crop(bounds)
    sprite.thumbnail((SIZE - 2, SIZE - 2), Image.Resampling.BOX)
    mask = sprite.getchannel('A').point(lambda value: 255 if value >= 128 else 0)
    sprite.putalpha(mask)
    tile = Image.new('RGBA', (SIZE, SIZE))
    tile.paste(sprite, ((SIZE - sprite.width) // 2, (SIZE - sprite.height) // 2), mask)
    tile.save(ASSETS / 'algema_detalhada.png')
    (ASSETS / 'algema_detalhada.bgra').write_bytes(tile.tobytes('raw', 'BGRA'))


if __name__ == '__main__':
    main()
