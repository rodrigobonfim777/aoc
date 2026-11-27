"""Recorta as duas folhas da dupla e exporta quadros BGRA de 32 x 32."""

from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps


ASSETS = Path(__file__).resolve().parents[1] / 'assets'
SIZE = 32
# Coordenadas relativas a imagem original (1448 x 1086).
REFERENCE_SIZE = (1448, 1086)
MOTION_ROWS = ((256, 429), (475, 642), (690, 850), (901, 1070))
MOTION_COLUMNS = ((94, 231, 369, 506, 647), (812, 955, 1092, 1230, 1382))
TRAP_ROWS = ((473, 654), (750, 960))
TRAP_COLUMNS = ((15, 184, 355, 528, 704), (741, 911, 1081, 1256, 1440))


def trim_background(sprite):
    """Limpa o fundo escuro ligado a borda sem remover os contornos internos."""
    pixels = sprite.load()
    width, height = sprite.size
    queue = deque([(x, y) for x in range(width) for y in (0, height - 1)]
                  + [(x, y) for y in range(height) for x in (0, width - 1)])
    seen = set()
    while queue:
        x, y = queue.popleft()
        if not (0 <= x < width and 0 <= y < height) or (x, y) in seen:
            continue
        seen.add((x, y))
        red, green, blue, alpha = pixels[x, y]
        if alpha >= 128 and max(red, green, blue) > 23:
            continue
        pixels[x, y] = (0, 0, 0, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    bounds = sprite.getbbox()
    if bounds is None:
        raise ValueError('Quadro vazio na folha.')
    return sprite.crop(bounds)


def read_sheet(filename, rows, columns):
    with Image.open(ASSETS / filename) as image:
        sheet = image.convert('RGBA')
    sx = sheet.width / REFERENCE_SIZE[0]
    sy = sheet.height / REFERENCE_SIZE[1]
    return [
        [
            [trim_background(sheet.crop((round(a * sx), round(top * sy),
                                          round(b * sx), round(bottom * sy))))
             for a, b in zip(edges, edges[1:])]
            for top, bottom in rows
        ]
        for edges in columns
    ]


def normalize_rows(rows, match_guard_height=False):
    # As poses de algema mantêm a escala comum, inclusive quando o ator se abaixa.
    scale = min(SIZE / max(frame.width for row in rows for frame in row),
                SIZE / max(frame.height for row in rows for frame in row))
    for row in rows:
        for frame in row:
            if match_guard_height:
                # A altura visível do policial é de 32 pixels em todos os quadros.
                # Mede a silhueta opaca para não contar resíduos transparentes.
                alpha = frame.getchannel('A').point(lambda v: 255 if v >= 128 else 0)
                frame = frame.crop(alpha.getbbox())
                frame_scale = min(SIZE / frame.width, SIZE / frame.height)
            else:
                frame_scale = scale
            width = max(1, round(frame.width * frame_scale))
            height = max(1, round(frame.height * frame_scale))
            sprite = frame.resize((width, height), Image.Resampling.BOX)
            alpha = sprite.getchannel('A').point(lambda v: 255 if v >= 128 else 0)
            sprite.putalpha(alpha)
            canvas = Image.new('RGBA', (SIZE, SIZE))
            canvas.paste(sprite, ((SIZE - width) // 2, SIZE - height), alpha)
            # Recupera pequenos trechos escuros da roupa e da máscara removidos
            # junto com o fundo preto, preservando as proporções de cada pose.
            alpha = ImageOps.expand(canvas.getchannel('A'), border=2)
            silhouette = alpha.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
            outline = Image.new('RGBA', canvas.size, (22, 21, 29))
            outline.putalpha(silhouette.crop((2, 2, SIZE + 2, SIZE + 2)))
            restored = Image.alpha_composite(outline, canvas)
            # Nas pernas, mantenha o espaço entre os pés da referência. Levante
            # as sombras do tecido sem clarear a pele ou os detalhes das algemas.
            for y in range(SIZE - height // 3, SIZE):
                for x in range((SIZE - width) // 2, (SIZE - width) // 2 + width):
                    red, green, blue, opacity = canvas.getpixel((x, y))
                    if not opacity:
                        restored.putpixel((x, y), (0, 0, 0, 0))
                    elif max(red, green, blue) < 110 and max(red, green, blue) - min(red, green, blue) < 35:
                        lift = (110 - max(red, green, blue)) // 3
                        restored.putpixel((x, y), (red + lift, green + lift, blue + lift, opacity))
            yield restored


def main():
    motion = read_sheet('personagens-movimento-referencia.png', MOTION_ROWS, MOTION_COLUMNS)
    trap = read_sheet('personagens-algemas-referencia.png', TRAP_ROWS, TRAP_COLUMNS)
    for name, walking, trapped in zip(('pilantra', 'patife'), motion, trap):
        # Ordem do jogo: direita, esquerda, costas, frente, queda, preso.
        directions = [walking[index] for index in (3, 2, 0, 1)]
        trap_rows = [trapped[1], trapped[0]]
        frames = list(normalize_rows(directions, match_guard_height=True))
        frames += list(normalize_rows(trap_rows))
        atlas = Image.new('RGBA', (4 * SIZE, 6 * SIZE))
        for index, frame in enumerate(frames):
            atlas.paste(frame, ((index % 4) * SIZE, (index // 4) * SIZE))
        atlas.save(ASSETS / f'{name}_animacoes.png')
        (ASSETS / f'{name}_animacoes.bgra').write_bytes(
            b''.join(frame.tobytes('raw', 'BGRA') for frame in frames))


if __name__ == '__main__':
    main()
