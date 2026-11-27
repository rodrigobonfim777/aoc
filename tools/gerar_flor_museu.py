"""Extrai o vaso de flor e o encaixa em um bloco do museu."""
from pathlib import Path

from PIL import Image

assets = Path(__file__).resolve().parents[1] / "assets"
with Image.open(assets / "flor_museu_referencia.png") as source:
    flower = source.convert("RGBA").crop((145, 226, 411, 650))

# O fundo preto e o contorno claro da seleção não fazem parte do vaso.
flower.putdata([
    (r, g, b, a) if max(r, g, b) > 30 and max(r, g, b) - min(r, g, b) > 20 else (0, 0, 0, 0)
    for r, g, b, a in flower.getdata()
])
flower = flower.crop(flower.getbbox())
flower.thumbnail((32, 30), Image.Resampling.LANCZOS)
tile = Image.new("RGBA", (32, 32))
tile.paste(flower, ((32 - flower.width) // 2, 31 - flower.height))
tile.putdata([
    (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    for r, g, b, a in tile.getdata()
])
tile.save(assets / "flor_museu.png")
(assets / "flor_museu.bgra").write_bytes(tile.tobytes("raw", "BGRA"))
