(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Ввод строки в графическом режиме                           *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT InputStr;

INTERFACE

uses Graph,
     DOS,
     CRT,
     Keyboard,
     Mouse,
     GEN640;

type
  pString = ^string;

  pInputLine = ^tInputLine;
  tInputLine = object
    x,y,dx,dy : word;                 { координаты строки               }
    MaxLen,                           { максимальная длина строки       }
    VisLen : byte;                    { видимое длина строки            }
    Data : pString;                   { редактируемая строка            }
    CurPos,                           { текущая позиция                 }
    CurVisPos,                        { видимая текущая позиция         }
    CursorPos : byte;                 { позиция курсора                 }
    FirstCal : boolean;               {                                 }
    Constructor Init(_x,_y,           { верхний левый угол              }
                     _dx,_dy : word;  { правый нижний угол              }
                     Len : byte);     { длина строка                    }
    Function GetData : string;        { возвращает редактируемую строку }
    Procedure SetData(const Str :
                            string);  { установить редактируемую строку }
    Procedure SetCurPos( n : byte );  { установить текущую позицию      }
    Procedure ShowCursor;             { показать курсор                 }
    Procedure Draw;                   { нарисовать видимую часть строки }
    Procedure Edit;                   { редактирование строки           }
    Destructor Done;
  end;

IMPLEMENTATION

Constructor tInputLine.Init;
begin
  x:=_x;
  y:=_y;
  dx:=_dx;
  dy:=_dy;
  MaxLen:=Len;
  CurPos:=1;
  CurVisPos:=1;
  CursorPos:=1;
  VisLen:=dx shr 3-2;
  GetMem(Data,MaxLen+1);
  Data^:='';
  FirstCal:=true;
end;

Function tInputLine.GetData;
begin
  GetData:=Data^;
end;

Procedure tInputLine.SetData;
begin
   Data^:=Str;
   SetCurPos(byte(Data^[0])+1);
end;

Procedure tInputLine.SetCurPos;
var LastPos : byte;
begin
  LastPos:=CurPos;
  if n<=byte(Data^[0])+1 then CurPos:=n
  else CurPos:=byte(Data^[0])+1;
  if CursorPos+(CurPos-LastPos)>VisLen then
    begin
      CursorPos:=VisLen;
    end
  else
  if CursorPos+(CurPos-LastPos)<1 then
    begin
      CursorPos:=1;
    end
  else
    CursorPos:=CursorPos+(CurPos-LastPos);
  CurVisPos:=CurPos-CursorPos+1;
end;

Procedure tInputLine.ShowCursor;
begin
  MouseHide;
  SetColor(White);
  Rectangle(x+CursorPos shl 3,y+(dy-16) shr 1+15,
            x+(CursorPos+1) shl 3,y+(dy-16) shr 1+16);
  MouseShow;
end;

Procedure tInputLine.Draw;
begin
  MouseHide;
  SetFillStyle(SolidFill,LightGray);
  Bar(x,y,x+dx,y+dy);
  if FirstCal and (Data^[0]<>#0) then
    begin
      SetFillStyle(SolidFill,Blue);
      if byte(Data^[0])>=VisLen then
        Bar(x+8,y,x+dx-16,y+dy-2)
      else
        Bar(x+8,y,x+8+byte(Data^[0])*8,y+dy-2);
    end;
  WriteShStr2(x+8,y+(dy-16) shr 1,White,copy(Data^,CurVisPos,VisLen));
  if CurVisPos>1 then
    WriteShStr2(x-1,y+(dy-16) shr 1,LightGreen,#17);
  if byte(Data^[0])-VisLen>CurVisPos-1 then
    WriteShStr2(x+(VisLen+1) shl 3,y+(dy-16) shr 1,LightGreen,#16);
  ShowCursor;
  MouseShow;
end;

Procedure tInputLine.Edit;
var Mx,My : word;

begin
  if PushKey(LeftKey) then
    begin
      if (byte(Data^[0])-VisLen>CurVisPos-1) and
         (MouseInsert(x+(VisLen+1) shl 3-1,y+(dy-16) shr 1,8,16)) and
         (CurPos<byte(Data^[0])+1) then
        begin
          SetCurPos(CurPos+1);
          Draw;
          Delay(30);
        end
      else
      if (CurVisPos>1) and
         (MouseInsert(x-1,y+(dy-16) shr 1,8,16)) and
         (CurPos>1) then
        begin
          SetCurPos(CurPos-1);
          Draw;
          Delay(30);
        end;
      if MouseInsert(x+8,y,VisLen shl 3,dy) then
        begin
          GetMouseXY(Mx,My);
          SetCurPos((Mx-x) shr 3+CurVisPos-1);
          Draw;
          while PushKey(LeftKey) do ;
        end
    end;
  if not FirstCal then
    begin
      if (byte(Data^[0])<>0) and
         (Mem[$0:$417] and 4<>0) and
         (Code=scY) then
        begin
          SetData('');
          Draw;
        end
      else
      if (Code=scLeft) then
        begin
          if CurPos>1 then
            begin
              SetCurPos(CurPos-1);
              Draw;
            end;
        end
      else
      if (Code=scRight) then
        begin
          if CurPos<byte(Data^[0])+1 then
            begin
              SetCurPos(CurPos+1);
              Draw;
            end;
        end
      else
      if (Code=scEnd) then
        begin
          if CurPos<byte(Data^[0])+1 then
            begin
              SetCurPos(byte(Data^[0])+1);
              Draw;
            end;
        end
      else
      if (Code=scHome) then
        begin
          if CurPos>1 then
            begin
              SetCurPos(1);
              Draw;
            end;
        end
      else
      if (Code=scDel) then
        begin
          if CurPos<byte(Data^[0])+1 then
            begin
              Data^:=copy(Data^,1,CurPos-1)+
                copy(Data^,CurPos+1,MaxLen);
              Draw;
            end;
        end
      else
      if (Code=scBackSpace) then
        begin
          if CurPos>1
            then
              begin
                Data^:=copy(Data^,1,CurPos-2)+
                  copy(Data^,CurPos,MaxLen);
                SetCurPos(CurPos-1);
                if (byte(Data^[0])<VisLen) and (CursorPos=1) then
                  begin
                    CurVisPos:=CurVisPos-1;
                    CursorPos:=2;
                  end;
                if CurPos=1 then CursorPos:=1;
                Draw;
              end
        end
      else
      if byte(Data^[0])<MaxLen-1 then
        begin
          if Symbol>#31 then
            begin
              Data^:=copy(Data^,1,CurPos-1)+Symbol+
                  copy(Data^,CurPos,MaxLen);
              SetCurPos(CurPos+1);
              Draw;
            end;
        end
    end
  else
    begin
      {$B+}
      if (Symbol>#31) or
         (Code=scDel) or
         (Code=scBackSpace) or
         ((Mem[$0:$417] and 4<>0) and (Code=scY)) then
        begin
          {$B-}
          FirstCal:=false;
          SetData('');
          Draw;
          Edit;
        end
      else
        if (Code=scLeft) or
           (Code=scRight) or
           (Code=scEnd) or
           (Code=scHome) then
          begin
            {$B-}
            FirstCal:=false;
            Draw;
            Edit;
          end;
    end;
end;

Destructor tInputLine.Done;
begin
  FreeMem(Data,MaxLen+1);
end;

END.