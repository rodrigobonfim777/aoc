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
    "diamante_pedra": (9, 1),
    "algema_esquerda": (1, 1),
    "algema_direita": (10, 3),
    "grade_esquerda": (4, 8),
    "grade_direita": (13, 2),
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
    if name.startswith("grade_"):
        # A referencia mostra apenas o trilho: completa o portao fechado.
        draw = ImageDraw.Draw(tile)
        draw.rectangle((0, 0, 15, 1), fill="#d5a33d")
        draw.line((5, 0, 9, 0), fill="#fff0a0")
        draw.line((1, 1, 1, 15), fill="#805823")
        draw.line((14, 1, 14, 15), fill="#805823")
        for x in (3, 6, 9, 12):
            draw.line((x + 1, 2, x + 1, 14), fill="#805823")
            draw.line((x, 2, x, 14), fill="#ffe27b")
        draw.line((2, 7, 13, 7), fill="#e2b14e")
        draw.line((2, 8, 13, 8), fill="#805823")
        draw.rectangle((1, 14, 14, 15), fill="#c89432")
        draw.rectangle((7, 7, 9, 10), fill="#60421c")
        draw.point((8, 8), fill="#fff0a0")
    tile.save(ROOT / f"assets/{name}.png")
    (ROOT / f"assets/{name}.bgra").write_bytes(tile.tobytes("raw", "BGRA"))

# Porta aberta: conserva o batente, com o vao livre e a folha azul de lado.
door = Image.open(ROOT / "assets/piso_direito.png").convert("RGBA")
draw = ImageDraw.Draw(door)
draw.rectangle((2, 1, 13, 14), fill="#0d1623", outline="#63788c")
draw.rectangle((2, 0, 13, 1), fill="#4b657b")
draw.rectangle((2, 14, 13, 15), fill="#7d8c99")
draw.polygon(((10, 2), (14, 0), (14, 14), (10, 12)), fill="#398fd8")
draw.line(((10, 2), (14, 0), (14, 14), (10, 12), (10, 2)), fill="#152f51")
draw.line((13, 2, 13, 12), fill="#70b9ed")
draw.point((11, 8), fill="#ffe27b")
door.save(ROOT / "assets/porta_aberta.png")
(ROOT / "assets/porta_aberta.bgra").write_bytes(door.tobytes("raw", "BGRA"))
