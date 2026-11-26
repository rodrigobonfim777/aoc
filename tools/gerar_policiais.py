"""Gera o atlas BGRA do policial: direita, esquerda, costas e frente.

Recorta a folha original em assets/policiais-referencia.png com Pillow.
"""

from pathlib import Path

from PIL import Image, ImageChops

ASSETS = Path(__file__).resolve().parents[1] / "assets"
REFERENCE = ASSETS / "policiais-referencia.png"
SIZE = 32


def runs(projection, gap):
    groups = []
    for i, hits in enumerate(projection):
        if not hits:
            continue
        if not groups or i - groups[-1][1] > gap:
            groups.append([i, i + 1])
        else:
            groups[-1][1] = i + 1
    return groups


def extract_reference():
    sheet = Image.open(REFERENCE).convert("RGBA")
    # A legenda ocupa a coluna à esquerda da folha.
    sheet = sheet.crop((round(sheet.width * 0.193), 0, sheet.width, sheet.height))
    red, green, blue, alpha = sheet.split()
    light = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    mask = ImageChops.multiply(light.point(lambda value: 255 if value > 34 else 0),
                               alpha.point(lambda value: 255 if value > 64 else 0))
    _, vertical = mask.getprojection()
    row_boxes = runs(vertical, gap=max(2, sheet.height // 80))
    if len(row_boxes) != 4:
        raise ValueError("A folha deve ter quatro linhas de sprites separadas.")
    result = []
    for top, bottom in row_boxes:
        columns = mask.crop((0, top, sheet.width, bottom)).getprojection()[0]
        boxes = runs(columns, gap=max(2, sheet.width // 110))
        if len(boxes) != 7:
            raise ValueError("Cada linha da folha deve ter sete quadros separados.")
        frames = []
        for left, right in boxes:
            margin = max(2, sheet.width // 180)
            crop = sheet.crop((max(0, left - margin), max(0, top - margin),
                               min(sheet.width, right + margin), min(sheet.height, bottom + margin)))
            frames.append(normalize(crop))
        result.append(frames)
    return [result[3], result[2], result[0], result[1]]


def normalize(sprite):
    # A folha tem RGB residual mesmo onde o alfa é zero, além de ruído de
    # baixa opacidade. Limpa isso antes de medir e redimensionar a figura.
    alpha = sprite.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    sprite.putalpha(alpha)
    sprite = sprite.crop(alpha.getbbox())
    width = max(1, round(sprite.width * SIZE / sprite.height))
    sprite = sprite.resize((width, SIZE), Image.Resampling.BOX)
    alpha = sprite.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    sprite.putalpha(alpha)
    canvas = Image.new("RGBA", (SIZE, SIZE))
    canvas.paste(sprite, ((SIZE - width) // 2, 0), alpha)
    return canvas


def main():
    frames = extract_reference()
    atlas = Image.new("RGBA", (7 * SIZE, 4 * SIZE))
    raw = bytearray()
    for row, direction in enumerate(frames):
        for col, frame in enumerate(direction):
            atlas.paste(frame, (col * SIZE, row * SIZE))
            raw.extend(frame.tobytes("raw", "BGRA"))
    atlas.save(ASSETS / "policial_animacoes.png")
    (ASSETS / "policial_animacoes.bgra").write_bytes(raw)


if __name__ == "__main__":
    main()
