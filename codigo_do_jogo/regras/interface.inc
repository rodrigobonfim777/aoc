global _jogo_iniciar, _jogo_tecla, _jogo_soltar, _jogo_tick, _jogo_consultar, _jogo_clicar
global _jogo_intervalo, _jogo_quadros_passo, _jogo_quadros_guarda, _jogo_menu

section .text align=16

; Entradas cdecl usadas pela janela em C++. A logica nao chama APIs do Windows.
_jogo_iniciar:
 jmp reiniciar

_jogo_tecla:
 ; cdecl: os registradores abaixo devem manter o valor que tinham no C++.
 ; Depois dos quatro pushes, o primeiro argumento está em ESP+20.
 push ebx
 push esi
 push edi
 push ebp
 mov eax,[esp+20]
 call teclado
 pop ebp
 pop edi
 pop esi
 pop ebx
 ret

_jogo_soltar:
 ; Soltar outra tecla não cancela a direção que está sendo mantida.
 mov eax,[esp+4]
 cmp eax,[tecla_movimento]
 jne .fim
 mov dword [tecla_movimento],0
.fim:
 ret

_jogo_clicar:
 cmp dword [estado],MENU_FASES
 jne .ignorar
 push esi
 push edi
 push ebx
 push ebp
 mov eax,[esp+20]
 call escolher_fase
 pop ebp
 pop ebx
 pop edi
 pop esi
 mov eax,1
 ret
.ignorar:
 xor eax,eax
 ret

_jogo_tick:
 ; EAX devolve 1 quando qualquer atualização pede um novo desenho.
 push ebx
 push esi
 push edi
 push ebp
 call avancar_animacao
 push eax
 call atualizar_guarda
 pop edx
 or eax,edx
 pop ebp
 pop edi
 pop esi
 pop ebx
 ret

; Estado para a camada visual. O layout corresponde a Cena em cena.hpp.
struc cena
 .fase resd 1
 .chaves resd 1
 .diamante resd 1
 .atalhos resd 1
 .aviso resd 1
 .mapa resd 1
 .tamanho resd 1
 .porta resd 1
 .estado resd 1
 .motivo resd 1
 .presos resd 1
 .quadros resd 1
 .dupla resd 10
 .guardas resd 10
 .diamantes_bonus resd 1
endstruc

%macro copiar_campo 2
 mov eax,[%2]
 mov [edi+%1],eax
%endmacro

_jogo_consultar:
 push ebx
 push esi
 push edi
 push ebp
 call aviso_do_painel
 mov edi,[esp+20]
 mov [edi+cena.aviso],eax
 ; O mapa continua no Assembly. O C++ recebe seu endereço para leitura.
 mov dword [edi+cena.mapa],mapa
 mov dword [edi+cena.atalhos],ATALHOS_TESTE
 copiar_campo cena.fase,fase
 copiar_campo cena.chaves,chaves
 copiar_campo cena.diamante,diamante_coletado
 copiar_campo cena.tamanho,tamanho_mapa
 copiar_campo cena.porta,pos_porta
 copiar_campo cena.estado,estado
 copiar_campo cena.motivo,motivo_derrota
 copiar_campo cena.presos,presos
 copiar_campo cena.quadros,quadros_restantes
 copiar_campo cena.diamantes_bonus,diamantes_bonus
 copiar_campo cena.dupla,homem
 copiar_campo cena.dupla+4,origem_homem
 copiar_campo cena.dupla+20,mulher
 copiar_campo cena.dupla+24,origem_mulher
 ; Cada animação da dupla tem três dwords: direção, quadro e tempo na algema.
 mov esi,animacao_homem
 lea edi,[edi+cena.dupla+8]
 movsd
 movsd
 movsd
 add edi,8
 movsd
 movsd
 movsd
 mov esi,pos_guarda
 ; Os dois blocos de guarda são contíguos: cinco dwords por guarda.
 mov ecx,10
 rep movsd
 pop ebp
 pop edi
 pop esi
 pop ebx
 ret

; EAX traz o código da tecla. EDX recebe o deslocamento na matriz.
teclado:
%if ATALHOS_TESTE
 lea edx,[eax-0x70]         ; VK_F1 ... VK_F4
 cmp edx,TOTAL_FASES
 jb .fase_teste
%endif
 cmp dword [estado],MENU_FASES
 je .fim
 cmp eax,'R'
 je reiniciar
 cmp eax,13
 je proxima_fase
 cmp eax,'P'
 jne .jogar
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
