/******************************************************************************
* Criado em.....: 28/06/17 21:52:35
* Funcao........: Classe para servir de interface para as operações da CPU
******************************************************************************/
#include 'HbClass.ch'
#include 'Operations.ch'
#include 'Memory.ch'
/******************************************************************************/
CLASS CPU

   EXPORTED:
      METHOD new( oMemory )
      METHOD feedInstruction( cInstruction )
      METHOD nextInstruction()
      METHOD executeInstruction()
      METHOD checkRegister( cRegister )    INLINE HB_HHasKey( ::hRegisters, cRegister )
      METHOD checkPointer( cPointer )      INLINE Left( cPointer, 1 ) == '('
      METHOD getRegisters()                INLINE ::hRegisters
      METHOD getError()                    INLINE ::cError
      METHOD getOperator1()                INLINE ::xOperator1
      METHOD getOperator2()                INLINE ::xOperator2
      METHOD getValueIn( cAddress )
      METHOD setValueIn( cAddress, xValue )
      METHOD exit()

   HIDDEN:
      METHOD getValueFromMemory( cAddress )
      METHOD writeValueInMemory( cAddress, xValue )

      VAR oMemory         INIT NIL
      VAR cError          INIT NIL

      //Atributos da CPU
      VAR hOperations     INIT InitializeOperations()
      VAR hRegisters      INIT InitializeRegisters()
      VAR xOperator1      INIT NIL
      VAR xOperator2      INIT NIL

END CLASS
/******************************************************************************/
/* EXPORTED METHODS ***********************************************************/
/******************************************************************************/
METHOD CPU:new( oMemory )

   ::oMemory := oMemory
   ::hRegisters[ "PC" ] := ::oMemory:getFirstInstruction()

RETURN Self
/******************************************************************************/
METHOD CPU:feedInstruction( cInstruction )

   LOCAL aInstruction

   IF Empty( cInstruction )
      /*
        Se a instrução for vazia, então zera o registrador de instrução
      */
      ::hRegisters[ "IR" ] := OP_NONE
   ELSE
      /*
        Caso seja uma STRING de instrução, separamos em um vetor de 3 strings, a fim de
          separar a operação (atribuído o devido op code ao IR, e os operadores
      */
      aInstruction := HB_ATokens( cInstruction )
      ::hRegisters[ "IR" ] := Operations_Id( aInstruction[1] )

      IF Len( aInstruction ) > 1
         ::xOperator1 := aInstruction[2]
         IF Len( aInstruction ) > 2
            ::xOperator2 := aInstruction[3]
         ENDIF
      ENDIF
   ENDIF

RETURN Self
/******************************************************************************/
METHOD CPU:nextInstruction()

   IF HB_HHasKey( ::oMemory:getInstructionsHash(), ::hRegisters[ "PC" ] )
      /*
        Se houver espaço na memória de instruções, então alimentaremos o contexto
          da CPU com a próxima instrução da memória
      */
      ::feedInstruction( ::oMemory:getInstructionsHash()[ ::hRegisters[ "PC" ]++ ] )
   ELSE
      /*
        Caso tenha chegado ao fim da memória, finalizamos a simulação
      */
      ::hRegisters[ "IR" ] := OP_EXIT
   ENDIF


RETURN Self
/******************************************************************************/
METHOD CPU:executeInstruction()

   LOCAL lReturn

   IF Empty( ::hRegisters[ "IR" ] )
      /*
        OP code em branco significa esperar o próximo ciclo de instrução. Gera erro para explicar o
          motivo de não executar nada.
      */
      ::cError := "Momento de espera (operacao em branco)"
      lReturn := .F.
   ELSE
      IF HB_HHasKey( ::hOperations, ::hRegisters[ "IR" ] )
         /*
            Buscamos na lista de instruções da CPU aquela que se adequa ao OPcode do IR
              e executamos
         */
         ::hOperations[ ::hRegisters[ "IR" ] ]:eval( Self )
         lReturn := .T.
      ELSE
         /*
            Se o OPcode não for encontrado na lista de instruções, então apresentamos erro
              de que a operação não foi prevista na arquitetura da CPU
         */
         ::cError := "Operacao " + Operations_Name( ::hRegisters[ "IR" ] ) + " nao prevista na CPU"
         lReturn := .F.
      ENDIF
   ENDIF

   ::xOperator1 := NIL
   ::xOperator2 := NIL

RETURN lReturn
/******************************************************************************/
METHOD CPU:getValueIn( cAddress )

   LOCAL xValue

   IF ::checkRegister( cAddress )
      /*
         Caso o operador endereço seja um registrador, o valor a ser utilizado é o armazenado em registrador
           da CPU.
      */
      xValue := ::hRegisters[ cAddress ]
   ELSE
      IF Left( cAddress, 1 ) == '('
         /*
            Endereçamento direto
            Caso o operador endereço seja um endereço para a memória (entre parênteses), preparamos o ambiente
         */
         ExtractAddress( @cAddress )
         /*
            Caso seja um registrador aninhado por parênteses, buscamos o endereco armazenado nele, como se fosse
              um ponteiro. Exemplo: (AX) nos faz buscar na memória o conteúdo do endereco de valor igual a AX.
         */
         IF ::checkRegister( cAddress )
            cAddress := Str( ::hRegisters[ cAddress ] )
         ELSE
            cAddress := Str( ::getValueFromMemory( cAddress ) )
         ENDIF
      ENDIF
      /*
        Endereçamento imediato
        Se o operador for um valor (nem registrador, nem endereço), então não há o que fazer com ele.
      */
      xValue := ::getValueFromMemory( cAddress )
   ENDIF

RETURN xValue
/******************************************************************************/
METHOD CPU:getValueFromMemory( cAddress )
   /*
      Para acessar a memoria setamos a flag da memória (registrador MF) para leitura, atribuímos o endereço
        ao registrador de endereço, e ativamos a memória.
   */
   ::hRegisters[ "MF" ] := MEM_GET
   ::hRegisters[ "MAR" ] := Val( cAddress )
   ::oMemory:loadValue( Self )

RETURN ::hRegisters[ "MBR" ]
/******************************************************************************/
METHOD CPU:writeValueInMemory( cAddress, xValue )
   /*
      Para escrever na memoria setamos a flag da memória (registrador MF) para escrita, atribuímos o endereço
        ao registrador de endereço, o valor ao registrador de dados, e ativamos a memória.
   */
   ::hRegisters[ "MF" ] := MEM_SET
   ::hRegisters[ "MAR" ] := Val( cAddress )
   ::hRegisters[ "MBR" ] := xValue
   ::oMemory:loadValue( Self )

RETURN Self
/******************************************************************************/
METHOD CPU:setValueIn( cAddress, xValue )

   IF ::checkRegister( cAddress )
      /*
         Caso o operador endereço seja um registrador, a CPU faz o manejamento
      */
      ::hRegisters[ cAddress ] := xValue
   ELSE
      IF ::checkPointer( cAddress )
         /*
            Endereçamento direto
            Caso o operador endereço seja um endereço para a memória (entre parênteses), preparamos o ambiente
         */
         ExtractAddress( @cAddress )
         /*
            Caso seja um registrador aninhado por parênteses, buscamos o endereco armazenado nele, como se fosse
              um ponteiro. Exemplo: (AX) nos faz buscar na memória o conteúdo do endereco de valor igual a AX.
         */
         IF ::checkRegister( cAddress )
            cAddress := Str( ::hRegisters[ cAddress ] )
         ELSE
            cAddress := Str( ::getValueFromMemory( cAddress ) )
         ENDIF
      ENDIF
      ::writeValueInMemory( cAddress, xValue )
   ENDIF

RETURN Self
/******************************************************************************/
METHOD CPU:exit()

RETURN ::hRegisters[ "IR" ] == OP_EXIT
/******************************************************************************/
/* Initialization *************************************************************/
/******************************************************************************/
STATIC FUNCTION InitializeOperations()

   LOCAL hOperations

   hOperations := Hb_Hash()

   Hb_HSet( hOperations, OP_ADD, { |o| Operations_Add( o ) } )
   Hb_HSet( hOperations, OP_SUB, { |o| Operations_Sub( o ) } )
   Hb_HSet( hOperations, OP_MUL, { |o| Operations_Mul( o ) } )
   Hb_HSet( hOperations, OP_DIV, { |o| Operations_Div( o ) } )
   Hb_HSet( hOperations, OP_CMP, { |o| Operations_Cmp( o ) } )
   Hb_HSet( hOperations, OP_MOV, { |o| Operations_Mov( o ) } )
   Hb_HSet( hOperations, OP_JE , { |o| Operations_Je(  o ) } )
   Hb_HSet( hOperations, OP_JNE, { |o| Operations_Jne( o ) } )
   Hb_HSet( hOperations, OP_JA , { |o| Operations_Ja(  o ) } )
   Hb_HSet( hOperations, OP_JAE, { |o| Operations_Jae( o ) } )
   Hb_HSet( hOperations, OP_JB , { |o| Operations_Jb(  o ) } )
   Hb_HSet( hOperations, OP_JBE, { |o| Operations_Jbe( o ) } )
   Hb_HSet( hOperations, OP_J  , { |o| Operations_J(   o ) } )

RETURN hOperations
/******************************************************************************/
STATIC FUNCTION InitializeRegisters()

   LOCAL hRegisters

   hRegisters = Hb_Hash()

   Hb_HSet( hRegisters, "PC" , 0 )
   Hb_HSet( hRegisters, "IR" , 0 )
   Hb_HSet( hRegisters, "MAR", 0 )
   Hb_HSet( hRegisters, "MBR", 0 )

   Hb_HSet( hRegisters, "AX" , 0 )
   Hb_HSet( hRegisters, "BX" , 0 )
   Hb_HSet( hRegisters, "CX" , 0 )
   Hb_HSet( hRegisters, "DX" , 0 )
   Hb_HSet( hRegisters, "BX2", 0 )
   Hb_HSet( hRegisters, "CX2", 0 )

   Hb_HSet( hRegisters, "SF" , 0 )
   Hb_HSet( hRegisters, "ZF" , 0 )
   Hb_HSet( hRegisters, "CF" , 0 )
   Hb_HSet( hRegisters, "MF" , 0 )

RETURN hRegisters
/******************************************************************************/