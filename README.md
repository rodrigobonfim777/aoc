# Patife e Pilantra — Fase 1

Jogo em Assembly x86 de 32 bits para Windows. Abra **Patife e Pilantra.exe**. Para montar novamente, abra o PowerShell nesta pasta e execute:

```powershell
nasm -f bin jogo.asm -o "Patife e Pilantra.exe"
```

## Como jogar

Use as setas ou WASD. Direita move o ladrão para a direita e a ladra para a esquerda. Para cima e para baixo, os dois seguem o mesmo sentido. Cada personagem só anda se a próxima casa estiver livre. Use uma parede para segurar um deles enquanto reposiciona o outro.

A alavanca dourada (A) abre as duas grades douradas. A azul (B) libera a coleta junto com A. Pise na alavanca e aperte Espaço. O painel superior mostra 1 para cada alavanca acionada. Com as duas ligadas, leve o ladrão à esquerda do diamante e a ladra à direita dele, ao mesmo tempo. O guarda anda uma casa a cada cinco comandos de direção, inclusive quando uma parede bloqueia a dupla. Ele busca o ladrão mais próximo pelo caminho livre e pode atravessar a porta azul entre as metades. Encostar nele ou em uma armadilha encerra a tentativa. P pausa ou continua e R reinicia.

## Para explicar ao professor

1. **Mapa.** Em `jogo.asm`, cada caractere de `mapa` representa uma casa. O mapa tem 19 colunas e 15 linhas. Contando a partir do zero, o ladrão começa na linha 13, coluna 1. Seu índice é 13 × 19 + 1 = 248.
2. **Comando.** O Windows entrega uma tecla a `procedimento`. A rotina `teclado` transforma a tecla em deslocamento no registrador EDX. Somar 1 anda uma coluna. Subtrair 19 sobe uma linha.
3. **Espelho e colisão.** Em `mover`, ESI guarda o endereço da posição de um personagem. `tentar_passo` soma EDX à posição e lê o caractere de destino antes de gravar a nova posição. A mesma rotina serve aos dois. Entre as chamadas, `neg edx` troca o sinal somente para movimentos horizontais. Experimente começar com três passos para a direita e um para cima para mostrar que o teste de parede é individual.
4. **Memória e bits.** Em `interagir`, a instrução `or` liga um bit de `chaves`. A vale 1 e B vale 2. Se ambas estiverem ligadas, o valor é 3. Em `tentar_passo`, `test` consulta o bit A para decidir se a grade permite passagem.
5. **Vitória.** `verificar_vitoria` confere o valor 3 e os dois índices ao lado do diamante. `estado` guarda se a fase está em andamento, pausada, vencida ou perdida.
6. **Desenho.** `desenhar` percorre a matriz. A divisão do índice por 19 devolve a linha em EAX e a coluna em EDX. Cada casa ocupa 16 × 16 pixels. `desenhar_ator` lê 16 linhas de 16 pixels para desenhar os personagens. `sprite` amplia os objetos de 8 × 8, e o Windows exibe a imagem pronta. `pe.inc` contém o cabeçalho do executável e as funções importadas do Windows.
7. **Perseguição.** Em `perseguir`, a busca em largura visita primeiro as casas a um passo do guarda, depois as que ficam a dois passos e assim por diante. `fila` registra as casas a visitar e `anterior` guarda por onde a busca chegou a cada uma. Ao encontrar um dos ladrões, o código segue esses registros de volta e anda só a primeira casa do caminho. No próximo turno do guarda, a busca considera as novas posições.


## Rota para ensaiar a apresentação

A partir do reinício, dê um toque por letra: WDWDSDWWDDDWDDWWWAA. Aperte Espaço uma vez para ativar as duas alavancas, depois siga WDDSASSAAWAAWWWWDDDDWWWWWW para vencer.