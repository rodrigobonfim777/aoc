"""Incorpora os recursos visuais no executável, sem depender de NASM."""

import struct
from pathlib import Path


ASSETS = Path(__file__).resolve().parents[1] / 'assets'
BGRA = {
    'patife': 'patife_animacoes',
    'pilantra': 'pilantra_animacoes',
    'policial': 'policial_animacoes',
    **{name: name for name in (
        'paredes_museu', 'paredes_cadeia', 'diamante_azul', 'diamante_roxo',
        'diamante_verde', 'vitrine_vazia', 'dinossauro_museu', 'esfinge_museu',
        'dinossauro_museu_detalhado', 'esfinge_museu_detalhado', 'pensador_museu',
        'mesa_museu', 'pensador_museu_detalhado', 'mesa_museu_detalhado',
        'porta_azul_fechada', 'porta_azul_aberta', 'porta_azul_fechada_detalhado',
        'porta_azul_aberta_detalhado', 'pedra_diamante', 'algema_detalhada',
        'piso_esquerdo', 'piso_direito', 'tiles_icones', 'tiles_museu', 'tiles_praia',
    )},
}
FONTES = {'fonte_normal': 'fonte5x7.bin', 'fonte_pequena': 'fonte4x6.bin'}


def embutir_arte(pasta):
    # Produz arquivos temporários para o C++; nada é carregado de assets ao jogar.
    header = pasta / 'arte_embutida.hpp'
    source = pasta / 'arte_embutida.cpp'
    arquivos = [(name, f'{file}.bgra', 'std::uint32_t', '<I') for name, file in BGRA.items()]
    arquivos += [(name, file, 'std::uint8_t', '<B') for name, file in FONTES.items()]
    with header.open('w', encoding='ascii') as h, source.open('w', encoding='ascii') as s:
        h.write('#pragma once\n#include <cstdint>\nnamespace arte {\n')
        s.write('#include "arte_embutida.hpp"\nnamespace arte {\n')
        for name, file, tipo, formato in arquivos:
            # BGRA vira um inteiro little-endian; os bytes da fonte ficam separados.
            pixels = [valor for (valor,) in struct.iter_unpack(formato, (ASSETS / file).read_bytes())]
            h.write(f'extern const {tipo} {name}[{len(pixels)}];\n')
            s.write(f'const {tipo} {name}[] = {{\n')
            for i in range(0, len(pixels), 12):
                s.write('    ' + ', '.join(hex(v) for v in pixels[i:i + 12]) + ',\n')
            s.write('};\n')
        h.write('}\n')
        s.write('}\n')
    return source
