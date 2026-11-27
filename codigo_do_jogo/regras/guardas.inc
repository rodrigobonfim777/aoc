; Atualiza a patrulha a cada tick, mesmo com a dupla parada.
; Posicao logica so e confirmada ao terminar a transicao visual.
atualizar_guarda:
 xor eax,eax
 cmp dword [pos_guarda],-1
 je .sem_guarda
 pushad
 mov ebp,pos_guarda
 call atualizar_um_guarda
 ; popad lê EAX deste lugar na pilha: grava ali o pedido de redesenho.
 mov [esp+28],eax
 cmp dword [pos_guarda_extra],-1
 je .fim
 mov ebp,pos_guarda_extra
 call atualizar_um_guarda
 or [esp+28],eax
.fim:
 popad
.sem_guarda:
 ret

atualizar_um_guarda:
 push dword 0               ; redesenha tambem se o guarda acabou de parar
 cmp dword [estado],0
 jne .parado
 cmp dword [ebp+guarda.quadros],0
 je .iniciar
 dec dword [ebp+guarda.quadros]
 jnz .transicao
 ; O guarda só ocupa o destino para a lógica após o último quadro do passo.
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

; Busca em largura: cada casa entra uma vez na fila. O primeiro ladrao
; encontrado e o mais proximo pelos corredores. Planeja o destino, sem antecipar a captura.
perseguir:
 ; anterior[casa] guarda de onde chegamos. Zero indica uma casa não visitada;
 ; a casa de índice zero é parede e não entra na fila.
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
 ; ESI lê do início da fila, enquanto EDI aponta para o fim.
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
 ; Marca antes de inserir, para não repetir uma casa por outro caminho.
 mov [anterior+eax*4],ebx
 mov [fila+edi*4],eax
 inc edi
.proximo:
 inc ecx
 cmp ecx,4
 jb .vizinho
 jmp .consultar
.caminho:
 ; Volta pelo caminho encontrado até achar a primeira casa após o guarda.
 ; Só essa casa se torna o próximo destino.
 mov eax,[anterior+ebx*4]
 cmp eax,[ebp+guarda.pos]
 je .avancar
 mov ebx,eax
 jmp .caminho
.avancar:
 mov [ebp+guarda.destino],ebx
.fim:
 ret
