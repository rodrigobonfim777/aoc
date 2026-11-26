"""Adapta a esfinge com pedestal a quatro blocos (2x2) do museu."""

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
image = Image.open(ROOT / "assets/esfinge_museu_referencia.png").convert("RGBA")
image = image.crop((205, 20, 1045, 820))
width, height = image.size
pixels = image.load()
# A referencia tem um contorno branco de selecao e pontos claros no fundo.
# Remove esses tons neutros antes da reducao, preservando o dourado da esfinge.
for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        if min(r, g, b) >= 150 and max(r, g, b) - min(r, g, b) <= 45:
            pixels[x, y] = (0, 0, 0, 0)
queue = deque((x, y) for x in range(width) for y in (0, height - 1))
queue.extend((x, y) for y in range(height) for x in (0, width - 1))
visited = set()
while queue:
    x, y = queue.popleft()
    if not (0 <= x < width and 0 <= y < height) or (x, y) in visited:
        continue
    visited.add((x, y))
    if max(pixels[x, y][:3]) > 22:
        continue
    pixels[x, y] = (0, 0, 0, 0)
    queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
# Renderizacao detalhada na resolucao final da janela (2x2 blocos = 64x64).
# A imagem vem diretamente da referencia; o fundo acompanha o piso do museu.
detailed = image.copy()
detailed.thumbnail((64, 64), Image.Resampling.LANCZOS)
canvas = Image.new("RGBA", (64, 64), "#27252b")
from PIL import ImageDraw
draw = ImageDraw.Draw(canvas)
for pos in (0, 32):
    draw.rectangle((pos, 0, pos + 1, 63), fill="#302d32")
    draw.rectangle((0, pos, 63, pos + 1), fill="#302d32")
canvas.alpha_composite(detailed, ((64 - detailed.width) // 2, 64 - detailed.height))
canvas.save(ROOT / "assets/esfinge_museu_detalhado.png")
(ROOT / "assets/esfinge_museu_detalhado.bgra").write_bytes(canvas.tobytes("raw", "BGRA"))

image.thumbnail((32, 32), Image.Resampling.NEAREST)
tile = Image.new("RGBA", (32, 32))
tile.paste(image, ((32 - image.width) // 2, 32 - image.height))
tile.putdata([p if p[3] else (0, 0, 0, 0) for p in tile.getdata()])
tile.save(ROOT / "assets/esfinge_museu.png")
# Quatro blocos consecutivos: superior esquerdo/direito, inferior esquerdo/direito.
(ROOT / "assets/esfinge_museu.bgra").write_bytes(b"".join(
    tile.crop((x, y, x + 16, y + 16)).tobytes("raw", "BGRA")
    for y in (0, 16) for x in (0, 16)
))
