"""Prepara a arte da praia em blocos BGRA de 32 × 32."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

assets = Path(__file__).resolve().parents[1] / "assets"
reference = Image.open(assets / "praia_referencia.png").convert("RGB")
scene = reference.copy()
columns = (9, 48, 156, 234, 310, 387, 464, 541, 618, 695,
           773, 849, 926, 1003, 1080, 1157, 1234, 1311, 1412, 1457)
rows = (7, 75, 154, 232, 309, 386, 463, 541, 617, 694,
        770, 847, 923, 1000, 1080, 1147)


def restore_sand(bounds, donor):
    """Substitui o elemento móvel da captura por areia da própria praia."""
    left, top, right, bottom = bounds
    width, height = right - left, bottom - top
    x, y = donor
    patch = reference.crop((x, y, x + width, y + height))
    mask = Image.new("L", patch.size)
    ImageDraw.Draw(mask).rectangle((4, 4, width - 5, height - 5), fill=255)
    scene.paste(patch, (left, top), mask.filter(ImageFilter.GaussianBlur(2)))


# Vitrine, alavanca, porta, algemas e guardas são desenhados pelo jogo.
for area, donor in (
    ((688, 77, 780, 156), (494, 75)),
    ((920, 600, 1005, 694), (62, 615)),
    ((690, 994, 778, 1081), (476, 995)),
    ((474, 364, 537, 468), (625, 351)),
    ((1003, 464, 1078, 541), (1082, 470)),
    ((1080, 294, 1155, 385), (62, 615)),
    ((136, 934, 227, 1001), (1246, 696)),
    ((1230, 923, 1321, 1001), (1246, 696)),
):
    restore_sand(area, donor)

# Usa areia livre de pedras e sombras sob as algemas e após o resgate.
for area in (
    (309, 237, 386, 303),
    (77, 546, 160, 612),
    (1157, 780, 1239, 841),
    (235, 845, 315, 915),
    (1080, 924, 1166, 998),
):
    restore_sand(area, (1246, 696))

# O chapéu do guarda da direita cruza a pedra acima dele na captura.
scene.paste(reference.crop((1079, 438, 1157, 471)), (1002, 438))


def place_sprite(name, bounds, origin, size):
    with Image.open(assets / f"{name}_referencia.png") as image:
        sprite = image.convert("RGBA").crop(bounds)
    # Elimina o fundo e o contorno branco do recorte.
    sprite.putdata([
        (r, g, b, a) if max(r, g, b) > 27 and max(r, g, b) - min(r, g, b) > 18 else (0, 0, 0, 0)
        for r, g, b, a in sprite.getdata()
    ])
    sprite = sprite.crop(sprite.getbbox())
    sprite.thumbnail(size, Image.Resampling.LANCZOS)
    x, y = origin
    scene.paste(sprite, (x + (size[0] - sprite.width) // 2, y + size[1] - sprite.height), sprite)


place_sprite("castelo_praia", (192, 90, 734, 730), (1083, 311), (67, 68))
place_sprite("concha_espiral", (222, 142, 1042, 738), (142, 937), (77, 58))
place_sprite("concha_leque", (304, 146, 963, 701), (1238, 932), (75, 65))

atlas = bytearray()
for y0, y1 in zip(rows, rows[1:]):
    for x0, x1 in zip(columns, columns[1:]):
        tile = scene.crop((x0, y0, x1, y1)).resize((32, 32), Image.Resampling.LANCZOS)
        atlas.extend(tile.convert("RGBA").tobytes("raw", "BGRA"))
(assets / "cenario_praia.bgra").write_bytes(atlas)
