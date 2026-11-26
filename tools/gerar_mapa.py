"""Extrai da referencia os blocos BGRA 16x16 incorporados pelo NASM.

Executar com Python e Pillow instalados. As alavancas mantem os sprites originais.
"""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
reference = Image.open(ROOT / "assets/mapa-referencia.png").convert("RGBA")
MAP_TOP = 58
TILES = {
    "parede": (1, 0),
    "parede_central": (9, 4),
    "algema_esquerda": (1, 1),
    "algema_direita": (10, 3),
    "piso_esquerdo": (1, 2),
    "piso_direito": (10, 4),
}

for name, (column, row) in TILES.items():
    box = (
        round(column * reference.width / 19),
        round(MAP_TOP + row * (reference.height - MAP_TOP) / 15),
        round((column + 1) * reference.width / 19),
        round(MAP_TOP + (row + 1) * (reference.height - MAP_TOP) / 15),
    )
    tile = reference.crop(box).resize((16, 16), Image.Resampling.NEAREST)
    tile.save(ROOT / f"assets/{name}.png")
    (ROOT / f"assets/{name}.bgra").write_bytes(tile.tobytes("raw", "BGRA"))

# Pedestal vazio: permanece no mapa depois que a dupla recolhe a joia.
stone = Image.open(ROOT / "assets/parede.png").convert("RGBA")
draw = ImageDraw.Draw(stone)
draw.rectangle((1, 1, 14, 3), fill="#8794a5")
draw.rectangle((2, 4, 13, 12), fill="#506174")
draw.line((2, 4, 2, 12), fill="#6a7b8d")
draw.line((13, 4, 13, 12), fill="#344457")
draw.rectangle((1, 13, 14, 15), fill="#607083")
draw.line((1, 15, 14, 15), fill="#263749")
stone.save(ROOT / "assets/pedra_diamante.png")
(ROOT / "assets/pedra_diamante.bgra").write_bytes(stone.tobytes("raw", "BGRA"))
