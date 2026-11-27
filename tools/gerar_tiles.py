"""Converte os atlas PNG editáveis em BGRA para a compilação do jogo."""

from pathlib import Path

from PIL import Image


ASSETS = Path(__file__).resolve().parents[1] / 'assets'


def main():
    for nome, total in (('icones', 5), ('museu', 7), ('praia', 7)):
        raiz = ASSETS / f'tiles_{nome}'
        with Image.open(raiz.with_suffix('.png')) as imagem:
            # A ordem dos blocos de cima para baixo corresponde aos índices de cena.cpp.
            if imagem.size != (16, total * 16):
                raise ValueError(f'{nome}: esperado um atlas vertical de {total} blocos de 16×16')
            dados = imagem.convert('RGBA').tobytes('raw', 'BGRA')
        raiz.with_suffix('.bgra').write_bytes(dados)


if __name__ == '__main__':
    main()
