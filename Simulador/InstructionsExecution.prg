/******************************************************************************
* Criado em.....: 28/06/17 21:52:35
* Funcao........: Funções para execução de instruções
******************************************************************************/
static s_nFirstDataAddress, s_nFirstInstructionAddress, s_nMemorySize
/******************************************************************************/
procedure SetSettings( hConfig )

   s_nFirstDataAddress        := hConfig[ "DataAddress" ]
   s_nFirstInstructionAddress := hConfig[ "Instruction" ]
   s_nMemorySize              := hConfig[ "MemorySize"  ]

return
/******************************************************************************/
function GetSettings()

   if Hb_IsNil( s_nFirstDataAddress )
      s_nFirstDataAddress        := 0
      s_nFirstInstructionAddress := 32
      s_nMemorySize              := 64
   endif

return Hb_Hash( "DataAddress", s_nFirstDataAddress       ,;
                "Instruction", s_nFirstInstructionAddress,;
                "MemorySize" , s_nMemorySize              )
/******************************************************************************/
procedure ExecuteInstructions( cFile )

   local oCpu, oMemory
   local cInstruction
   local lExecuteFile

   cls

   lExecuteFile := !Empty( cFile ) .and. File( cFile )
   GetSettings()
   oMemory := MainMemory():new( s_nFirstDataAddress, s_nFirstInstructionAddress, s_nMemorySize )
   oCpu := CPU():new( oMemory )

   if lExecuteFile
      oMemory:loadFromFile( cFile )
      cMensagem := "Pressione F1 para pausar a execucao e ver todos os enderecos de memoria de dados. Pressione F2 para pausar a execucao e ver todos os enderecos de memoria de instrucao."
      @ 24,02 say "Pressione ENTER para prosseguir para a proxima instrucao."
   else
      cMensagem := "Pressione F1 para pausar a execucao e ver todos os enderecos de memoria de dados."
      SetKey( 28, { || ShowMemoryData( oMemory ) } )
      @ 24,00 say ">"
   endif
   Alert( cMensagem )

   @ 00,00 say "REGISTRADORES:"
   @ 3,0 to 3,79
   @ 23,0 to 23,79


   do while .t.

      WriteRegisters( oCpu )

      if lExecuteFile
         oCPU:nextInstruction()
      else
         AskInstruction( @cInstruction )
         oCPU:feedInstruction( cInstruction )
      endif

      if oCpu:exit()
         exit
      else
         if oCpu:executeInstruction()
            if Empty( cInstruction )
               WriteMessage( "Executada operacao '" + Operations_Name( oCpu:getRegisters()[ "IR" ] ) + "'." )
            else
               WriteMessage( cInstruction )
            endif
         elseif !Empty( oCpu:getError() )
            WriteMessage( oCpu:getError() )
         endif
         if lExecuteFile
            switch Inkey( 0 )
               case -1
                  ShowMemoryInstructions( oMemory )
                  exit
               case 28
                  ShowMemoryData( oMemory )
                  exit
            endswitch
         endif
      endif
   enddo

return
/******************************************************************************/
static procedure AskInstruction( cInstruction )

   local GetList := {}
   local cUserInput

   do while Empty( cUserInput )
      cUserInput := PadR( "Digite uma instrucao a ser executada. 'EXIT' para sair.", 78 )
      @ 24,02 get cUserInput color "W/N" picture '@!' valid !Empty( cUserInput )
      Inkey(0)
      cUserInput := Space( 78 )
      Hb_KeyPut( LastKey() )
      read

      if LastKey() != 27
         exit
      endif
   enddo

   cInstruction := AllTrim( cUserInput ) //Retirar espaços em branco

return
/******************************************************************************/
static procedure WriteMessage( cMessage )

   if !Empty( cMessage )
      //Salva o conteúdo da linha 5 (segunda mensagem mostrada) até a linha 22 (última mensagem mostrada)
      // e restaura uma linha acima, liberando um espaço para a próxima mensagem
      RestScreen( 4, 0, 21, 79, SaveScreen( 5, 0, 22, 79 ) )
      @ 22,00 say PadR( '[' + Time() + '] ' + cMessage, 80 ) //Garantir que aepnas 80 caracteres serão impressos
   endif

return
/******************************************************************************/
static procedure WriteRegisters( oCpu )

   //Escrevemos os registradores de flag, que só possuem 1 dígito
   @ 1,00 say ConcatRegister( oCpu, "SF", 1 )
   @ 1,10 say ConcatRegister( oCpu, "ZF", 1 )
   @ 2,00 say ConcatRegister( oCpu, "CF", 1 )
   @ 2,10 say ConcatRegister( oCpu, "MF", 1 )

   //Escrevemos os registradores de controle da CPU
   @ 1,20 say ConcatRegister( oCpu, "PC" , 3 )
   @ 1,32 say ConcatRegister( oCpu, "IR" , 3 )
   @ 2,20 say ConcatRegister( oCpu, "MAR", 3 )
   @ 2,32 say ConcatRegister( oCpu, "MBR", 3 )

   //Escrevemos os demais registradores
   @ 1,44 say ConcatRegister( oCpu, "AX" , 5 )
   @ 1,56 say ConcatRegister( oCpu, "BX" , 5 )
   @ 1,70 say ConcatRegister( oCpu, "BX2", 5 )
   @ 2,44 say ConcatRegister( oCpu, "CX" , 5 )
   @ 2,56 say ConcatRegister( oCpu, "CX2", 5 )
   @ 2,70 say ConcatRegister( oCpu, "DX" , 5 )

return
/******************************************************************************/
static function ConcatRegister( oCpu, cRegister, nSize )

   if Hb_IsNil( nSize )
      nSize := 5
   endif

return PadL( cRegister, 3 ) + ': ' + StrZero( oCpu:getRegisters()[ cRegister ], nSize )
/******************************************************************************/
procedure ShowMemoryData( oMemory )

   local oScreen := TScreen():store( "Anterior" )
   local aMemoryAddresses
   local nAddress
   local x, y

   aMemoryAddresses := Hb_HKeys( oMemory:getDataHash() )

   cls
   @ 00,00 say "ENDERECOS DE MEMORIA COM DADOS"

   for x := 0 to 79 step 10
      for y = 1 to 24 step 1
         nAddress := aMemoryAddresses[ 1 ]
         @ y,x   say StrZero( nAddress, 3 ) + ': ' color "W+/N"
         @ y,x+4 say StrZero( oMemory:getDataHash()[nAddress], 5 ) color "W/N"

         @ y,x+9 say "|" color "W+/N"

         Hb_ADel( aMemoryAddresses, 1, .t. )
         if Empty( aMemoryAddresses )
            exit
         endif
      next
      if Empty( aMemoryAddresses )
         exit
      endif
   next

   Inkey(0)

   oScreen:restore( "Anterior" )

return
/******************************************************************************/
procedure ShowMemoryInstructions( oMemory )

   local oScreen := TScreen():store( "Anterior" )
   local aMemoryAddresses
   local nAddress
   local x, y

   aMemoryAddresses := Hb_HKeys( oMemory:getInstructionsHash() )

   cls
   @ 00,00 say "ENDERECOS DE MEMORIA COM INSTRUCOES"

   for x := 0 to 79 step 20
      for y = 1 to 24 step 1
         nAddress := aMemoryAddresses[ 1 ]
         @ y,x   say StrZero( nAddress, 3 ) + ': ' color "W+/N"
         @ y,x+4 say oMemory:getInstructionsHash()[nAddress] color "W/N"

         @ y,x+19 say "|" color "W+/N"

         Hb_ADel( aMemoryAddresses, 1, .t. )
         if Empty( aMemoryAddresses )
            exit
         endif
      next
      if Empty( aMemoryAddresses )
         exit
      endif
   next

   Inkey(0)

   oScreen:restore( "Anterior" )

return
/******************************************************************************/
