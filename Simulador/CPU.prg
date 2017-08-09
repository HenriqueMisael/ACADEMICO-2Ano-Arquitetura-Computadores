/******************************************************************************
* Criado em.....: 28/06/17 21:52:35
* Funcao........: Classe para servir de interface para as opera��es da CPU
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
        Se a instru��o for vazia, ent�o zera o registrador de instru��o
      */
      ::hRegisters[ "IR" ] := OP_NONE
   ELSE
      /*
        Caso seja uma STRING de instru��o, separamos em um vetor de 3 strings, a fim de
          separar a opera��o (atribu�do o devido op code ao IR, e os operadores
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
        Se houver espa�o na mem�ria de instru��es, ent�o alimentaremos o contexto
          da CPU com a pr�xima instru��o da mem�ria
      */
      ::feedInstruction( ::oMemory:getInstructionsHash()[ ::hRegisters[ "PC" ]++ ] )
   ELSE
      /*
        Caso tenha chegado ao fim da mem�ria, finalizamos a simula��o
      */
      ::hRegisters[ "IR" ] := OP_EXIT
   ENDIF


RETURN Self
/******************************************************************************/
METHOD CPU:executeInstruction()

   LOCAL lReturn

   IF Empty( ::hRegisters[ "IR" ] )
      /*
        OP code em branco significa esperar o pr�ximo ciclo de instru��o. Gera erro para explicar o
          motivo de n�o executar nada.
      */
      ::cError := "Momento de espera (operacao em branco)"
      lReturn := .F.
   ELSE
      IF HB_HHasKey( ::hOperations, ::hRegisters[ "IR" ] )
         /*
            Buscamos na lista de instru��es da CPU aquela que se adequa ao OPcode do IR
              e executamos
         */
         ::hOperations[ ::hRegisters[ "IR" ] ]:eval( Self )
         lReturn := .T.
      ELSE
         /*
            Se o OPcode n�o for encontrado na lista de instru��es, ent�o apresentamos erro
              de que a opera��o n�o foi prevista na arquitetura da CPU
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
         Caso o operador endere�o seja um registrador, o valor a ser utilizado � o armazenado em registrador
           da CPU.
      */
      xValue := ::hRegisters[ cAddress ]
   ELSE
      IF Left( cAddress, 1 ) == '('
         /*
            Endere�amento direto
            Caso o operador endere�o seja um endere�o para a mem�ria (entre par�nteses), preparamos o ambiente
         */
         ExtractAddress( @cAddress )
         /*
            Caso seja um registrador aninhado por par�nteses, buscamos o endereco armazenado nele, como se fosse
              um ponteiro. Exemplo: (AX) nos faz buscar na mem�ria o conte�do do endereco de valor igual a AX.
         */
         IF ::checkRegister( cAddress )
            cAddress := Str( ::hRegisters[ cAddress ] )
         ELSE
            cAddress := Str( ::getValueFromMemory( cAddress ) )
         ENDIF
      ENDIF
      /*
        Endere�amento imediato
        Se o operador for um valor (nem registrador, nem endere�o), ent�o n�o h� o que fazer com ele.
      */
      xValue := ::getValueFromMemory( cAddress )
   ENDIF

RETURN xValue
/******************************************************************************/
METHOD CPU:getValueFromMemory( cAddress )
   /*
      Para acessar a memoria setamos a flag da mem�ria (registrador MF) para leitura, atribu�mos o endere�o
        ao registrador de endere�o, e ativamos a mem�ria.
   */
   ::hRegisters[ "MF" ] := MEM_GET
   ::hRegisters[ "MAR" ] := Val( cAddress )
   ::oMemory:loadValue( Self )

RETURN ::hRegisters[ "MBR" ]
/******************************************************************************/
METHOD CPU:writeValueInMemory( cAddress, xValue )
   /*
      Para escrever na memoria setamos a flag da mem�ria (registrador MF) para escrita, atribu�mos o endere�o
        ao registrador de endere�o, o valor ao registrador de dados, e ativamos a mem�ria.
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
         Caso o operador endere�o seja um registrador, a CPU faz o manejamento
      */
      ::hRegisters[ cAddress ] := xValue
   ELSE
      IF ::checkPointer( cAddress )
         /*
            Endere�amento direto
            Caso o operador endere�o seja um endere�o para a mem�ria (entre par�nteses), preparamos o ambiente
         */
         ExtractAddress( @cAddress )
         /*
            Caso seja um registrador aninhado por par�nteses, buscamos o endereco armazenado nele, como se fosse
              um ponteiro. Exemplo: (AX) nos faz buscar na mem�ria o conte�do do endereco de valor igual a AX.
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