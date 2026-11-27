; Uma linha da imagem = uma linha da matriz. Indice = linha*19 + coluna.
; Linha e coluna começam em zero: a casa (13, 1) tem índice 248.
; Estes mapas são moldes. A partida usa uma cópia que pode ser alterada.
; # parede, T armadilha, G grade A, a/b alavancas, D diamante,
; E porta azul (B), V vigia, H/M posicoes iniciais.
section .data align=16

mapa_inicial:
 db '###################'
 db '#T....#..D....#..T#'
 db '#..##....####G...V#'
 db '##..####.#T...###.#'
 db '#.#......#........#'
 db '#.####T..#.b###...#'
 db '#....###.#.#....#.#'
 db '####.....#.#....#.#'
 db '#..#G#####...###T.#'
 db '#.#T.#a..#.#......#'
 db '#.#..###.#..#.#.#.#'
 db '#.#....#.#.#..#..##'
 db '#...##...#.#.#.#..#'
 db '#H.....#.E.......M#'
 db '###################'

; Museu: s123 fossil, 4567 esfinge, IJKL Pensador, NOPQ mesa (todos 2x2).
; Paredes, cordoes, algemas e alavanca seguem a referencia do museu.
mapa_museu:
 db '###################'
 db '#s1......D........#'
 db '#23..#.#.#.......V#'
 db '#..#c#.#.#.....NO.#'
 db '#..###.#.#.#c#.PQ.#'
 db 'v....#T..#.###.cc.#'
 db '#.##.###.#........#'
 db '#........#.#.#.#..#'
 db '#..#######c#.#b#..#'
 db '#.#.....T###.###..#'
 db '#.#.IJ#..#....T...#'
 db '#...KL#.c#.#.#.#..#'
 db '#..###T..#.###.#45#'
 db '#p.H.....E.....M67#'
 db '###################'

; Praia: u = palmeira, q = pranchas, k = castelo de areia, f = caixote.
mapa_praia:
 db '###################'
 db '#u.......D.....q.u#'
 db '#V.###...#.###...V#'
 db '#..#T#.#.#..#.....#'
 db '#.#....#.##.#..k..#'
 db '#.#f.#...#..###.#.#'
 db '#.####.###......#.#'
 db '#T.....#.#.#.#....#'
 db '#.####.#.#.#b#.#T.#'
 db '#.#......#.###.#..#'
 db '#.#.####.#....#T..#'
 db '#.#T.....##.##.##.#'
 db '#u.##.##.#..f#T..u#'
 db '#H.......E.......M#'
 db '###################'

; Mapa, posicoes de Pilantra/Patife/guarda, tamanho, porta e chaves.
; Cada registro tem sete valores de 4 bytes. reiniciar usa essa largura
; para localizar a configuração de cada fase pelo seu número.
fases:
 dd mapa_inicial,LEFT_START,RIGHT_START,GUARDA_INICIO,15*COLS,13*COLS+9,3
 dd mapa_museu,13*COLS+3,13*COLS+15,GUARDA_INICIO,15*COLS,13*COLS+9,2
 dd mapa_praia,LEFT_START,RIGHT_START,GUARDA_INICIO,15*COLS,13*COLS+9,2
