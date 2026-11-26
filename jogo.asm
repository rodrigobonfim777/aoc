; Patife e Pilantra. NASM, x86 de 32 bits, Win32.
%include "pe.inc"
%define COLS 19
%define ROWS 15
%define WIDTH 304
%define HEIGHT 276
%define LEFT_START (13*COLS+1)
%define GUARDA_INICIO (2*COLS+17)
%define RIGHT_START (13*COLS+17)
%define QUADROS_PASSO 12
%define QUADROS_GUARDA 44
%define INTERVALO_QUADRO 16
%define MAX_COMANDOS 16
%define QUADROS_PERSONAGEM 4
%define QUADROS_POLICIAL 7
%define TEMPO_QUEDA_ALGEMA 16
%define TAMANHO_ATOR 32
%define BYTES_QUADRO_ATOR (TAMANHO_ATOR*TAMANHO_ATOR*4)
%define TOTAL_FASES 3

; TEMPORARIO: F1-F3 ficam ativos durante o desenvolvimento.
; Na entrega final, compile com -dATALHOS_TESTE=0.
%ifndef ATALHOS_TESTE
 %define ATALHOS_TESTE 1
%endif

; Paredes, joia e decoracoes bloqueiam a dupla e o guarda.
%macro bloquear_casa_solida 2
 cmp %1,'#'
 je %2
 cmp %1,'D'
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
%endmacro

; Uma linha da imagem = uma linha da matriz. Indice = linha*19 + coluna.
; # parede, T armadilha, G grade A, a/b alavancas, D diamante,
; E porta azul (B), V vigia, H/M posicoes iniciais.
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

; Museu: s123 = fossil 2x2, 4567 = esfinge 2x2; p quadro, v vaso, c cordao.
mapa_museu:
 db '###################'
 db '#s1......D........#'
 db '#23....#.#......Tp#'
 db '#..#c#.#.#.#c#.#..#'
 db '#..###.#.#.###.#.##'
 db 'v....#T..#V.......#'
 db '#.##.###.#.#.#.#..#'
 db '#........#c#.#b#..#'
 db '#..#########.###..#'
 db '#.T......#....T...#'
 db '#.######.#.#.#.#..#'
 db '#........#........#'
 db '#....c...#.###.#45#'
 db '#p.H.....E.....M67#'
 db '###################'

; Praia: u = palmeira, q = pranchas, k = castelo de areia, f = caixote.
mapa_praia:
 db '###################'
 db '#u.......D.....q.u#'
 db '#..###...#.###....#'
 db '#..#T#.#.#..#.....#'
 db '#.#.V..#.##.#..k..#'
 db '#.#f.#...#..###.#.#'
 db '#.####.###.....V#.#'
 db '#T.....#.#.#.#....#'
 db '#.####.#.#.#b#.#T.#'
 db '#.#......#.###.#..#'
 db '#.#.####.#....#T..#'
 db '#.#T.....##.##.##.#'
 db '#u.##.##.#..f#T..u#'
 db '#H.......E.......M#'
 db '###################'

; Mapa, posicoes de Pilantra/Patife/guarda, tamanho, porta, chaves e margem vertical.
fases:
 dd mapa_inicial,LEFT_START,RIGHT_START,GUARDA_INICIO,15*COLS,13*COLS+9,3,0
 dd mapa_museu,13*COLS+3,13*COLS+15,5*COLS+10,15*COLS,13*COLS+9,2,0
 dd mapa_praia,LEFT_START,RIGHT_START,4*COLS+4,15*COLS,13*COLS+9,2,0
fase dd 0                  ; 0 cadeia, 1 museu, 2 praia
tamanho_mapa dd 0
pos_porta dd 0
chaves_necessarias dd 0
margem_mapa dd 0

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
comandos_inicio dd 0
comandos_fim dd 0
comandos_quantidade dd 0
direcoes dd -COLS,-1,1,COLS
janela dd 0
dc dd 0
indice dd 0
classe db 'PatifePilantraAOC',0
titulo db 'Patife e Pilantra',0
align 4
wc dd 3,procedimento,0,0,0,0,0,0,0,classe
area dd 0,0,WIDTH*2,HEIGHT*2
bmi dd 40,WIDTH*2,-HEIGHT*2
 dw 1,32
 times 6 dd 0

; Dados alterados pelo jogo ficam fora das paginas de instrucoes.
; Isso evita travamentos na traducao x86 do Wine/Rosetta apos redesenhar.
align 4096,db 0
start:
 call reiniciar
 pcall GetModuleHandleA,0
 mov [wc+16],eax
 pcall LoadCursorA,0,32512
 mov [wc+24],eax
 pcall RegisterClassA,wc
 pcall AdjustWindowRect,area,0xca0000,0
 mov eax,[area+8]
 sub eax,[area]
 mov edx,[area+12]
 sub edx,[area+4]
 pcall CreateWindowExA,0,classe,titulo,0xca0000,0x80000000,0x80000000,eax,edx,0,0,[wc+16],0
 test eax,eax
 jz .erro
 mov [janela],eax
 pcall ShowWindow,eax,5
 pcall SetTimer,[janela],1,INTERVALO_QUADRO,0
 test eax,eax
 jz .erro
.mensagens:
 pcall GetMessageA,msg,0,0,0
 test eax,eax
 jle .fim
 pcall TranslateMessage,msg
 pcall DispatchMessageA,msg
 jmp .mensagens
.erro:
 pcall ExitProcess,1
.fim:
 pcall ExitProcess,0

procedimento:
 push ebp
 mov ebp,esp
 push ebx
 push esi
 push edi
 mov eax,[ebp+12]           ; mensagem do Windows
 cmp eax,2                  ; WM_DESTROY
 je .sair
 cmp eax,15                 ; WM_PAINT
 je .pintar
 cmp eax,275                ; WM_TIMER
 je .animar
 cmp eax,257                ; WM_KEYUP
 je .soltar
 cmp eax,256                ; WM_KEYDOWN
 jne .padrao
 test dword [ebp+20],1<<30   ; repeticao continua e controlada pelo timer
 jnz .zero
 mov eax,[ebp+16]           ; codigo da tecla
 call teclado
 pcall InvalidateRect,[ebp+8],0,0
 jmp .zero
.soltar:
 mov eax,[ebp+16]
 cmp eax,[tecla_movimento]
 jne .zero
 mov dword [tecla_movimento],0
 jmp .zero
.animar:
 cmp dword [ebp+16],1
 jne .padrao
 call avancar_animacao
 push eax
 call atualizar_guarda
 pop edx
 or eax,edx
 test eax,eax
 jz .zero
 pcall InvalidateRect,[ebp+8],0,0
 jmp .zero
.pintar:
 pcall BeginPaint,[ebp+8],paint
 mov [dc],eax
 call desenhar
 pcall EndPaint,[ebp+8],paint
 jmp .zero
.sair:
 pcall KillTimer,[ebp+8],1
 pcall PostQuitMessage,0
.zero:
 xor eax,eax
 jmp .voltar
.padrao:
 pcall DefWindowProcA,[ebp+8],[ebp+12],[ebp+16],[ebp+20]
.voltar:
 pop edi
 pop esi
 pop ebx
 pop ebp
 ret 16

teclado:
%if ATALHOS_TESTE
 lea edx,[eax-0x70]         ; VK_F1 ... VK_F3
 cmp edx,TOTAL_FASES
 jb .fase_teste
%endif
 cmp eax,'R'
 je reiniciar
 cmp eax,13
 je proxima_fase
 cmp eax,'P'
 jne .jogar
 test dword [ebp+20],1<<30 ; segurar P nao deve alternar repetidamente
 jnz .fim
 cmp dword [estado],1
 ja .fim
 xor dword [estado],1
 ret
.jogar:
 cmp dword [estado],0
 jne .fim
 cmp eax,32
 je interagir
 mov edx,-COLS
 cmp eax,38
 je .direcao
 cmp eax,'W'
 je .direcao
 mov edx,COLS
 cmp eax,40
 je .direcao
 cmp eax,'S'
 je .direcao
 mov edx,-1
 cmp eax,37
 je .direcao
 cmp eax,'A'
 je .direcao
 mov edx,1
 cmp eax,39
 je .direcao
 cmp eax,'D'
 je .direcao
.fim:
 ret

.direcao:
 mov [tecla_movimento],eax
 mov [rumo_ativo],edx
 jmp mover

%if ATALHOS_TESTE
.fase_teste:
 mov [fase],edx
 jmp reiniciar
%endif

proxima_fase:
 cmp dword [estado],2
 jne .fim
 cmp dword [fase],TOTAL_FASES-1
 jae .fim
 inc dword [fase]
 jmp reiniciar
.fim:
 ret

reiniciar:
 push esi
 push edi
 push ecx
 mov eax,[fase]
 shl eax,5
 add eax,fases
 mov esi,[eax]
 mov edi,mapa
 mov ecx,[eax+16]
 mov [tamanho_mapa],ecx
 rep movsb
 pop ecx
 pop edi
 pop esi
 mov edx,[eax+20]
 mov [pos_porta],edx
 mov edx,[eax+24]
 mov [chaves_necessarias],edx
 mov edx,[eax+28]
 mov [margem_mapa],edx
 mov edx,[eax+12]
 mov [pos_guarda],edx
 mov [origem_guarda],edx
 mov [destino_guarda],edx
 mov dword [quadros_guarda],0
 mov dword [direcao_guarda],3
 mov edx,-1
 cmp dword [fase],2
 jne .guarda_extra
 mov edx,6*COLS+15
.guarda_extra:
 mov [pos_guarda_extra],edx
 mov [origem_guarda_extra],edx
 mov [destino_guarda_extra],edx
 mov dword [quadros_guarda_extra],0
 mov dword [direcao_guarda_extra],3
 mov edx,[eax+4]
 mov [homem],edx
 mov [origem_homem],edx
 mov edx,[eax+8]
 mov [mulher],edx
 mov [origem_mulher],edx
 mov dword [chaves],0
 mov dword [presos],0
 mov dword [diamante_coletado],0
 mov dword [aviso_coleta],0
 mov dword [estado],0
 mov dword [motivo_derrota],0
 mov dword [quadros_restantes],0
 mov dword [animacao_homem],0
 mov dword [animacao_homem+4],0
 mov dword [animacao_homem+8],0
 mov dword [animacao_mulher],1
 mov dword [animacao_mulher+4],0
 mov dword [animacao_mulher+8],0
 mov dword [tecla_movimento],0
 mov dword [rumo_ativo],0
 mov dword [comandos_inicio],0
 mov dword [comandos_fim],0
 mov dword [comandos_quantidade],0
 ret

mover:
 cmp dword [quadros_restantes],0
 je iniciar_passo
 ; Enfileira toques durante a transicao, sem repetir eventos do teclado.
 cmp dword [comandos_quantidade],MAX_COMANDOS
 jae .fim
 mov eax,[comandos_fim]
 mov [fila_comandos+eax*4],edx
 inc eax
 and eax,MAX_COMANDOS-1
 mov [comandos_fim],eax
 inc dword [comandos_quantidade]
.fim:
 ret

iniciar_passo:
 mov eax,[homem]
 mov [origem_homem],eax
 mov eax,[mulher]
 mov [origem_mulher],eax
 call executar_passo
 mov eax,[origem_homem]
 cmp eax,[homem]
 jne .limpar_aviso
 mov eax,[origem_mulher]
 cmp eax,[mulher]
 je .animacao
.limpar_aviso:
 mov dword [aviso_coleta],0
.animacao:
 mov eax,[origem_homem]
 mov ebx,[homem]
 mov edx,animacao_homem
 call atualizar_direcao
 mov eax,[origem_mulher]
 mov ebx,[mulher]
 mov edx,animacao_mulher
 call atualizar_direcao
 mov dword [quadros_restantes],QUADROS_PASSO
 ret

; EAX = origem, EBX = destino, EDX = dados de animacao do personagem.
; A fase de caminhada so avanca quando houve deslocamento.
atualizar_direcao:
 mov ecx,ebx
 sub ecx,eax
 jz .fim
 cmp ecx,1
 je .direita
 cmp ecx,-1
 je .esquerda
 cmp ecx,-COLS
 je .costas
 mov ecx,3
 jmp .gravar
.direita:
 xor ecx,ecx
 jmp .gravar
.esquerda:
 mov ecx,1
 jmp .gravar
.costas:
 mov ecx,2
.gravar:
 mov [edx],ecx
 mov ecx,[edx+4]
 add ecx,2
 and ecx,QUADROS_PERSONAGEM-1
 mov [edx+4],ecx
.fim:
 ret

; EAX retorna 1 quando um tick muda a imagem. A pausa congela a transicao.
avancar_animacao:
 push ebx
 xor ebx,ebx
 cmp dword [estado],1
 je .fim
 cmp dword [estado],0
 jne .movimento
 test dword [presos],1
 jz .animar_patife
 inc dword [animacao_homem+8]
 test dword [animacao_homem+8],3
 jnz .animar_patife
 mov ebx,1
.animar_patife:
 test dword [presos],2
 jz .movimento
 inc dword [animacao_mulher+8]
 test dword [animacao_mulher+8],3
 jnz .movimento
 mov ebx,1
.movimento:
 cmp dword [quadros_restantes],0
 je .comando
 dec dword [quadros_restantes]
 mov ebx,1
 jnz .fim
.comando:
 cmp dword [estado],0
 jne .fim
 cmp dword [comandos_quantidade],0
 jne .retirar
 cmp dword [tecla_movimento],0
 je .fim
 mov edx,[rumo_ativo]
 jmp .iniciar
.retirar:
 mov eax,[comandos_inicio]
 mov edx,[fila_comandos+eax*4]
 inc eax
 and eax,MAX_COMANDOS-1
 mov [comandos_inicio],eax
 dec dword [comandos_quantidade]
.iniciar:
 call iniciar_passo
 mov ebx,1
.fim:
 mov eax,ebx
 pop ebx
 ret

; Atualiza a patrulha a cada tick, mesmo com a dupla parada.
; Posicao logica so e confirmada ao terminar a transicao visual.
atualizar_guarda:
 pushad
 mov ebp,pos_guarda
 call atualizar_um_guarda
 mov [esp+28],eax
 cmp dword [pos_guarda_extra],-1
 je .fim
 mov ebp,pos_guarda_extra
 call atualizar_um_guarda
 or [esp+28],eax
.fim:
 popad
 ret

atualizar_um_guarda:
 push dword 0               ; redesenha tambem se o guarda acabou de parar
 cmp dword [estado],0
 jne .parado
 cmp dword [ebp+guarda.quadros],0
 je .iniciar
 dec dword [ebp+guarda.quadros]
 jnz .transicao
 mov eax,[ebp+guarda.destino]
 cmp eax,[ebp+guarda.origem]
 setne byte [esp]
 mov [ebp+guarda.pos],eax
.iniciar:
 call verificar_captura_guarda
 cmp dword [estado],0
 jne .mudou
 mov eax,[ebp+guarda.pos]
 mov [ebp+guarda.origem],eax
 mov [ebp+guarda.destino],eax
 call perseguir
 mov eax,[ebp+guarda.destino]
 sub eax,[ebp+guarda.origem]
 jz .duracao
 call direcao_do_deslocamento
 mov [ebp+guarda.direcao],ecx
.duracao:
 mov dword [ebp+guarda.quadros],QUADROS_GUARDA
.transicao:
 mov eax,[ebp+guarda.origem]
 cmp eax,[ebp+guarda.destino]
 je .parado
.mudou:
 add esp,4
 mov eax,1
 ret
.parado:
 pop eax
 ret

verificar_captura_guarda:
 mov eax,[ebp+guarda.pos]
 cmp eax,[homem]
 je .homem
 cmp eax,[mulher]
 jne .fim
 mov eax,2
 jmp encerrar_derrota
.homem:
 mov eax,1
 jmp encerrar_derrota
.fim:
 ret

executar_passo:
 mov esi,homem
 call tentar_passo
 cmp dword [estado],0
 jne .fim
 cmp edx,1
 je .espelhar
 cmp edx,-1
 jne .direita
.espelhar:
 neg edx                    ; so o deslocamento horizontal muda de sinal
.direita:
 mov esi,mulher
 call tentar_passo
.fim:
 ret

tentar_passo:
 mov ebx,1
 cmp esi,homem
 je .verificar_preso
 mov ebx,2
.verificar_preso:
 test [presos],ebx
 jnz .fim
 call virar_personagem      ; vira antes de testar a parede ou outro obstaculo
 mov eax,[esi]
 add eax,edx
 mov cl,[mapa+eax]
 bloquear_casa_solida cl,.fim
 cmp cl,'E'
 jne .grade
 test dword [chaves],2
 jz .fim
 jmp .entrar
.grade:
 cmp cl,'G'
 jne .entrar
 test dword [chaves],1
 jz .fim
.entrar:
 mov [esi],eax
 cmp eax,[pos_guarda]
 je .guarda
 cmp eax,[pos_guarda_extra]
 je .guarda
 cmp cl,'T'
 jne .fim
 ; Entrar na algema ocupada pelo parceiro preso e um resgate.
 ; O socorrista nao deve ser preso pela mesma casa nessa entrada.
 mov ecx,homem
 cmp esi,mulher
 je .parceiro
 mov ecx,mulher
.parceiro:
 cmp eax,[ecx]
 jne .prender
 mov ecx,ebx
 xor ecx,3                  ; bit do outro personagem
 test [presos],ecx
 jz .prender
 mov byte [mapa+eax],'.'     ; a algema usada desaparece apos o resgate
 not ecx
 and [presos],ecx
 ret
.prender:
 or [presos],ebx
 cmp esi,homem
 jne .prender_patife
 mov dword [animacao_homem+8],0
 jmp .verificar_derrota
.prender_patife:
 mov dword [animacao_mulher+8],0
.verificar_derrota:
 ; Se B estiver desligada, a captura da Patife tem prioridade.
 test dword [presos],2
 jz .verificar_dupla_presa
 test dword [chaves],2
 jnz .verificar_dupla_presa
 mov eax,4
 jmp encerrar_derrota
.verificar_dupla_presa:
 cmp dword [presos],3
 jne .fim
 mov eax,3
 jmp encerrar_derrota
.guarda:
 mov eax,1
 cmp esi,homem
 je .derrota
 mov eax,2
.derrota:
 jmp encerrar_derrota
.fim:
 ret

; ESI = personagem, EDX = comando (ja espelhado para a Patife).
; Conserva o comando e a mascara de prisao usados por tentar_passo.
virar_personagem:
 push eax
 push ecx
 mov ecx,animacao_homem
 cmp esi,homem
 je .direcao
 mov ecx,animacao_mulher
.direcao:
 xor eax,eax
 cmp edx,1
 je .gravar
 mov eax,1
 cmp edx,-1
 je .gravar
 mov eax,2
 cmp edx,-COLS
 je .gravar
 mov eax,3
.gravar:
 mov [ecx],eax
 pop ecx
 pop eax
 ret

; Registra a primeira causa; a caixa e desenhada dentro do jogo.
encerrar_derrota:
 cmp dword [estado],0
 jne .fim
 mov [motivo_derrota],eax
 mov dword [estado],3
.fim:
 ret

interagir:
 mov dword [aviso_coleta],0
 call resgatar
 mov eax,[homem]
 call acionar_alavanca
 mov eax,[mulher]
 call acionar_alavanca
 call coletar_diamante
 jmp verificar_fuga

; Qualquer um dos dois personagens pode acionar A ou B.
; EAX = posicao do personagem. Alcanca a alavanca a esquerda, direita ou abaixo:
; assim, o personagem pode estar ao lado ou no bloco acima dela.
acionar_alavanca:
 mov ecx,1                  ; direcoes: -1, +1, +COLS (sem diagonais)
.vizinho:
 mov edx,eax
 add edx,[direcoes+ecx*4]
 cmp byte [mapa+edx],'a'
 je .a
 cmp byte [mapa+edx],'b'
 jne .proximo
 or dword [chaves],2
 jmp .proximo
.a:
 or dword [chaves],1
.proximo:
 inc ecx
 cmp ecx,4
 jb .vizinho
 ret

; So o parceiro livre pode soltar a algema, de uma casa vizinha (sem diagonais).
resgatar:
 mov eax,[homem]
 mov edx,[mulher]
 cmp dword [presos],1
 je .procurar
 cmp dword [presos],2
 jne .fim
 xchg eax,edx
.procurar:
 xor ecx,ecx
.vizinho:
 mov ebx,eax
 add ebx,[direcoes+ecx*4]
 cmp ebx,edx
 je .libertar
 inc ecx
 cmp ecx,4
 jb .vizinho
.fim:
 ret
.libertar:
 mov byte [mapa+eax],'.'
 mov dword [presos],0
 ret

; A joia so e recolhida por Espaco, um personagem em cada lateral, em qualquer ordem.
coletar_diamante:
 cmp dword [estado],0
 jne .fim
 cmp dword [presos],0
 jne .fim
 cmp dword [diamante_coletado],0
 jne .fim
 call dupla_ao_lado_diamante
 test eax,eax
 jz .faltam_personagens
 mov dword [diamante_coletado],1
.fim:
 ret
.faltam_personagens:
 mov esi,coleta_posicione_dupla
 jmp avisar_coleta

; Explica uma tentativa frustrada apenas quando alguem esta junto da joia.
avisar_coleta:
 cmp dword [homem],COLS+8
 je .mostrar
 cmp dword [homem],COLS+10
 je .mostrar
 cmp dword [mulher],COLS+8
 je .mostrar
 cmp dword [mulher],COLS+10
 jne .fim
.mostrar:
 mov [aviso_coleta],esi
.fim:
 ret

dupla_ao_lado_diamante:
 mov eax,[homem]
 mov edx,[mulher]
 cmp eax,COLS+8
 je .pilantra_esquerda
 cmp eax,COLS+10
 jne .nao
 cmp edx,COLS+8
 je .sim
 jmp .nao
.pilantra_esquerda:
 cmp edx,COLS+10
 jne .nao
.sim:
 mov eax,1
 ret
.nao:
 xor eax,eax
 ret

; A fuga tambem exige Espaco: ambos livres, na porta aberta ou ao lado dela.
verificar_fuga:
 cmp dword [estado],0
 jne .fim
 cmp dword [diamante_coletado],1
 jne .fim
 cmp dword [presos],0
 jne .fim
 test dword [chaves],2
 jz .fim
 mov eax,[homem]
 call perto_da_porta
 test eax,eax
 jz .fim
 mov eax,[mulher]
 call perto_da_porta
 test eax,eax
 jz .fim
 mov dword [estado],2
.fim:
 ret

perto_da_porta:
 sub eax,[pos_porta]
 cmp eax,0
 je .perto
 cmp eax,1
 je .perto
 cmp eax,-1
 je .perto
 cmp eax,COLS
 je .perto
 cmp eax,-COLS
 je .perto
 xor eax,eax
 ret
.perto:
 mov eax,1
 ret

; Busca em largura: cada casa entra uma vez na fila. O primeiro ladrao
; encontrado e o mais proximo pelos corredores. Planeja o destino, sem antecipar a captura.
perseguir:
 mov edi,anterior
 mov ecx,COLS*ROWS
 xor eax,eax
 rep stosd
 mov eax,[ebp+guarda.pos]
 mov [anterior+eax*4],eax
 mov [fila],eax
 xor esi,esi                ; indice da proxima casa a consultar
 mov edi,1                  ; indice da proxima vaga
.consultar:
 cmp esi,edi
 je .fim
 mov ebx,[fila+esi*4]
 inc esi
 cmp ebx,[homem]
 je .caminho
 cmp ebx,[mulher]
 je .caminho
 xor ecx,ecx
.vizinho:
 mov eax,[direcoes+ecx*4]
 add eax,ebx
 cmp dword [anterior+eax*4],0
 jne .proximo
 mov dl,[mapa+eax]
 bloquear_casa_solida dl,.proximo
 cmp dl,'T'
 je .proximo
 cmp dl,'E'
 jne .grade
 test dword [chaves],2
 jz .proximo
 jmp .enfileirar
.grade:
 cmp dl,'G'
 jne .enfileirar
 test dword [chaves],1
 jz .proximo
.enfileirar:
 mov [anterior+eax*4],ebx
 mov [fila+edi*4],eax
 inc edi
.proximo:
 inc ecx
 cmp ecx,4
 jb .vizinho
 jmp .consultar
.caminho:
 mov eax,[anterior+ebx*4]
 cmp eax,[ebp+guarda.pos]
 je .avancar
 mov ebx,eax
 jmp .caminho
.avancar:
 mov [ebp+guarda.destino],ebx
.fim:
 ret

; EDI aponta para o pixel superior esquerdo. Cada pixel ocupa 4 bytes.
; EAX = cor RGB, ECX = largura, EDX = altura.
retangulo:
 pushad
 mov ebx,ecx
.linha:
 mov ecx,ebx
 rep stosd
 add edi,WIDTH*4
 mov ecx,ebx
 shl ecx,2
 sub edi,ecx
 dec edx
 jnz .linha
 popad
 ret

%macro bloco 5
 push edi
 add edi,(%2*WIDTH+%1)*4
 mov ecx,%3
 mov edx,%4
 mov eax,%5
 call retangulo
 pop edi
%endmacro

desenhar:
 mov edi,pixels
 mov eax,0x171d30
 mov ecx,WIDTH*HEIGHT
 rep stosd
 mov dword [indice],0
.casa:
 mov eax,[indice]
 xor edx,edx
 mov ecx,COLS
 div ecx                    ; EAX = linha, EDX = coluna
 imul eax,WIDTH*16
 shl edx,4
 lea edi,[eax+edx+WIDTH*16]
 lea edi,[pixels+edi*4]
 add edi,[margem_mapa]
 mov ebx,[indice]
 mov al,[mapa+ebx]
 cmp al,'T'
 jne .tema
 cmp ebx,[homem]
 jne .armadilha_patife
 test dword [presos],1
 jnz .armadilha_ocupada
.armadilha_patife:
 cmp ebx,[mulher]
 jne .tema
 test dword [presos],2
 jz .tema
.armadilha_ocupada:
 mov al,'.'                 ; o quadro do personagem ja contem a algema
.tema:
 cmp dword [fase],2
 je .praia
 cmp dword [fase],1
 je .museu
 cmp al,'#'
 je .parede
 push eax
 mov eax,ebx
 xor edx,edx
 mov ecx,COLS
 div ecx
 mov esi,piso_esquerdo
 cmp edx,9
 jb .piso
 mov esi,piso_direito
.piso:
 call desenhar_bgra
 pop eax
 cmp al,'D'
 je .diamante
 cmp al,'T'
 je .algema
 cmp al,'G'
 je .grade_mapa
 cmp al,'a'
 je .alavanca_a
 cmp al,'b'
 je .alavanca_b
 cmp al,'E'
 jne .proxima_casa
 test dword [chaves],2
 jnz .porta_aberta
 mov esi,entrada
 call sprite
 jmp .proxima_casa
.porta_aberta:
 mov esi,porta_aberta
 jmp .bloco_bgra
.diamante:
 mov esi,pedra_diamante
 call desenhar_bgra
 cmp dword [diamante_coletado],0
 jne .vitrine_vazia
 mov esi,diamante_azul
 jmp .bloco_bgra
.vitrine_vazia:
 mov esi,vitrine_vazia
 jmp .bloco_bgra
.algema:
 mov esi,algema_esquerda
 mov ecx,algema_direita
 mov eax,ebx
 xor edx,edx
 push ecx
 mov ecx,COLS
 div ecx
 pop ecx
 cmp edx,9
 jb .bloco_bgra
 mov esi,ecx
 jmp .bloco_bgra
.grade_mapa:
 test dword [chaves],1
 jnz .proxima_casa
 mov esi,icone_grade_a
 mov ecx,paleta_grade
 jmp .desenhar_icone
.alavanca_a:
 mov ecx,paleta_alavanca_a
 mov edx,1
 jmp .alavanca
.alavanca_b:
 mov ecx,paleta_alavanca_b
 mov edx,2
.alavanca:
 mov esi,alavanca_esquerda
 test [chaves],edx
 jz .desenhar_icone
 mov esi,alavanca_direita
.desenhar_icone:
 call desenhar_tile_icone
 jmp .proxima_casa
.parede:
 mov eax,ebx
 xor edx,edx
 mov ecx,COLS
 div ecx
 mov esi,parede
 cmp edx,9
 jne .bloco_bgra
 mov esi,parede_central
.bloco_bgra:
 call desenhar_bgra
 jmp .proxima_casa
.museu:
 cmp al,'#'
 je .parede_museu
 cmp ebx,5*COLS
 je .planta_museu
 mov esi,piso_museu
 call desenhar_tile_museu
 cmp al,'D'
 je .diamante_no_museu
 cmp al,'b'
 je .alavanca_b
 cmp al,'s'
 je .dinossauro_museu
 cmp al,'1'
 jb .figuras_museu
 cmp al,'3'
 jbe .dinossauro_museu
 cmp al,'7'
 jbe .esfinge_museu
.figuras_museu:
 mov esi,figuras_museu
.procurar_museu:
 cmp byte [esi],0
 je .proxima_casa
 cmp al,[esi]
 je .objeto_museu
 add esi,5
 jmp .procurar_museu
.objeto_museu:
 mov esi,[esi+1]
 cmp al,'E'
 jne .tile_museu
 test dword [chaves],2
 jz .tile_museu
 mov esi,porta_museu_aberta
 jmp .tile_museu
.dinossauro_museu:
 mov esi,dinossauro_museu
 cmp al,'s'
 je .bloco_bgra
 movzx eax,al
 sub eax,'0'
 shl eax,10
 add esi,eax
 jmp .bloco_bgra
.esfinge_museu:
 mov esi,esfinge_museu
 movzx eax,al
 sub eax,'4'
 shl eax,10
 add esi,eax
 jmp .bloco_bgra
.diamante_no_museu:
 mov esi,parede_museu
 call desenhar_tile_museu
 cmp dword [diamante_coletado],0
 jne .vitrine_vazia
 mov esi,diamante_roxo
 jmp .bloco_bgra
.parede_museu:
 cmp ebx,5
 je .bandeira
 cmp ebx,12
 je .bandeira
 cmp ebx,2
 je .luz
 cmp ebx,4
 je .luz
 cmp ebx,13
 je .luz
 cmp ebx,16
 je .luz
 mov esi,moldura_museu
 cmp ebx,COLS
 jb .tile_museu
 cmp ebx,14*COLS
 jae .tile_museu
 mov eax,ebx
 xor edx,edx
 mov ecx,COLS
 div ecx
 mov esi,coluna_museu
 test edx,edx
 jz .tile_museu
 cmp edx,COLS-1
 je .tile_museu
 mov esi,parede_museu
 jmp .tile_museu
.planta_museu:
 mov esi,coluna_museu
 call desenhar_tile_museu
 mov esi,vaso_museu
 jmp .tile_museu
.luz:
 mov esi,luz_museu
 jmp .tile_museu
.bandeira:
 mov esi,bandeira_museu
.tile_museu:
 call desenhar_tile_museu
 jmp .proxima_casa
.praia:
 mov esi,parede_praia
 cmp al,'#'
 je .tile_praia
 mov esi,piso_praia
 call desenhar_tile_praia
 cmp al,'D'
 je .diamante_na_praia
 cmp al,'b'
 je .alavanca_b
 mov esi,figuras_praia
.buscar_figura_praia:
 cmp byte [esi],0
 je .proxima_casa
 cmp al,[esi]
 je .objeto_praia
 add esi,5
 jmp .buscar_figura_praia
.objeto_praia:
 mov esi,[esi+1]
 cmp al,'E'
 jne .tile_praia
 test dword [chaves],2
 jz .tile_praia
 mov esi,porta_museu_aberta
 jmp .tile_praia
.diamante_na_praia:
 mov esi,pedestal_praia
 call desenhar_tile_praia
 cmp dword [diamante_coletado],0
 jne .vitrine_vazia
 mov esi,diamante_verde
 jmp .bloco_bgra
.tile_praia:
 call desenhar_tile_praia
.proxima_casa:
 inc dword [indice]
 mov eax,[indice]
 cmp eax,[tamanho_mapa]
 jb .casa
 ; Na partida, os atores entram na resolucao final. Sob as caixas,
 ; compoe a versao reduzida primeiro para respeitar o escurecimento.
 cmp dword [estado],0
 je .imagem_pronta
 mov dword [indice],0
.pessoas:
 mov eax,[indice]
 xor edx,edx
 mov ecx,COLS
 div ecx
 imul eax,WIDTH*16
 shl edx,4
 lea edi,[eax+edx+WIDTH*16]
 lea edi,[pixels+edi*4]
 add edi,[margem_mapa]
 mov ebx,[indice]
 cmp ebx,[destino_guarda]
 jne .verificar_guarda_extra
 push edi
 mov eax,[origem_guarda]
 mov edx,[quadros_guarda]
 mov ecx,[direcao_guarda]
 call .desenhar_guarda
 pop edi
.verificar_guarda_extra:
 cmp ebx,[destino_guarda_extra]
 jne .jogadores
 push edi
 mov eax,[origem_guarda_extra]
 mov edx,[quadros_guarda_extra]
 mov ecx,[direcao_guarda_extra]
 call .desenhar_guarda
 pop edi
.jogadores:
 mov esi,pilantra
 cmp ebx,[homem]
 je .homem
 mov esi,patife
 cmp ebx,[mulher]
 je .mulher
 jmp .proxima
.desenhar_guarda:
 call selecionar_quadro_guarda
 call interpolar_guarda
 call desenhar_ator_reduzido
 ret
.homem:
 mov edx,animacao_homem
 mov eax,[origem_homem]
 jmp .ator
.mulher:
 mov edx,animacao_mulher
 mov eax,[origem_mulher]
.ator:
 call selecionar_quadro
 call interpolar_posicao
 call desenhar_ator_reduzido
.proxima:
 inc dword [indice]
 mov eax,[indice]
 cmp eax,[tamanho_mapa]
 jb .pessoas
 cmp dword [estado],1
 jne .derrota
 call desenhar_caixa_pausa
 jmp .imagem_pronta
.derrota:
 cmp dword [estado],3
 jne .vitoria
 call desenhar_caixa_game_over
 jmp .imagem_pronta
.vitoria:
 cmp dword [estado],2
 jne .imagem_pronta
 call desenhar_caixa_vitoria
.imagem_pronta:
 ; Amplia os pixels aqui para evitar o travamento de StretchDIBits no Wine.
 mov esi,pixels
 mov edi,pixels_tela
 mov edx,HEIGHT
.ampliar_linha:
 mov ecx,WIDTH
.ampliar_pixel:
 lodsd
 mov [edi],eax
 mov [edi+4],eax
 mov [edi+WIDTH*8],eax
 mov [edi+WIDTH*8+4],eax
 add edi,8
 loop .ampliar_pixel
 add edi,WIDTH*8
 dec edx
 jnz .ampliar_linha
 ; Exposicoes usam a resolucao final, sem ampliar o sprite reduzido de 32x32.
 cmp dword [fase],1
 jne .exibir_imagem
 mov esi,dinossauro_museu_detalhado
 mov edi,pixels_tela+((1+1)*16*2*WIDTH*2+1*16*2)*4
 call desenhar_exposicao_detalhada
 mov esi,esfinge_museu_detalhada
 mov edi,pixels_tela+((12+1)*16*2*WIDTH*2+16*16*2)*4
 call desenhar_exposicao_detalhada
.exibir_imagem:
 cmp dword [estado],0
 jne .enviar_imagem
 call desenhar_atores_tela
.enviar_imagem:
 pcall SetDIBitsToDevice,[dc],0,0,WIDTH*2,HEIGHT*2,0,0,0,HEIGHT*2,pixels_tela,bmi,0
 pcall GetStockObject,16
 pcall SelectObject,[dc],eax
 pcall SetBkMode,[dc],1
 pcall SetTextColor,[dc],0xf6e8dc
 mov eax,[fase]
 mov esi,[cabecalhos+eax*4]
 mov eax,8
 mov edx,7
 call escrever
%if ATALHOS_TESTE
 mov esi,indicador_teste
 mov eax,420
 mov edx,7
 call escrever
%endif
 mov esi,statusA
 mov eax,[chaves]
 and eax,1
 add al,'0'
 mov [marcaA],al
 mov eax,[chaves]
 shr eax,1
 add al,'0'
 mov [marcaB],al
 mov eax,[diamante_coletado]
 add al,'0'
 mov [marcaD],al
 cmp dword [fase],0
 je .escrever_status
 mov esi,statusB
.escrever_status:
 mov eax,280
 mov edx,7
 call escrever
 mov eax,[estado]
 mov esi,[avisos+eax*4]
 cmp eax,2
 jne .verificar_aviso_derrota
 cmp dword [fase],TOTAL_FASES-1
 jne .aviso
 mov esi,vitoria_praia
 jmp .aviso
.verificar_aviso_derrota:
 cmp eax,3
 jne .aviso_preso
 mov eax,[motivo_derrota]
 mov esi,[avisos_derrota+eax*4]
 jmp .aviso
.aviso_preso:
 test eax,eax
 jnz .aviso
 cmp dword [presos],1
 jne .aviso_mulher
 mov esi,homem_preso
 jmp .aviso
.aviso_mulher:
 cmp dword [presos],2
 jne .objetivo
 mov esi,mulher_presa
 jmp .aviso
.objetivo:
 cmp dword [diamante_coletado],1
 jne .coleta
 mov esi,ajuda_fuga
 jmp .aviso
.coleta:
 cmp dword [aviso_coleta],0
 je .condicoes_coleta
 mov esi,[aviso_coleta]
 jmp .aviso
.condicoes_coleta:
 call dupla_ao_lado_diamante
 test eax,eax
 jz .aviso
 mov esi,ajuda_coleta
.aviso:
 mov eax,8
 mov edx,519
 call escrever
 ret

desenhar_fundo_caixa:
 pushad
 ; Escurece o mapa, preservando-o visivel atras do painel.
 mov edi,pixels
 mov ecx,WIDTH*HEIGHT
.escurecer:
 mov eax,[edi]
 and eax,0x00fefefe
 shr eax,1
 stosd
 loop .escurecer
 mov edi,pixels
 bloco 16,83,276,116,0x070e19
 bloco 14,80,276,116,0x945465
 bloco 16,81,272,1,0xcd8797
 bloco 16,83,272,111,0x0c1828
 bloco 34,144,236,34,0x2d4566
 bloco 34,144,236,1,0x3a567b
 popad
 ret

desenhar_caixa_game_over:
 pushad
 call desenhar_fundo_caixa
 mov ebx,0xdce6f2
 mov esi,titulo_game_over
 mov edx,94
 mov ecx,2
 call texto_centralizado
 mov eax,[motivo_derrota]
 mov esi,[causas_game_over+eax*4]
 mov edx,122
 mov ecx,1
 call texto_centralizado
 mov esi,game_over_reiniciar
 mov edx,151
 call texto_centralizado
 mov esi,game_over_novamente
 mov edx,165
 call texto_centralizado
 popad
 ret

desenhar_caixa_vitoria:
 pushad
 call desenhar_fundo_caixa
 mov ebx,0xdce6f2
 mov esi,titulo_fase_concluida
 mov edx,94
 mov ecx,2
 call texto_centralizado
 cmp dword [fase],1
 je .museu_concluido
 cmp dword [fase],2
 je .praia_concluida
 mov esi,vitoria_fuga_linha1
 mov edx,118
 mov ecx,1
 call texto_pequeno_centralizado
 mov esi,vitoria_fuga_linha2
 mov edx,130
 call texto_pequeno_centralizado
 mov esi,vitoria_proxima_linha1
 mov edx,151
 call texto_pequeno_centralizado
 mov esi,vitoria_proxima_linha2
 mov edx,165
 call texto_pequeno_centralizado
 jmp .fim
.museu_concluido:
 mov esi,vitoria_museu_linha1
 mov edx,118
 mov ecx,1
 call texto_pequeno_centralizado
 mov esi,vitoria_proxima_linha1
 mov edx,151
 call texto_pequeno_centralizado
 mov esi,vitoria_proxima_linha2
 mov edx,165
 call texto_pequeno_centralizado
 jmp .fim
.praia_concluida:
 mov esi,vitoria_praia_linha1
 mov edx,118
 mov ecx,1
 call texto_pequeno_centralizado
 mov esi,vitoria_praia_linha2
 mov edx,151
 call texto_pequeno_centralizado
.fim:
 popad
 ret

desenhar_caixa_pausa:
 pushad
 call desenhar_fundo_caixa
 mov ebx,0xdce6f2
 mov esi,titulo_pausa
 mov edx,94
 mov ecx,2
 call texto_centralizado
 mov esi,pausa_descricao
 mov edx,122
 mov ecx,1
 call texto_centralizado
 mov esi,pausa_continuar
 mov edx,151
 call texto_centralizado
 mov esi,pausa_reiniciar
 mov edx,165
 call texto_centralizado
 popad
 ret

; Fontes incorporadas: ESI texto, EDX linha, ECX escala, EBX cor RGB.
texto_centralizado:
 push ebp
 mov ebp,config_fonte_normal
 call texto_fonte_centralizada
 pop ebp
 ret

texto_pequeno_centralizado:
 push ebp
 mov ebp,config_fonte_pequena
 call texto_fonte_centralizada
 pop ebp
 ret

texto_fonte_centralizada:
 pushad
 xor eax,eax
.contar:
 cmp byte [esi+eax],0
 je .posicionar
 inc eax
 jmp .contar
.posicionar:
 imul eax,[ebp+12]
 imul eax,ecx
 neg eax
 add eax,WIDTH
 sar eax,1
 call texto_pixel
 popad
 ret

; EAX coluna, EDX linha, ECX escala, EBX cor, EBP configuracao da fonte.
texto_pixel:
 pushad
 sub esp,40
 mov [esp],ebx
 mov [esp+4],ecx
 imul edx,WIDTH
 add edx,eax
 lea edi,[pixels+edx*4]
 mov eax,[ebp]
 mov [esp+20],eax
 mov eax,[ebp+4]
 mov [esp+24],eax
 mov eax,[ebp+8]
 mov [esp+28],eax
 mov eax,[ebp+12]
 mov [esp+32],eax
 mov eax,[ebp+16]
 mov [esp+36],eax
.caractere:
 lodsb
 movzx eax,al
 test eax,eax
 jz .fim
 mov [esp+16],edi
 sub eax,32
 cmp eax,58
 ja .seguinte
 imul eax,[esp+28]
 add eax,[esp+20]
 mov ebp,eax
 mov eax,[esp+28]
 mov [esp+8],eax
.linha:
 movzx eax,byte [ebp]
 inc ebp
 mov [esp+12],eax
 mov ebx,[esp+24]
.pixel:
 mov eax,[esp+36]
 test [esp+12],eax
 jz .transparente
 mov eax,[esp]
 mov ecx,[esp+4]
 mov edx,ecx
 call retangulo
.transparente:
 shl dword [esp+12],1
 mov eax,[esp+4]
 lea edi,[edi+eax*4]
 dec ebx
 jnz .pixel
 mov eax,WIDTH
 sub eax,[esp+24]
 imul eax,[esp+4]
 shl eax,2
 add edi,eax
 dec dword [esp+8]
 jnz .linha
.seguinte:
 mov edi,[esp+16]
 mov eax,[esp+32]
 imul eax,[esp+4]
 shl eax,2
 add edi,eax
 jmp .caractere
.fim:
 add esp,40
 popad
 ret

; ESI aponta para 8 linhas de 8 indices de cor. Zero = transparente.
sprite:
 pushad
 mov ebp,8
.linha:
 mov ebx,8
.pixel:
 movzx eax,byte [esi]
 inc esi
 sub eax,'0'
 jz .pular
 mov eax,[paleta+eax*4]
 mov [edi],eax
 mov [edi+4],eax
 mov [edi+WIDTH*4],eax
 mov [edi+WIDTH*4+4],eax
.pular:
 add edi,8
 dec ebx
 jnz .pixel
 add edi,(WIDTH*2-16)*4
 dec ebp
 jnz .linha
 popad
 ret

desenhar_tile_museu:
 pushad
 mov ebx,paleta_museu
 jmp desenhar_tile_indexado
desenhar_tile_praia:
 pushad
 mov ebx,paleta_praia
 jmp desenhar_tile_indexado
desenhar_tile_icone:
 pushad
 mov ebx,ecx
desenhar_tile_indexado:
 mov edx,16
.linha:
 mov ecx,16
.pixel:
 movzx eax,byte [esi]
 inc esi
 sub eax,'0'
 jz .transparente
 cmp eax,9
 jbe .cor
 sub eax,'A'-'0'-10
.cor:
 mov eax,[ebx+eax*4]
 mov [edi],eax
.transparente:
 add edi,4
 loop .pixel
 add edi,(WIDTH-16)*4
 dec edx
 jnz .linha
 popad
 ret

; ESI = atlas, EDX = direcao/fase, EAX = origem, EBX = destino.
; Cada direcao tem quatro quadros. As duas ultimas linhas sao queda e algema.
selecionar_quadro:
 push eax
 mov ecx,1
 cmp edx,animacao_homem
 je .testar_algema
 mov ecx,2
.testar_algema:
 test [presos],ecx
 jnz .algema
 mov ecx,[edx]
 imul ecx,QUADROS_PERSONAGEM
 cmp dword [quadros_restantes],0
 je .endereco
 cmp eax,ebx
 je .endereco
 mov eax,QUADROS_PASSO
 sub eax,[quadros_restantes]
 shl eax,1
 push ecx
 push edx
 mov ecx,QUADROS_PASSO
 xor edx,edx
 div ecx
 pop edx
 pop ecx
 add eax,[edx+4]
 and eax,QUADROS_PERSONAGEM-1
 add ecx,eax
 jmp .endereco
.algema:
 mov ecx,[edx+8]
 cmp ecx,TEMPO_QUEDA_ALGEMA
 jae .preso
 cmp dword [estado],3
 je .derrota_imediata
 shr ecx,2
 add ecx,4*QUADROS_PERSONAGEM
 jmp .endereco
.derrota_imediata:
 mov ecx,TEMPO_QUEDA_ALGEMA
.preso:
 sub ecx,TEMPO_QUEDA_ALGEMA
 shr ecx,3
 and ecx,QUADROS_PERSONAGEM-1
 add ecx,5*QUADROS_PERSONAGEM
.endereco:
 imul ecx,BYTES_QUADRO_ATOR
 add esi,ecx
 pop eax
 ret

; EAX = origem, EBX = destino, ECX = direcao, EDX = quadros restantes.
selecionar_quadro_guarda:
 push eax
 push edx
 imul esi,ecx,QUADROS_POLICIAL
 cmp eax,ebx
 je .endereco
 test edx,edx
 jz .endereco
 mov eax,QUADROS_GUARDA
 sub eax,edx
 imul eax,6
 xor edx,edx
 mov ecx,QUADROS_GUARDA
 div ecx
 lea esi,[esi+eax+1]
.endereco:
 imul esi,BYTES_QUADRO_ATOR
 add esi,policial
 pop edx
 pop eax
 ret

; EAX = deslocamento de uma casa. Devolve o indice da direcao em ECX.
direcao_do_deslocamento:
 xor ecx,ecx
 cmp eax,1
 je .fim
 inc ecx
 cmp eax,-1
 je .fim
 inc ecx
 cmp eax,-COLS
 je .fim
 inc ecx
.fim:
 ret

; Interpola a mesma distancia de 16 pixels com tempos independentes.
; EDI = pixel destino, EAX = indice origem, EBX = indice destino.
interpolar_posicao:
 push ecx
 push edx
 mov ecx,QUADROS_PASSO
 mov edx,[quadros_restantes]
 call interpolar_casa
 pop edx
 pop ecx
 ret

interpolar_guarda:
 push ecx
 mov ecx,QUADROS_GUARDA
 call interpolar_casa
 pop ecx
 ret

; ECX = duracao total, EDX = quadros restantes. Divide antes da largura da tela.
interpolar_casa:
 push eax
 push ebx
 push edx
 sub eax,ebx
 mov ebx,1
 cmp eax,COLS
 jne .cima
 mov eax,1
 mov ebx,WIDTH
 jmp .aplicar
.cima:
 cmp eax,-COLS
 jne .aplicar
 mov eax,-1
 mov ebx,WIDTH
.aplicar:
 imul eax,edx
 shl eax,4
 cdq
 idiv ecx
 imul eax,ebx
 shl eax,2
 add edi,eax
 pop edx
 pop ebx
 pop eax
 ret

desenhar_atores_tela:
 pushad
 mov ebp,pos_guarda
 call desenhar_policial_tela
 cmp dword [pos_guarda_extra],-1
 je .dupla
 mov ebp,pos_guarda_extra
 call desenhar_policial_tela
.dupla:
 mov ebx,[homem]
 call posicionar_ator
 mov eax,[origem_homem]
 mov esi,pilantra
 mov edx,animacao_homem
 call desenhar_jogador_tela
 mov ebx,[mulher]
 call posicionar_ator
 mov eax,[origem_mulher]
 mov esi,patife
 mov edx,animacao_mulher
 call desenhar_jogador_tela
 popad
 ret

; EBX = casa, EDI = endereco do pixel no mapa em resolucao logica.
posicionar_ator:
 mov eax,ebx
 xor edx,edx
 mov ecx,COLS
 div ecx
 imul eax,WIDTH*16
 shl edx,4
 lea edi,[eax+edx+WIDTH*16]
 lea edi,[pixels+edi*4]
 add edi,[margem_mapa]
 ret

desenhar_policial_tela:
 mov ebx,[ebp+guarda.destino]
 call posicionar_ator
 mov eax,[ebp+guarda.origem]
 mov edx,[ebp+guarda.quadros]
 mov ecx,[ebp+guarda.direcao]
 call selecionar_quadro_guarda
 call interpolar_guarda
 call converter_posicao_tela
 jmp desenhar_ator_detalhado

desenhar_jogador_tela:
 call selecionar_quadro
 call interpolar_posicao
 call converter_posicao_tela
 jmp desenhar_ator_detalhado

; Converte a coordenada interpolada para a superficie em escala 2x.
converter_posicao_tela:
 sub edi,pixels
 mov eax,edi
 xor edx,edx
 mov ecx,WIDTH*4
 div ecx
 imul eax,WIDTH*16
 lea edi,[pixels_tela+eax+edx*2]
 ret

; Tamanho do destino, largura da superficie e passo no sprite original.
%macro desenhar_ator_bgra 3
 pushad
 mov edx,%1
%%linha:
 mov ecx,%1
%%pixel:
 mov eax,[esi]
 add esi,%3*4
 test eax,0xff000000
 jz %%transparente
 mov [edi],eax
%%transparente:
 add edi,4
 loop %%pixel
 add esi,(%3-1)*TAMANHO_ATOR*4
 add edi,(%2-%1)*4
 dec edx
 jnz %%linha
 popad
 ret
%endmacro

desenhar_ator_reduzido:
 desenhar_ator_bgra 16,WIDTH,2

desenhar_ator_detalhado:
 desenhar_ator_bgra TAMANHO_ATOR,WIDTH*2,1

; Exposicoes opacas de 64x64, compostas com o piso e fora da caixa central.
desenhar_exposicao_detalhada:
 pushad
 mov edx,64
.linha:
 mov ecx,64
.pixel:
 lodsd
 cmp dword [estado],0
 je .gravar
 and eax,0x00fefefe
 shr eax,1
.gravar:
 stosd
 loop .pixel
 add edi,(WIDTH*2-64)*4
 dec edx
 jnz .linha
 popad
 ret

; Blocos BGRA de 16x16, inteiramente dentro de uma casa.
desenhar_bgra:
 pushad
 mov edx,16
.linha:
 mov ecx,16
.pixel:
 lodsd
 test eax,eax
 jz .transparente
 mov [edi],eax
.transparente:
 add edi,4
 loop .pixel
 add edi,(WIDTH-16)*4
 dec edx
 jnz .linha
 popad
 ret

escrever:
 xor ecx,ecx
.contar:
 cmp byte [esi+ecx],0
 je .texto
 inc ecx
 jmp .contar
.texto:
 pcall TextOutA,[dc],eax,edx,esi,ecx
 ret

align 4096,db 0
cabecalhos dd cabecalho_prisao,cabecalho_museu,cabecalho_praia
cabecalho_prisao db '01  PATIFE E PILANTRA | PRIS',0xc3,'O',0
cabecalho_museu db '02  PATIFE E PILANTRA | MUSEU',0
cabecalho_praia db '03  PATIFE E PILANTRA | PRAIA',0
statusA db 'A:'
marcaA db '0','  '
statusB db 'B:'
marcaB db '0',' D:'
marcaD db '0',0
avisos dd ajuda,pausa,vitoria,derrota
ajuda db 'WASD/Setas: mover   Espaco: alavanca/resgate   P: pausa   R: reiniciar',0
%if ATALHOS_TESTE
indicador_teste db 'TESTE F1-F3',0
%endif
ajuda_coleta db 'Aperte Espaco para pegar o diamante. Depois voltem a porta azul.',0
coleta_posicione_dupla db 'PARA PEGAR: um personagem de cada lado; depois aperte Espaco.',0
ajuda_fuga db 'DIAMANTE COLETADO! Levem os dois a porta azul e apertem Espaco.',0
homem_preso db 'PILANTRA PRESO! Aproxime a Patife e aperte Espaco para soltar.',0
mulher_presa db 'PATIFE PRESA! Aproxime o Pilantra e aperte Espaco para soltar.',0
pausa db 'PAUSA   |   Pressione P para continuar.',0
vitoria db 'FASE CONCLUIDA! Pressione Enter para a proxima fase.',0
vitoria_praia db 'PRAIA CONCLUIDA! R para jogar esta fase novamente.',0
derrota db 'GAME OVER! R para tentar novamente.',0
derrota_homem db 'GAME OVER: o guarda capturou o Pilantra. R para reiniciar.',0
derrota_mulher db 'GAME OVER: o guarda capturou a Patife. R para reiniciar.',0
derrota_algemas db 'GAME OVER: os dois ficaram presos nas algemas. R para reiniciar.',0
derrota_porta db 'GAME OVER: Patife presa nas algemas. R para reiniciar.',0
avisos_derrota dd derrota,derrota_homem,derrota_mulher,derrota_algemas,derrota_porta
titulo_game_over db 'GAME OVER',0
titulo_fase_concluida db 'FASE CONCLUIDA',0
titulo_pausa db 'JOGO PAUSADO',0
pausa_descricao db 'A PARTIDA ESTA PAUSADA',0
pausa_continuar db 'APERTE P PARA CONTINUAR',0
pausa_reiniciar db 'R PARA REINICIAR A FASE',0
vitoria_fuga_linha1 db 'OS LADROES CONSEGUIRAM FUGIR',0
vitoria_fuga_linha2 db 'DA CADEIA COM O DIAMANTE',0
vitoria_proxima_linha1 db 'PRESSIONE ENTER PARA IR',0
vitoria_proxima_linha2 db 'PARA A PROXIMA FASE',0
vitoria_museu_linha1 db 'A DUPLA FUGIU DO MUSEU COM A JOIA',0
vitoria_praia_linha1 db 'A DUPLA ESCAPOU DA PRAIA COM A JOIA',0
vitoria_praia_linha2 db 'APERTE R PARA JOGAR DE NOVO',0
causas_game_over dd causa_generica,causa_homem,causa_mulher,causa_algemas,causa_porta
causa_generica db 'A TENTATIVA TERMINOU',0
causa_homem db 'O GUARDA CAPTUROU O PILANTRA',0
causa_mulher db 'O GUARDA CAPTUROU A PATIFE',0
causa_algemas db 'OS DOIS FICARAM PRESOS NAS ALGEMAS',0
causa_porta db 'PATIFE PRESA NAS ALGEMAS',0
game_over_reiniciar db 'APERTE R PARA REINICIAR',0
game_over_novamente db 'E JOGAR NOVAMENTE',0
fonte_pixel: incbin "assets/fonte5x7.bin"
fonte_pequena: incbin "assets/fonte4x6.bin"
align 4
config_fonte_normal dd fonte_pixel,5,7,6,16
config_fonte_pequena dd fonte_pequena,4,6,5,8
paleta dd 0,0x111526,0xe2eff9,0xeab685,0x96533c,0xf1bc59,0x398fd8,0x55e3e6,0xaa6488,0x748699
%include "icones.inc"
figuras_museu:
 db 's'
 dd fossil_museu
 db 'p'
 dd placa_museu
 db 'v'
 dd vaso_museu
 db 'c'
 dd cordao_museu
 db 'f'
 dd vitrine_museu
 db 'T'
 dd algema_museu
 db 'E'
 dd porta_museu
 db 0
%include "museu.inc"
figuras_praia:
 db 'u'
 dd palmeira_praia
 db 'q'
 dd pranchas_praia
 db 'k'
 dd castelo_praia
 db 'f'
 dd caixote_praia
 db 'T'
 dd algema_museu
 db 'E'
 dd porta_museu
 db 0
%include "praia.inc"
align 4
pilantra: incbin "assets/pilantra_animacoes.bgra"
patife: incbin "assets/patife_animacoes.bgra"
parede: incbin "assets/parede.bgra"
parede_central: incbin "assets/parede_central.bgra"
diamante_pedra: incbin "assets/diamante_pedra.bgra"
diamante_azul: incbin "assets/diamante_azul.bgra"
diamante_roxo: incbin "assets/diamante_roxo.bgra"
diamante_verde: incbin "assets/diamante_verde.bgra"
vitrine_vazia: incbin "assets/vitrine_vazia.bgra"
dinossauro_museu: incbin "assets/dinossauro_museu.bgra"
esfinge_museu: incbin "assets/esfinge_museu.bgra"
dinossauro_museu_detalhado: incbin "assets/dinossauro_museu_detalhado.bgra"
esfinge_museu_detalhada: incbin "assets/esfinge_museu_detalhado.bgra"
pedra_diamante: incbin "assets/pedra_diamante.bgra"
algema_esquerda: incbin "assets/algema_esquerda.bgra"
algema_direita: incbin "assets/algema_direita.bgra"
piso_esquerdo: incbin "assets/piso_esquerdo.bgra"
piso_direito: incbin "assets/piso_direito.bgra"
porta_aberta: incbin "assets/porta_aberta.bgra"
entrada:
 db '0111111001666610016666100166661001666510016666100111111009999990'
policial: incbin "assets/policial_animacoes.bgra"
align 512,db 0
file_end:
absolute file_end
msg resb 32
paint resb 64
fila resd COLS*ROWS
anterior resd COLS*ROWS
pixels resd WIDTH*HEIGHT
pixels_tela resd WIDTH*HEIGHT*4
fila_comandos resd MAX_COMANDOS
reserve_size equ $-file_end
