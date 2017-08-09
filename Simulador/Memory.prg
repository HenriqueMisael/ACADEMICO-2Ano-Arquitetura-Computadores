/******************************************************************************
* Criado em.....: 28/06/17 21:52:35
* Funcao........: Classe para servir de interface para as operações da Memória Principal
******************************************************************************/
#include 'HbClass.ch'
#include 'Memory.ch'
/******************************************************************************/
CLASS MainMemory

   EXPORTED:
      METHOD new( nDataStart, nInstructionsStart, nSize )
      METHOD getDataHash()          INLINE ::hData
      METHOD getInstructionsHash()  INLINE ::hInstructions
      METHOD getFirstInstruction()  INLINE ::nInstructionsStart
      METHOD loadFromFile( cFile )
      METHOD loadValue( oCpu )

   HIDDEN:
      METHOD allocate( hHash, nStart, nEnd )
      VAR hData              INIT Hb_Hash()
      VAR hInstructions      INIT Hb_Hash()
      VAR nInstructionsStart INIT 0

END CLASS
/******************************************************************************/
/* EXPORTED METHODS ***********************************************************/
/******************************************************************************/
METHOD MainMemory:new( nDataStart, nInstructionsStart, nSize )

   IF nDataStart < nInstructionsStart
      ::allocate( ::hData, nDataStart, nInstructionsStart-1, 0 )
      ::allocate( ::hInstructions, nInstructionsStart, nSize, "" )
   ELSE
      ::allocate( ::hInstructions, nInstructionsStart, nDataStart-1, "" )
      ::allocate( ::hData, nDataStart, nSize, 0 )
   ENDIF

   ::nInstructionsStart := nInstructionsStart

RETURN Self
/******************************************************************************/
METHOD MainMemory:loadValue( oCpu )

   SWITCH oCpu:getRegisters()[ "MF" ]
      CASE MEM_GET
         oCpu:getRegisters[ "MBR" ] := ::hData[ oCpu:getRegisters[ "MAR" ] ]
         EXIT
      CASE MEM_SET
         ::hData[ oCpu:getRegisters[ "MAR" ] ] := oCpu:getRegisters[ "MBR" ]
         EXIT
   END

RETURN Self
/******************************************************************************/
METHOD MainMemory:loadFromFile( cFile )

   LOCAL aInstructions
   LOCAL nLine

   aInstructions := Hb_ATokens( MemoRead( cFile ), Chr( 13 ) + Chr( 10 ) )

   FOR nLine := 1 to Len( aInstructions )
      aInstructions[ nLine ] := HB_ATokens( aInstructions[ nLine ], "//" )[1]
      ::hInstructions[ nLine-1+::nInstructionsStart ] := aInstructions[ nLine ]
      IF nLine > Len( ::hInstructions )
         EXIT
      ENDIF
   NEXT

RETURN Self
/******************************************************************************/
METHOD MainMemory:allocate( hHash, nStart, nEnd, cEmpty )

   LOCAL nAddress
   /*
      Alocando posições de memória para o tamanho requerido
   */
   FOR nAddress := nStart TO nEnd
      Hb_HSet( hHash, nAddress, cEmpty )
   NEXT

RETURN Self
