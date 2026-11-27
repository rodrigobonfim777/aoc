; Enter só avança depois da vitória. No bônus, abre o menu de fases.
proxima_fase:
 cmp dword [estado],2
 jne .fim
 cmp dword [fase],TOTAL_FASES-1
 je .menu
 inc dword [fase]
 jmp reiniciar
.menu:
 mov dword [estado],MENU_FASES
.fim:
 ret

; EAX traz X nos 16 bits inferiores e Y nos superiores.
; A divisão por BOTAO_PASSO dá o índice da fase; o resto descarta o vão.
escolher_fase:
 movzx edx,ax
 sub edx,BOTAO_X*2
 cmp edx,BOTAO_LARGURA*2
 jae .fim
 shr eax,16
 sub eax,BOTAO_Y*2
 cmp eax,TOTAL_FASES*BOTAO_PASSO*2
 jae .fim
 xor edx,edx
 mov ecx,BOTAO_PASSO*2
 div ecx
 cmp edx,BOTAO_ALTURA*2
 jae .fim
 mov [fase],eax
 jmp reiniciar
.fim:
 ret

; Copia o mapa original da fase para desfazer mudanças como algemas removidas.
reiniciar:
 push esi
 push edi
 push ecx
 mov eax,[fase]
 imul eax,7*4
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
 ; Origem e destino começam juntos para não animar a entrada na fase.
 mov edx,[eax+12]
 mov [pos_guarda],edx
 mov [origem_guarda],edx
 mov [destino_guarda],edx
 mov dword [quadros_guarda],0
 mov dword [direcao_guarda],3
 mov edx,-1
 ; Nesta versão as fases têm no máximo um guarda; o bônus não tem nenhum.
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
 ; Limpa progresso, animações e teclas pendentes da tentativa anterior.
 mov dword [chaves],0
 mov dword [presos],0
 mov dword [diamante_coletado],0
 mov dword [diamantes_bonus],0
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
 mov dword [proximo_rumo],0
 ret

; Registra a primeira causa; a caixa e desenhada dentro do jogo.
encerrar_derrota:
 cmp dword [estado],0
 jne .fim
 mov [motivo_derrota],eax
 mov dword [estado],3
.fim:
 ret
