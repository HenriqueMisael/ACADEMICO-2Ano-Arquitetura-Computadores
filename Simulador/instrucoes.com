ADD 0 10 //Declara um vetor(desordenado) de 10 posições entre os endereços 0 e 9
ADD 1 8
ADD 2 7
ADD 3 9 //Endereço "3" de memoria recebe o dado "9"
ADD 4 4
ADD 5 6
ADD 6 2
ADD 7 5
ADD 8 1
ADD 9 3
MOV CX 0 //Inicia CX(Contador do laço mais externo) com o endereço inicial do vetor
MOV CX2 0 //Inicia CX2(Contador do laço mais interno) com o endereço inicial do vetor
MOV BX 0 //Inicia BX e BX2(Marcadores de indice) com o endereço inicial do vetor
MOV BX2 0
MOV DX (BX) //(INICIO DO LAÇO MAIS EXTERNO) DX recebe o endereço da primeira posiçaõ do vetor (DX guarda o endereço do menor elemento)
CMP (BX2) ((DX)) //(INICIO DO LAÇO MAIS INTERNO) Compara o conteudo apontado por BX2 E DX
JB 50 //Se o conteudo apontado por BX2 for menor que o conteudo apontado por DX pula para instrução 50
J 51 //Caso nao seja menor, obrigatoriamente pula para as proximas instruções
MOV DX (BX2) //Se é menor DX recebe BX2 (endereço do menor elemento)
ADD CX2 1 //Incrementa o contador2 em 1 unidade
CMP CX2 10 //Verifica se o contador2 ja passou por todo vetor
JE 56 //Pula para instrução 56 caso o contador2 ja tenha percorrido todo vvetor
ADD BX2 1 //BX2 é incrementado em 1 unidade (aponta para proxima posição do vetor)
J 47 //Pula para o inicio do laço mais interno
MOV AX ((DX)) //(REALIZA AS TROCAS) Acumulador recebe o conteudo apontado por DX (o menor elemento)
MOV (DX) ((CX)) //O conteudo da posição do menor elemento recebe o elemento apontado por contador1
MOV (CX) (AX) //O elemento apontado por contador1 recebe o conteudo de acumulador (o menor elemento)
ADD CX 1 //Incrementa o contador1 em 1 unidade
MOV CX2 (CX) //Contador2 recebe o conteudo de contador1
CMP CX 9 //Verifica se o contador1 ja passou por todo vetor
JE 66 //Pula para instrução 65(EXIT) caso o contador1 ja tenha passado por todo vetor
ADD BX 1 //Se ainda nao percorreu todo vetor, BX1 é acrescentado em 1 unidade (aponta para proxima posição do vetor)
MOV BX2 (BX) //BX2 recebe o conteudo de BX (para percorrer o vetor novamente a partir de BX)
J  46 //Pula para o inicio do laço mais externo
EXIT //Fim da ordenação

























