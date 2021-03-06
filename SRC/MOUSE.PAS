(*************************************************************************)
(*  �஥�� :  Font Editor for DOS                                        *)
(*            ����� ࠡ��� � �����                                      *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    ����  : �濫��᪨� ��ਫ�                                         *)
(*    ���   : 12.07.96                            �. ����ᠭ�஢        *)
(*************************************************************************)
{$I PARAMS}
UNIT MOUSE;

INTERFACE

var
  MouseError : shortint;               { ��� �訡��                       }
  NumButtons : byte;                   { ������⢮ ������ ���           }

type

  {-------    ⨯� �����    -------}

  TCurType=(Programmed,              { �ணࠬ��                         }
            Apparat);                { �������                         }

const

  {---    ����⠭�� ⨯�� ���    ---}

  ParalMouse  = 1;                   { ��ࠫ���쭠� ����                 }
  PosledMouse = 2;                   { ��᫥����⥫쭠� ����             }
  PortMouse   = 3;                   { ������砥��� � ����� ����         }
  PS_2Mouse   = 4;                   { ���� PS/2                         }
  HPMouse     = 5;                   { ���� ��� �Hewlett-Packard�      }

  {-----    ����⠭�� �訡��    -----}

  msOk        =  0;                  { �ᯥ譮� �믮������                }
  msNoDriver  = -1;                  { �ࠩ��� ��� �� ��⠭�����         }
  msNoPresent = -2;                  { ���� ���������                   }

  {----  ����⠭�� ������ ���   ----}

  LeftKey   = 1;
  RightKey  = 2;
  MiddleKey = 4;

  {--------   ������ ���   --------}

const
  Arrow1 : array [0..31] of word =
         (16383,08191,04095,04095,
          01023,00511,00255,00127,
          00063,00127,00511,04351,
          45311,63615,63615,64767,
          00000,16384,24576,28672,
          30720,31744,32256,32512,
          32640,31744,27648,17920,
          01536,00768,00768,00000);
  Arrow2 : array [0..31] of word =
         (40959,01023,00127,32783,
          32769,32768,49153,49167,
          49407,57599,57599,57599,
          61951,61951,61951,64511,
          00000,24576,31744,16256,
          16368,16382,08176,07680,
          07680,03584,03584,03584,
          01024,01024,01024,00000);
  Lupa : array [0..31] of word =
         (61567,57407,49183,34183,
          04167,00199,00967,00967,
          06087,36743,49155,57345,
          61440,65472,65504,65521,
          00000,03968,04160,08224,
          18192,18448,18448,18448,
          16400,08240,04216,04092,
          00062,00030,00014,00000);

  { ���樫������ �ࠩ��� ���                                            }
Procedure InitMouse;
  { �������� ����� ���                                                  }
Procedure MouseShow;
  { ������ ����� ���                                                  }
Procedure MouseHide;
  { ������� ���न���� ��થ� ���                                      }
Procedure GetMouseXY(var X,Y : word);
  { ��⠭����� ���न���� ��થ� ���                                    }
Procedure SetMouseXY(X,Y : word);
  { ���ﭨ� ������ ���                                                 }
Function  PushKey(Key : byte):boolean;
  { ��।����� �࠭��� ��।������� ���                                  }
Procedure SetLimMove(x0,y0,          { ���� ���孨� 㣮�                 }
                     x1,y1           { �ࠢ� ������ 㣮�                 }
                          : word);
  { ࠧ���� ������ ᢥ⮢��� ���                                     }
Procedure SetPenEmul;
  { ������� ������ ᢥ⮢��� ���                                     }
Procedure ClrPenEmul;
  { ��।����� ������� �᪫�祭��                                         }
Procedure SetElimSpace(x0,y0,        { ���� ���孨� 㣮�                 }
                       x1,y1         { �ࠢ� ������ 㣮�                 }
                            : word);
  { ��।����� ࠧ��� ���� ��� �࠭���� ���ଠ樨 � ���ﭨ� ���     }
Function  GetBufSize:word;
  { ��࠭��� ⥪�饥 ���ﭨ� ���                                      }
Procedure SaveMouseInfo(const Buf);
  { ����⠭����� ���ﭨ� ���                                           }
Procedure LoadMouseInfo(const Buf);
  { ��।����� �᫮ ����⨩ ������ ���                                  }
Procedure MouseGetNP(Key             { �஢��塞�� ������                }
                        :byte;
                     var   Count,      { ������⢮ ����⨩               }
                           LastX,LastY { ���न���� ��᫥����� ������    }
                                      : word);
 { ��⠭����� ���짮��⥫�᪨� ����� ��� ( ����᪨� ०�� )          }
Procedure SetNewGCursor(Width,       { �ਭ� ��થ�                     }
                        Height       { ���� ��થ�                     }
                              : word;
                        PBitmap      { 㪠��⥫� �� ��⮢�� ����          }
                               : pointer);
 { ��⠭����� ���짮��⥫�᪨� ����� ��� ( ⥪�⮢� ०�� )            }
Procedure SetNewTCursor(CurType      { ⨯ �����                        }
                               : TCurType;
                                     {   �������    �    �ணࠬ��    }
                                     {������������������������������������}
                        Param1,      { ��砫쭠� ����� �    ��᪠ AND     }
                        Param2       { ����筠�  ����� �    ��᪠ XOR     }
                              :word);
  { ������ ᪮���� ��થ�                                               }
Procedure SetCursorSpeed(GorizSpeed, { �᫮ ����� �� ��ਧ��⠫�         }
                         VertSpeed   { �᫮ ����� �� ���⨪���           }
                                  : word);
  { ������� ��࠭��� ��࠭��� �� ���ன �⮡ࠦ����� ����� ���         }
Procedure SetNumPage(Page : word);
  { ��।������ ⨯� ���          ( ࠡ�⠥� ���ࠢ��쭮 )               }
Procedure GetMouseVersion(var
                          Version    { ����� �ࠩ��� ���               }
                             : word;
                          var
                          MType,     { ⨯ ���                           }
                          NumIRQ     { ����� IRQ                          }
                            : byte);
  { ���� � �������� �࠭��� ?                                            }
Function MouseInsert(x,y,dx,dy : word) : boolean;

IMPLEMENTATION

USES  DOS;

var R            : Registers;
    IntVec       : pointer;
    MousePresent : boolean;

Procedure GetMouseVersion;
begin
  R.AX:=$24;
  Intr($33,R);
  Version:=R.BL shl 8+R.BH;
  MType:=R.CH;
  NumIRQ:=R.CL;
end;

Procedure SetNumPage; ASSEMBLER;
asm
  mov ax,1Eh
  mov bx,page
  int 33h
end;

Procedure SetCursorSpeed; ASSEMBLER;
asm
  mov ax,0Fh
  mov cx,GorizSpeed
  mov dx,VertSpeed
  int 33h
end;

Procedure SetNewTCursor;
begin
  if CurType=Programmed then
    asm
      mov ax,0Ah
      mov bx,0
      mov cx,Param1
      mov dx,Param2
      int 33h
    end
  else
    asm
      mov ax,0Ah
      mov bx,1
      mov cx,Param1
      mov dx,Param2
      int 33h
    end
end;

Procedure SetNewGCursor;
begin
  R.AX:=$09;
  R.BX:=Width;
  R.CX:=Height;
  R.ES:=seg(PBitmap^);
  R.DX:=ofs(PBitmap^);
  Intr($33,R);
end;

Procedure MouseGetNP;
begin
  R.AX:=$05;
  R.BX:=Key;
  Intr($33,R);
  Count:=R.BX;
  LastX:=R.CX;
  LastY:=R.DX;
end;

Procedure SaveMouseInfo;
begin
  R.AX:=$16;
  R.ES:=seg(Buf);
  R.DX:=ofs(Buf);
  Intr($33,R);
end;

Procedure LoadMouseInfo;
begin
  R.AX:=$17;
  R.ES:=seg(Buf);
  R.DX:=ofs(Buf);
  Intr($33,R);
end;

Function GetBufSize;
var Size:word;

begin
  asm
    mov ax,15h
    int 33h
    mov size,bx
  end;
  GetBufSize:=Size;
end;

Procedure SetElimSpace; ASSEMBLER;
asm
  mov ax,10h
  mov cx,x0
  mov dx,y0
  mov si,x1
  mov di,y1
  int 33h
end;

Procedure SetPenEmul; ASSEMBLER;
asm
  mov ax,0Dh
  int 33h
end;

Procedure ClrPenEmul; ASSEMBLER;
asm
  mov ax,0Eh
  int 33h
end;

Procedure SetLimMove; ASSEMBLER;
asm
  mov ax,7
  mov cx,x0
  mov dx,x1
  int 33h
  mov ax,8
  mov cx,y0
  mov dx,y1
  int 33h
end;

Function PushKey;
var Keys:word;

 begin
  asm
    mov ax,3
    int 33h
    mov Keys,bx
  end;
  if (Keys and Key) <> 0 then PushKey:=true
  else PushKey:=false;
  if not MousePresent then PushKey:=false;
end;

Procedure SetMouseXY; ASSEMBLER;
asm
  mov ax,4
  mov cx,x
  mov dx,y
  int 33h
end;

Procedure GetMouseXY;
var x_,y_ : word;
begin
  asm
   mov ax,3
   int 33h
   mov x_,cx
   mov y_,dx
  end;
  x:=x_;
  y:=y_;
end;

Procedure MouseShow; ASSEMBLER;
asm
  mov ax,1
  int 33h
end;

Procedure MouseHide; ASSEMBLER;
asm
  mov ax,2
  int 33h
end;

Procedure InitMouse;
var Error,
    Buttons : word;
begin
  if not MousePresent then
    MouseError:=-2
  else
    begin
      asm
        mov ax,0
        int 33h
        mov Error,ax
        mov Buttons,bx
      end;
      if Error=0 then
        MouseError:=-1
      else
        begin
          MouseError:=0;
          NumButtons:=Buttons;
        end
    end
end;

Function MouseInsert;
var mx,my : word;

begin
  GetMouseXY(mx,my);
  if (mx>x) and (my>y) and (mx<x+dx) and (my<y+dy) then
    MouseInsert:=true
  else
    MouseInsert:=false;
end;

BEGIN
  GetIntVec($33,IntVec);
  if IntVec = nil then
     MousePresent:=false
  else
     if byte(IntVec^)=$CE then
       MousePresent:=false
     else
       MousePresent:=true;
END.