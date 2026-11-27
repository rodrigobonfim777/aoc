; Entrada do NASM: reúne os módulos em um único objeto x86.
; Leia mapas.inc para entender a grade; depois siga teclado -> mover
; ou teclado -> interagir. O C++ acessa o jogo pelas funções de interface.inc.
bits 32

%include "config.inc"
%include "mapas.inc"
%include "estado.inc"
%include "interface.inc"
%include "fases.inc"
%include "movimento.inc"
%include "guardas.inc"
%include "interacao.inc"
%include "avisos.inc"

section .rdata align=4
global _musica_pcm, _musica_bytes
_musica_pcm: incbin "assets/audioAoc.s16le"
_musica_bytes: dd $ - _musica_pcm
