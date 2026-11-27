; Espaço tenta resgatar, acionar alavancas, coletar a joia e verificar a saída.
; Cada rotina só muda o estado se suas próprias condições forem atendidas.
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
 ; OR mantém as alavancas já acionadas: A = 01b, B = 10b.
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
 ; O laço sempre usa EAX para o preso e EDX para quem pode resgatar.
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
 ; A casa volta a ser piso. O reinício restaura a armadilha do mapa original.
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

; O diamante está na linha 1, coluna 9. Devolve 1 se os dois lados
; (colunas 8 e 10) estiverem ocupados, em qualquer ordem.
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

; EAX = casa do personagem. A diferença para a porta deve ser 0, ±1 ou ±COLS.
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
