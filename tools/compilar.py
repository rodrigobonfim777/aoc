"""Compila o jogo x86 para Windows com NASM e MinGW de 32 bits."""

import argparse
import re
import shutil
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory
from arte import embutir_arte


ROOT = Path(__file__).resolve().parents[1]


def compilar():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--entrega', action='store_true', help='desativa F1, F2 e F3')
    parser.add_argument('--compilador', default='g++', help='compilador MinGW de 32 bits')
    parser.add_argument('--saida', type=Path, default=ROOT / 'Patife e Pilantra.exe')
    args = parser.parse_args()

    nasm = shutil.which('nasm')
    cpp = shutil.which(args.compilador)
    if not nasm or not cpp:
        parser.error('Coloque NASM e MinGW no PATH.')
    alvo = subprocess.check_output([cpp, '-dumpmachine'], text=True).strip()
    if not re.fullmatch(r'mingw32|i[3-6]86-.*(?:mingw32|windows-gnu)', alvo):
        parser.error('Use MinGW de 32 bits, por exemplo --compilador i686-w64-mingw32-g++.')

    with TemporaryDirectory(prefix='aoc-compilar-') as temp:
        pasta = Path(temp)
        objeto = pasta / 'jogo.obj'
        exe = pasta / 'jogo.exe'
        arte = embutir_arte(pasta)
        # O NASM gera um objeto x86. O MinGW junta o objeto, o C++ e a arte.
        subprocess.run([nasm, '-f', 'win32', '-I', 'codigo_do_jogo/regras/',
                        f'-dATALHOS_TESTE={int(not args.entrega)}',
                        'codigo_do_jogo/regras/jogo.asm', '-o', str(objeto)], cwd=ROOT, check=True)
        subprocess.run([cpp, '-std=c++11', '-O2', '-Wall', '-Wextra', '-Wpedantic',
                        '-mwindows', '-static', '-Wl,--no-insert-timestamp',
                        '-I', temp, 'codigo_do_jogo/visual/visual.cpp', 'codigo_do_jogo/visual/cena.cpp', str(arte),
                        str(objeto), '-lgdi32', '-lwinmm', '-o', str(exe)],
                       cwd=ROOT, check=True)
        shutil.copyfile(exe, args.saida)
    print(f'Compilado em: {args.saida}')


if __name__ == '__main__':
    compilar()
