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
 db '#s1......D....##.T#'
 db '#23V.#.#.##.##....#'
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

; Praia: u palmeira, q pranchas, k castelo de areia, o concha.
mapa_praia:
 db '###################'
 db '#u.......D.....q.u#'
 db '#u.###...#.###..Vu#'
 db '#..#T#.#.#..#.....#'
 db '#.#....#.##.#.k...#'
 db '#.#b.#...#..###.#.#'
 db '#.####.###......#.#'
 db '#T.....#.#.#.#....#'
 db '#.####.#.#.#.#.#..#'
 db '#.#......#.###.#..#'
 db '#.#.####.#....#T..#'
 db '#.#T.....##.##.##.#'
 db '#.o##.##.#...#T.o.#'
 db '#H.......E.......M#'
 db '###################'

; Bonus: x/y/z diamantes azul/roxo/verde; C vitrine da coroa.
mapa_bonus:
 db '###################'
 db '#........C......x.#'
 db '#.###.##.#.####...#'
 db '#........#...#..#.#'
 db '###y#.##.#..z#....#'
 db '#...#....#.#...##.#'
 db '#.#...#.##...#.y..#'
 db '#.#.x.#..###.#.#..#'
 db '#...#...##...#....#'
 db '#.###z#..#.#...#..#'
 db '#...#.#..#.###....#'
 db '#.#......#.....#z.#'
 db '#.#.###..#.##..#..#'
 db '#H...y...#.x.....M#'
 db '###################'

; Mapa, posicoes de Pilantra/Patife/guarda, tamanho, porta e chaves.
; Cada registro tem sete valores de 4 bytes; reiniciar usa essa largura.
fases:
 dd mapa_inicial,LEFT_START,RIGHT_START,GUARDA_INICIO,15*COLS,13*COLS+9,3
 dd mapa_museu,13*COLS+3,13*COLS+15,GUARDA_MUSEU_ESQUERDA,15*COLS,13*COLS+9,2
 dd mapa_praia,LEFT_START,RIGHT_START,GUARDA_PRAIA_DIREITA,15*COLS,13*COLS+9,2
 dd mapa_bonus,LEFT_START,RIGHT_START,-1,15*COLS,-1,0
