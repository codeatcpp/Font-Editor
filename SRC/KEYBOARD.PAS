(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Модуль клавиатуры                                          *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT  Keyboard;

INTERFACE

uses CRT,
     DOS;

VAR
  Code : byte;
  Symbol : char;
  OldKeyInt : pointer;

CONST
    scNoKey   = 255;
    scEsc   = 1;                     { Скэн-коды клавиш }
    sc1     = 2;
    sc2     = 3;
    sc3     = 4;
    sc4     = 5;
    sc5     = 6;
    sc6     = 7;
    sc7     = 8;
    sc8     = 9;
    sc9     = 10;
    sc0     = 11;
    scMinus = 12;
    scPlus  = 13;
    scBackSpace  = 14;
    scTAB   = 15;
    scQ     = 16;
    scW     = 17;
    scE     = 18;
    scR     = 19;
    scT     = 20;
    scY     = 21;
    scU     = 22;
    scI     = 23;
    scO     = 24;
    scP     = 25;
    scLS    = 26;
    scRS    = 27;
    scEnter = 28;
    scCtrl  = 29;
    scA     = 30;
    scS     = 31;
    scD     = 32;
    scF     = 33;
    scG     = 34;
    scH     = 35;
    scJ     = 36;
    scK     = 37;
    scL     = 38;
    scDPoint      = 39;
    scApostr      = 40;
    scApostr2     = 41;
    scShiftL      = 42;
    scZ     = 44;
    scX     = 45;
    scC     = 46;
    scV     = 47;
    scB     = 48;
    scN     = 49;
    scM     = 50;
    scLess  = 51;
    scMore  = 52;
    scQuest = 53;
    scShiftR      = 54;
    scPrintScreen = 55;
    scAlt   = 56;
    scSpace = 57;
    scCapsLock    = 58;
    scF1    = 59;
    scF2    = 60;
    scF3    = 61;
    scF4    = 62;
    scF5    = 63;
    scF6    = 64;
    scF7    = 65;
    scF8    = 66;
    scF9    = 67;
    scF10   = 68;
    scNumLock    = 69;
    scScrollLock = 70;
    scHome  = 71;
    scUp    = 72;
    scPgUp  = 73;
    scMinus2     = 74;
    scLeft  = 75;
    sc52    = 76;
    scRight = 77;
    scPlus2 = 78;
    scEnd   = 79;
    scDown  = 80;
    scPgDn  = 81;
    scIns   = 82;
    scDel   = 83;
    scWAlt  = 128;
    scWCtrl = 256;
    scWShift = 512;

Procedure ClearBuf;                  { очищает буфер клавиатуры          }
Procedure GetSymbol;
Procedure NewKeyInt; INTERRUPT;
Procedure KeyIntInit;
Procedure KeyIntDone;

IMPLEMENTATION

Procedure KeyIntInit;
begin
  GetIntVec(9,OldKeyInt);
  SetIntVec(9,@NewKeyInt);
end;

Procedure KeyIntDone;
begin
  SetIntVec(9,OldKeyInt);
end;

Procedure ClearBuf; ASSEMBLER;

label test,return;

asm
  TEST:
            mov  ah,11
            int  33
            or   AL,AL
            jz   RETURN
            mov  ah,7
            int  33
            jmp  TEST
  RETURN:
end;

Procedure NewKeyInt;
begin
  asm
    push ax
    in al,60h
    mov Code,al
    pop ax
    jmp OldKeyInt;
    {
    in al,61h
    mov ah,al
    or al,80h
    out 61h,al
    mov al,ah
    out 61h,al
    mov al,20h
    out 20h,al
    }
  end;
end;

Procedure GetSymbol;
begin
  if keypressed then
    begin
      asm
        mov ah,0
        int 16h
        mov Symbol,al
      end;
    end
  else
    begin
      Symbol:=#0;
    end;
  asm
  end;
end;

END.