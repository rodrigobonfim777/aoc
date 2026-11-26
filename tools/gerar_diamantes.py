"""Extrai vitrines completas, com vidro e joia, da referencia fornecida.

Gera sprites BGRA 16x16. Executar com Python e Pillow instalados.
"""

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
reference = Image.open(ROOT / "assets/diamantes_vidro_referencia.png").convert("RGBA")
BOXES = {
    "azul": (50, 36, 800, 805),
    "roxo": (900, 36, 1650, 805),
    "verde": (1750, 36, 2500, 805),
}

sprites = [(f"diamante_{name}", reference.crop(box)) for name, box in BOXES.items()]
empty = Image.open(ROOT / "assets/vitrine_vazia_referencia.png").convert("RGBA")
sprites.append(("vitrine_vazia", empty.crop((44, 15, 810, 810))))

for name, tile in sprites:
    width, height = tile.size
    pixels = tile.load()
    queue = deque()
    visited = set()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    # Remove somente o preto externo conectado as bordas, mantendo os
    # contornos escuros do vidro e as linhas entre as facetas da joia.
    while queue:
        x, y = queue.popleft()
        if not (0 <= x < width and 0 <= y < height) or (x, y) in visited:
            continue
        visited.add((x, y))
        r, g, b, _ = pixels[x, y]
        if max(r, g, b) > 22:
            continue
        pixels[x, y] = (0, 0, 0, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    tile = tile.resize((16, 16), Image.Resampling.NEAREST)
    # O renderizador usa valor BGRA zero como pixel transparente.
    tile.putdata([p if p[3] else (0, 0, 0, 0) for p in tile.getdata()])
    tile.save(ROOT / f"assets/{name}.png")
    (ROOT / f"assets/{name}.bgra").write_bytes(tile.tobytes("raw", "BGRA"))
