(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Модуль работы с мышью                                      *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 12.07.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT MOUSE;

INTERFACE

var
  MouseError : shortint;               { код ошибки                       }
  NumButtons : byte;                   { количество кнопок мыши           }

type

  {-------    типы курсора    -------}

  TCurType=(Programmed,              { програмный                         }
            Apparat);                { аппаратный                         }

const

  {---    константы типов мыши    ---}

  ParalMouse  = 1;                   { параллельная мышь                 }
  PosledMouse = 2;                   { последовательная мышь             }
  PortMouse   = 3;                   { подключаемая к порту мышь         }
  PS_2Mouse   = 4;                   { мышь PS/2                         }
  HPMouse     = 5;                   { мышь фирмы ∙Hewlett-Packard∙      }

  {-----    константы ошибок    -----}

  msOk        =  0;                  { успешное выполнение                }
  msNoDriver  = -1;                  { драйвер мыши не установлен         }
  msNoPresent = -2;                  { мышь отсутствует                   }

  {----  константы кнопок мыши   ----}

  LeftKey   = 1;
  RightKey  = 2;
  MiddleKey = 4;

  {--------   курсоры мыши   --------}

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

  { иницилизирует драйвер мыши                                            }
Procedure InitMouse;
  { показать курсор мыши                                                  }
Procedure MouseShow;
  { спрятать курсор мыши                                                  }
Procedure MouseHide;
  { получить координаты маркера мыши                                      }
Procedure GetMouseXY(var X,Y : word);
  { установить координаты маркера мыши                                    }
Procedure SetMouseXY(X,Y : word);
  { состояние кнопок мыши                                                 }
Function  PushKey(Key : byte):boolean;
  { опредилить границы передвижения мыши                                  }
Procedure SetLimMove(x0,y0,          { левый верхний угол                 }
                     x1,y1           { правый нижний угол                 }
                          : word);
  { разрешить эмуляцию светового пера                                     }
Procedure SetPenEmul;
  { запретить эмуляцию светового пера                                     }
Procedure ClrPenEmul;
  { опредилить область исключения                                         }
Procedure SetElimSpace(x0,y0,        { левый верхний угол                 }
                       x1,y1         { правый нижний угол                 }
                            : word);
  { опредилить размер буфера для хранения информации о состоянии мыши     }
Function  GetBufSize:word;
  { сохранить текущее состояние мыши                                      }
Procedure SaveMouseInfo(const Buf);
  { восстановить состояние мыши                                           }
Procedure LoadMouseInfo(const Buf);
  { опредилить число нажатий кнопки мыши                                  }
Procedure MouseGetNP(Key             { проверяемая клавиша                }
                        :byte;
                     var   Count,      { количество нажатий               }
                           LastX,LastY { координаты последнего нажатия    }
                                      : word);
 { установить пользовательский курсор мыши ( графический режим )          }
Procedure SetNewGCursor(Width,       { ширина маркера                     }
                        Height       { высота маркера                     }
                              : word;
                        PBitmap      { указатель на битовое поле          }
                               : pointer);
 { установить пользовательский курсор мыши ( текстовый режим )            }
Procedure SetNewTCursor(CurType      { тип курсора                        }
                               : TCurType;
                                     {   аппаратный    ║    програмный    }
                                     {═════════════════╬══════════════════}
                        Param1,      { начальная линия ║    маска AND     }
                        Param2       { конечная  линия ║    маска XOR     }
                              :word);
  { задать скорость маркера                                               }
Procedure SetCursorSpeed(GorizSpeed, { число микки по горизонтали         }
                         VertSpeed   { число микки по вертикали           }
                                  : word);
  { задание экранной страницы на которой отображается курсор мыши         }
Procedure SetNumPage(Page : word);
  { определение типа мыши          ( работает неправильно )               }
Procedure GetMouseVersion(var
                          Version    { версия драйвера мыши               }
                             : word;
                          var
                          MType,     { тип мыши                           }
                          NumIRQ     { номер IRQ                          }
                            : byte);
  { мышь в заданных границах ?                                            }
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