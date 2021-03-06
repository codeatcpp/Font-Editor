(*************************************************************************)
(*  �஥�� :  Font Editor for DOS                                        *)
(*            �������������� � ������ 640x480                            *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    ����  : �濫��᪨� �. �.                                          *)
(*    ���   : � 01.12.94 �� 13.10.95             ���� �������ࠤ        *)
(*************************************************************************)
{$I PARAMS}
{$I-}
UNIT GEN640;

INTERFACE

USES DOS;

TYPE
    PTFont=^TFont;
    TFont=record                      { ������� CHR 䠩�� }
       CopyRight:string[70];          { ���                }
       Number:integer;                { ������⢮ ᨬ����� }
       FirstCode,                     { ��� ��ࢮ�� ᨬ���� }
       Height,                        { ����              }
       Width:byte;                    { ��ਭ�              }
       Res:array[1..4] of byte;       { �����              }
       Font:array[1..4097] of byte;   { �����              }
      end;

CONST
    XORWrite=$18;    { ������ ���� ᨬ����� }
    ORWrite=$10;
    ANDWrite=$8;
    COPYWrite=0;
    FontBuf:PTFont=nil;
    FontError: byte = 0;

VAR
    FontFirstCode,                    { ��� ��ࢮ�� ᨬ����      }
    FontHeight,                       { ����                   }
    FontWidth,                        { ��ਭ�                   }
    NumberOfChar,                     { ��᫮ �뢥������ ᨬ�����}
                                      { �� ��᫥���� ���饭�� �}
                                      {   WriteStrXY             }
    FirstWritten:byte;                { ���� �뢥����� ᨬ��� }
                                      { �� ��᫥���� ���饭�� �}
                                      {   WriteStrXY             }

Function GetFNT:PathStr;
Procedure InitBuf;
Procedure DoneBuf;
Procedure LoadFNT(Name:string; Always : boolean);
Function InitFont(                    { ���樠������ ������� }
                  Font:pointer;        { ���� ����            }
                  Name:string          { ��� 䠩��, �᫨ FONT=nil}
                  ):boolean;
Procedure DoneFont;                   { �������� CHR 䠩��       }
Procedure WriteStrXY2(                { ����� ��ப� ���        }
                                      { �஢�ન �।���� ��࠭� }
                      x,y:word;       { ��窠 �ਢ離� }
                      color,          { ����           }
                      WriteMode:byte; { ����� ����   }
                      st:string);     { ��ப�         }
Procedure WriteStrXY3(                { ����� ��ப� ���        }
                                      { �஢�ન �।���� ��࠭� }
                      x,y:word;       { ��窠 �ਢ離� }
                      color,          { ����           }
                      WriteMode:byte; { ����� ����   }
                      st:string);     { ��ப�         }
Procedure WriteShStr2(                 { ����� ��ப� � ⥭��    }
                                      {   �।���� ��࠭�        }
                      x,y:word;       { ��窠 �ਢ離� }
                      color:byte;     { ����           }
                      st:string);     { ��ப�         }
Procedure WriteShStr3(                 { ����� ��ப� � ⥭��    }
                                      {   �।���� ��࠭�        }
                      x,y:word;       { ��窠 �ਢ離� }
                      color:byte;     { ����           }
                      st:string);     { ��ப�         }

Procedure STFONT;                     { ����                    }


IMPLEMENTATION

USES  Graph;

CONST
    LastFontName:PathStr='';
    FontSize:integer=0;               { ������ CHR 䠩�� � �����}
    FontAddr:pointer=nil;             { ���� CHR � �����       }
    OWorkAddr:word=0;                 { ���� ��ࢮ�� ᨬ����    }
    SWorkAddr:word=0;

VAR
    FontFlag:boolean;                 { TRUE  ����� � CHR 䠩�e }
                                      { FALSE        � ���       }

Procedure STFONT; EXTERNAL;           { ����                    }
{$L STFONT}

Function InitFont(                    { ���樠������ ������� }
                  Font:pointer;        { ���� ����            }
                  Name:string          { ��� 䠩��, �᫨ FONT=nil}
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
                     InitFont:=false;       { CHR 䠩� �� ������ }
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
   if ((name=LastFontName) or (name='��� �����')) and not Always
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

Procedure DoneFont;                         { �������� CHR 䠩�� }
 begin
   if FontFlag
     then
       FreeMem(FontAddr,FontSize);
 end;

Procedure WriteStrXY2(x,y:word;       { ��窠 �ਢ離� }
                      color,          { ����           }
                      WriteMode:byte; { ����� ����   }
                      st:string);     { ��ப�         }
 var xx,                { ���饭�� � ����� �� ����� ��஭� }
     shx: byte;         { ���饭�� � ����              }
     H:byte;
     F: byte;           { ��� ��ࢮ�� ᨬ����           }
     FAddr:word;        { ���� ������ ��ࢮ�� ᨬ���� }
     HH: byte;
 begin
   asm
     mov  si,bp
     sub  si,100h            { ss:si - ���� st   }

     mov  dx,$3CE            { ����� ����� 2 }
     mov  ax,$205
     out  dx,ax

                             { ����� ࠡ��� ������ ॣ���஢ }
     mov  al,3               { � ������������ }
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

     mov  bx,y       { bx = ����稩 ���� � ��࠭� }
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

Procedure WriteStrXY3(x,y:word;       { ��窠 �ਢ離� }
                      color,          { ����           }
                      WriteMode:byte; { ����� ����   }
                      st:string);     { ��ப�         }
 var xx,                { ���饭�� � ����� �� ����� ��஭� }
     shx: byte;         { ���饭�� � ����              }
     H,                 { ���� ᨬ����                }
     F: byte;           { ��� ��ࢮ�� ᨬ����           }
     FAddr:word;        { ���� ������ ��ࢮ�� ᨬ���� }
     HH: byte;
 begin
   asm
     mov  si,bp
     sub  si,100h            { ss:si - ���� st   }

     mov  dx,$3CE            { ����� ����� 2 }
     mov  ax,$205
     out  dx,ax

                             { ����� ࠡ��� ������ ॣ���஢ }
     mov  al,3               { � ������������ }
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

     mov  bx,y       { bx = ����稩 ���� � ��࠭� }
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

Procedure WriteShStr2(                { ����� ��ப� � ⥭��    }
                                      {   �।���� ��࠭�        }
                      x,y:word;       { ��窠 �ਢ離� }
                      color:byte;     { ����           }
                      st:string);     { ��ப�         }
 begin
   WriteStrXY2(x+2,y+2,Black,COPYWrite,st);
   WriteStrXY2(x,y,color,COPYWrite,st);
 end;

Procedure WriteShStr3(                { ����� ��ப� � ⥭��    }
                                      {   �।���� ��࠭�        }
                      x,y:word;       { ��窠 �ਢ離� }
                      color:byte;     { ����           }
                      st:string);     { ��ப�         }
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

