"""Recorta a referência dourada em blocos de 32 × 32 para a fase bônus."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

assets = Path(__file__).resolve().parents[1] / "assets"
columns = (2, 78, 153, 230, 307, 384, 461, 538, 615, 692,
           769, 846, 923, 1000, 1077, 1154, 1231, 1308, 1384, 1460)
rows = (3, 75, 148, 225, 301, 377, 453, 529, 605, 681,
        757, 833, 904, 979, 1042, 1102)
with Image.open(assets / "mapa_bonus_referencia.png") as image:
    scene = image.convert("RGBA")


def display_tile(filename):
    # O mesmo recorte mantém as duas vitrines alinhadas durante a troca.
    with Image.open(assets / filename) as image:
        display = image.convert("RGBA").crop((55, 17, 1201, 1218))
    display.thumbnail((32, 32), Image.Resampling.LANCZOS)
    # O renderizador do jogo aceita pixels opacos ou transparentes.
    display.putalpha(display.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
    floor = tile(1, 8)
    floor.alpha_composite(display, ((32 - display.width) // 2, 32 - display.height))
    return floor


def source_tile(row, col):
    box = (columns[col], rows[row], columns[col + 1], rows[row + 1])
    return scene.crop(box)


def tile(row, col):
    return source_tile(row, col).resize((32, 32), Image.Resampling.LANCZOS)


# Para cada joia, uma casa livre da mesma fileira fornece o piso dourado
# e a estrela central. A moldura e as sombras continuam sendo da própria casa.
floor_donors = {
    (1, 16): 15, (4, 3): 5, (4, 12): 11, (6, 15): 16,
    (7, 4): 3, (9, 5): 7, (11, 16): 17, (13, 5): 6, (13, 11): 10,
}


def floor_without_gem(row, col, donor_col):
    original = source_tile(row, col)
    donor = source_tile(row, donor_col).resize(original.size, Image.Resampling.LANCZOS)
    # O piso é dourado. Azul, verde e roxo identificam o interior da joia.
    mask = Image.new("L", original.size)
    mask.putdata([255 if max(g, b) > r + 30 else 0
                  for r, g, b, _ in original.getdata()])
    left, top, right, bottom = mask.getbbox()
    patch = Image.new("L", original.size)
    ImageDraw.Draw(patch).rectangle((left - 5, top - 5, right + 5, bottom + 5), fill=255)
    original.paste(donor, mask=patch.filter(ImageFilter.GaussianBlur(1.2)))
    return original.resize((32, 32), Image.Resampling.LANCZOS)


display = display_tile("coroa_bonus_referencia.png")
empty_display = display_tile("vitrine_coroa_vazia_referencia.png")
atlas = bytearray()
for row in range(len(rows) - 1):
    for col in range(len(columns) - 1):
        block = display if (row, col) == (1, 9) else tile(row, col)
        atlas.extend(block.tobytes("raw", "BGRA"))
atlas.extend(empty_display.tobytes("raw", "BGRA"))
floor_indices = bytearray((len(rows) - 1) * (len(columns) - 1))
for index, ((row, col), donor_col) in enumerate(floor_donors.items(), start=1):
    floor_indices[row * (len(columns) - 1) + col] = index
    atlas.extend(floor_without_gem(row, col, donor_col).tobytes("raw", "BGRA"))
atlas.extend(floor_indices)
(assets / "cenario_bonus.bgra").write_bytes(atlas)
