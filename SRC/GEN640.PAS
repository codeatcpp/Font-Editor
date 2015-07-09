(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            ЗНАКОГЕНЕРАТОР В РЕЖИМЕ 640x480                            *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский М. В.                                          *)
(*    Дата   : с 01.12.94 по 13.10.95             МИЭТ Зеленоград        *)
(*************************************************************************)
{$I PARAMS}
{$I-}
UNIT GEN640;

INTERFACE

USES DOS;

TYPE
    PTFont=^TFont;
    TFont=record                      { Структура CHR файла }
       CopyRight:string[70];          { Инфо                }
       Number:integer;                { Количество символов }
       FirstCode,                     { Код первого символа }
       Height,                        { Высота              }
       Width:byte;                    { Ширина              }
       Res:array[1..4] of byte;       { Резерв              }
       Font:array[1..4097] of byte;   { Данные              }
      end;

CONST
    XORWrite=$18;    { Режимы печати символов }
    ORWrite=$10;
    ANDWrite=$8;
    COPYWrite=0;
    FontBuf:PTFont=nil;
    FontError: byte = 0;

VAR
    FontFirstCode,                    { Код первого символа      }
    FontHeight,                       { Высота                   }
    FontWidth,                        { Ширина                   }
    NumberOfChar,                     { Число выведенных символов}
                                      { при последнем обращении к}
                                      {   WriteStrXY             }
    FirstWritten:byte;                { Первый выведенный символ }
                                      { при последнем обращении к}
                                      {   WriteStrXY             }

Function GetFNT:PathStr;
Procedure InitBuf;
Procedure DoneBuf;
Procedure LoadFNT(Name:string; Always : boolean);
Function InitFont(                    { Инициализация генератора }
                  Font:pointer;        { Адрес шрифта            }
                  Name:string          { Имя файла, если FONT=nil}
                  ):boolean;
Procedure DoneFont;                   { Удаление CHR файла       }
Procedure WriteStrXY2(                { Печать строки без        }
                                      { проверки пределов экрана }
                      x,y:word;       { Точка привязки }
                      color,          { Цвет           }
                      WriteMode:byte; { Режим печати   }
                      st:string);     { Строка         }
Procedure WriteStrXY3(                { Печать строки без        }
                                      { проверки пределов экрана }
                      x,y:word;       { Точка привязки }
                      color,          { Цвет           }
                      WriteMode:byte; { Режим печати   }
                      st:string);     { Строка         }
Procedure WriteShStr2(                 { Печать строки с тенью    }
                                      {   пределов экрана        }
                      x,y:word;       { Точка привязки }
                      color:byte;     { Цвет           }
                      st:string);     { Строка         }
Procedure WriteShStr3(                 { Печать строки с тенью    }
                                      {   пределов экрана        }
                      x,y:word;       { Точка привязки }
                      color:byte;     { Цвет           }
                      st:string);     { Строка         }

Procedure STFONT;                     { Шрифт                    }


IMPLEMENTATION

USES  Graph;

CONST
    LastFontName:PathStr='';
    FontSize:integer=0;               { Размер CHR файла в байтах}
    FontAddr:pointer=nil;             { Адрес CHR в памяти       }
    OWorkAddr:word=0;                 { Адрес первого символа    }
    SWorkAddr:word=0;

VAR
    FontFlag:boolean;                 { TRUE  данные в CHR файлe }
                                      { FALSE        в ОЗУ       }

Procedure STFONT; EXTERNAL;           { Шрифт                    }
{$L STFONT}

Function InitFont(                    { Инициализация генератора }
                  Font:pointer;        { Адрес шрифта            }
                  Name:string          { Имя файла, если FONT=nil}
                  ):boolean;
 var f:file;
     res:word;
     i:word;
 procedure SetVar;
  begin
    with PTFont(FontAddr)^ do
      begin
        OWorkAddr:=ofs(Font[1]);
        SWorkAddr:=seg(Font[1]);
        FontHeight:=Height;
        FontWidth:=Width;
        FontFirstCode:=FirstCode;
      end;
   end;
 Begin
   if Font=nil
     then
       begin
         if Name=''
           then
             begin
               FontFlag:=false;
               FontAddr:=@STFONT;
               SetVar;
               InitFont:=true;
             end
           else
             begin
               FontFlag:=true;
               Assign(f,name);
               Reset(f,1);
               FontError:=IOResult;
               if FontError<>0
                 then
                   begin
                     InitFont:=false;       { CHR файл не найден }
                     FontSize:=0;
                   end
                 else
                   begin
                     FontSize:=FileSize(f);
                     GetMem(FontAddr,FontSize);
                     BlockRead(f,FontAddr^,FontSize,res);
                     FontError:=IOResult;
                     InitFont:=true;
                     SetVar;
                     Close(f);
                   end;
             end;
       end
     else
       begin
         FontFlag:=false;
         FontAddr:=Font;
         SetVar;
         InitFont:=true;
       end;
  end;

Procedure LoadFNT(Name:string ; Always : boolean);
 var f:file;
     r:word;
 begin
   if (name='')
     then
       begin
         InitFont(nil,'');
         exit;
       end;
   if ((name=LastFontName) or (name='Без имени')) and not Always
     then
       begin
         InitFont(FontBuf,'');
         exit;
       end;
   LastFontName:=name;
   Assign(f,name);
   Reset(f,1);
   FontError:=IOResult;
   if FontError=0 then
     if (FileSize(f)=4096) or (FileSize(f)=2048)
       then
         begin
           with FontBuf^ do
             begin
               BlockRead(f,Font,FileSize(f));
               FontError:=IOResult;
               Number:=255;
               Firstcode:=0;
               Height:=FileSize(f) shr 8;
               Width:=1;
               InitFont(FontBuf,'');
               Close(f);
             end;
         end
       else
         FontError:=215;
 end;

Procedure DoneFont;                         { Удаление CHR файла }
 begin
   if FontFlag
     then
       FreeMem(FontAddr,FontSize);
 end;

Procedure WriteStrXY2(x,y:word;       { Точка привязки }
                      color,          { Цвет           }
                      WriteMode:byte; { Режим печати   }
                      st:string);     { Строка         }
 var xx,                { Смещение в байтах от левой стороны }
     shx: byte;         { Смещение в байте              }
     H:byte;
     F: byte;           { Код первого символа           }
     FAddr:word;        { Адрес матрицы первого символа }
     HH: byte;
 begin
   asm
     mov  si,bp
     sub  si,100h            { ss:si - адрес st   }

     mov  dx,$3CE            { Режим записи 2 }
     mov  ax,$205
     out  dx,ax

                             { Режим работы буферных регистров }
     mov  al,3               { с видеопамятью }
     mov  ah,WriteMode
     out  dx,ax

     mov  al,FontHeight
     mov  H,al
     mov  HH,4
     cmp  al,16
     je   @@6
     mov  HH,3

  @@6:
     mov  al,FontFirstCode
     mov  F,al
     mov  ax,OWorkAddr
     mov  FAddr,ax

     mov  ax,$A000
     mov  es,ax
     push ds
     mov  ds,SWorkAddr

     mov  bx,x
     mov  ax,bx
     mov  cl,3
     shr  bx,cl
     mov  xx,bl
     shl  bx,cl
     sub  ax,bx
     mov  shx,al

     mov  bx,y       { bx = Рабочий адрес в экране }
     mov  cl,4
     shl  bx,cl
     mov  dx,bx
     mov  cl,2
     shl  bx,cl
     add  bx,dx
     mov  ch,0
     mov  cl,xx
     add  bx,cx

     mov  ch,0
     mov  cl,ss:[si]
     cmp  cl,0
     je   @@3
     inc  si
     mov  dx,$3CE

        @@1:
             push cx
             push bx

             mov  ah,0
             mov  al,ss:[si]
        @@11:
             sub  al,F
             mov  cl,HH
             shl  ax,cl
             add  ax,FAddr
             mov  di,ax

             mov  ch,H

               @@2:
                    mov  al,8
                    mov  ah,ds:[di]
                    mov  cl,shx
                    shr  ah,cl
                    out  dx,ax
                    mov  al,es:[bx]
                    mov  al,color
                    mov  es:[bx],al
                    mov  al,8
                    mov  ah,ds:[di]
                    mov  cl,8
                    sub  cl,shx
                    shl  ah,cl
                    out  dx,ax
                    mov  al,es:[bx+1]
                    mov  al,color
                    mov  es:[bx+1],al
                    inc  di
                    add  bx,80
                    dec  ch
                    jne  @@2


         @@4:
             pop  bx
             inc  bx
         @@5:
             pop  cx
             inc  si
             loop @@1

  @@3:
     pop  ds
   end;
   SetColor(Black);
   Line(0,0,0,0);
 end;

Procedure WriteStrXY3(x,y:word;       { Точка привязки }
                      color,          { Цвет           }
                      WriteMode:byte; { Режим печати   }
                      st:string);     { Строка         }
 var xx,                { Смещение в байтах от левой стороны }
     shx: byte;         { Смещение в байте              }
     H,                 { Высота символа                }
     F: byte;           { Код первого символа           }
     FAddr:word;        { Адрес матрицы первого символа }
     HH: byte;
 begin
   asm
     mov  si,bp
     sub  si,100h            { ss:si - адрес st   }

     mov  dx,$3CE            { Режим записи 2 }
     mov  ax,$205
     out  dx,ax

                             { Режим работы буферных регистров }
     mov  al,3               { с видеопамятью }
     mov  ah,WriteMode
     out  dx,ax

     mov  al,FontHeight
     mov  H,al
     mov  HH,4
     cmp  al,16
     je   @@6
     mov  HH,3

  @@6:
     mov  al,FontFirstCode
     mov  F,al
     mov  ax,OWorkAddr
     mov  FAddr,ax

     mov  ax,$A000
     mov  es,ax
     push ds
     mov  ds,SWorkAddr

     mov  bx,x
     mov  ax,bx
     mov  cl,3
     shr  bx,cl
     mov  xx,bl
     shl  bx,cl
     sub  ax,bx
     mov  shx,al

     mov  bx,y       { bx = Рабочий адрес в экране }
     mov  cl,4
     shl  bx,cl
     mov  dx,bx
     mov  cl,2
     shl  bx,cl
     add  bx,dx
     mov  ch,0
     mov  cl,xx
     add  bx,cx

     mov  ch,0
     mov  cl,ss:[si]
     cmp  cl,0
     je   @@3
     inc  si
     mov  dx,$3CE

        @@1:
             push cx
             push bx

             mov  ah,0
             mov  al,ss:[si]
             cmp  al,9
             jnz  @@11
             pop  bx
             add  bx,8
             jmp  @@5
        @@11:
             sub  al,F
             mov  cl,HH
             shl  ax,cl
             add  ax,FAddr
             mov  di,ax

             mov  ch,H

               @@2:
                    mov  al,8
                    mov  ah,ds:[di]
                    mov  cl,shx
                    shr  ah,cl
                    out  dx,ax
                    mov  al,es:[bx]
                    mov  al,color
                    mov  es:[bx],al
                    mov  al,es:[bx+80]
                    mov  al,color
                    mov  es:[bx+80],al
                    mov  al,8
                    mov  ah,ds:[di]
                    mov  cl,8
                    sub  cl,shx
                    shl  ah,cl
                    out  dx,ax
                    mov  al,es:[bx+1]
                    mov  al,color
                    mov  es:[bx+1],al
                    mov  al,es:[bx+81]
                    mov  al,color
                    mov  es:[bx+81],al
                    inc  di
                    add  bx,160
                    dec  ch
                    jne  @@2


         @@4:
             pop  bx
             inc  bx
         @@5:
             pop  cx
             inc  si
             loop @@1

  @@3:
     pop  ds
   end;
   SetColor(Black);
   Line(0,0,0,0);
 end;

Procedure WriteShStr2(                { Печать строки с тенью    }
                                      {   пределов экрана        }
                      x,y:word;       { Точка привязки }
                      color:byte;     { Цвет           }
                      st:string);     { Строка         }
 begin
   WriteStrXY2(x+2,y+2,Black,COPYWrite,st);
   WriteStrXY2(x,y,color,COPYWrite,st);
 end;

Procedure WriteShStr3(                { Печать строки с тенью    }
                                      {   пределов экрана        }
                      x,y:word;       { Точка привязки }
                      color:byte;     { Цвет           }
                      st:string);     { Строка         }
 begin
   WriteStrXY3(x+2,y+2,Black,COPYWrite,st);
   WriteStrXY3(x,y,color,COPYWrite,st);
 end;


Procedure InitBuf;
 begin
   GetMem(FontBuf,4200);
 end;

Procedure DoneBuf;
 begin
   FreeMem(FontBuf,4200);
 end;

Function GetFNT:PathStr;
 begin
   GetFNT:=LastFontName;
 end;

END.

