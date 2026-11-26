# Patife e Pilantra — Fase 1

Jogo em Assembly x86 de 32 bits para Windows. Abra **Patife e Pilantra.exe**. Para montar novamente, abra o PowerShell nesta pasta e execute:

```powershell
nasm -f bin jogo.asm -o "Patife e Pilantra.exe"
```

## Como jogar

Patife é a mulher (ladra), e Pilantra é o homem (ladrão).

Use as setas ou WASD; segure uma direção para continuar andando. Cada passo desliza suavemente entre as casas em cerca de 130 ms. Soltar a tecla termina apenas o passo em andamento; toques rápidos feitos durante a transição ficam na fila. Direita move o ladrão para a direita e a ladra para a esquerda. Para cima e para baixo, os dois seguem o mesmo sentido. Cada personagem só anda se a próxima casa estiver livre. Use uma parede para segurar um deles enquanto reposiciona o outro. Um personagem algemado também fica parado, sem impedir os movimentos do parceiro.

A alavanca dourada (A) abre as duas grades douradas. A azul (B) abre a porta azul entre as metades, mostrando a folha aberta em vez de remover seu desenho, e libera a coleta junto com A. Qualquer um dos dois personagens pode acionar qualquer alavanca: pise nela e aperte Espaço. O painel superior mostra 1 para cada alavanca acionada. Com as duas ligadas, leve o ladrão à esquerda do diamante e a ladra à direita dele, ao mesmo tempo. O guarda anda uma casa a cada cinco comandos de direção, inclusive quando uma parede bloqueia a dupla. Ele busca o ladrão mais próximo pelo caminho livre e pode atravessar a porta azul depois que B é acionada. Encostar no guarda encerra a tentativa. Pisar em uma algema prende apenas aquele personagem: ele fica parado, enquanto o parceiro continua se movendo. Para resgatar, entre na casa do personagem preso: o contato solta o parceiro sem prender quem veio salvar. Também é possível ficar em uma casa vizinha (acima, abaixo ou ao lado) e apertar Espaço. Após qualquer resgate, a algema daquela casa desaparece e os dois podem passar por ela sem ficar presos novamente. R restaura todas as algemas da fase. Se os dois ficarem presos, use R para reiniciar. P pausa ou continua e R reinicia.

## Para explicar ao professor

1. **Mapa.** Em `jogo.asm`, cada caractere de `mapa` representa uma casa. O mapa tem 19 colunas e 15 linhas. Contando a partir do zero, o ladrão começa na linha 13, coluna 1. Seu índice é 13 × 19 + 1 = 248.
2. **Comando.** O Windows entrega uma tecla a `procedimento`. A rotina `teclado` transforma a tecla em deslocamento no registrador EDX. Somar 1 anda uma coluna. Subtrair 19 sobe uma linha.
3. **Espelho e colisão.** Em `mover`, ESI guarda o endereço da posição de um personagem. `tentar_passo` soma EDX à posição e lê o caractere de destino antes de gravar a nova posição. A mesma rotina serve aos dois. `executar_passo` aplica as regras na matriz; `iniciar_passo` guarda as posições anteriores. Um timer de 16 ms chama `avancar_animacao`, e `interpolar_posicao` aproxima o desenho dois pixels por quadro até completar a casa. A pausa congela a transição e R também limpa a fila de comandos. Entre as chamadas, `neg edx` troca o sinal somente para movimentos horizontais. Experimente começar com três passos para a direita e um para cima para mostrar que o teste de parede é individual.
4. **Memória e bits.** Em `interagir`, `acionar_alavanca` verifica a casa de cada personagem; qualquer um pode ligar A ou B. A instrução `or` liga o bit correspondente de `chaves`. A vale 1 e B vale 2. Se ambas estiverem ligadas, o valor é 3. Em `tentar_passo`, `test` consulta o bit A para liberar as grades e o bit B para liberar a porta azul.
5. **Algemas e resgate.** `presos` usa o bit 0 para o ladrão e o bit 1 para a ladra. `tentar_passo` bloqueia apenas quem estiver preso e trata a entrada na casa do parceiro preso como resgate, antes de aplicar a algema ao socorrista. `resgatar`, chamada por Espaço, libera o personagem se o parceiro livre estiver em uma das quatro casas vizinhas. O desenho sobrepõe uma algema ao personagem preso e mostra a instrução de resgate. O resgate troca a algema (`T`) por piso (`.`) no mapa. R limpa esses bits e restaura uma cópia de `mapa_inicial`, trazendo as algemas de volta.
6. **Vitória.** `verificar_vitoria` confere o valor 3 e os dois índices ao lado do diamante. `estado` guarda se a fase está em andamento, pausada, vencida ou perdida.
7. **Desenho.** `desenhar` percorre a matriz. A divisão do índice por 19 devolve a linha em EAX e a coluna em EDX. Cada casa ocupa 16 × 16 pixels. `desenhar_personagem` lê os sprites BGRA de 16 × 16 pixels do Pilantra (personagem 1) e da Patife (personagem 2), recortados da referência. Os personagens são desenhados após o mapa e cabem inteiramente em uma casa. `desenhar_ator` mantém o sprite de 16 × 16 do guarda. `sprite` amplia os objetos de 8 × 8, e o Windows exibe a imagem pronta. `pe.inc` contém o cabeçalho do executável e as funções importadas do Windows.
8. **Perseguição.** Em `perseguir`, a busca em largura visita primeiro as casas a um passo do guarda, depois as que ficam a dois passos e assim por diante. `fila` registra as casas a visitar e `anterior` guarda por onde a busca chegou a cada uma. Ao encontrar um dos ladrões, o código segue esses registros de volta e anda só a primeira casa do caminho. No próximo turno do guarda, a busca considera as novas posições.


## Rota para demonstrar as alavancas

A partir do reinício, dê um toque por letra e aguarde cada passo terminar: WDWDSDWWDDDWDDWWWAA. Aperte Espaço uma vez para ativar as duas alavancas. Essa sequência demonstra a abertura das grades e da porta azul; depois, continue evitando o guarda até alcançar as posições de vitória.

## Desenhos dos personagens

Os desenhos usam o quadro IDLE e os seis quadros ANDANDO da imagem fornecida em `assets/personagens-referencia.png`: personagem 1 = Pilantra, personagem 2 = Patife. Os recortes são adaptados à resolução do jogo com fundo transparente, mantendo as proporções. Cada personagem tem quatro direções, com uma pose parada e seis poses de caminhada por direção. As laterais usam a referência e seu espelhamento; frente e costas foram adaptadas ao mesmo estilo porque não aparecem na imagem. Subir mostra as costas; descer mostra a frente. A direção acompanha o movimento individual de cada personagem, inclusive o espelhamento horizontal. Personagens bloqueados ou presos ficam na pose parada. Os arquivos `.bgra` são incorporados ao `.exe`; não é necessário distribuí-los separadamente para jogar. Para regenerá-los, execute `python3 tools/gerar_personagens.py` com Pillow instalado.


## Desenho do mapa

Paredes, linha central pontilhada, diamante sobre a pedra, pisos, algemas e grades usam blocos de 16 × 16 pixels extraídos de `assets/mapa-referencia.png`. As grades fechadas são amarelas, com barras verticais e travessas completas; ao abrir, liberam a casa inteira. As alavancas mantêm os desenhos anteriores. `python3 tools/gerar_mapa.py` regenera os arquivos com Pillow instalado. Os blocos são incorporados ao executável.
