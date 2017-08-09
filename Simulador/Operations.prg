/******************************************************************************
* Criado em.....: 28/06/17 21:52:35
* Funcao........: Funcoes das operações
******************************************************************************/
#include 'Operations.ch'
/******************************************************************************/
function Operations_Name( nOperationId )
   /*
      Baseado no OPcode, retorna a descrição da operação
   */
   switch nOperationId
      case OP_EXIT;return "EXIT"
      case OP_ADD ;return "ADD"
      case OP_SUB ;return "SUB"
      case OP_MUL ;return "MUL"
      case OP_DIV ;return "DIV"
      case OP_CMP ;return "CMP"
      case OP_MOV ;return "MOV"
      case OP_JE  ;return "JE"
      case OP_JNE ;return "JNE"
      case OP_JA  ;return "JA"
      case OP_JAE ;return "JAE"
      case OP_JB  ;return "JB"
      case OP_JBE ;return "JBE"
      case OP_J   ;return "J"
   end switch

return ""
/******************************************************************************/
function Operations_Id( cOperationName )
   /*
      Baseado na descrição, retorna o OPcode da operação
   */
   switch cOperationName
      case "EXIT";return OP_EXIT
      case "ADD" ;return OP_ADD
      case "SUB" ;return OP_SUB
      case "MUL" ;return OP_MUL
      case "DIV" ;return OP_DIV
      case "CMP" ;return OP_CMP
      case "MOV" ;return OP_MOV
      case "JE"  ;return OP_JE
      case "JNE" ;return OP_JNE
      case "JA"  ;return OP_JA
      case "JAE" ;return OP_JAE
      case "JB"  ;return OP_JB
      case "JBE" ;return OP_JBE
      case "J"   ;return OP_J
   end switch

return 0
/******************************************************************************/
procedure Operations_Add( oCpu )
   /*
      Soma o valor do primeiro operando ao segundo e armazena no primeiro.
   */
   local n1, n2

   n1 := oCpu:getValueIn( oCpu:getOperator1() )
   if oCpu:checkRegister( oCpu:getOperator2() )
      n2 := oCpu:getValueIn( oCpu:getOperator2() )
   elseif oCpu:checkPointer( oCpu:getOperator2() )
      n2 := oCpu:getValueIn( ExtractAddress( oCpu:getOperator2() ) )
   else
      n2 := Val( oCpu:getOperator2() )
   endif

   oCpu:setValueIn( oCpu:getOperator1(),;
                    n1+n2 )

return
/******************************************************************************/
procedure Operations_Sub( oCpu )
   /*
      Subtrai o valor do primeiro operando do segundo e armazena no primeiro.
   */
   local n1, n2

   n1 := oCpu:getValueIn( oCpu:getOperator1() )
   if oCpu:checkRegister( oCpu:getOperator2() )
      n2 := oCpu:getValueIn( oCpu:getOperator2() )
   elseif oCpu:checkPointer( oCpu:getOperator2() )
      n2 := oCpu:getValueIn( ExtractAddress( oCpu:getOperator2() ) )
   else
      n2 := Val( oCpu:getOperator2() )
   endif

   oCpu:setValueIn( oCpu:getOperator1(),;
                    n1-n2 )
return
/******************************************************************************/
procedure Operations_Mul( oCpu )
   /*
      Multiplica o AX pelo operando
   */
   local nMultiplier

   if oCpu:checkPointer( oCpu:getOperator1() )
      nMultiplier := oCpu:getValueIn( oCpu:getOperator1() )
   else
      nMultiplier := Val( oCpu:getOperator1() )
   endif

   oCpu:setValueIn( "AX", nMultiplier*oCpu:getValueIn( "AX" ) )

return
/******************************************************************************/
procedure Operations_Div( oCpu )
   /*
      Divide o AX pelo operando, e armazena no AX. O resto é armazenado em DX
   */
   local nInitialAx, nDivider

   if oCpu:checkPointer( oCpu:getOperator1() )
      nDivider := oCpu:getValueIn( oCpu:getOperator1() )
   else
      nDivider := Val( oCpu:getOperator1() )
   endif

   oCpu:setValueIn( "AX", nMultiplier*oCpu:getValueIn( "AX" ) )

   nInitialAx := oCpu:getValueIn( "AX" )

   oCpu:setValueIn( "AX", Int( nInitialAx/nDivider ) )
   oCpu:setValueIn( "DX", nInitialAx%nDivider )

return
/******************************************************************************/
procedure Operations_Cmp( oCpu )
   /*
      Compara dois operandos e seta os flags de acordo com o resultado
      SF se o resultado for negativo
      ZF se o resultado for zero
   */
   local nValueOne, nValueTwo, nResult

   nValueOne := oCpu:getValueIn( oCpu:getOperator1() )
   if oCpu:checkPointer( oCpu:getOperator2() )
      nValueTwo := oCpu:getValueIn( ExtractAddress( oCpu:getOperator2() ) )
   elseif oCpu:checkRegister( oCpu:getOperator2() )
      nValueTwo := oCpu:getValueIn( oCpu:getOperator2() )
   else
      nValueTwo := Val( oCpu:getOperator2() )
   endif

   nResult := nValueOne - nValueTwo

   if nResult >= 0
      oCpu:setValueIn( "SF", 0 )
      oCpu:setValueIn( "CF", 0 )
      if nResult == 0
         oCpu:setValueIn( "ZF", 1 )
      else
         oCpu:setValueIn( "ZF", 0 )
      endif
   else
      oCpu:setValueIn( "CF", 1 )
      oCpu:setValueIn( "SF", 1 )
      oCpu:setValueIn( "ZF", 0 )
   endif

return
/******************************************************************************/
procedure Operations_Mov( oCpu )

   local xValue

   if oCpu:checkPointer( oCpu:getOperator2() )
      xValue := oCpu:getValueIn( ExtractAddress( oCpu:getOperator2() ) )
   else
      xValue := Val( oCpu:getOperator2() )
   endif

   oCpu:setValueIn( oCpu:getOperator1(), xValue )

return
/******************************************************************************/
procedure Operations_Je( oCpu )
   /*
      Salta para um novo endereço de instrução caso o resultado da última comparação
        seja "iguais"
   */
   if oCpu:getRegisters()[ "ZF" ] == 1
      Jump( oCpu, oCpu:getOperator1() )
   endif

return
/******************************************************************************/
procedure Operations_Jne( oCpu )
   /*
      Salta para um novo endereço de instrução caso o resultado da última comparação
        seja "diferentes"
   */
   if oCpu:getRegisters()[ "ZF" ] == 0
      Jump( oCpu, oCpu:getOperator1() )
   endif

return
/******************************************************************************/
procedure Operations_Ja( oCpu )
   /*
      Salta para um novo endereço de instrução caso o resultado da última comparação
        seja "primeiro maior que o segundo"
   */
   if oCpu:getRegisters()[ "CF" ] == 0 .and.;
      oCpu:getRegisters()[ "ZF" ] == 0

      Jump( oCpu, oCpu:getOperator1() )
   endif

return
/******************************************************************************/
procedure Operations_Jae( oCpu )
   /*
      Salta para um novo endereço de instrução caso o resultado da última comparação
        seja "primeiro maior ou igual ao segundo"
   */
   if oCpu:getRegisters()[ "CF" ] == 0
      Jump( oCpu, oCpu:getOperator1() )
   endif

return
/******************************************************************************/
procedure Operations_Jb( oCpu )
   /*
      Salta para um novo endereço de instrução caso o resultado da última comparação
        seja "primeiro menor que o segundo"
   */
   if oCpu:getRegisters()[ "CF" ] == 1
      Jump( oCpu, oCpu:getOperator1() )
   endif

return
/******************************************************************************/
procedure Operations_Jbe( oCpu )
   /*
      Salta para um novo endereço de instrução caso o resultado da última comparação
        seja "primeiro menor ou igual ao segundo"
   */
   if oCpu:getRegisters()[ "CF" ] == 1 .or.;
      oCpu:getRegisters()[ "ZF" ] == 1

      Jump( oCpu, oCpu:getOperator1() )
   endif

return
/******************************************************************************/
procedure Operations_J( oCpu )
   /*
      Salta para um novo endereço de instrução
   */
   Jump( oCpu, oCpu:getOperator1() )

return
/******************************************************************************/
static procedure Jump( oCpu, cAddress )
   /*
      Atribui o um novo endereço para o PC
   */
   if oCpu:checkPointer( cAddress )
      oCpu:getRegisters()[ "PC" ] := oCpu:getValueIn( ExtractAddress( cAddress ) )
   else
      oCpu:getRegisters()[ "PC" ] := Val( cAddress )
   endif

return
/******************************************************************************/
