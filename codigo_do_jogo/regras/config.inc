; Um passo vertical muda o índice em COLS. Um passo horizontal muda em 1.
; A borda do mapa impede que o movimento ultrapasse a matriz.
%define COLS 19
%define ROWS 15
%define LEFT_START (13*COLS+1)
; Casa livre junto ao canto superior direito (evita a algema/palmeira da linha 1).
%define GUARDA_INICIO (2*COLS+17)
%define GUARDA_MUSEU_ESQUERDA (2*COLS+3)
%define GUARDA_PRAIA_DIREITA (2*COLS+16)
%define RIGHT_START (13*COLS+17)
; Duração de um passo em ticks. Cada tick é solicitado a cada 16 ms.
%define QUADROS_PASSO 7
%define QUADROS_GUARDA 40
%define INTERVALO_QUADRO 16
%define QUADROS_PERSONAGEM 4
%define FASE_PRAIA 2
%define FASE_BONUS 3
%define TOTAL_FASES 4
%define MENU_FASES 4

; Geometria lógica do menu. O clique chega em coordenadas 2x da janela.
%define BOTAO_X 52
%define BOTAO_Y 80
%define BOTAO_LARGURA (COLS*16-2*BOTAO_X)
%define BOTAO_ALTURA 24
%define BOTAO_PASSO 32

; TEMPORARIO: F1-F4 ficam ativos durante o desenvolvimento.
; Na entrega final, compile com -dATALHOS_TESTE=0.
%ifndef ATALHOS_TESTE
 %define ATALHOS_TESTE 1
%endif

; Paredes, joia e decoracoes bloqueiam a dupla e o guarda.
; %1 é o caractere da casa, %2 é o rótulo para onde saltar se ela for sólida.
; Portas, grades e armadilhas são tratados à parte pelo chamador.
%macro bloquear_casa_solida 2
 cmp %1,'#'
 je %2
 cmp %1,'D'
 je %2
 cmp %1,'C'
 je %2
 cmp %1,'a'
 je %2
 cmp %1,'b'
 je %2
 cmp %1,'s'
 je %2
 cmp %1,'1'
 je %2
 cmp %1,'2'
 je %2
 cmp %1,'3'
 je %2
 cmp %1,'4'
 je %2
 cmp %1,'5'
 je %2
 cmp %1,'6'
 je %2
 cmp %1,'7'
 je %2
 cmp dword [fase],1
 jne %%outras_decoracoes
 cmp %1,'I'
 jb %%outras_decoracoes
 cmp %1,'L'
 jbe %2
 cmp %1,'N'
 jb %%outras_decoracoes
 cmp %1,'Q'
 jbe %2
%%outras_decoracoes:
 cmp %1,'p'
 je %2
 cmp %1,'v'
 je %2
 cmp %1,'c'
 je %2
 cmp %1,'f'
 je %2
 cmp %1,'u'
 je %2
 cmp %1,'q'
 je %2
 cmp %1,'k'
 je %2
 cmp %1,'o'                 ; concha da praia
 je %2
%endmacro
