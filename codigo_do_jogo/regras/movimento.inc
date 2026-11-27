; EDX traz o deslocamento. Se a animação ainda está em curso, guarda
; apenas a última direção pedida para aplicar no próximo passo.
mover:
 cmp dword [quadros_restantes],0
 je iniciar_passo
 mov [proximo_rumo],edx     ; usa o toque mais recente na proxima casa
 ret

iniciar_passo:
 ; O destino muda pelas regras imediatamente. O desenho usa a origem
 ; registrada aqui para interpolar a posição durante a caminhada.
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
 je .fim
.limpar_aviso:
 mov dword [aviso_coleta],0
 mov eax,[origem_homem]
 mov ebx,[homem]
 mov edx,animacao_homem
 call atualizar_direcao
 mov eax,[origem_mulher]
 mov ebx,[mulher]
 mov edx,animacao_mulher
 call atualizar_direcao
 mov dword [quadros_restantes],QUADROS_PASSO-1
.fim:
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
 xor edx,edx
 ; Consome o rumo pendente. Se estiver vazio, usa a tecla ainda mantida.
 xchg edx,[proximo_rumo]
 test edx,edx
 jnz .iniciar
 cmp dword [tecla_movimento],0
 je .fim
 mov edx,[rumo_ativo]
.iniciar:
 call iniciar_passo
 mov ebx,1
.fim:
 mov eax,ebx
 pop ebx
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

; Aplica a dupla de movimentos com a mesma rotina de colisão.
; Ex.: D soma 1 ao Pilantra e subtrai 1 da Patife. W subtrai COLS dos dois.
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

; ESI aponta para a posição a atualizar; EDX é o deslocamento.
; EBX identifica o personagem na máscara presos: 1 = Pilantra, 2 = Patife.
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
 ; O parceiro ocupa a casa mesmo quando esta preso. O resgate usa Espaco.
 cmp esi,homem
 jne .verificar_homem
 cmp eax,[mulher]
 je .fim
 jmp .verificar_terreno
.verificar_homem:
 cmp eax,[homem]
 je .fim
.verificar_terreno:
 mov cl,[mapa+eax]
 bloquear_casa_solida cl,.fim
 cmp cl,'E'
 jne .grade
 ; B (bit 1) abre a porta E; A (bit 0) abre a grade G.
 test dword [chaves],2
 jz .fim
 jmp .entrar
.grade:
 cmp cl,'G'
 jne .entrar
 test dword [chaves],1
 jz .fim
.entrar:
 ; Grava a casa somente após checar parceiro, terreno, porta e grade.
 mov [esi],eax
 cmp dword [fase],FASE_BONUS
 je recolher_diamante_bonus
 cmp eax,[pos_guarda]
 je .guarda
 cmp eax,[pos_guarda_extra]
 je .guarda
 cmp cl,'T'
 jne .fim
 ; OR liga o bit do personagem sem alterar o bit do parceiro.
 or [presos],ebx
 cmp esi,homem
 jne .prender_patife
 mov dword [animacao_homem+8],0
 jmp .verificar_derrota
.prender_patife:
 mov dword [animacao_mulher+8],0
.verificar_derrota:
 ; Com B desligada, o parceiro do outro lado não alcança a alavanca.
 test dword [chaves],2
 jnz .verificar_dupla_presa
 cmp dword [fase],FASE_PRAIA
 je .verificar_captura_praia
 test dword [presos],2
 jz .verificar_dupla_presa
 mov eax,4
 jmp encerrar_derrota
.verificar_captura_praia:
 test dword [presos],1
 jz .verificar_dupla_presa
 mov eax,5
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
