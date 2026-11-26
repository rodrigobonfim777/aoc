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

; Uma linha da imagem = uma linha da matriz. Indice = linha*19 + coluna.
; # parede, T armadilha, G grade A, a/b alavancas, D diamante,
; E porta de entrada, V vigia, H/M posicoes iniciais.
mapa:
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

homem dd LEFT_START
mulher dd RIGHT_START
chaves dd 0                 ; bit 0 = A, bit 1 = B
estado dd 0                 ; 0 jogando, 1 pausa, 2 vitoria, 3 capturados
pos_guarda dd GUARDA_INICIO
turnos dd 0
direcoes dd -COLS,-1,1,COLS
janela dd 0
dc dd 0
indice dd 0
classe db 'PatifePilantraAOC',0
titulo db 'Patife e Pilantra | Fase 1',0
align 4
wc dd 3,procedimento,0,0,0,0,0,0,0,classe
area dd 0,0,WIDTH*2,HEIGHT*2
bmi dd 40,WIDTH,-HEIGHT
 dw 1,32
 times 6 dd 0

start:
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
 cmp eax,256                ; WM_KEYDOWN
 jne .padrao
 mov eax,[ebp+16]           ; codigo da tecla
 call teclado
 pcall InvalidateRect,[ebp+8],0,0
 jmp .zero
.pintar:
 pcall BeginPaint,[ebp+8],paint
 mov [dc],eax
 call desenhar
 pcall EndPaint,[ebp+8],paint
 jmp .zero
.sair:
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
 je mover
 cmp eax,'W'
 je mover
 mov edx,COLS
 cmp eax,40
 je mover
 cmp eax,'S'
 je mover
 mov edx,-1
 cmp eax,37
 je mover
 cmp eax,'A'
 je mover
 mov edx,1
 cmp eax,39
 je mover
 cmp eax,'D'
 je mover
.fim:
 ret

reiniciar:
 mov dword [pos_guarda],GUARDA_INICIO
 mov dword [turnos],0
 mov dword [homem],LEFT_START
 mov dword [mulher],RIGHT_START
 mov dword [chaves],0
 mov dword [estado],0
 ret

mover:
 mov esi,homem
 call tentar_passo
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
 jb verificar_vitoria
 mov dword [turnos],0
 call perseguir
 jmp verificar_vitoria
.fim:
 ret

tentar_passo:
 mov eax,[esi]
 add eax,edx
 mov cl,[mapa+eax]
 cmp cl,'#'
 je .fim
 cmp cl,'D'                 ; o diamante e alcancado pelas laterais
 je .fim
 cmp cl,'E'
 je .fim
 cmp cl,'G'
 jne .entrar
 test dword [chaves],1
 jz .fim
.entrar:
 mov [esi],eax
 cmp cl,'T'
 je .captura
 cmp eax,[pos_guarda]
 jne .fim
.captura:
 mov dword [estado],3
.fim:
 ret

interagir:
 mov eax,[homem]
 cmp byte [mapa+eax],'a'
 jne .b
 or dword [chaves],1
.b:
 mov eax,[mulher]
 cmp byte [mapa+eax],'b'
 jne verificar_vitoria
 or dword [chaves],2
verificar_vitoria:
 cmp dword [estado],0
 jne .fim
 cmp dword [chaves],3
 jne .fim
 cmp dword [homem],COLS+8
 jne .fim
 cmp dword [mulher],COLS+10
 jne .fim
 mov dword [estado],2
.fim:
 ret

; Busca em largura: cada casa entra uma vez na fila. O primeiro ladrao
; encontrado e o mais proximo pelos corredores. A porta E liga as metades.
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
 mov dword [estado],3
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
 mov ecx,0x292b3a
 mov eax,ebx
 xor edx,edx
 mov esi,COLS
 div esi
 cmp edx,9
 jb .piso
 mov ecx,0x203042
.piso:
 mov eax,ecx
 mov ecx,15
 mov edx,15
 call retangulo
 pop eax
 mov esi,figuras
.procurar:
 cmp byte [esi],0
 je .pessoas
 cmp al,[esi]
 je .objeto
 add esi,5
 jmp .procurar
.objeto:
 cmp al,'G'
 jne .sprite
 test dword [chaves],1
 jnz .pessoas
.sprite:
 mov esi,[esi+1]
 call sprite
 jmp .pessoas
.parede:
 bloco 0,0,15,15,0x354555
 bloco 1,1,14,1,0x506273
 bloco 0,8,16,1,0x202c39
 bloco 8,9,1,7,0x202c39
.pessoas:
 mov esi,vigia
 cmp ebx,[pos_guarda]
 je .ator
 mov esi,ladrao
 cmp ebx,[homem]
 je .ator
 mov esi,ladra
 cmp ebx,[mulher]
 jne .proxima
.ator:
 call desenhar_ator
.proxima:
 inc dword [indice]
 cmp dword [indice],ROWS*COLS
 jb .casa
 pcall StretchDIBits,[dc],0,0,WIDTH*2,HEIGHT*2,0,0,WIDTH,HEIGHT,pixels,bmi,0,0xcc0020
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
 mov eax,460
 mov edx,7
 call escrever
 mov eax,[estado]
 mov esi,[avisos+eax*4]
 mov eax,8
 mov edx,519
 call escrever
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

cabecalho db '01  PATIFE E PILANTRA   |   DUPLA DO DIAMANTE',0
statusA db 'A:'
marcaA db '0','  B:'
marcaB db '0',0
avisos dd ajuda,pausa,vitoria,derrota
ajuda db 'WASD/Setas: mover   Espaco: alavanca   P: pausa   R: reiniciar',0
pausa db 'PAUSA   |   Pressione P para continuar.',0
vitoria db 'DIAMANTE ROUBADO!   |   R para jogar novamente.',0
derrota db 'DUPLA CAPTURADA!   |   R para tentar novamente.',0
paleta dd 0,0x111526,0xe2eff9,0xeab685,0x96533c,0xf1bc59,0x398fd8,0x55e3e6,0xaa6488,0x748699
figuras:
 db 'T'
 dd armadilha
 db 'G'
 dd grade
 db 'D'
 dd gema
 db 'a'
 dd alavA
 db 'b'
 dd alavB
 db 'E'
 dd entrada
 db 0
ladrao:
 db '0000011111000000'
 db '0000199999110000'
 db '0001999999910000'
 db '0001111111111000'
 db '0000433333340000'
 db '0004112112114000'
 db '0000433333340000'
 db '0000044334400000'
 db '0000115555110000'
 db '0001922222291000'
 db '0003121111213000'
 db '0003412222143000'
 db '0000011551100000'
 db '0000019109100000'
 db '0000019109100000'
 db '0000122101221000'
ladra:
 db '0000001111000000'
 db '0000048444400000'
 db '0014488844441000'
 db '0144444114444100'
 db '0144013333334100'
 db '0144011211214100'
 db '0044013333331000'
 db '0000004383340000'
 db '0000011888110000'
 db '0000188282881000'
 db '0001388811883100'
 db '0004318851883400'
 db '0000011188110000'
 db '0000018108100000'
 db '0000019109100000'
 db '0000122101221000'
armadilha:
 db '0000000002200220020000200020020000022000009999000111111009900990'
grade:
 db '0555555000155100001551000012210000155100001551000015510005555550'
gema:
 db '0002200000777700077227700777777000777700000770000002200000000000'
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
reserve_size equ 32+64+2*COLS*ROWS*4+WIDTH*HEIGHT*4
