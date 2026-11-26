; Patife e Pilantra - fase 01. NASM, x86 de 32 bits, Win32.
%include "pe.inc"
%define COLS 19
%define ROWS 15
%define WIDTH 304
%define HEIGHT 276
%define LEFT_START (13*COLS+1)
%define GUARDA_INICIO (2*COLS+17)
%define RITMO_GUARDA 5
%define RIGHT_START (13*COLS+17)
%define QUADROS_PASSO 8
%define INTERVALO_QUADRO 16
%define MAX_COMANDOS 16
%define QUADROS_PERSONAGEM 7
%define BYTES_QUADRO (16*16*4)

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

mapa times COLS*ROWS db 0   ; copia da fase, com as algemas ainda ativas
homem dd LEFT_START         ; Pilantra
mulher dd RIGHT_START       ; Patife
chaves dd 0                 ; bit 0 = A, bit 1 = B
presos dd 0                 ; bit 0 = homem algemado, bit 1 = mulher algemada
diamante_coletado dd 0
estado dd 0                 ; 0 jogando, 1 pausa, 2 vitoria, 3 capturados
motivo_derrota dd 0         ; 1/2 guarda pegou homem/mulher; 3 ambos presos; 4 porta
pos_guarda dd GUARDA_INICIO
turnos dd 0
origem_homem dd LEFT_START
origem_mulher dd RIGHT_START
origem_guarda dd GUARDA_INICIO
quadros_restantes dd 0
animacao_homem dd 0,0       ; direcao (direita/esquerda/costas/frente), fase
animacao_mulher dd 1,0
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
titulo db 'Patife e Pilantra | Fase 1',0
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
 cmp eax,'R'
 je reiniciar
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

reiniciar:
 push esi
 push edi
 push ecx
 mov esi,mapa_inicial
 mov edi,mapa
 mov ecx,COLS*ROWS
 rep movsb
 pop ecx
 pop edi
 pop esi
 mov dword [pos_guarda],GUARDA_INICIO
 mov dword [turnos],0
 mov dword [homem],LEFT_START
 mov dword [mulher],RIGHT_START
 mov dword [chaves],0
 mov dword [presos],0
 mov dword [diamante_coletado],0
 mov dword [estado],0
 mov dword [motivo_derrota],0
 mov dword [origem_homem],LEFT_START
 mov dword [origem_mulher],RIGHT_START
 mov dword [origem_guarda],GUARDA_INICIO
 mov dword [quadros_restantes],0
 mov dword [animacao_homem],0
 mov dword [animacao_homem+4],0
 mov dword [animacao_mulher],1
 mov dword [animacao_mulher+4],0
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
 mov eax,[pos_guarda]
 mov [origem_guarda],eax
 call executar_passo
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
; Quem ficou bloqueado ou preso conserva a pose, sem caminhar no lugar.
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
 add ecx,3
 cmp ecx,6
 jb .fase
 sub ecx,6
.fase:
 mov [edx+4],ecx
.fim:
 ret

; EAX retorna 1 quando um tick muda a imagem. A pausa congela a transicao.
avancar_animacao:
 push ebx
 xor ebx,ebx
 cmp dword [estado],1
 je .fim
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
 cmp dword [estado],0
 jne .fim
 inc dword [turnos]
 cmp dword [turnos],RITMO_GUARDA
 jb .fim
 mov dword [turnos],0
 call perseguir
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
 mov eax,[esi]
 add eax,edx
 mov cl,[mapa+eax]
 cmp cl,'#'
 je .fim
 cmp cl,'D'                 ; o diamante e alcancado pelas laterais
 je .fim
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
 cmp dword [presos],3
 je .ambos_presos
 ; Patife presa com B desligada tambem encerra a tentativa.
 test dword [presos],2
 jz .fim
 test dword [chaves],2
 jnz .fim
 mov eax,4
 jmp encerrar_derrota
.ambos_presos:
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

; Registra a primeira causa; a caixa e desenhada dentro do jogo.
encerrar_derrota:
 cmp dword [estado],0
 jne .fim
 mov [motivo_derrota],eax
 mov dword [estado],3
.fim:
 ret

interagir:
 call resgatar
 mov eax,[homem]
 call acionar_alavanca
 mov eax,[mulher]
 call acionar_alavanca
 call coletar_diamante
 jmp verificar_fuga

; Qualquer um dos dois personagens pode acionar A ou B.
; EAX = posicao do personagem no mapa.
acionar_alavanca:
 cmp byte [mapa+eax],'a'
 je .a
 cmp byte [mapa+eax],'b'
 jne .fim
 or dword [chaves],2
 ret
.a:
 or dword [chaves],1
.fim:
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
 cmp dword [chaves],3
 jne .fim
 call dupla_ao_lado_diamante
 test eax,eax
 jz .fim
 mov dword [diamante_coletado],1
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
 sub eax,13*COLS+9
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
; encontrado e o mais proximo pelos corredores. A porta E aberta liga as metades.
perseguir:
 mov edi,anterior
 mov ecx,COLS*ROWS
 xor eax,eax
 rep stosd
 mov eax,[pos_guarda]
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
 cmp dl,'#'
 je .proximo
 cmp dl,'T'
 je .proximo
 cmp dl,'D'
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
 cmp eax,[pos_guarda]
 je .avancar
 mov ebx,eax
 jmp .caminho
.avancar:
 mov [pos_guarda],ebx
 cmp ebx,[homem]
 je .pegou
 cmp ebx,[mulher]
 jne .fim
.pegou:
 mov eax,1
 cmp ebx,[homem]
 je .derrota
 mov eax,2
.derrota:
 jmp encerrar_derrota
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
 mov ebx,[indice]
 mov al,[mapa+ebx]
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
 mov esi,figuras
.procurar:
 cmp byte [esi],0
 je .proxima_casa
 cmp al,[esi]
 je .objeto
 add esi,5
 jmp .procurar
.objeto:
 cmp al,'E'
 jne .sprite
 test dword [chaves],2
 jnz .porta_aberta
.sprite:
 mov esi,[esi+1]
 call sprite
 jmp .proxima_casa
.porta_aberta:
 mov esi,porta_aberta
 jmp .bloco_bgra
.diamante:
 mov esi,diamante_pedra
 cmp dword [diamante_coletado],0
 je .bloco_bgra
 mov esi,pedra_diamante
 jmp .bloco_bgra
.algema:
 mov esi,algema_esquerda
 mov ecx,algema_direita
 jmp .lado
.grade_mapa:
 test dword [chaves],1
 jnz .proxima_casa
 mov esi,grade_esquerda
 mov ecx,grade_direita
.lado:
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
.proxima_casa:
 inc dword [indice]
 cmp dword [indice],ROWS*COLS
 jb .casa
 ; Personagens sao desenhados depois de todas as casas do mapa.
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
 mov ebx,[indice]
 mov esi,vigia
 cmp ebx,[pos_guarda]
 je .guarda
 mov esi,pilantra
 cmp ebx,[homem]
 je .homem
 mov esi,patife
 cmp ebx,[mulher]
 je .mulher
 jmp .proxima
.guarda:
 mov eax,[origem_guarda]
 call interpolar_posicao
 call desenhar_ator
 jmp .proxima
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
 call desenhar_personagem
 cmp ebx,[homem]
 jne .algema_mulher
 test dword [presos],1
 jnz .algemado
.algema_mulher:
 cmp ebx,[mulher]
 jne .proxima
 test dword [presos],2
 jz .proxima
.algemado:
 bloco 3,9,4,4,0x111526
 bloco 9,9,4,4,0x111526
 bloco 4,10,2,2,0xe2eff9
 bloco 10,10,2,2,0xe2eff9
 bloco 6,10,4,1,0x748699
.proxima:
 inc dword [indice]
 cmp dword [indice],ROWS*COLS
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
 pcall SetDIBitsToDevice,[dc],0,0,WIDTH*2,HEIGHT*2,0,0,0,HEIGHT*2,pixels_tela,bmi,0
 pcall GetStockObject,16
 pcall SelectObject,[dc],eax
 pcall SetBkMode,[dc],1
 pcall SetTextColor,[dc],0xf6e8dc
 mov esi,cabecalho
 mov eax,8
 mov edx,7
 call escrever
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
 mov eax,460
 mov edx,7
 call escrever
 mov eax,[estado]
 mov esi,[avisos+eax*4]
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
 cmp dword [chaves],3
 jne .aviso
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

; Os atores usam 16x16 pixels para detalhar rostos, roupas e acessorios.
desenhar_ator:
 pushad
 mov edx,16
.linha:
 mov ecx,16
.pixel:
 movzx eax,byte [esi]
 inc esi
 sub eax,'0'
 jz .transparente
 mov eax,[paleta+eax*4]
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
; Cada direcao tem idle + seis passos; cada casa usa metade do ciclo.
selecionar_quadro:
 push eax
 mov ecx,[edx]
 imul ecx,QUADROS_PERSONAGEM
 cmp dword [quadros_restantes],0
 je .endereco
 cmp eax,ebx
 je .endereco
 mov eax,QUADROS_PASSO
 sub eax,[quadros_restantes]
 imul eax,3
 shr eax,3
 add eax,[edx+4]
 cmp eax,6
 jb .fase
 sub eax,6
.fase:
 inc eax
 add ecx,eax
.endereco:
 imul ecx,BYTES_QUADRO
 add esi,ecx
 pop eax
 ret

; EDI = pixel da casa destino, EAX = origem, EBX = indice destino.
; Um quadro aproxima a imagem em dois pixels, preservando a matriz logica.
interpolar_posicao:
 push eax
 sub eax,ebx
 cmp eax,COLS
 jne .cima
 mov eax,WIDTH
 jmp .aplicar
.cima:
 cmp eax,-COLS
 jne .aplicar
 mov eax,-WIDTH
.aplicar:
 imul eax,[quadros_restantes]
 shl eax,3
 add edi,eax
 pop eax
 ret

; Sprites da referencia: BGRA 16x16, inteiramente dentro de uma casa.
desenhar_bgra:
desenhar_personagem:
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
cabecalho db '01  PATIFE E PILANTRA   |   DUPLA DO DIAMANTE',0
statusA db 'A:'
marcaA db '0','  B:'
marcaB db '0',' D:'
marcaD db '0',0
avisos dd ajuda,pausa,vitoria,derrota
ajuda db 'WASD/Setas: mover   Espaco: alavanca/resgate   P: pausa   R: reiniciar',0
ajuda_coleta db 'Aperte Espaco para pegar o diamante. Depois voltem a porta azul.',0
ajuda_fuga db 'DIAMANTE COLETADO! Levem os dois a porta azul e apertem Espaco.',0
homem_preso db 'PILANTRA PRESO! Aproxime a Patife e aperte Espaco para soltar.',0
mulher_presa db 'PATIFE PRESA! Aproxime o Pilantra e aperte Espaco para soltar.',0
pausa db 'PAUSA   |   Pressione P para continuar.',0
vitoria db 'FASE CONCLUIDA! Pressione Enter para a proxima fase.',0
derrota db 'GAME OVER! R para tentar novamente.',0
derrota_homem db 'GAME OVER: o guarda capturou o Pilantra. R para reiniciar.',0
derrota_mulher db 'GAME OVER: o guarda capturou a Patife. R para reiniciar.',0
derrota_algemas db 'GAME OVER: os dois ficaram presos nas algemas. R para reiniciar.',0
derrota_porta db 'GAME OVER: Patife presa e porta azul fechada. R para reiniciar.',0
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
causas_game_over dd causa_generica,causa_homem,causa_mulher,causa_algemas,causa_porta
causa_generica db 'A TENTATIVA TERMINOU',0
causa_homem db 'O GUARDA CAPTUROU O PILANTRA',0
causa_mulher db 'O GUARDA CAPTUROU A PATIFE',0
causa_algemas db 'OS DOIS FICARAM PRESOS NAS ALGEMAS',0
causa_porta db 'PATIFE PRESA E PORTA AZUL FECHADA',0
game_over_reiniciar db 'APERTE R PARA REINICIAR',0
game_over_novamente db 'E JOGAR NOVAMENTE',0
fonte_pixel: incbin "assets/fonte5x7.bin"
fonte_pequena: incbin "assets/fonte4x6.bin"
align 4
config_fonte_normal dd fonte_pixel,5,7,6,16
config_fonte_pequena dd fonte_pequena,4,6,5,8
paleta dd 0,0x111526,0xe2eff9,0xeab685,0x96533c,0xf1bc59,0x398fd8,0x55e3e6,0xaa6488,0x748699
figuras:
 db 'a'
 dd alavA
 db 'b'
 dd alavB
 db 'E'
 dd entrada
 db 0
align 4
pilantra: incbin "assets/pilantra_animacoes.bgra"
patife: incbin "assets/patife_animacoes.bgra"
parede: incbin "assets/parede.bgra"
parede_central: incbin "assets/parede_central.bgra"
diamante_pedra: incbin "assets/diamante_pedra.bgra"
pedra_diamante: incbin "assets/pedra_diamante.bgra"
algema_esquerda: incbin "assets/algema_esquerda.bgra"
algema_direita: incbin "assets/algema_direita.bgra"
grade_esquerda: incbin "assets/grade_esquerda.bgra"
grade_direita: incbin "assets/grade_direita.bgra"
piso_esquerdo: incbin "assets/piso_esquerdo.bgra"
piso_direito: incbin "assets/piso_direito.bgra"
porta_aberta: incbin "assets/porta_aberta.bgra"
alavA:
 db '0055000005335000005500000009500000009500009995900555555001111110'
alavB:
 db '0066000006226000006600000009600000009600009996900666666001111110'
entrada:
 db '0111111001666610016666100166661001666510016666100111111009999990'
vigia:
 db '0000011111100000'
 db '0000166666610000'
 db '0001666655661000'
 db '0000111155111100'
 db '0000433333340000'
 db '0000413113140000'
 db '0000433443340000'
 db '0000044334400000'
 db '0001166226611000'
 db '0016616556166100'
 db '0016311661163100'
 db '0003311551133000'
 db '0000016666100000'
 db '0000016106100000'
 db '0000019109100000'
 db '0000199101991000'
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
