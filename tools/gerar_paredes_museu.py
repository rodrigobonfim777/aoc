"""Recorta a moldura e o bloco interno do museu na resolução final da janela."""
from pathlib import Path
from PIL import Image

assets = Path(__file__).resolve().parents[1] / 'assets'
source = Image.open(assets / 'paredes_museu_referencia.png').convert('RGB')
# A perspectiva da referência deixa as colunas externas mais estreitas.
x = [0, 68, 145, 221, 297, 371, 448, 525, 600, 676, 753, 829, 906, 981, 1057, 1132, 1208, 1284, 1350, 1411]
y = [0, 76, 152, 229, 305, 382, 457, 533, 608, 683, 757, 830, 905, 980, 1057, 1115]

def bloco(col, row):
    tile = source.crop((x[col], y[row], x[col+1], y[row+1]))
    if row == 0 and col in (5, 12):
        # Inclui a ponta do estandarte na mesma casa da moldura.
        tile = source.crop((x[col], 0, x[col+1], 96))
    return tile.resize((32, 32), Image.Resampling.LANCZOS).convert('RGBA').tobytes('raw', 'BGRA')

# Ordem usada por selecionar_parede_museu: topo, rodapé, lados e bloco interno.
ordem = ([(col, row) for row in (0, 14) for col in range(19)]
         + [(col, row) for col in (0, 18) for row in range(1, 14)] + [(5, 2)])
(assets / 'paredes_museu.bgra').write_bytes(b''.join(bloco(*pos) for pos in ordem))
