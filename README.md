# Patife e Pilantra — Cadeia, Museu e Praia

Jogo em Assembly x86 de 32 bits para Windows. Abra **Patife e Pilantra.exe**. Para montar novamente, abra o PowerShell nesta pasta e execute:

```powershell
nasm -f bin jogo.asm -o "Patife e Pilantra.exe"
```

## Atalhos temporários de teste

O executável do repositório mostra **TESTE F1-F3** no topo. Pressione **F1** para abrir a Cadeia, **F2** para o Museu ou **F3** para a Praia. Cada atalho começa a fase escolhida do zero.

**Na entrega final**, compile com os atalhos desativados:

```powershell
nasm -dATALHOS_TESTE=0 -f bin jogo.asm -o "Patife e Pilantra.exe"
```

Nessa versão, o jogo começa na Cadeia e só avança após vencer e apertar Enter.

## Como jogar

Patife é a mulher (ladra), e Pilantra é o homem (ladrão).

Use as setas ou WASD; segure uma direção para continuar andando. Cada passo desliza suavemente entre as casas em cerca de 0,2 segundo. Soltar a tecla termina apenas o passo em andamento; toques rápidos feitos durante a transição ficam na fila. Direita move o ladrão para a direita e a ladra para a esquerda. Para cima e para baixo, os dois seguem o mesmo sentido. Cada personagem só anda se a próxima casa estiver livre. Use uma parede para segurar um deles enquanto reposiciona o outro. Um personagem algemado também fica parado, sem impedir os movimentos do parceiro.

A alavanca laranja (A) abre as duas grades douradas. A azul (B) abre a porta azul entre as metades, mostrando a folha aberta em vez de remover seu desenho, sem interferir na coleta do diamante. Qualquer um dos dois personagens pode acionar qualquer alavanca: fique em uma casa à esquerda, à direita ou acima dela e aperte Espaço. A alavanca começa inclinada para a esquerda e vira para a direita ao ser acionada. A casa da alavanca fica bloqueada para os personagens e para o policial. O painel superior mostra 1 para cada alavanca acionada e D:1 depois da coleta. Mesmo com as portas e grades fechadas, leve um personagem à esquerda e o outro à direita do diamante, em qualquer ordem, e aperte Espaço para pegar a joia. Os dois precisam estar livres. A pedra permanece no lugar e a partida continua. Para vencer, leve os dois até a porta azul aberta (sobre ela ou em uma casa vizinha, sem diagonais) e aperte Espaço para fugir. Ao vencer, aparece uma caixa FASE CONCLUÍDA sobre o mapa, informando que os ladrões fugiram da cadeia com o diamante. Pressione Enter para seguir para o museu. R continua reiniciando a fase atual. Chegar ao diamante ou à saída sem apertar Espaço não conclui nenhuma dessas ações. O guarda se move continuamente, cerca de uma casa a cada 0,7 segundo, mesmo quando os personagens estão parados. O movimento dele tem animação independente e congela durante a pausa e nas telas de vitória ou derrota. Ele busca o ladrão mais próximo pelo caminho livre e pode atravessar a porta azul depois que B é acionada. Encostar no guarda encerra a tentativa. Pisar em uma algema prende apenas aquele personagem: ele fica parado, enquanto o parceiro continua se movendo. Para resgatar, entre na casa do personagem preso: o contato solta o parceiro sem prender quem veio salvar. Também é possível ficar em uma casa vizinha (acima, abaixo ou ao lado) e apertar Espaço. Após qualquer resgate, a algema daquela casa desaparece e os dois podem passar por ela sem ficar presos novamente. R restaura todas as algemas da fase. Se os dois ficarem presos, ou se a Patife ficar presa enquanto a porta azul estiver fechada, a tentativa termina: use R para reiniciar. Ao perder, uma caixa GAME OVER dentro do jogo, sobre o mapa escurecido, informa o motivo: o guarda capturou a Patife ou o Pilantra, os dois ficaram presos nas algemas, ou a Patife ficou presa com a porta azul fechada. Nesse último caso, o aviso prioriza “PATIFE PRESA NAS ALGEMAS”, mesmo se o Pilantra estiver preso. Aperte R para fechar a caixa e reiniciar a partida. O motivo também permanece no rodapé. P abre a tela JOGO PAUSADO sobre o mapa escurecido e congela movimentos e animações; P novamente continua a partida, e R reinicia. As frases abaixo de FASE CONCLUÍDA usam uma fonte menor, de 4 × 6 pixels, mantendo o título em destaque.

No museu, a dupla começa nos corredores de baixo, nas posições do print. O fóssil, os quadros, os cordões e a vitrine são obstáculos. Pegue o diamante no topo com um personagem de cada lado e Espaço; a alavanca B no corredor da direita só é necessária para abrir a saída e fugir com os dois. Se a Patife cair em uma algema antes de abrir a porta, é Game Over. O mapa está em `jogo.asm` e os desenhos estão em `museu.inc`.

Ao vencer o museu, pressione Enter para ir à praia. Na terceira fase, palmeiras, pranchas, caixotes e castelos de areia bloqueiam o caminho. Acione B, pegue o diamante e volte à porta azul, desviando dos dois guardas. R reinicia a fase atual.

## Para explicar ao professor

1. **Mapa.** Em `jogo.asm`, cada caractere de `mapa` representa uma casa. O mapa tem 19 colunas e 15 linhas. Contando a partir do zero, o ladrão começa na linha 13, coluna 1. Seu índice é 13 × 19 + 1 = 248.
2. **Comando.** O Windows entrega uma tecla a `procedimento`. A rotina `teclado` transforma a tecla em deslocamento no registrador EDX. Somar 1 anda uma coluna. Subtrair 19 sobe uma linha.
3. **Espelho e colisão.** Em `mover`, ESI guarda o endereço da posição de um personagem. `tentar_passo` soma EDX à posição e lê o caractere de destino antes de gravar a nova posição. A mesma rotina serve aos dois. `executar_passo` aplica as regras na matriz; `iniciar_passo` guarda as posições anteriores. Um timer de 16 ms chama `avancar_animacao`, e `interpolar_posicao` distribui os 16 pixels de deslocamento ao longo de cerca de 0,2 segundo; o guarda usa o mesmo cálculo com duração independente de cerca de 0,7 segundo. A pausa congela a transição e R também limpa a fila de comandos. Entre as chamadas, `neg edx` troca o sinal somente para movimentos horizontais. Experimente começar com três passos para a direita e um para cima para mostrar que o teste de parede é individual.
4. **Memória e bits.** Em `interagir`, `acionar_alavanca` verifica as alavancas alcançáveis a partir das casas laterais ou acima de cada objeto; qualquer um pode ligar A ou B. A instrução `or` liga o bit correspondente de `chaves`. A vale 1 e B vale 2. Se ambas estiverem ligadas, o valor é 3. Em `tentar_passo`, `test` consulta o bit A para liberar as grades e o bit B para liberar a porta azul.
5. **Algemas e resgate.** `presos` usa o bit 0 para o ladrão e o bit 1 para a ladra. `tentar_passo` encerra a tentativa se a Patife for presa com B desligada; nos demais casos, bloqueia apenas quem estiver preso e trata a entrada na casa do parceiro preso como resgate, antes de aplicar a algema ao socorrista. `resgatar`, chamada por Espaço, libera o personagem se o parceiro livre estiver em uma das quatro casas vizinhas. O desenho mostra a queda e depois a animação do personagem preso, junto da instrução de resgate. O resgate troca a algema (`T`) por piso (`.`) no mapa. R limpa esses bits e restaura uma cópia de `mapa_inicial`, trazendo as algemas de volta.
6. **Coleta e fuga.** `coletar_diamante`, chamada por Espaço, confere apenas se os dois estao livres e um personagem esta em cada lateral da joia, em qualquer ordem, e liga `diamante_coletado`, mantendo `estado` em jogo. `verificar_fuga`, também chamada somente por Espaço, exige o diamante, a porta azul aberta e ambos os personagens livres na saída ou em uma casa vizinha. Só então `estado` passa para vitória. R limpa a coleta e restaura o diamante sobre a pedra.
7. **Desenho.** `desenhar` percorre a matriz. A divisão do índice por 19 devolve a linha em EAX e a coluna em EDX. Cada casa ocupa 16 × 16 pixels. Os quadros do Pilantra (personagem 1) e da Patife (personagem 2) usam sprites BGRA de 32 × 32 pixels. Cada personagem ocupa uma casa e é desenhado por cima do cenário. Os policiais usam o atlas `assets/policial_animacoes.bgra`, com quatro direções e sete quadros por direção, incluindo a pose parada. Durante a partida, os quadros de 32 × 32 pixels são desenhados na resolução final da janela, com transparência e sem aumentar o espaço ocupado no mapa. `python tools/gerar_policiais.py` gera o atlas com Pillow e recorta a folha original quando ela está salva em `assets/policiais-referencia.png`. `sprite` amplia os objetos de 8 × 8, e o Windows exibe a imagem pronta. `pe.inc` contém o cabeçalho do executável e as funções importadas do Windows.
8. **Perseguição.** Em `perseguir`, a busca em largura visita primeiro as casas a um passo do guarda, depois as que ficam a dois passos e assim por diante. `fila` registra as casas a visitar e `anterior` guarda por onde a busca chegou a cada uma. Ao encontrar um dos ladrões, o código segue esses registros de volta e planeja a primeira casa do caminho em `destino_guarda`. `atualizar_guarda` avança a animação pelo timer; ao chegar, confirma a posição e verifica a captura. A busca seguinte considera as novas posições, sem depender das teclas da dupla.


## Demonstração das alavancas

Use paredes para reposicionar a dupla e leve qualquer personagem a uma casa lateral ou acima de cada alavanca; Espaço abre as grades ou a porta correspondente. O policial persegue em tempo real, então o caminho e o tempo de espera precisam considerar a posição dele. Use P para pausar durante a explicação. Depois de coletar a joia com Espaço, volte com os dois à porta azul e aperte Espaço para fugir.

## Desenhos dos personagens

A folha `assets/personagens-movimento-referencia.png` fornece os quatro quadros de cada direção da dupla. A folha `assets/personagens-algemas-referencia.png` fornece as poses de queda e de personagem preso. Os recortes têm fundo transparente e são desenhados em 32 × 32 pixels durante a partida. O quadro de frente da Patife vem diretamente da folha. A direção acompanha o movimento individual, inclusive o espelhamento dos comandos horizontais. Para regenerar os atlas BGRA incorporados ao jogo, execute `python tools/gerar_personagens.py` com Pillow instalado.


## Desenho do mapa

Paredes, linha central pontilhada, diamante sobre a pedra, pisos e algemas da Cadeia usam blocos de 16 × 16 pixels extraídos de `assets/mapa-referencia.png`. `python3 tools/gerar_mapa.py` regenera esses arquivos com Pillow instalado. Os ícones das alavancas A e B e das grades estão em `icones.inc`. A grade fechada usa a letra A e barras douradas. Quando abre, a casa volta a mostrar o piso. Os desenhos são incorporados ao executável.


## Cores dos diamantes

A Cadeia usa o diamante azul, o Museu usa o roxo e a Praia usa o verde. As vitrines completas, com vidro, moldura e joia, são extraídas de `assets/diamantes_vidro_referencia.png`, adaptadas a 16 × 16 pixels e incorporadas ao executável. Para regenerá-los, execute `python3 tools/gerar_diamantes.py` com Pillow instalado. Depois da coleta, a vitrine passa a usar `assets/vitrine_vazia_referencia.png`, mantendo o vidro vazio visível e o bloco sólido nas três fases.


O fóssil no canto do Museu usa a referência `assets/dinossauro_museu_referencia.png`, com pedestal e corda, em uma área sólida de 2 × 2 blocos. `python3 tools/gerar_dinossauro.py` regenera os quatro blocos com Pillow instalado.

A esfinge no canto inferior direito do Museu ocupa 2 × 2 blocos sólidos, com pedestal e corda da referência `assets/esfinge_museu_referencia.png`. Para regenerá-la, execute `python3 tools/gerar_esfinge.py` com Pillow instalado.

As duas exposições usam também sprites detalhados de 64 × 64 pixels, derivados diretamente das referências e desenhados na resolução final da janela. Assim, preservam mais detalhes dentro da mesma área de 2 × 2 blocos. Os scripts geram ambas as resoluções; nas telas de pausa e fim de jogo, as exposições acompanham o escurecimento do mapa.
