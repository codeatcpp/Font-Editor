(*************************************************************************)
(*  �஥�� :  Font Editor for DOS                                        *)
(*            ����� ࠡ��� � ������                                     *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    ����  : �濫��᪨� ��ਫ�                                         *)
(*    ���   : 12.07.96                            �. ����ᠭ�஢        *)
(*************************************************************************)
{$I PARAMS}
UNIT LWindows;

INTERFACE        {*** ��������� ������ ***}

USES Graph,
     Keyboard,
     Mouse,
     Resourse,
     BITMAP,
     Crt,
     GEN640,
     LString,
     Constant,
     LColors,
     LMList;

VAR Windows:Tlist;

CONST
  ShadowSize:byte=6;                  { ࠧ��� ⥭�                       }
  MaxKeys=100;                        { ���ᨬ��쭮� �᫮ ������ � ����  }
  FExit:boolean=false;                { 䫠� ������� ����                }
  FGlobalExit:boolean=false;          { 䫠� ��室� �� �ணࠬ��          }
  Color1=cNewColor2;
  Color2=cNewColor1;
  DrawAfterClose:boolean=false;

TYPE
  TActProc=procedure;
  TKeyName=string[24];                { ⨯ ������ � ������              }
  tExtr=string[10];
  TColor=0..15;
  TFrame=0..7;

  TKeyType=(HiddenKey,Simple,Standart,Classic);      { ⨯� ������        }
  TWindowType=(WSimple,WStandart,WClassic,WFrame);   { ⨯� ����          }

  TPMKeys=^TMKeys;                    { 㪠��⥫� �� ���ᨢ ������        }

  { ��ࠬ���� ���� }

  TWindows=record
    WindType  : TWindowType;          { ⨯ ����                          }
    x,y,dx,dy : Integer;              { ࠧ���� ����                      }
    HelpCtx   : word;                 { ���⥪�⭠� ������               }
    BefOpenPr : TActProc;             { ��楤�� �� ������             }
    OpenProc  : TActProc;             { ��楤�� �� ����⨨            }
    ContProc  : TActProc;             { ��楤�� ��뢠���� ���� ����    }
                                      { ��⨢��                           }
    Shadow    : Boolean;              { 䫠� ⥭�                         }
    Keys      : TPMKeys;              { 㪠��⥫� �� ���ᨢ ������        }
    NumKeys   : Byte;                 { ������⢮ ������ � ����          }
    Color     : TColor;               { 梥� ����                         }
    FrameColor: TColor;               { 梥� ࠬ��                        }
    FrameThick: TFrame;               { ⮫騭� ࠬ��                     }
  end;
  TPWindows=^TWindows;

  { ��ࠬ���� ������, ��।������ ���� }

  Tkeys=record
    KeyType   : tKeyType;             { ⨯ ������                        }
    x,y,dx,dy : Integer;              { ࠧ���� ������                    }
    PushProc  : tActProc;             { ��楤�� �� ����⨨             }
    PushWind  : tPWindows;            { ����, ���뢠���� �� ����⨨     }
    Name      : tKeyName;             { ������� � ������                  }
    Ext       : tExtr;                { ���७�� ����� ������           }
    CloseAfPr : Boolean;              { ������� ��᫥ �맮�� ��楤���    }
    BitMap    : ptBitMap;             { 㪠��⥫� �� ����ࠦ���� � ������ }
    HotKey    : Word;                 { ������ ������ (�. KEYBOARD)    }
                                      { ��� :HotKey[+scAlt][+Shift][+Ctrl]}
    HelpCtx   : word;                 { ���⥪�⭠� ������               }
    CanActive : boolean;              { 䫠� ���������� �뤥����� ������ }
    Centered  : Boolean;              { 業��஢��� ⥪�� � ������       }
    Color     : TColor;               { 梥� ������                       }
  end;
  TMKeys=array[1..MaxKeys] of TKeys;

  {++ ��ꥪ� ���� ++}

  PTWindow=^TWindow;
  TWindow = object(TListElem)
    HelpCtx : word;                { ���⥪�⭠� ������                }
    x,y,dx,dy:integer;             { ���न���� � ࠧ��� ����           }
    Constructor Init(_x,_y,_dx,_dy:integer);
    Procedure SetVis; virtual;     { ��⠭����� ��������� ����          }
    Procedure SetUnVis; virtual;   { ����⠭����� ����ࠦ���� ��� ����� }
    Destructor Done; virtual;
  end;

  {++ ��ꥪ� ����� ������ ++}

  PTHiddenKey=^THiddenKey;
  THiddenKey = object(tWindow)
    FCentered,                     { 業��஢��� ⥪�� � ������        }
    FWasPush,                      { ������ �뫠 �����                 }
    FActive: boolean;              { 䫠� ��⨢���� ������             }
    Window:PTWindow;               { ����, ���஬� �ਭ������� ������  }
    PushProc: TActProc;            { ��楤�� �� ����⨨              }
    Name :tKeyName;                { ������� � ������                   }
    Ext : tExtr;                   { ���७�� ����� ������            }
    CanAct,                        { 䫠� ���������� �뤥����� ������  }
    CloseAfPr : Boolean;           { ������� ��᫥ �맮�� ��楤���     }
    PushWind:TPWindows;            { 㪠��⥫� �� ������ ����           }
    HotKey: Word;                  { ������ ������                    }
    Color : tColor;                { 梥� ᨬ����� � ������             }
    Constructor Init(_Window: PTWindow; const _PushProc: TActProc;
                 _x,_y,_dx,_dy: integer; const _Name :TKeyName;
                 const _Ext : tExtr;_Close,_CanAct : boolean; _HotKey:Word;
                 _PushWind: TPWindows; _Centered : boolean;
                 _Color : tColor; _HelpCtx : word);
    Procedure Press; virtual;           { ����஢��� ����⨥ ������    }
    Procedure GetXY(var _x,_y:integer); virtual;
                                        { ������� ���न���� ������    }
                                        { �⭮�⥫쭮 ����             }
    Function HotPressed:boolean;        { �஢�ઠ ���. ����祩 ������ }
    Function Inside:boolean;            { �஢���� ������⢨� ��५�� }
                                        { ��� � �।���� ������        }
    Procedure WriteKeyName(_x,_y:integer;
                const _name: TkeyName;
                _Color : byte);         { ������� ��� ������           }
    Procedure SetVis; virtual;
    Procedure Frame;                    { �����./����. ࠬ�� ������    }
    Procedure SetActive; virtual;       { ��⠭����� ��⨢����� ������  }
    Procedure SetUnActive; virtual;     { ����� ��⨢����� ������    }
    Function Hint( AHelpCtx : word )
                   : string;            { �����頥� ��ப� ���⥪�⭮�
                                          �����                        }
  end;

  {++ ��ꥪ� ����� ������ ++}

  pSimpleKey = ^tSimpleKey;
  tSimpleKey = object(tHiddenKey)
    BitMap : PTBitMap;              { 㪠��⥫� �� ����ࠦ���� � ������ }
    Constructor Init(_Window: PTWindow; const _PushProc: TActProc;
                 _x,_y,_dx,_dy: integer; const _Name:TKeyName;
                 const _Ext: tExtr ; _Close,_CanAct : boolean; _HotKey:Word;
                 _PushWind: TPWindows;  const _BitMap : PTBitMap;
                 _Centered : boolean; _Color : tColor; _HelpCtx : word);
    Procedure SetActive; virtual;
    Procedure SetUnActive; virtual;
    Procedure Press; virtual;
    Procedure SetVis; virtual;
  end;

  {++ ��ꥪ� �⠭���⭠� ������ ++}

  PTStandartKey=^TStandartKey;
  TStandartKey = object(THiddenKey)
    BitMap : PTBitMap;              { 㪠��⥫� �� ����ࠦ���� � ������ }
    Constructor Init(_Window: PTWindow; const _PushProc: TActProc;
                 _x,_y,_dx,_dy: integer; const _Name:TKeyName;
                 const _Ext : tExtr; _Close,_CanAct : boolean; _HotKey:word;
                 _PushWind: TPWindows; const _BitMap : PTBitMap;
                 _Color : tColor; _HelpCtx : word);
    Procedure SetVis; virtual;
    Procedure Press; virtual;
    Procedure SetActive; virtual;
    Procedure SetUnActive; virtual;
  end;

  {++ ��ꥪ� ������᪠� ������ ++}

  PTClassicKey=^TClassicKey;
  TClassicKey = object(TStandartKey)
    Constructor Init(_Window: PTWindow; const _PushProc: TActProc;
                 _x,_y,_dx,_dy: integer; const _Name:TKeyName;
                 const _Ext : tExtr; _Close,_CanAct : boolean; _HotKey:word;
                 _PushWind: TPWindows; _Color:TColor;
                 const _BitMap : PTBitMap; _HelpCtx : word);
    Procedure Press; virtual;
    Procedure SetVis; virtual;
    Procedure SetActive; virtual;
  end;

  {++ ��ꥪ� ����ࠦ���� ��� ����� ++}

  TBackWindow = object (TWindow)
    ImageSave: boolean;            { ��࠭��� ����ࠦ���� ��� ����� ?  }
    Constructor Init(_x,_y,_dx,_dy:integer);
    Procedure SetUnVis; virtual;   { ����⠭����� ����ࠦ���� ��� ����� }
    Destructor Done; virtual;
    private
    BackImage:pointer;             { 㪠��⥫� �� ����ࠦ���� ��� ����� }
    Size:word;                     { ࠧ��� ����ࠦ����                 }
  end;

  {++ ��ꥪ� ⥭� ���� ++}

  PTShadowWindow=^TShadowWindow;
  TShadowWindow=object(TBackWindow)
    Constructor Init(_x,_y,_dx,_dy:integer; Shadow : boolean);
    Procedure SetShadowVis; virtual;  { ��⠭����� ��������� ⥭�       }
  end;

  {++ ��ꥪ� ���⮥ ���� ++}

  PTSimpleWindow=^TSimpleWindow;
  TSimpleWindow = object(TShadowWindow)
    HelpWasClear,
    HelpActive : boolean;
    Lkeys: PTList;                       { ᯨ᮪ ������ ����           }
    Keys : byte;                         { ������⢮ ������ � ����     }
    BefoOpenProc,                        { ��楤�� �� ������        }
    AfteOpenProc,                        { ��楤�� ��᫥ ������     }
    ContProc : TActProc;
    Color: TColor;                       { 梥� ����                    }
    Constructor Init(_x,_y,_dx,_dy:integer; _Color: TColor;
                     PMKeys: TPMKeys; _Keys: byte;
                     _BOpProc,_AOpProc,_ContProc: TActProc;
                     Shadow : boolean; _HelpCtx : word);
    Procedure SetKeysVis;                { ��⠭����� ��������� ������  }
    Procedure SetVis; virtual;
    Procedure StInsAll; virtual;         { �஢���� �����ᢨ� ��� �� }
                                         { ��� ������� ����            }
    Function Inside : boolean;           { ��५�� � ���� ?             }
    Destructor Done; virtual;
  end;

  {++ ��ꥪ� ������᪮� ���� ++}

  PTClassicWindow=^TClassicWindow;
  TClassicWindow = object(TSimpleWindow)
    FShadow: boolean;                    { 䫠� ⥭�                    }
    Constructor Init(_x,_y,_dx,_dy:integer; _Color: TColor;
                     _Shadow: boolean; PMKeys: TPMKeys;
                     _Keys: byte; _BOpProc,_AOpProc,
                     _ContProc: TActProc; _HelpCtx : word);
    Procedure SetVis; virtual;
  end;

  {++ ��ꥪ� �⠭���⭮� ���� ++}

  PTStandartWindow=^TStandartWindow;
  TStandartWindow = object(TClassicWindow)
    Constructor Init(_x,_y,_dx,_dy:integer; _Shadow: boolean;
                     PMKeys: TPMKeys; _Keys: byte;
                     _BOpProc,_AOpProc,_ContProc: TActProc; _HelpCtx : word);
    Procedure SetVis; virtual;
  end;

  {++ ��ꥪ� ���� � ࠬ��� ++}

  PTFrameWindow=^TFrameWindow;
  TFrameWindow = object(TClassicWindow)
    FrameColor: TColor;                  { 梥� ࠬ��                   }
    FrameThick: TFrame;                  { ⮫騭� ࠬ��                }
    Constructor Init(_x,_y,_dx,_dy:integer; _Color: TColor;
                     _FrameColor: Tcolor; _FrameThick:TFrame;
                     _Shadow:boolean; PMKeys: TPMKeys;
                     _Keys: byte; _BOpProc,_AOpProc,
                     _ContProc: TActProc; _HelpCtx : word);
    Procedure SetVis; virtual;
  end;


Procedure CloseAll;                     { ������� �� ���� �� ��������   }
Procedure SetAllVis;                    { ��⠭����� ��������� ��� ���� }
Procedure MakeWindow                    { ᮧ���� ����                   }
              (_Window: TPWindows );    { 㪠��⥫� �� ��ࠬ���� ����    }
Procedure CloseLastWind;                { ������� ��᫥���� ����         }
Procedure Quit;                         { ������� �� ����               }


IMPLEMENTATION   {*** �������������� ����� ������ ***}

   {-- ����ணࠬ�� TWindow --}

Constructor TWindow.Init;
begin
  x:=_x;
  y:=_y;
  dx:=_dx;
  dy:=_dy;
end;

Procedure TWindow.SetVis;
begin
end;

Procedure TWindow.SetUnVis;
begin
end;

Destructor TWindow.Done;
begin
  SetUnVis;
end;

  {-- ����ணࠬ�� THiddenKey --}

Procedure THiddenKey.Press;
var  ImgSize,ImgSize2: word;
     PTImage,PTImage2:pointer;
     xx,yy: integer;

begin
  MouseHide;
  GetXY(xx,yy);
  ImgSize2:=ImageSize(xx,yy,xx+dx,yy+dy);
  GetMem(PTImage2,ImgSize2);
  GetImage(xx,yy,xx+dx,yy+dy,PTImage2^);
  ImgSize:=ImageSize(xx,yy,xx+dx-1,yy+dy-1);
  GetMem(PTImage,ImgSize);
  GetImage(xx,yy,xx+dx-1,yy+dy-1,PTImage^);
  PutImage(xx+1,yy+1,PTImage^,CopyPut);
  FreeMem(PTImage,ImgSize);
  SetColor(Black);
  Rectangle(xx,yy,xx+dx,yy+dy);
  MoveTo(xx+dx,yy+1);
  LineRel(-dx+1,0);
  LineRel(0,dy-1);
  MouseShow;
  while PushKey(LeftKey) do ;
  MouseHide;
  PutImage(xx,yy,PTImage2^,CopyPut);
  FreeMem(PTImage2,ImgSize2);
  Frame;
  FActive:=false;
  MouseShow;
end;

Procedure THiddenKey.SetVis;
var _x,xx,yy:integer;

begin
  GetXY(xx,yy);
  if FCentered then _x:=xx+((dx-(byte(Name[0]) shl 3-(CountSymbols(Name,
  '~')+CountSymbols(Name,'&')) shl 3)) shr 1)
  else _x:=xx+3;
  WriteKeyName(_x,yy+((dy-14) shr 1),Name,Color);
  WriteKeyName(xx+dx-(byte(Ext[0]) shl 3-CountSymbols(Ext,'~') shl 3)-3,
               yy+((dy-14) shr 1),Ext,0);
  FActive:=false;
end;

Procedure THiddenKey.Frame;
var xx,yy:integer;

begin
  MouseHide;
  GetXY(xx,yy);
  SetColor(GetPixel(xx,yy) xor White);
  SetWriteMode(XorPut);
  SetLineStyle(DottedLn,0,1);
  Rectangle(xx,yy,xx+dx,yy+dy);
  SetLineStyle(SolidLn,0,1);
  SetWriteMode(CopyPut);
  MouseShow;
end;

Procedure THiddenKey.SetActive;
begin
  Frame
end;

Procedure THiddenKey.SetUnActive;
begin
  Frame
end;

Procedure THiddenKey.GetXY;
begin
  with Window^ do
    begin
      _x:=x;
      _y:=y;
    end;
  _x:=_x+x;
  _y:=_y+y;
end;

Function THiddenKey.HotPressed:boolean;
begin
  if HotKey and scWAlt = scWAlt then
    if (Code=HotKey-scWAlt) and
       (Mem[$0:$417] and 8<>0) then
      HotPressed:=true
    else HotPressed:=false
  else
  if HotKey and scWCtrl = scWCtrl then
    if (Code=HotKey-scWCtrl) and
         (Mem[$0:$417] and 4<>0) then
      HotPressed:=true
    else HotPressed:=false
  else
  if HotKey and scWShift = scWShift then
    if (Code=HotKey-scWShift) and
         ((Mem[$0:$417] and 2<>0) or (Mem[$0:$417] and 1<>0)) then
      HotPressed:=true
    else HotPressed:=false
  else
  if (Code=HotKey) and
       (Mem[$0:$417] and 8=0) then HotPressed:=true
  else HotPressed:=false;
end;

Function THiddenKey.Inside;
var mx,my: word;
    xx,yy :integer;
    Ctx   : string[80];

begin
  GetMouseXY(mx,my);
  GetXY(xx,yy);
  if (mx>xx) and (mx<xx+dx) and (my>yy) and (my<yy+dy) and not FWasPush
     then
       begin
         Inside:=true;
         if not FActive then
           begin
             FActive:=true;
             MouseHide;
             SetFillStyle(SolidFill,cStatusLine);
             Bar(10,461,639,479);
             Ctx:=Hint(HelpCtx);
             ptSimpleWindow(Window)^.HelpWasClear:=false;
             WriteStrXY2(10,462,cSLText,COPYWrite,Ctx);
             WriteStrXY2(11,462,cSLText,COPYWrite,Ctx);
             SetActive;
             MouseShow;
           end
       end
  else
    begin
      Inside:=false;
      if FActive then
        begin
          FActive:=false;
          SetUnActive;
        end
    end
end;

Procedure THiddenKey.WriteKeyName;
var q:byte;
    _xx,rez:integer;

begin
  LoadFnt('',false);
  _xx:=_x;
  for q:=1 to byte(_Name[0]) do
    if _Name[q]='&' then
      begin
        _xx:=_xx+8 shr 1
      end;
  for q:=1 to byte(_Name[0]) do
  begin
    if _Name[q]='&' then
      begin
        WriteStrXY2(_xx,_y,_Color,CopyWrite,_Name[q+1]);
        SetColor(_Color);
        MoveTo(_xx,_y+13);
        LineRel(8,0);
        q:=q+1;
        _xx:=_xx+8;
      end
    else
    if _Name[q]='~' then
      begin
        q:=q+1;
        while _Name[q]<>'~' do
          begin
            WriteStrXY2(_xx,_y,Magenta,CopyWrite,_Name[q]);
            _xx:=_xx+8;
            q:=q+1;
          end;
      end
    else
      begin
        WriteStrXY2(_xx,_y,_Color,CopyWrite,_Name[q]);
        _xx:=_xx+8;
      end;
  end;
end;

Constructor THiddenKey.Init;
begin
  inherited Init(_x,_y,_dx,_dy);
  Window:=_Window;
  Name:=_Name;
  Ext:=_Ext;
  CanAct:=_CanAct;
  CloseAfPr:=_Close;
  FActive:=false;
  HotKey:=_HotKey;
  PushProc:=_PushProc;
  PushWind:=_PushWind;
  FWasPush:=false;
  FCentered:=_Centered;
  Color:=_Color;
  HelpCtx:=_HelpCtx;
end;

Function tHiddenKey.Hint;
begin
  case AHelpCtx of
    hcFile      : Hint:='������� �ࠢ����� 䠩����';
    hcNew       : Hint:='����஢��� � ������� ।���஢���� �⠭�����'+
                        ' ����';
    hcOpen      : Hint:='������ �������騩 䠩�';
    hcSave      : Hint:='���࠭��� ।����㥬� ����';
    hcSaveAs    : Hint:='���࠭��� 䠩� � ��㣮� ��⮫���,'+
                        ' � ��㣨� ������� � �.�.';
    hcExit      : Hint:='�������� ࠡ��� � ।����';
    hcEdit      : Hint:='������� ।���஢���� ����';
    hcUndo      : Hint:='�⬥���� �।����� ������� ।���஢����';
    hcCopy      : Hint:='����஢��� ᨬ��� �� ⥪�饩 ����樨 '+
                         '����� � ����';
    hcPaste     : Hint:='��⠢��� �� ���� ᨬ��� � ⥪���� ������'+
                        ' �����';
    hcHelp      : Hint:='��ࠢ�� ।����';
    hcF_Editor  : Hint:='��ࠢ�� �� �ᯮ�짮����� � �����祭�� �ணࠬ�� '+
                        ' ''FONT EDITOR''';
    hcAbout     : Hint:='���ଠ�� �� ����᪨� �ࠢ�� � ���ᨨ �ணࠬ��';
    hcClose     : Hint:='������� ⥪�饥 ����';
    hcCancel    : Hint:='�⬥���� �������';
    hcModif     : Hint:='������� �८�ࠧ������ ᨬ����� ( ������, '+
                        'ᤢ����� � �.�. )';
    hcClear     : Hint:='����� ⥪�騩 ᨬ���';
    hcLeftSc    : Hint:='�������� ᨬ���(�) �����';
    hcRightSc   : Hint:='�������� ᨬ���(�) ��ࠢ�';
    hcDownSc    : Hint:='�������� ᨬ���(�) ����';
    hcUpSc      : Hint:='�������� ᨬ���(�) �����';
    hcInverse   : Hint:='������஢��� ᨬ���(�)';
    hcRotate    : Hint:='�������� ᨬ���(�) �� 90� ( ⮫쪮 ��� ᨬ����� '+
                        'ࠧ��஬ 8x8 )';
    hcHoriz     : Hint:='�������� ᨬ���(�) �� ��ਧ��⠫�';
    hcVert      : Hint:='�������� ᨬ���(�) �� ���⨪���';
    hcTarget    : Hint:='�������� ����⢨� ������';
    hcUp        : Hint:='�������� �।����� �࠭���';
    hcDown      : Hint:='�������� ᫥����� �࠭���';
  else Hint:='';
  end;
end;

  {-- ����ணࠬ�� tSimpleKey --}

Constructor tSimpleKey.Init;
begin
  inherited Init(_Window,_PushProc,_x,_y,_dx,_dy,_Name,_Ext,_Close,_CanAct,
  _HotKey,_PushWind,_Centered,_Color,_HelpCtx);
  BitMap:=_BitMap;
end;

Procedure tSimpleKey.SetActive;
var _x,xx,yy : integer;

begin
  if CanAct then
    begin
      GetXY(xx,yy);
      SetFillStyle(SolidFill,Color);
      MouseHide;
      Bar(xx,yy,xx+dx,yy+dy);
      WriteKeyName(xx+dx-(byte(Ext[0]) shl 3-CountSymbols(Ext,'~') shl 3)-3,
                   yy+((dy-14) shr 1),Ext,White);
      if FCentered then _x:=xx+(dx-(byte(Name[0])-CountSymbols(Name,
      '~')) shl 3) shr 1
      else _x:=xx+3;
      WriteKeyName(_x,yy+((dy-14) shr 1),Name,White);
      MouseShow;
    end;
end;

Procedure tSimpleKey.SetUnActive;
var _x,xx,yy : integer;

begin
  GetXY(xx,yy);
  SetFillStyle(SolidFill,LightGray);
  MouseHide;
  Bar(xx,yy,xx+dx,yy+dy);
  WriteKeyName(xx+dx-(byte(Ext[0]) shl 3-CountSymbols(Ext,'~') shl 3)-3,
               yy+((dy-14) shr 1),Ext,0);
  if FCentered then _x:=xx+(dx-(byte(Name[0])-CountSymbols(Name,
  '~')) shl 3) shr 1
  else _x:=xx+3;
  WriteKeyName(_x,yy+((dy-14) shr 1),Name,Blue);
  MouseShow;
end;

Procedure tSimpleKey.Press;
begin
  SetUnActive;
end;

Procedure tSimpleKey.SetVis;
var xx,yy : integer;

begin
  GetXY(xx,yy);
  MouseHide;
  if BitMap<>nil then
    PutImage(xx+2+(dx-BitMap^.dx-4) shr 1,yy+2+(dy-BitMap^.dy-4) shr 1,
             BitMap^,CopyPut);
  FActive:=false;
  SetUnActive;
  MouseShow;
end;

  {-- ����ணࠬ�� TStandartKey --}

Constructor TStandartKey.Init;
begin
  inherited Init(_Window,_PushProc,_x,_y,_dx,_dy,_Name,_Ext,_Close,_CanAct,
  _HotKey,_PushWind,true,_Color,_HelpCtx);
  BitMap:=_BitMap;
end;

Procedure TStandartKey.Press;
var  xx,yy: integer;
     ImgSize: word;
     PTImage:pointer;

begin
  MouseHide;
  GetXY(xx,yy);
  ImgSize:=ImageSize(xx+2,yy+2,xx+dx-2,yy+dy-2);
  GetMem(PTImage,ImgSize);
  GetImage(xx+2,yy+2,xx+dx-2,yy+dy-2,PTImage^);
  PutImage(xx+3,yy+3,PTImage^,CopyPut);
  FreeMem(PTImage,ImgSize);
  SetColor(White);
  MoveTo(xx+dx,yy);
  LineRel(0,dy);
  LineRel(-dx,0);
  SetColor(DarkGray);
  LineRel(0,-dy);
  LineRel(dx,0);
  SetColor(Color1);
  MoveTo(xx+dx-1,yy+1);
  LineRel(0,dy-2);
  LineRel(2-dx,0);
  SetColor(Black);
  LineRel(0,2-dy);
  LineRel(dx-1,0);
  MouseShow;
  while PushKey(LeftKey) do ; 
  MouseHide;
  SetVis;
  SetUnActive;
  FActive:=false;
  MouseShow;
end;

Procedure TStandartKey.SetVis;
var
  xx,yy:integer;
begin
    MouseHide;
    GetXY(xx,yy);
    SetFillStyle(SolidFill,LightGray);
    Bar(xx,yy,xx+dx,yy+dy);
    SetColor(Color1);
    MoveTo(xx,yy+dy);
    LineRel(0,-dy);
    LineRel(dx,0);
    SetColor(DarkGray);
    LineRel(0,dy);
    LineRel(-dx,0);
    MoveTo(xx+1,yy+dy-1);
    SetColor(White);
    LineRel(0,2-dy);
    LineRel(dx-2,0);
    SetColor(Color2);
    LineRel(0,dy-2);
    LineRel(1-dx,0);
    if BitMap<>nil then
      PutImage(xx+2+(dx-BitMap^.dx-4) shr 1,yy+2+(dy-BitMap^.dy-4) shr 1,
               BitMap^,CopyPut);
    FActive:=false;
    SetUnActive;
    WriteKeyName(xx+dx-(byte(Ext[0]) shl 3-CountSymbols(Ext,'~') shl 3)-3,
                 yy+((dy-14) shr 1),Ext,0);
    MouseShow;
end;

Procedure TStandartKey.SetActive;
var dxx,xx,yy:integer;

begin
  MouseHide;
  GetXY(xx,yy);
  dxx:=dx;
  if BitMap<>nil then
    begin
      xx:=xx+BitMap^.dx;
      dxx:=dx-BitMap^.dx;
    end;
  WriteKeyName(xx+((dxx-byte(Name[0]) shl 3) shr 1),
            yy+((dy-14) shr 1),Name,LightCyan);
  MouseShow;
end;

Procedure TStandartKey.SetUnActive;
var dxx,xx,yy:integer;

begin
  MouseHide;
  GetXY(xx,yy);
  dxx:=dx;
  if BitMap<>nil then
    begin
      xx:=xx+BitMap^.dx;
      dxx:=dx-BitMap^.dx;
    end;
  WriteKeyName(xx+((dxx-byte(Name[0]) shl 3) shr 1),
            yy+((dy-14) shr 1),Name,Black);
  MouseShow;
end;

  {-- ����ணࠬ�� TClassicKey --}

Constructor TClassicKey.Init;
begin
  inherited Init(_Window,_PushProc,_x,_y,_dx,_dy,_Name,_Ext,_Close,_CanAct,
                    _HotKey,_PushWind,_BitMap,_Color,_HelpCtx);
end;

Procedure TClassicKey.Press;
var xx,yy:integer;
    ImgSize: word;
    PTImage:pointer;

begin
  MouseHide;
  GetXY(xx,yy);
  ImgSize:=ImageSize(xx+2,yy+2,xx+dx-2,yy+dy-2);
  GetMem(PTImage,ImgSize);
  GetImage(xx+2,yy+2,xx+dx-2,yy+dy-2,PTImage^);
  PutImage(xx+3,yy+3,PTImage^,CopyPut);
  SetColor(Color);
  MoveTo(xx+dx,yy);
  LineRel(-dx,0);
  LineRel(0,dy);
  MouseShow;
  while PushKey(LeftKey) do;
  MouseHide;
  SetVis;
  SetUnActive;
  FreeMem(PTImage,ImgSize);
  FActive:=false;
  MouseShow;
end;

Procedure TClassicKey.SetVis;
var xx,yy:integer;

begin
  MouseHide;
  GetXY(xx,yy);
  SetFillStyle(SolidFill,Color);
  Bar(xx,yy,xx+dx,yy+dy);
  MoveTo(xx+dx,yy);
  SetColor(Color+8);
  LineRel(-dx,0);
  LineRel(0,dy);
  MoveTo(xx+dx,yy+1);
  LineRel(1-dx,0);
  LineRel(0,dy-1);
  SetColor(Black);
  MoveTo(xx+1,yy+dy);
  LineRel(dx-1,0);
  LineRel(0,1-dy);
  MoveTo(xx+2,yy+dy-1);
  LineRel(dx-3,0);
  LineRel(0,3-dy);
  if BitMap<>nil then
    PutImage(xx+3,yy+(dy-BitMap^.dy) shr 1,BitMap^,CopyPut);
  FActive:=false;
  WriteKeyName(xx+dx-(byte(Ext[0]) shl 3-CountSymbols(Ext,'~') shl 3)-3,
               yy+((dy-14) shr 1),Ext,0);
  SetUnActive;
  MouseShow;
end;

Procedure TClassicKey.SetActive;
var dxx,xx,yy:integer;

begin
  MouseHide;
  GetXY(xx,yy);
  dxx:=dx;
  if BitMap<>nil then
    begin
      xx:=xx+BitMap^.dx;
      dxx:=dx-BitMap^.dx;
    end;
  WriteKeyName(xx+((dxx-byte(Name[0]) shl 3) shr 1),
            yy+((dy-14) shr 1),Name,White);
  MouseShow;
end;

  {-- ����ணࠬ�� TBackWindow --}

Constructor TBackWindow.Init;
begin
  MouseHide;
  inherited Init(_x,_y,_dx,_dy);
  if longint(dx)*dy>65535 then
    begin
      ImageSave:=false;
      Size:=0;
    end
  else
    begin
      ImageSave:=true;
      Size:=ImageSize(x,y,x+dx,y+dy);
      GetMem(BackImage,Size);
      GetImage(x,y,x+dx,y+dy,BackImage^)
    end;
  MouseShow;
  Symbol:=#0;
  Code:=0;
end;

Procedure TBackWindow.SetUnVis;
begin
  MouseHide;
  if ImageSave then PutImage(x,y,BackImage^,COPYPut)
  else SetAllVis;
  MouseShow;
end;

Destructor TBackWindow.Done;
begin
  inherited Done;
  FreeMem(BackImage,Size);
end;

  {-- ����ணࠬ�� TSimpleWindow --}

Constructor TSimpleWindow.Init;
var q:byte;

begin
  inherited Init(_x,_y,_dx,_dy,Shadow);
  New(LKeys,Init);
  Color:=_Color;
  Keys:=_Keys;
  BefoOpenProc:=_BOpProc;
  AfteOpenProc:=_AOpProc;
  ContProc:=_ContProc;
  HelpCtx:=_HelpCtx;
  for q:=1 to Keys do
    begin
      with Lkeys^ do
        begin
          with PMKeys^[q] do
            begin
              case PMKeys^[q].KeyType  of
                HiddenKey : AddElem(New(PTHiddenKey,Init(@Self,PushProc,x,y,
                       dx,dy,Name,Ext,CloseAfPr,CanActive,HotKey,PushWind,
                       Centered,Color,HelpCtx)));
                Simple    : AddElem(New(pSimpleKey,Init(@Self,PushProc,x,y,
                       dx,dy,Name,Ext,CloseAfPr,CanActive,HotKey,PushWind,
                       BitMap,Centered,Color,HelpCtx)));
                Standart  : AddElem(New(PTStandartKey,Init(@Self,PushProc,x,
                              y,dx,dy,Name,Ext,CloseAfPr,CanActive,HotKey,
                              PushWind,BitMap,0,HelpCtx)));
                Classic   : AddElem(New(PTClassicKey,Init(@Self,PushProc,x,y,
                       dx,dy,Name,Ext,CloseAfPr,CanActive,HotKey,
                       PushWind,Color,BitMap,HelpCtx)))
            end
          end
        end
    end
end;

Procedure TSimpleWindow.StInsAll;
var
  WorkKey:PTHiddenKey;
  xx,yy:word;

begin
  HelpActive:=false;
  WorkKey:=PTHiddenKey(Lkeys^.First);
  while WorkKey<>nil do
    with WorkKey^ do
      begin
        GetMouseXY(xx,yy);
        if ((Inside and PushKey(LeftKey)) or HotPressed) and not FWasPush
          then
            begin
              FWasPush:=true;
              SetActive;
              if Inside then SetActive;
              Press;
              while PushKey(LeftKey) do ;
              PushProc;
              if PushWind<>nil then MakeWindow(PushWind);
              FWasPush:=false;
              if CloseAfPr then FExit:=true;
            end;
        if Inside then HelpActive:=true;
        WorkKey:=PTHiddenKey(Next);
      end;
      if not HelpActive and not HelpWasClear then
        begin
          HelpWasClear:=true;
          HelpActive:=false;
          MouseHide;
          SetFillStyle(SolidFill,cStatusLine);
          Bar(10,461,639,479);
          MouseShow;
        end;
  ContProc;
end;

Procedure TSimpleWindow.SetVis;
begin
  MouseHide;
  BefoOpenProc;
  SetFillStyle(SolidFill,Color);
  Bar(x,y,x+dx,y+dy);
  SetKeysVis;
  AfteOpenProc;
  MouseShow;
end;

Procedure TSimpleWindow.SetKeysVis;
var
  PKey:PTHiddenKey;

begin
  PKey:=PTHiddenKey(LKeys^.First);
  while PKey<>nil do
    begin
      PKey^.SetVis;
      PKey:=PTHiddenKey(PKey^.Next);
    end;
end;

Function tSimpleWindow.Inside;
var mx,my : word;

begin
  GetMouseXY(mx,my);
  if (mx>x) and (my>y) and (mx<x+dx) and (my<y+dy) then
    Inside:=True
  else
    Inside:=False;
end;

Destructor TSimpleWindow.Done;
begin
  inherited Done;
  Dispose(LKeys,Done);
end;

  {-- ����ணࠬ�� TShadowWindow --}

Constructor TShadowWindow.Init;
begin
  inherited Init(_x,_y,_dx,_dy);
  if Shadow then
    begin
      dx:=dx-ShadowSize;
      dy:=dy-ShadowSize;
    end;
end;

Procedure TShadowWindow.SetShadowVis;
var i : byte;

begin
  SetColor(Black);
  SetWriteMode(OrPut);
  for i:=0 to ShadowSize do
    begin
      MoveTo(x+ShadowSize,y+dy+ShadowSize-i);
      SetLineStyle(UserBitLn,21845,1);
      LineRel(dx-i,0);
      if i mod 2 = 0 then
        SetLineStyle(UserBitLn,21845,1)
      else
        SetLineStyle(UserBitLn,43690,1);
      LineRel(0,i-dy);
    end;
  SetLineStyle(SolidLn,0,1);
  SetWriteMode(COPYPut);
end;

  {-- ����ணࠬ�� TClassicWindow --}

Constructor TClassicWindow.Init;
begin
  inherited Init(_x,_y,_dx,_dy,_Color,PMKeys,_Keys,
                     _BOpProc,_AOpProc,_ContProc,_Shadow,_HelpCtx);
  FShadow:=_Shadow;
end;

Procedure TClassicWindow.SetVis;

const
  Gray50 : FillPatternType = ($AA,$55,$AA,$55,$AA,$55,$AA,$55);

var
  i:byte;

begin
  MouseHide;
  BefoOpenProc;
  if FShadow then TShadowWindow.SetShadowVis;
  SetColor(Color+8);
  for i:=1 to 4 do
    begin
      MoveTo(x+dx-i,y+i);
      LineRel(i shl 1-dx,0);
      LineRel(0,dy-i shl 1)
    end;
  SetColor(Color);
  Rectangle(x,y,x+dx,y+dy);
  SetFillStyle(SolidFill,Color);
  Bar(x+5,y+5,x+dx-5,y+dy-5);
  MoveTo(x,y);
  LineRel(5,5);
  MoveTo(x+dx,y);
  LineRel(-5,5);
  MoveTo(x+dx,y+dy);
  LineRel(-5,-5);
  MoveTo(x,y+dy);
  LineRel(5,-5);
  SetFillPattern(Gray50,Color);
  FloodFill(x+dx-2,y+dy-1,Color);
  FloodFill(x+dx-1,y+dy-4,Color);
  SetColor(Black);
  Rectangle(x,y,x+dx,y+dy);
  SetKeysVis;
  AfteOpenProc;
  MouseShow;
end;

  {-- ����ணࠬ�� TStandartWindow --}

Constructor TStandartWindow.Init;
begin
  inherited Init(_x,_y,_dx,_dy,LightGray,_Shadow,
                      PMKeys,_Keys,_BOpProc,_AOpProc,_ContProc,_HelpCtx);
end;

Procedure TStandartWindow.SetVis;
var i:byte;

begin
  MouseHide;
  BefoOpenProc;
{  if FShadow then TShadowWindow.SetShadowVis; }
  SetFillStyle(SolidFill,LightGray);
  Bar(x,y,x+dx,y+dy);
  SetColor(Color1);
  for i:=1 to 3 do
    begin
      MoveTo(x+dx-i,y+i);
      LineRel(i shl 1-dx,0);
      LineRel(0,dy-i shl 1)
    end;
  SetFillStyle(SolidFill,LightGray);
  Bar(x+4,y+4,x+dx-4,y+dy-4);
  SetColor(Color2);
  for i:=1 to 3 do
    begin
      MoveTo(x+i,y+dy-i);
      LineRel(dx-i shl 1,0);
      LineRel(0,i shl 1-dy);
    end;
  SetColor(LightGray);
  MoveTo(x,y);
  LineRel(3,3);
  SetColor(Black);
  MoveTo(x+dx,y+dy);
  LineRel(-3,-3);
  SetColor(Black);
  Rectangle(x,y,x+dx,y+dy);
  SetKeysVis;
  AfteOpenProc;
  MouseShow;
end;

  {-- ����ணࠬ�� TFrameWindow --}

Constructor TFrameWindow.Init;
begin
  inherited Init(_x,_y,_dx,_dy,_Color,_Shadow,PMKeys,
                      _Keys,_BOpProc,_AOpProc,_ContProc,_HelpCtx);
  FrameColor:=_FrameColor;
  FrameThick:=_FrameThick;
end;

Procedure TFrameWindow.SetVis;
var q:byte;
begin
  MouseHide;
  BefoOpenProc;
  if FShadow then TShadowWindow.SetShadowVis;
  SetFillStyle(SolidFill,Color);
  Bar(x,y,x+dx,y+dy);
  SetColor(FrameColor);
  for q:=0 to FrameThick-1 do Rectangle(x+q,y+q,x+dx-q,y+dy-q);
  SetKeysVis;
  AfteOpenProc;
  MouseShow;
end;

  {-- ��楤��� � �㭪樨 ����� --}

Procedure CloseAll;
begin
  while Windows.Prev<>nil do Dispose(Windows.DeleteElem(Windows.Last),Done);
end;

Procedure SetAllVis;
var Wind:PTWindow;

begin
  MouseHide;
  Wind:=PTWindow(Windows.First);
  while Wind<>nil do
    begin
      Wind^.SetVis;
      Wind:=PTWindow(Wind^.Next);
    end;
  MouseShow;
end;

Procedure MakeWindow;
begin
  with _Window^ do
    begin
      case WindType of
        WSimple   : Windows.AddElem(new(PTSimpleWindow,Init(X,
                                                            Y,
                                                            DX,
                                                            Y,
                                                            Color,
                                                            Keys,
                                                            NumKeys,
                                                            BefOpenPr,
                                                            OpenProc,
                                                            ContProc,
                                                            False,
                                                            HelpCtx)));
        WStandart : Windows.AddElem(new(PTStandartWindow,Init(X,
                                                              Y,
                                                              DX,
                                                              DY,
                                                              Shadow,
                                                              Keys,
                                                              NumKeys,
                                                              BefOpenPr,
                                                              OpenProc,
                                                              ContProc,
                                                              HelpCtx)));
        WClassic  : Windows.AddElem(new(PTClassicWindow,Init(X,
                                                             Y,
                                                             DX,
                                                             DY,
                                                             Color,
                                                             Shadow,
                                                             Keys,
                                                             NumKeys,
                                                             BefOpenPr,
                                                             OpenProc,
                                                             ContProc,
                                                             HelpCtx)));
        WFrame    : Windows.AddElem(new(PTFrameWindow,Init(X,
                                                           Y,
                                                           DX,
                                                           DY,
                                                           Color,
                                                           FrameColor,
                                                           FrameThick,
                                                           Shadow,
                                                           Keys,
                                                           NumKeys,
                                                           BefOpenPr,
                                                           OpenProc,
                                                           ContProc,
                                                           HelpCtx)));
      end;
    end;
  MouseHide;
  SetFillStyle(SolidFill,cStatusLine);
  Bar(0,461,639,479);
  MouseShow;
  PTSimpleWindow(Windows.Last)^.SetVis;
  while not FExit and not FGlobalExit do
    with ptSimpleWindow(Windows.Last)^ do
      begin
        GetSymbol;
        StInsAll;
        if PushKey(LeftKey) and not Inside and (Windows.First<>Windows.Last)
          then
            begin
              FExit:=true;
              while PushKey(LeftKey) do
            end
        else
          begin
            if (Code=scEsc) and (Windows.First<>Windows.Last) then
              FExit:=true;
          end;
      end;
  Dispose(Windows.DeleteElem(Windows.Last),Done);
  if DrawAfterClose and (Windows.First<>nil) then
    begin
      MouseHide;
      ptFrameWindow(Windows.First)^.AfteOpenProc;
      MouseShow;
      DrawAfterClose:=false;
    end;
  if FGlobalExit=false then FExit:=false
  else FExit:=true;
  MouseHide;
  SetFillStyle(SolidFill,cStatusLine);
  Bar(0,461,639,479);
  MouseShow;
end;

Procedure CloseLastWind;
begin
  FExit:=true;
end;

Procedure Quit;
begin
  FGlobalExit:=true;
  FExit:=true;
end;

END.