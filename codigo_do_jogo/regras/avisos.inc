; Escolhe o aviso pelas regras do jogo; o C++ apenas apresenta o texto.
; EAX devolve o endereço da mensagem. O estado decide a mensagem principal;
; durante a partida há avisos específicos de resgate, coleta e fuga.
aviso_do_painel:
 mov eax,[estado]
 cmp eax,MENU_FASES
 je .sem_aviso
 mov esi,[avisos+eax*4]
 cmp eax,2
 jne .verificar_aviso_derrota
 cmp dword [fase],TOTAL_FASES-1
 jne .aviso
 mov esi,vitoria_bonus
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
 cmp dword [fase],FASE_BONUS
 jne .objetivo_regular
 mov esi,ajuda_bonus
 jmp .aviso
.objetivo_regular:
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
 mov eax,esi
 ret
.sem_aviso:
 xor eax,eax
 ret

section .rdata align=16
_jogo_intervalo dd INTERVALO_QUADRO
_jogo_quadros_passo dd QUADROS_PASSO
_jogo_quadros_guarda dd QUADROS_GUARDA
_jogo_menu dd BOTAO_X,BOTAO_Y,BOTAO_LARGURA,BOTAO_ALTURA,BOTAO_PASSO
avisos dd ajuda,pausa,vitoria,derrota
ajuda db 'WASD/Setas: mover   Espaco: alavanca/resgate   P: pausa   R: reiniciar',0
ajuda_coleta db 'Aperte Espaco para pegar o diamante. Depois voltem a porta azul.',0
coleta_posicione_dupla db 'PARA PEGAR: um personagem de cada lado; depois aperte Espaco.',0
ajuda_fuga db 'DIAMANTE COLETADO! Levem os dois a porta azul e apertem Espaco.',0
homem_preso db 'PILANTRA PRESO! Aproxime a Patife e aperte Espaco para soltar.',0
mulher_presa db 'PATIFE PRESA! Aproxime o Pilantra e aperte Espaco para soltar.',0
pausa db 'Jogo pausado. Pressione P para continuar.',0
vitoria db 'Fase concluida! Pressione Enter para jogar a proxima fase.',0
vitoria_bonus db 'Jogo zerado! Clique ENTER para abrir o menu de fases.',0
ajuda_bonus db 'Passe sobre as joias. Um de cada lado da coroa + Espaco.',0
derrota db 'Game over! Pressione R para tentar novamente.',0
derrota_homem db 'O guarda capturou o Pilantra. Pressione R para reiniciar.',0
derrota_mulher db 'O guarda capturou a Patife. Pressione R para reiniciar.',0
derrota_algemas db 'A dupla ficou presa nas algemas. Pressione R para reiniciar.',0
derrota_porta db 'A Patife ficou presa nas algemas. Pressione R para reiniciar.',0
derrota_porta_pilantra db 'O Pilantra ficou preso nas algemas. Pressione R para reiniciar.',0
avisos_derrota dd derrota,derrota_homem,derrota_mulher,derrota_algemas,derrota_porta,derrota_porta_pilantra
