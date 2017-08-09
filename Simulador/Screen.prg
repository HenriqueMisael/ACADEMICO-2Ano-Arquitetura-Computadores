/******************************************************************************
* Criado em.....: 31/05/17 22:44:35
* Funcao........: Classe para controle das telas
******************************************************************************/
#include 'HbClass.ch'
/******************************************************************************/
CLASS TScreen

   EXPORTED:
      METHOD store( cDescription )
      METHOD restore( cDescription )

   HIDDEN:
      VAR hScreens INIT Hb_Hash()

END CLASS
/******************************************************************************/
METHOD TScreen:store( cDescription )

   Hb_HSet( ::hScreens, cDescription, { SetColor(), SaveScreen() } )

RETURN Self
/******************************************************************************/
METHOD TScreen:restore( cDescription )

   SetColor( ::hScreens[ cDescription, 1 ] )
   RestScreen( ,,,,::hScreens[ cDescription, 2 ] )

RETURN Self
/******************************************************************************/