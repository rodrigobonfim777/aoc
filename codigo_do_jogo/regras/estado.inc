; Dados mutáveis da partida. As regras consultam e alteram estes valores.
fase dd 0                  ; 0 cadeia, 1 museu, 2 praia
tamanho_mapa dd 0
pos_porta dd 0
chaves_necessarias dd 0

mapa times COLS*ROWS db 0   ; copia da fase, com as algemas ainda ativas
homem dd LEFT_START         ; Pilantra
mulher dd RIGHT_START       ; Patife
chaves dd 0                 ; bit 0 = A, bit 1 = B
presos dd 0                 ; bit 0 = homem algemado, bit 1 = mulher algemada
diamante_coletado dd 0
aviso_coleta dd 0
estado dd 0                 ; 0 jogando, 1 pausa, 2 vitoria, 3 capturados
motivo_derrota dd 0         ; 1/2 guarda pegou homem/mulher; 3 ambos presos; 4 porta
; A rotina de patrulha recebe em EBP o endereco de um destes blocos.
; destino é planejado antes da animação. pos guarda a última casa confirmada
; e é o valor usado para decidir se houve captura.
struc guarda
 .pos resd 1
 .destino resd 1
 .quadros resd 1
 .origem resd 1
 .direcao resd 1
endstruc
pos_guarda dd GUARDA_INICIO
destino_guarda dd GUARDA_INICIO
quadros_guarda dd 0
origem_guarda dd GUARDA_INICIO
direcao_guarda dd 3        ; direita/esquerda/costas/frente
pos_guarda_extra dd -1
destino_guarda_extra dd -1
quadros_guarda_extra dd 0
origem_guarda_extra dd -1
direcao_guarda_extra dd 3
origem_homem dd LEFT_START
origem_mulher dd RIGHT_START
quadros_restantes dd 0
animacao_homem dd 0,0,0     ; direcao, fase da caminhada, tempo na algema
animacao_mulher dd 1,0,0
tecla_movimento dd 0
rumo_ativo dd 0
proximo_rumo dd 0
direcoes dd -COLS,-1,1,COLS

section .bss align=16
; Fila e predecessores da busca em largura. Espaço para uma entrada por casa.
fila resd COLS*ROWS
anterior resd COLS*ROWS
