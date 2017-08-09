/******************************************************************************
* Criado em.....: 31/05/17 22:44:35
* Funcao........: Fonte principal do simulador
******************************************************************************/
#define SISTEMA_ALTURA  25
#define SISTEMA_LARGURA 80

#define K_ESC     27
#define K_UP      5
#define K_DOWN    24
#define K_ENTER   13

#define MENU_DESCRICAO 1
#define MENU_ACAO      2
/******************************************************************************/
static s__Executando, s_UltimoMenuExecutado
/******************************************************************************/
procedure Main()

   set cursor off

   SetMode( SISTEMA_ALTURA,SISTEMA_LARGURA )

   s__Executando := .t.

   do while s__Executando
      cls
      ExecutaMenu( RetornaOpcoesMenuPrincipal(), @s_UltimoMenuExecutado )
   enddo

return
/******************************************************************************/
static function RetornaOpcoesMenuPrincipal()

   local aOpcoesPrincipal

   aOpcoesPrincipal := Array( 0 )
   AAdd( aOpcoesPrincipal, { "Executar comando manual", { || InterfaceExecucaoLinhaComando() } } )
   AAdd( aOpcoesPrincipal, { "Executar instrucoes.com", { || ExecuteInstructions( "instrucoes.com" ) } } )
   AAdd( aOpcoesPrincipal, { "Tutorial para utilizar" , { || HowToUse() } } )
   AAdd( aOpcoesPrincipal, { "Configurar memoria"     , { || MemoryStartSettings() } } )
   AAdd( aOpcoesPrincipal, { "Sair"                   , { || s__Executando := .f. } } )

return aOpcoesPrincipal
/******************************************************************************/
static procedure CodigoAciiTecla( nTecla )

   Alert( Str( nTecla ) )

return
/******************************************************************************/
procedure ExecutaMenu( aOpcoes, nSelecionado )

   local oScreen
   local aOpcao
   local nLinhaInicial, nColunaInicial, nNumeroOpcoes, nMaiorDescricao
   local nTecla
   local cCor

   oScreen := TScreen():store( "Anterior" )

   nNumeroOpcoes   := Len( aOpcoes )
   nMaiorDescricao := CalculaMaiorDescricao( aOpcoes )

   nLinhaInicial  := Int( ( SISTEMA_ALTURA-nNumeroOpcoes )/2 )
   nColunaInicial := Int( ( SISTEMA_LARGURA-nMaiorDescricao )/2 )

   if Empty( nSelecionado )
      nSelecionado := 1
   endif

   SetColor( "W/N" )
   @ nLinhaInicial, nColunaInicial to nLinhaInicial+nNumeroOpcoes+1, nColunaInicial+nMaiorDescricao+1
   do while nTecla != K_ESC .and. nTecla != K_ENTER
      Alert( nSelecionado )
      for each aOpcao in aOpcoes
         if nSelecionado == aOpcao:__enumIndex()
            cCor := "N/W"
         else
            cCor := "W/N"
         endif
         @ nLinhaInicial + aOpcao:__enumIndex(), nColunaInicial+1 say PadC( AllTrim( aOpcao[ MENU_DESCRICAO ] ), nMaiorDescricao ) color cCor
      next

      nTecla := Inkey( 0 )
      switch nTecla
         case K_UP
            if nSelecionado == 1
               nSelecionado := nNumeroOpcoes
            else
               nSelecionado--
            endif
            exit
         case K_DOWN
            if nSelecionado == nNumeroOpcoes
               nSelecionado := 1
            else
               nSelecionado++
            endif
            exit
         case K_ENTER
            aOpcoes[ nSelecionado, MENU_ACAO ]:eval()
            exit
      end switch
   enddo

   oScreen:restore( "Anterior" )

return
/******************************************************************************/
static function CalculaMaiorDescricao( aOpcoes )

   local aOpcao
   local nMaior, nTamanhoAtual

   nMaior := 0
   for each aOpcao in aOpcoes
      nTamanhoAtual := Len( aOpcao[ MENU_DESCRICAO ] )
      if nTamanhoAtual > nMaior
         nMaior := nTamanhoAtual
      endif
   next

return nMaior
/******************************************************************************/
static procedure InterfaceExecucaoLinhaComando()

   ExecuteInstructions()

return
/******************************************************************************/
static procedure MemoryStartSettings()

   local oScreen
   local hConfig
   local GetList
   local nDataStart, nInstruction, nSize

   oScreen := TScreen():store( "Anterior" )
   GetList := {}

   hConfig := GetSettings()
   nDataStart   := hConfig[ "DataAddress" ]
   nInstruction := hConfig[ "Instruction" ]
   nSize        := hConfig[ "MemorySize"  ]

   @  7,21 to 12,58
   @  8,22 say "Configuracoes-------------------"
   @  9,22 say "Tamanho total da memoria......: " get nSize        picture "999" valid nSize > 1
   @ 10,22 say "Endereco inicial dos dados....: " get nDataStart   picture "99"  valid nDataStart   != nInstruction
   @ 11,22 say "Endereco da primeira instrucao: " get nInstruction picture "99"  valid nDataStart   != nInstruction
   read

   if LastKey() != 27
      SetSettings( Hb_Hash( "DataAddress", nDataStart  ,;
                            "Instruction", nInstruction,;
                            "MemorySize" , nSize        ) )
   endif

   oScreen:restore( "Anterior" )

return
/******************************************************************************/
static procedure HowToUse()

   local oScreen

   oScreen := TScreen():store( "Anterior" )

   @ 03,00 to 20,79
   @ 04,01 say "  Para executar o simulador, utilize a opcao 'instrucoes.com', e a CPU sera  "
   @ 05,01 say "alimentada com as instrucoes presentes no arquivo 'instrucoes.com', que deve "
   @ 06,01 say "estar na mesma pasta em que o simulador está sendo executado.                "
   @ 07,01 say "  Como operando, pode-se passar um registrador, um endereço de memoria ou um "
   @ 08,01 say "valor. Quando se passa um registrador, basta escrever seu nome no operando.  "
   @ 09,01 say "Quando for um endereco de memoria, entao deve ser passado entre parenteses   "
   @ 10,01 say "quando for necessario obter seu valor da memoria. Por exemplo, na seguinte   "
   @ 11,01 say "instrucao: ADD 10 (3), o valor do endereco 3 esta sendo acrescido ao valor   "
   @ 12,01 say "do endereco 10, e armazenado no endereco 10. Neste caso e importante a       "
   @ 13,01 say "presenca do parentese para que o processador identifique que necessita buscar"
   @ 14,01 say "na memoria, e que aquele nao e o valor a ser usado. Utilizar ADD (10) (3) im-"
   @ 15,01 say "plicaria no processador buscar no endereco 10 o endereco para ser acrescido. "
   @ 16,01 say "Ou seja, caso no endereco 10 tivessemos o valor 4, entao o processador iria  "
   @ 17,01 say "Acrescentar o valor do endereco 3 ao valor do endereco 4.                    "
   @ 18,01 say "  Como outro exemplo, usemos JE 10. Nesta instrucao, assume-se que o operando"
   @ 19,01 say "e um endereco, pois nao ha sentido de ser um valor.                          "
   @ 11,11 say "ADD 10 (3)" color "R/N"
   @ 14,62 say "ADD (10) (3)" color "R/N"
   @ 18,30 say "JE 10" color "R/N"
   Inkey( 0 )

   oScreen:restore( "Anterior" )

return
/******************************************************************************/
function ExtractAddress( cAddress )

   cAddress := SubStr( cAddress, 2, Len( cAddress )-2 ) //Retira os parêteses

return cAddress
/******************************************************************************/