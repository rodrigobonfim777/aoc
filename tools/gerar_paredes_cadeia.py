"""Recorta as paredes da Cadeia em blocos BGRA na resolução da janela."""
from pathlib import Path
from PIL import Image, ImageDraw

assets = Path(__file__).resolve().parents[1] / "assets"
source = Image.open(assets / "paredes_cadeia_referencia.png").convert("RGB")
# Remove o papel branco externo sem recolorir os reflexos do metal.
ImageDraw.floodfill(source, (0, 0), (23, 29, 48), thresh=90)
x = [7, 69, 150, 222, 296, 373, 449, 529, 599, 687,
     760, 842, 913, 986, 1057, 1132, 1205, 1280, 1378, 1442]
y = [5, 81, 152, 221, 292, 362, 432, 501, 572, 642,
     712, 782, 850, 918, 997, 1076]

# Mesmo formato da moldura do Museu; o último recorte é a divisória da Cadeia.
boxes = [(x[c], y[r], x[c+1], y[r+1]) for r in (0, 14) for c in range(19)]
boxes += [(x[c], y[r], x[c+1], y[r+1]) for c in (0, 18) for r in range(1, 14)]
boxes += [(373, 432, 449, 501), (687, 220, 760, 289)]
atlas = bytearray()
for box in boxes:
    tile = source.crop(box).resize((32, 32), Image.Resampling.LANCZOS)
    atlas.extend(tile.convert("RGBA").tobytes("raw", "BGRA"))
(assets / "paredes_cadeia.bgra").write_bytes(atlas)
