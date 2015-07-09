(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Редактор матричных шрифтов                                 *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
Program Font_Studio;

uses Graph,
     LGraph,
     Mouse,
     Resourse,
     CRT,
     Gen640,
     Keyboard,
     Dos,
     LDos,
     LString,
     InputStr,
     LSound,
     LWindows,
     LColors,
     Constant;

var  InputLine : pInputLine;                { строка ввода                }

type
  tAnswer=(Yes,No,Cancel);                  { тип ответа (да,нет,отмена)  }
  tCom=(sLeft,sRight,sUp,sDown,cInverse,
        cVert,cHoriz,cRotate);              { команды                     }

const
  Xnet = 50;                                { позиция сетки по X          }
  Xtab = 315;                               { позиция таблицы по X        }
  Ytab = 115;                               { позиция таблицы по Y        }
  Xcur : byte = 0;                          { позиция курсора             }
  Ycur : byte = 0;                          {                  в таблице  }
  Untitled = 'без имени';
  FontName : PathStr='';                    { имя шрифта                  }
  Topic : byte = 0;                         { номер темы для поиска       }
  FSaveAs : boolean = false;                { флаг 'Сохранить как'        }
  Clipboard : array[1..16] of
    byte=(0,0,0,0,0,0,0,0,
          0,0,0,0,0,0,0,0);                 { буфер                       }
  FModified : boolean = false;              { флаг 'Модифицирован'        }
  FRemember : boolean = false;              { флаг для слхранения симаола }
  FSymbolOnly : boolean = true;             { флаг 'Команды для'          }
  Answer : tAnswer = Cancel;                { ответ                       }
  MouseType : boolean = false;

type
  pOpenWindow = ^tOpenWindow;
  tOpenWindow = object(tStandartWindow)   { объект окно сохранить/открыть }
    Constructor Init;
    Procedure SetVis; virtual;
    Procedure StInsAll; virtual;
    Destructor Done; virtual;
  end;

var
  Ynet     : word;                          { позиция сетки по Y          }
  FontType : byte;                          { тип шрифта (8 или 16)       }
  Buf      : string;                       { буфер для передачи сообщений }
  Dir  : DirStr;
  Name : PathStr;
  Ext  : ExtStr;
  FOpen : boolean;                          { флаг открыть/сохранить      }
  UndoBuf : array[0..15] of byte;           { буфер UNDO                  }

Procedure NUL ; FAR; FORWARD;
Procedure Error(Err : byte) ; FORWARD;
Procedure SaveFont ; FAR ; FORWARD;
Procedure Quest; FORWARD;
Function WasModified: tAnswer; FORWARD;
Procedure Help; FAR; FORWARD;

Procedure FontFile ; FAR;          { процедура открытия/сохранения шрифта }
var _Name : string;
    Num:byte;

begin
  Name:=InputLine^.GetData;
  FSplit(Name,Dir,_Name,Ext);
  if Name='' then Error(4)
  else
    begin
      if Ext='' then Name:=Name+'.FNT';
      if copy(Dir,2,1)=':' then
        if (UpCase(Dir[1])='B') and (NumDrives<2) then
          begin
            Error(15);
            Exit;
          end;
    end;
  if Name<>'' then
    begin
      if FOpen then
        begin
          LoadFNT(Name,true);
          Error(FontError);
          if FontError=0 then
            begin
              FExit:=true;
              if (FontHeight<>FontType) and
                 (FontType=16) then
                FillChar(Clipboard,16,0);
              FontType:=FontHeight;
              FontName:=Name;
              FModified:=false;
              Move(FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+1],
                UndoBuf,FontType);
              Answer:=Yes;
            end
          else
            with InputLine^ do
              begin
                Draw;
                ShowCursor;
              end;
        end
      else
        begin
          FSaveAs:=true;
          SaveFont;
          FSaveAs:=false;
        end;
    end;
end;

Procedure FileCanc; FAR;
begin
  Answer:=Cancel;
  FExit:=true;
end;

const
  OpenWindKeys:array[1..3] of TKeys =
  ((KeyType:Standart;
    X:228;
    Y:70;
    DX:70;
    DY:20;
    PushProc: FontFile;
    PushWind: nil;
    Name:'Ok';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scEnter),
   (KeyType:Standart;
    X:300;
    Y:70;
    DX:70;
    DY:20;
    PushProc: FileCanc;
    PushWind: nil;
    Name:'&Отмена';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scJ+scWAlt;
    HelpCtx : hcCancel),
   (KeyType:Standart;
    X:372;
    Y:70;
    DX:70;
    DY:20;
    PushProc: Help;
    PushWind: nil;
    Name:'Справка';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scF1;
    HelpCtx : hcHelp));

  { подпрограммы tOpenWindow }

Constructor tOpenWindow.Init;
var Ctx : byte;

begin
  if FOpen then Ctx:=hcOpen
  else Ctx:=hcSaveAs;
  inherited Init(65,30,462,110,true,@OpenWindKeys,3,nul,nul,nul,Ctx);
  New(InputLine,Init(81,67,424,16,80));
  if FontName<>Untitled then InputLine^.SetData(FontName);
end;

Procedure tOpenWindow.SetVis;
begin
  inherited SetVis;
  MouseHide;
  SimpleFrame(80,64,428,22,cNewColor1,cNewColor2);
  if FOpen then WriteShStr2(85,41,White,'Открыть файл :')
  else WriteShStr2(85,41,White,'Сохранить файл как :');
  with InputLine^ do
    begin
      Draw;
      ShowCursor;
    end;
  MouseShow;
end;

Procedure tOpenWindow.StInsAll;
begin
  inherited StInsAll;
  InputLine^.Edit;
end;

Destructor tOpenWindow.Done;
begin
  Dispose(InputLine,Done);
  Inherited Done;
  MouseHide;
  SetFillStyle(SolidFill,cStatusLine);
  Bar(0,461,639,479);
    MouseShow;
end;


Procedure DrawNet;         { рисует сетку для вывода увеличенного символа }
var i : byte;

begin
  SetColor(cNet);
  Ynet:=130+(300-FontType shl 4) div 2;
  for i:=0 to FontType do
    Line(Xnet,Ynet+i shl 4,Xnet+128,Ynet+i shl 4);
  for i:=0 to 8 do
    Line(Xnet+i shl 4,Ynet,Xnet+i shl 4,Ynet+FontType shl 4);
end;

Procedure SetPixel(X, Y, Color : byte);       { закрашивает квадрат сетки }
var i : byte;

begin
  SetFillStyle(SolidFill,Color);
  Bar(Xnet+X shl 4+1,Ynet+Y shl 4+1,Xnet+X shl 4+15,Ynet+Y shl 4+15);
end;

Procedure DrawSymbol( Num : byte );             { рисует символ в таблице }
var x,y,_y : byte;
begin
  X:=Num-Num shr 4 shl 4;
  Y:=Num shr 4;
  if FontType=16 then _Y:=0
  else _Y:=4;
  SetFillStyle(solidfill,cBackGround);
  Bar(Xtab+x*20,Ytab+y*21,Xtab+8+x*20,Ytab+16+y*21);
  WriteStrXY2(Xtab+x*20,Ytab+_Y+y*21,cSymbTable,CopyWrite,char(Num));
end;

Procedure DrawSymbolTable;                    { рисует символьную таблицу }
var i : byte;

begin
  LoadFNT(FontName,false);
  for i:=0 to 255 do
    DrawSymbol(i);
  LoadFNT('',false);
end;

Procedure SetCursor(Num : byte); { устанавливает курсор в заданные коорд. }
var x,y : byte;
    _Num : string[3];

begin
  Str(Num,_Num);
  SetFillStyle(solidfill,cBackGround);
  Bar(Xnet+28,Ynet-24,Xnet+100,Ynet-10);
  WriteShStr2(Xnet+(128-(byte(_num[0])+6) shl 3) shr 1,
    Ynet-24,cSymbCode,'ASCII='+_Num);
  X:=Num-Num shr 4 shl 4;
  Y:=Num shr 4;
  if FRemember then
    begin
      Move(FontBuf^.Font[(X+Y shl 4)*FontType+1],UndoBuf,FontType);
      FRemember:=false;
    end;
  SetColor(cBackGround);
  Rectangle(Xtab-3+20*Xcur,Ytab-2+21*Ycur,Xtab+10+20*Xcur,Ytab+17+21*Ycur);
  SetColor(cCursor);
  Rectangle(Xtab-3+20*X,Ytab-2+21*Y,Xtab+10+20*X,Ytab+17+21*Y);
  Xcur:=X;
  Ycur:=Y;
end;

Procedure DrawBigSymbol(Num : byte );         { рисует увеличенный символ }
var x,y : byte;

begin
  for y:=1 to FontType do
    for x:=0 to 7 do
      begin
        if (FontBuf^.Font[Num*FontType+y] shr x) and 1 <> 0 then
          SetPixel(7-x,y-1,cNPixel)
        else
          SetPixel(7-x,y-1,cBackGround);
      end;
end;

Function MouseInTable(var Num   { номер символа на котором находится мышь }
                          : byte) : boolean;
var mx,my : word;

begin
  GetMouseXY(mx,my);
  if (mx>Xtab-5) and (my>Ytab-4) and (mx<Xtab+310) and (my<YTab+332) then
    MouseInTable:=True
  else
    begin
      MouseInTable:=False;
      Exit;
    end;
  Num:=((my-(Ytab-4)) div 21) shl 4+(mx-(Xtab-5)) div 20;
end;

Function MouseInNet(var X, Y  { позиция в сетке на которую указывает мышь }
                        : byte) : boolean;
var mx,my : word;

begin
  GetMouseXY(mx,my);
  if (mx>Xnet) and (my>Ynet) and (mx<Xnet+128) and
     (my<Ynet+FontType shl 4) then
    MouseInNet:=True
  else
    begin
      MouseInNet:=False;
      Exit;
    end;
  X:=(mx-Xnet) div 16;
  Y:=(my-Ynet) div 16;
end;

Function GetNetPix(X, Y : byte) : boolean;          { есть пиксел в x,y ? }
begin
  if GetPixel(Xnet+X shl 4+1,Ynet+Y shl 4+1)=cBackGround then
    GetNetPix:=False
  else
    GetNetPix:=True;
end;

Procedure SetSymbPix(X, Y : byte ; SetPix : boolean );
                               { устанавливае/сбрасывает пиксел в символе }
begin
  FModified:=true;
  if SetPix then
    FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+y+1]:=
      FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+y+1] or (1 shl (7-x))
  else
    FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+y+1]:=
      FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+y+1]  and not (1 shl (7-x));
  LoadFNT(FontName,false);
  DrawSymbol(Xcur+Ycur shl 4);
  LoadFNT('',false);
end;

Procedure WriteFontName;                 { пишет имя редактируемого фонта }
begin
  SetFillStyle(solidfill,cBackGround);
  Bar(Xtab,Ytab-30,Xtab+320,Ytab-30+16);
  if FontName<>Untitled then
    begin
      FSplit(FontName,Dir,Name,Ext);
      Name:='Файл : '+Name+Ext;
    end
  else
    Name:='Файл : без имени';
  WriteShStr2(Xtab+(20 shl 4-byte(Name[0]) shl 3) shr 1,
                       Ytab-30,cFontName,Name);
end;

Procedure DrawClipboard;                                   { рисует буфер }
var x,y : byte;

begin
  SetFillStyle(solidfill,cBackGround);
  Bar(Xnet+27,Ynet+(FontType+1) shl 4,
      Xnet+27+72,Ynet+(FontType+1) shl 4+16);
  WriteShStr2(Xnet+27,Ynet+(FontType+1) shl 4,White,'Буфер :');
  SetColor(cNewColor1);
  Rectangle(Xnet+88,Ynet+(FontType+1) shl 4-2+(16-FontType) shr 1,
            Xnet+99,Ynet+(FontType+2) shl 4+1-(16-FontType) shr 1);
  for y:=1 to FontType do
    for x:=0 to 7 do
      if Clipboard[y] and (1 shl x) <> 0 then
        PutPixel(Xnet+90+(7-x),
                 Ynet+(FontType+1) shl 4+y-1+(16-FontType) shr 1,White);
end;

Procedure WriteQuest; FAR;                       { пишет вопрос из буфера }
begin
  WriteStrXY2(70+(500-byte(Buf[0]) shl 3) shr 1,210,cBackGround,COPYPut,Buf);
end;

Procedure SetNo; FAR;                              { установить ответ НЕТ }
begin
  Answer:=No;
end;

Procedure SetYes; FAR;                              { установить ответ ДА }
begin
  Answer:=Yes;
end;

Procedure SetCancel; FAR;                       { установить ответ ОТМЕНА }
begin
  Answer:=Cancel;
end;

Procedure Quest;                              { открывает окно с вопросом }
const
  QuestWindKeys:array[1..3] of TKeys =
  ((KeyType:Standart;
    X:135;
    Y:60;
    DX:70;
    DY:20;
    PushProc: SetYes;
    PushWind: nil;
    Name:'Да';
    Ext:'';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scEnter),
   (KeyType:Standart;
    X:215;
    Y:60;
    DX:70;
    DY:20;
    PushProc: SetNo;
    PushWind: nil;
    Name:'&Нет';
    Ext:'';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scWAlt+scY),
   (KeyType:Standart;
    X:295;
    Y:60;
    DX:70;
    DY:20;
    PushProc: SetCancel;
    PushWind: nil;
    Name:'&Отмена';
    Ext:'';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scJ+scWAlt;
    HelpCtx : hcCancel));

  QuestWindow:TWindows=(
    WindType:WStandart;
    x:70;
    y:190;
    dx:500;
    dy:100;
    HelpCtx : hcNoContext;
    BefOpenPr: nul;
    OpenProc: WriteQuest;
    ContProc: nul;
    Shadow:false;
    Keys:@QuestWindKeys;
    NumKeys:3);

begin
  MakeWindow(@QuestWindow);
end;

Procedure WriteError; FAR;                       { пишет ошибку из буфера }
begin
  WriteShStr3(20+(609-byte(Buf[0]) shl 3) shr 1,205,cEWText,Buf);
end;

Procedure Error( Err : byte );                        { обработчик ошибок }
const
  ErrWindKeys:array[1..1] of TKeys =
  ((KeyType:Standart;
    X:259;
    Y:60;
    DX:100;
    DY:20;
    PushProc: CloseLastWind;
    PushWind: nil;
    Name:'Ok';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scEnter;
    HelpCtx : hcClose;
    CanActive : true;
    Centered:true));

  ErrorWindow:TWindows=(
    WindType:WStandart;
    x:10;
    y:190;
    dx:619;
    dy:100;
    HelpCtx : hcNoContext;
    BefOpenPr: nul;
    OpenProc: WriteError;
    ContProc: nul;
    Shadow: false;
    Keys:@ErrWindKeys;
    NumKeys:1);

begin
  if Err<>0 then
    begin
      Beep;
      case Err of
        002 : Buf:='Файл не найден.';
        003 : Buf:='Путь не найден.';
        004 : Buf:='Имя файла отсутствует.';
        005 : Buf:='Отказ в доступе к файлу.';
        015 : Buf:='Неверное имя дисковода.';
        100 : Buf:='Ошибка чтения диска.';
        103 : Buf:='HLP файл не найден или имеет неверный формат,'+
                   ' помощь недоступна !';
        150 : Buf:='Диск защищен от записи.';
        152 : Buf:='Дисковод не готов.';
        156 : Buf:='Дисковод не найден.';
        158 : Buf:='Сектор не найден.';
        159 : Buf:='Неправильное имя файла.';
        162 : Buf:='Ошибка оборудования.';
        215 : Buf:='Неверный формат файла.';
        else  Buf:='Ошибка ввода/вывода.';
      end;
      MakeWindow(@ErrorWindow);
    end;
end;

Procedure OpenProc;         { процедура открытия окна 'сохранить/открыть' }
begin
  SetFillStyle(SolidFill,cStatusLine);
  Bar(0,461,639,479);
  Windows.AddElem(new(pOpenWindow,Init));
  pOpenWindow(Windows.Last)^.SetVis;
  while not FExit do
  with pOpenWindow(Windows.Last)^ do
    begin
      GetSymbol;
      StInsAll;
      if (PushKey(LeftKey) and not Inside) or (Code=scEsc)
        then
          begin
            FExit:=true;
            Answer:=Cancel;
            while PushKey(LeftKey) do;
          end;
    end;
  Dispose(Windows.DeleteElem(Windows.Last),Done);
  FExit:=false;
  if Answer<>Cancel then
    ptFrameWindow(Windows.First)^.SetVis;
end;

{$F+}

Procedure Nul;                                         { пустая процедура }
begin
end;

Procedure MainProc;                            { процедура основного окна }
begin
  SetFillStyle(solidfill,Blue);
  Bar(0,66,639,460);
  DrawSymbolTable;
  DrawNet;
  DrawClipboard;
  DrawBigSymbol(Xcur+Ycur shl 4);
  SetCursor(Xcur+Ycur shl 4);
  WriteFontName;
end;

Procedure HandleEvent;                               { обработчик событий }
var SN,
    Code,
    X,Y : byte;

begin
 if not MouseType and MouseInTable(SN) then
    begin
      MouseType:=true;
      SetNewGCursor(8,8,@Lupa);
    end
  else
    if MouseType and not MouseInTable(SN) then
      begin
        MouseType:=false;
        SetNewGCursor(1,1,@Arrow2);
      end;
  if PushKey(LeftKey) then
    begin
      if MouseInTable(SN) then
        begin
          if SN<>Xcur+Ycur shl 4 then
            begin
              MouseHide;
              DrawBigSymbol(SN);
              FRemember:=true;
              SetCursor(SN);
              MouseShow;
            end
        end
      else
      if MouseInNet(X,Y) then
        begin
          if not GetNetPix(x,y) then
            begin
              MouseHide;
              SetPixel(x,y,cNPixel);
              SetSymbPix(x,y,true);
              MouseShow;
            end;
        end
    end
  else
  if PushKey(RightKey) then
    begin
      if MouseInNet(X,Y) then
        if GetNetPix(x,y) then
          begin
              MouseHide;
              SetPixel(x,y,cBackGround);
              SetSymbPix(x,y,false);
              MouseShow;
          end
    end
  else
    begin
      if Code=scRight then
        begin
          if Xcur<15 then
            begin
              MouseHide;
              SN:=Xcur+Ycur shl 4+1;
              DrawBigSymbol(SN);
              FRemember:=true;
              SetCursor(SN);
              MouseShow;
            end;
        end
      else
      if Code=scLeft then
        begin
          if Xcur>0 then
            begin
              MouseHide;
              SN:=Xcur+Ycur shl 4-1;
              DrawBigSymbol(SN);
              FRemember:=true;
              SetCursor(SN);
              MouseShow;
            end;
        end
      else
      if Code=scDown then
        begin
          if Ycur<15 then
            begin
              MouseHide;
              SN:=Xcur+(Ycur+1) shl 4;
              DrawBigSymbol(SN);
              FRemember:=true;
              SetCursor(SN);
              MouseShow;
            end;
        end
      else
      if Code=scUp then
        begin
          if Ycur>0 then
            begin
              MouseHide;
              SN:=Xcur+(Ycur-1) shl 4;
              DrawBigSymbol(SN);
              FRemember:=true;
              SetCursor(SN);
              MouseShow;
            end;
        end
    end;
end;

Procedure SaveAs;                                      { СОХРАНИТЬ КАК... }
begin
  FOpen:=false;
  OpenProc;
end;


Procedure OpenFont;                                          { ОТКРЫТЬ... }
begin
  if WasModified<>Cancel then
    begin
      FOpen:=true;
      OpenProc;
    end;
end;

Procedure SaveFont;              { сохраняет на диске редактируемый шрифт }
var F : file;
    E : byte;
    Font : PathStr;
    S : SearchRec;
    Save : boolean;

begin
  Save:=true;
  if (FontName=Untitled) or FSaveAs then
    begin
      Font:=Name;
      FSplit(Font,Dir,Name,Ext);
      Font:=Dir+Name+Ext;
      FindFirst(Font,AnyFile,S);
      if S.Name=UpString(Name+Ext) then
        begin
          Buf:='Данный файл уже существует. Сохранять ?';
          Quest;
          if Answer=No then
            begin
              Exit
            end
          else
          if Answer=Cancel then
            begin
              FExit:=true;
              Exit;
            end;
        end
      else Save:=true;
    end
  else
    Font:=FontName;
  Assign(F,Font);
  Rewrite(F,1);
  E:=IOResult;
  if E<>0 then
    if E=2 then Error(159)
    else
      Error(E)
  else
    begin
      Seek(F,0);
      BlockWrite(F,FontBuf^.Font,FontType shl 8);
      E:=IOResult;
      if E<>0 then Error(E)
      else
        FontName:=Font;
    end;
  if E=0 then
    begin
      FModified:=false;
      Answer:=Yes;
      Close(F);
      FExit:=true;
    end;
end;

Procedure Save;                                               { СОХРАНИТЬ }
begin
  if FontName=Untitled then SaveAs
  else SaveFont;
  if Windows.Last=Windows.First then FExit:=false;
end;

Procedure CopySym;                                           { КОПИРОВАТЬ }
begin
  Move(FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+1],Clipboard,FontType);
  MouseHide;
  DrawClipboard;
  MouseShow;
end;

Procedure PasteSym;                                            { ВСТАВИТЬ }
begin
  Move(FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+1],UndoBuf,FontType);
  Move(Clipboard,FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+1],FontType);
  LoadFNT(FontName,false);
  MouseHide;
  DrawSymbol(Xcur+Ycur shl 4);
  LoadFNT('',false);
  DrawBigSymbol(Xcur+Ycur shl 4);
  FModified:=true;
  MouseShow;
  FRemember:=false;
end;

Procedure UndoSym;                                         { ВОССТАНОВИТЬ }
var _Buf : array[0..15] of byte;

begin
  Move(FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+1],_Buf,FontType);
  Move(UndoBuf,FontBuf^.Font[(Xcur+Ycur shl 4)*FontType+1],FontType);
  Move(_Buf,UndoBuf,FontType);
  MouseHide;
  LoadFNT(FontName,false);
  DrawSymbol(Xcur+Ycur shl 4);
  LoadFNT('',false);
  DrawBigSymbol(Xcur+Ycur shl 4);
  MouseShow;
end;

Procedure ExitEd;                                    { ВЫХОД ИЗ ПРОГРАММЫ }
begin
  if FModified then
    begin
      WasModified;
      if Answer<>Cancel then
        FGlobalExit:=true
    end
  else
    FGlobalExit:=true;
end;

Procedure StandFont;                                        { СТАНДАРТНЫЙ }
begin
  if (FontName=Untitled) and not FModified then
  else
    begin
      if WasModified<>Cancel then
        begin
          Move(@STFONT^,FontBuf^,4178);
          Move(FontBuf^.Font[(Xcur+Ycur shl 4) shr 4+1],UndoBuf,16);
          FontName:=Untitled;
          FontType:=16;
          MouseHide;
          ptFrameWindow(Windows.First)^.AfteOpenProc;
          FModified:=false;
          FExit:=false;
          MouseShow;
        end;
    end;
end;

Procedure ClearSym;                                            { ОЧИСТИТЬ }
var Num : byte;

begin
  Num:=Xcur+Ycur shl 4;
  Move(FontBuf^.Font[Num*FontType+1],UndoBuf,FontType);
  FillChar(FontBuf^.Font[Num*FontType+1],FontType,0);
  if Windows.Last=Windows.First then
    begin
      LoadFNT(FontName,false);
      MouseHide;
      DrawSymbol(Num);
      DrawBigSymbol(Num);
      MouseShow;
      LoadFNT('',false);
    end
  else
    DrawAfterClose:=true;
  Fmodified:=true;
end;

Procedure Up( P : pointer );                      { сдвигает символ вверх }
var _seg,_ofs : word;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  asm
    mov es,_seg
    mov si,_ofs
    mov al,es:[si]
    mov ch,0
    mov cl,FontType
    dec cl
    inc si

@@1:
    mov ah,es:[si]
    mov es:[si-1],ah
    inc si
    loop @@1
    dec si
    mov es:[si],al
  end;
end;

Procedure UpAll;                             { сдвигает все символы вверх }
var i : byte;

begin
  for i:=0 to 255 do
    Up(@(FontBuf^.Font[i*FontType+1]));
end;

Procedure Down( P : pointer );                     { сдвигает символ вниз }
var _seg,_ofs : word;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  asm
    mov es,_seg
    mov si,_ofs
    mov ch,0
    mov cl,FontType
    add si,cx
    dec si
    mov al,es:[si]
    dec cl
    dec si

@@1:
    mov ah,es:[si]
    mov es:[si+1],ah
    dec si
    loop @@1
    inc si
    mov es:[si],al
  end;
end;

Procedure DownAll;                            { сдвигает все символы вниз }
var i : byte;

begin
  for i:=0 to 255 do
    Down(@(FontBuf^.Font[i*FontType+1]));
end;

Procedure Left( P : pointer );                    { сдвигает символ влево }
var _seg,_ofs : word;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  asm
    mov ch,0
    mov cl,FontType
    mov es,_seg
    mov si,_ofs

@@1:
    mov al,es:[si]
    rol al,1
    mov es:[si],al
    inc si
    loop @@1
  end;
end;

Procedure LeftAll;                           { сдвигает все символы влево }
var _seg,_ofs,size : word;

begin
  _seg:=seg(FontBuf^.Font[1]);
  _ofs:=ofs(FontBuf^.Font[1]);
  Size:=FontType shl 8;
  asm
    mov cx,size
    mov es,_seg
    mov si,_ofs

@@1:
    mov al,es:[si]
    rol al,1
    mov es:[si],al
    inc si
    loop @@1
  end;
end;

Procedure Right( P : pointer );                  { сдвигает символ вправо }
var _seg,_ofs : word;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  asm
    mov ch,0
    mov cl,FontType
    mov es,_seg
    mov si,_ofs

@@1:
    mov al,es:[si]
    ror al,1
    mov es:[si],al
    inc si
    loop @@1
  end;
end;

Procedure RightAll;                         { сдвигает все символы вправо }
var _seg,_ofs,size : word;

begin
  _seg:=seg(FontBuf^.Font[1]);
  _ofs:=ofs(FontBuf^.Font[1]);
  Size:=FontType shl 8;
  asm
    mov cx,size
    mov es,_seg
    mov si,_ofs

@@1:
    mov al,es:[si]
    ror al,1
    mov es:[si],al
    inc si
    loop @@1
  end;
end;

Procedure Inverse( P : pointer );                    { инвертирует символ }
var _seg,_ofs : word;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  asm
    mov es,_seg
    mov si,_ofs
    mov ch,0
    mov cl,FontType

@@1:
    mov al,es:[si]
    not al
    mov es:[si],al
    inc si
    loop @@1
  end;
end;

Procedure InverseAll;                           { инвертирует все символы }
var _seg,_ofs,size : word;

begin
  _seg:=seg(FontBuf^.Font[1]);
  _ofs:=ofs(FontBuf^.Font[1]);
  size:=FontType shl 8;
  asm
    mov es,_seg
    mov si,_ofs
    mov cx,size

@@1:
    mov al,es:[si]
    not al
    mov es:[si],al
    inc si
    loop @@1
  end;
end;

Procedure Vert( P : pointer );         { поворочивает символ по вертикали }
var _seg,_ofs,
    _seg2,_ofs2 : word;
    _Buf : array[0..16] of byte;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  _seg2:=seg(_buf);
  _ofs2:=ofs(_buf);
  asm
    mov es,_seg
    mov si,_ofs
    mov ss,_seg2
    mov di,_ofs2
    mov ch,0
    mov cl,FontType
    add di,cx
    dec di

@@1:
    mov al,es:[si]
    mov ss:[di],al
    inc si
    dec di
    loop @@1
    mov ch,0
    mov cl,FontType
    mov es,_seg
    mov si,_ofs
    mov ss,_seg2
    mov di,_ofs2

@@2:
    mov al,ss:[di]
    mov es:[si],al
    inc si
    inc di
    loop @@2
  end;
end;

Procedure VertAll;                { поворочивает все символы по вертикали }
var i : byte;

begin
  for i:=0 to 255 do
    Vert(@(FontBuf^.Font[i*FontType+1]));
end;

Procedure Horiz( P : pointer );      { поворочивает символ по горизонтали }
var _seg,_ofs,
    _seg2,_ofs2 : word;
    _Buf : array[0..16] of byte;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  _seg2:=seg(_buf);
  _ofs2:=ofs(_buf);
  asm
    mov es,_seg
    mov si,_ofs
    mov ss,_seg2
    mov di,_ofs2
    mov ch,0
    mov cl,FontType

@@1:
    push cx
    mov cx,8

@@2:
    mov al,es:[si]
    shl al,1
    mov es:[si],al
    mov al,ss:[di]
    pushf
    shr al,1
    popf
    jnc @@3
    or al,128

@@3:
    mov ss:[di],al
    loop @@2
    inc si
    inc di
    pop cx
    loop @@1
    mov ch,0
    mov cl,FontType
    mov es,_seg
    mov si,_ofs
    mov ss,_seg2
    mov di,_ofs2

@@0:
    mov al,ss:[di]
    mov es:[si],al
    inc si
    inc di
    loop @@0
  end;
end;

Procedure HorizAll;             { поворочивает все символы по горизонтали }
var i : byte;

begin
  for i:=0 to 255 do
    Horiz(@(FontBuf^.Font[i*FontType+1]));
end;

Procedure Rotate( P : pointer );            { поворачивает символ на 90° }
var _seg,_ofs,
    _seg2,_ofs2 : word;
    _Buf : array[0..7] of byte;

begin
  _seg:=seg(p^);
  _ofs:=ofs(p^);
  _seg2:=seg(_buf);
  _ofs2:=ofs(_buf);
  asm
    mov es,_seg
    mov si,_ofs
    mov ss,_seg2
    mov di,_ofs2
    mov cx,8

@@1:
    push cx
    mov cx,8

@@2:
    mov al,es:[si]
    mov bx,cx
    pop cx
    push cx
    shr al,cl
    mov cx,bx
    mov al,ss:[di]
    pushf
    shr al,1
    popf
    jnc @@3
    or al,128

@@3:
    mov ss:[di],al
    inc si
    loop @@2
    mov si,_ofs
    inc di
    pop cx
    loop @@1
    mov cx,8
    mov es,_seg
    mov ss,_seg2
    mov di,_ofs2

@@0:
    mov al,ss:[di]
    mov es:[si],al
    inc si
    inc di
    loop @@0
  end;
end;

Procedure RotateAll;                    { поворачивает все символы на 90° }
var i : byte;

begin
  for i:=0 to 255 do
    Rotate(@(FontBuf^.Font[i*FontType+1]));
end;

Procedure Command( Com : tCom ); NEAR;                { обработчик команд }
var Num,
    i : byte;
    Commands : procedure( P : pointer );
    CommandsForAll : procedure;

begin
  case Com of
    sLeft    : begin
                 Commands:=Left;
                 CommandsForAll:=LeftAll;
               end;
    sRight   : begin
                 Commands:=Right;
                 CommandsForAll:=RightAll;
               end;
    sUp      : begin
                 Commands:=Up;
                 CommandsForAll:=UpAll;
               end;
    sDown    : begin
                 Commands:=Down;
                 CommandsForAll:=DownAll;
               end;
    cInverse : begin
                 Commands:=Inverse;
                 CommandsForAll:=InverseAll;
               end;
    cVert    : begin
                 Commands:=Vert;
                 CommandsForAll:=VertAll;
               end;
    cHoriz   : begin
                 Commands:=Horiz;
                 CommandsForAll:=HorizAll;
               end;
    cRotate  : begin
                 if FontType<>8 then Exit;
                 Commands:=Rotate;
                 CommandsForAll:=RotateAll;
               end;
  end;
  if FSymbolOnly then
    begin
      Num:=XCur+YCur shl 4;
      Move(FontBuf^.Font[Num*FontType+1],UndoBuf,FontType);
      Commands(@(FontBuf^.Font[Num*FontType+1]));
      if Windows.Last=Windows.First then
        begin
          MouseHide;
          LoadFNT(FontName,false);
          DrawSymbol(Num);
          DrawBigSymbol(Num);
          MouseShow;
          LoadFNT('',false);
        end
      else
        DrawAfterClose:=true;
    end
  else
    begin
      CommandsForAll;
      if Windows.Last=Windows.First then
        begin
          MouseHide;
          DrawSymbolTable;
          DrawBigSymbol(XCur+YCur shl 4);
          MouseShow;
        end
      else
        DrawAfterClose:=true;
    end;
  FModified:=true;
end;

Procedure ScrollLeft;                                    { СДВИНУТЬ ВЛЕВО }
begin
  Command(sLeft);
end;

Procedure ScrollRight;                                  { СДВИНУТЬ ВПРАВО }
begin
  Command(sRight);
end;

Procedure ScrollUp;                                      { СДВИНУТЬ ВВЕРХ }
begin
  Command(sUp);
end;

Procedure ScrollDown;                                     { СДВИНУТЬ ВНИЗ }
begin
  Command(sDown);
end;

Procedure InverseSym;                                     { ИНВЕРТИРОВАТЬ }
begin
  Command(cInverse);
end;

Procedure VertSym;                                      { ПОВЕРНУТЬ ВЕРТ. }
begin
  Command(cVert);
end;

Procedure HorizSym;                                    { ПОВЕРНУТЬ ГОРИЗ. }
begin
  Command(cHoriz);
end;

Procedure RotateSym;                                   { ПОВЕРНУТЬ НА 90° }
begin
  Command(cRotate);
end;

Procedure ChangeTarget; FORWARD;                            { КОМАНДЫ ДЛЯ }

Procedure HelpProc;                                         { О РЕДАКТОРЕ }
begin
  Topic:=hcF_Editor;
  Help
end;

Procedure About;                    { процедура после открытия окна ABOUT }
begin
  PutImage(109,150,@PCXName^,COPYPut);
  WriteStrXY2(188,185,cNormText,CopyPut,'Copyright № 1996 Лядвинский Кирилл');
  WriteStrXY2(164,199,cNormText,CopyPut,'Не для продажи. http://www.codeatcpp.com');
  SetColor(cNormText);
  Line(180,220,468,220);
end;

{$F-}

Function WasModified: tAnswer;    { проверяет был ли изменен шрифт и если }
                                  { изменен, спрашивает 'СОХРАНИТЬ ?'     }
begin
  Answer:=No;
  if FModified then
    begin
      Buf:='Файл '+FontName+' был изменен. Сохранить ?';
      Quest;
      if Answer=Yes then
        if FontName=Untitled then SaveAs
        else SaveFont;
    end;
  WasModified:=Answer;
end;

const
  FileWindKeys:array[1..7] of TKeys =
  ((KeyType:Simple;
    X:6;
    Y:6;
    DX:177;
    DY:16;
    PushProc: StandFont;
    PushWind: nil;
    Name:'С&тандартный';
    Ext:'';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scN;
    HelpCtx : hcNew;
    CanActive : true;
    Centered:false;
    Color: Blue),
   (KeyType:Simple;
    X:6;
    Y:23;
    DX:177;
    DY:16;
    PushProc: OpenFont;
    PushWind: nil;
    Name:'&Открыть...';
    Ext:'F3';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scJ;
    HelpCtx : hcOpen;
    CanActive : true;
    Centered:false;
    Color: Blue),
   (KeyType:Simple;
    X:6;
    Y:40;
    DX:177;
    DY:16;
    PushProc: Save;
    PushWind: nil;
    Name:'&Сохранить';
    Ext:'F2';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scC;
    HelpCtx : hcSave;
    CanActive : true;
    Centered:false;
    Color: Blue),
   (KeyType:Simple;
    X:6;
    Y:57;
    DX:177;
    DY:16;
    PushProc: SaveAs;
    PushWind: nil;
    Name:'Сохранить &как...';
    Ext:'';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scR;
    HelpCtx : hcSaveAs;
    CanActive : true;
    Centered:false;
    Color : Blue),
   (KeyType:Simple;
    X:6;
    Y:74;
    DX:177;
    DY:16;
    PushProc: nul;
    PushWind: nil;
    Name:'─────────────────────';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scNoKey;
    HelpCtx : hcNoContext;
    CanActive : false;
    Centered:true;
    Color : LightGray),
   (KeyType:Simple;
    X:6;
    Y:91;
    DX:177;
    DY:16;
    PushProc: ExitEd;
    PushWind: nil;
    Name:'В&ыход';
    Ext:'Alt+X';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scS;
    HelpCtx : hcExit;
    CanActive : true;
    Centered:false;
    Color: Blue),

      { иконка помощи }

   (KeyType:Standart;
    X:500;
    Y:23;
    DX:25;
    DY:25;
    PushProc: Help;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXHelp;
    HotKey:scF1;
    HelpCtx : hcHelp));

  { ОКНО ФАЙЛ }

  FileWindow:TWindows=(
    WindType:WStandart;
    x:10;
    y:10;
    dx:190;
    dy:114;
    HelpCtx : hcFile;
    BefOpenPr: nul;
    OpenProc: nul;
    ContProc: nul;
    Shadow:false;
    Keys:@FileWindKeys;
    NumKeys:7);

  EditWindKeys:array[1..5] of TKeys =
  ((KeyType:Simple;
    X:6;
    Y:6;
    DX:207;
    DY:16;
    PushProc: UndoSym;
    PushWind: nil;
    Name:'&Восстановить';
    Ext:'Alt+BkSp';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scD;
    HelpCtx : hcUndo;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:23;
    DX:207;
    DY:16;
    PushProc: nul;
    PushWind: nil;
    Name:'─────────────────────────';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scNoKey;
    HelpCtx : hcNoContext;
    CanActive : false;
    Centered:true;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:40;
    DX:207;
    DY:16;
    PushProc: CopySym;
    PushWind: nil;
    Name:'&Копировать';
    Ext:'Ctrl+Ins';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scR;
    HelpCtx : hcCopy;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:57;
    DX:207;
    DY:16;
    PushProc: PasteSym;
    PushWind: nil;
    Name:'В&ставить';
    Ext:'Shift+Ins';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scC;
    HelpCtx : hcPaste;
    CanActive : true;
    Centered:false;
    Color:Blue),

      { иконка помощи }

   (KeyType:Standart;
    X:263;
    Y:23;
    DX:25;
    DY:25;
    PushProc: Help;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXHelp;
    HotKey:scF1;
    HelpCtx : hcHelp));

  { ОКНО РЕДАКТОР }

  EditWindow:TWindows=(
    WindType:WStandart;
    x:247;
    y:10;
    dx:220;
    dy:80;
    HelpCtx : hcEdit;
    BefOpenPr: nul;
    OpenProc: nul;
    ContProc: nul;
    Shadow:false;
    Keys:@EditWindKeys;
    NumKeys:5);

  AboutWindKey:array[1..1] of TKeys =
  ((KeyType:Standart;
    X:200;
    Y:95;
    DX:100;
    DY:20;
    PushProc: nul;
    PushWind: nil;
    Name:'Ok';
    Ext:'';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scEnter;
    HelpCtx : hcClose;
    CanActive : true;
    Centered: true;
    Color:cNormText));

  AboutWindow:TWindows=(
    WindType:WStandart;
    x:70;
    y:140;
    dx:500;
    dy:130;
    HelpCtx : hcAbout;
    BefOpenPr: nul;
    OpenProc: About;
    ContProc: nul;
    Shadow: false;
    Keys:@AboutWindKey;
    NumKeys:1);

  HlpWindKeys:array[1..4] of TKeys =
  ((KeyType:Simple;
    X:6;
    Y:6;
    DX:137;
    DY:16;
    PushProc: HelpProc;
    PushWind: nil;
    Name:'&О редакторе';
    Ext:'F1';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scJ;
    HelpCtx : hcF_Editor;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:23;
    DX:137;
    DY:16;
    PushProc: nul;
    PushWind: nil;
    Name:'────────────────';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scNoKey;
    HelpCtx : hcNoContext;
    CanActive : false;
    Centered:true;
    Color: Blue),
   (KeyType:Simple;
    X:6;
    Y:40;
    DX:137;
    DY:16;
    PushProc: nul;
    PushWind: @AboutWindow;
    Name:'Об &авторе';
    Ext:'';
    CloseAfPr: true;
    BitMap:nil;
    HotKey:scF;
    HelpCtx : hcAbout;
    CanActive : true;
    Centered:false;
    Color: Blue),

      { иконка помощи }

   (KeyType:Standart;
    X:161;
    Y:23;
    DX:25;
    DY:25;
    PushProc: Help;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXHelp;
    HotKey:scF1;
    HelpCtx : hcHelp));


  { ОКНО СПРАВКА РЕДАКТОРА }

  HelpWindow:TWindows=(
    WindType:WStandart;
    x:349;
    y:10;
    dx:150;
    dy:65;
    HelpCtx : hcHelp;
    BefOpenPr: nul;
    OpenProc: nul;
    ContProc: nul;
    Shadow:false;
    Keys: @HlpWindKeys;
    NumKeys:4);

  ModWindKeys:array[1..14] of TKeys =
  ((KeyType:Simple;
    X:6;
    Y:6;
    DX:217;
    DY:16;
    PushProc: ClearSym;
    PushWind: nil;
    Name:'&Очистить';
    Ext:'Ctrl+Del';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scJ;
    HelpCtx : hcClear;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:23;
    DX:217;
    DY:16;
    PushProc: InverseSym;
    PushWind: nil;
    Name:'&Инвертировать';
    Ext:'Ctrl+Tab';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scB;
    HelpCtx : hcInverse;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:40;
    DX:217;
    DY:16;
    PushProc: nul;
    PushWind: nil;
    Name:'─────────────────────────';
    Ext:'';
    CloseAfPr: false;
    BitMap:nil;
    HotKey:scNoKey;
    HelpCtx : hcNoContext;
    CanActive : false;
    Centered:true;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:57;
    DX:217;
    DY:16;
    PushProc: ScrollLeft;
    PushWind: nil;
    Name:'&Сдвинуть влево';
    Ext:'Ctrl+Left';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scC;
    HelpCtx : hcLeftSc;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:74;
    DX:217;
    DY:16;
    PushProc: ScrollRight;
    PushWind: nil;
    Name:'С&двинуть вправо';
    Ext:'Ctrl+Right';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scL;
    HelpCtx : hcRightSc;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:91;
    DX:217;
    DY:16;
    PushProc: ScrollUp;
    PushWind: nil;
    Name:'Сд&винуть вверх';
    Ext:'Ctrl+Up';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scD;
    HelpCtx : hcRightSc;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:108;
    DX:217;
    DY:16;
    PushProc: ScrollDown;
    PushWind: nil;
    Name:'Сдви&нуть вниз';
    Ext:'Ctrl+Down';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scY;
    HelpCtx : hcDownSc;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:125;
    DX:217;
    DY:16;
    PushProc: nul;
    PushWind: nil;
    Name:'─────────────────────────';
    Ext:'';
    CloseAfPr: false;
    BitMap:nil;
    HotKey:scNoKey;
    HelpCtx : hcNoContext;
    CanActive : false;
    Centered:true;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:142;
    DX:217;
    DY:16;
    PushProc: RotateSym;
    PushWind: nil;
    Name:'&Повернуть на 90°';
    Ext:'Ctrl+П';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scG;
    HelpCtx : hcRotate;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:159;
    DX:217;
    DY:16;
    PushProc: VertSym;
    PushWind: nil;
    Name:'Пов&ернуть верт.';
    Ext:'Ctrl+В';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scT;
    HelpCtx : hcVert;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:176;
    DX:217;
    DY:16;
    PushProc: HorizSym;
    PushWind: nil;
    Name:'Поверну&ть гориз.';
    Ext:'Ctrl+Г';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scN;
    HelpCtx : hcHoriz;
    CanActive : true;
    Centered:false;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:193;
    DX:217;
    DY:16;
    PushProc: nul;
    PushWind: nil;
    Name:'─────────────────────────';
    Ext:'';
    CloseAfPr: false;
    BitMap:nil;
    HotKey:scNoKey;
    HelpCtx : hcNoContext;
    CanActive : false;
    Centered:true;
    Color:Blue),
   (KeyType:Simple;
    X:6;
    Y:210;
    DX:217;
    DY:16;
    PushProc: ChangeTarget;
    PushWind: nil;
    Name:'&Команды для';
    Ext:'cимвола';
    CloseAfPr:true;
    BitMap:nil;
    HotKey:scR;
    HelpCtx : hcTarget;
    CanActive : true;
    Centered:false;
    Color:Blue),

      { иконка помощи }

   (KeyType:Standart;
    X:430;
    Y:23;
    DX:25;
    DY:25;
    PushProc: Help;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXHelp;
    HotKey:scF1;
    HelpCtx : hcHelp));


  { ОКНО ПРЕОБРАЗОВАНИЯ }

  ModifWindow:TWindows=(
    WindType:WStandart;
    x:80;
    y:10;
    dx:230;
    dy:235;
    HelpCtx : hcModif;
    BefOpenPr: nul;
    OpenProc: nul;
    ContProc: nul;
    Shadow:false;
    Keys: @ModWindKeys;
    NumKeys:14);

  KeyMainWind:array[1..21] of TKeys =

  { МЕНЮ  }

  ((KeyType:Standart;
    X:7;
    Y:7;
    DX:70;
    DY:20;
    PushProc: nul;
    PushWind: @FileWindow;
    Name:'&Файл';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scA+scWAlt;
    HelpCtx: hcFile),
   (KeyType:Standart;
    X:79;
    Y:7;
    DX:150;
    DY:20;
    PushProc: nul;
    PushWind: @ModifWindow;
    Name:'&Преобразования';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scG+scWAlt;
    HelpCtx: hcModif),
   (KeyType:Standart;
    X:231;
    Y:7;
    DX:100;
    DY:20;
    PushProc: nul;
    PushWind:@EditWindow;
    Name:'Р&едактор';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scT+scWAlt;
    HelpCtx: hcEdit),
   (KeyType:Standart;
    X:333;
    Y:7;
    DX:100;
    DY:20;
    PushProc: nul;
    PushWind: @HelpWindow;
    Name:'&Справка';
    Ext:'';
    CloseAfPr: false;
    BitMap:nil;
    HotKey:scC+scWAlt;
    HelpCtx: hcHelp),

    { иконка открытия файла }

   (KeyType:Standart;
    X:10;
    Y:33;
    DX:25;
    DY:25;
    PushProc: OpenFont;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXOpen;
    HotKey:scF3;
    HelpCtx:hcOpen),

   { иконка сохранения файла }


   (KeyType:Standart;
    X:40;
    Y:33;
    DX:25;
    DY:25;
    PushProc: Save;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXSave;
    HotKey:scF2;
    HelpCtx : hcSave),

    { иконка создания шрифта }

   (KeyType:Standart;
    X:80;
    Y:33;
    DX:25;
    DY:25;
    PushProc: StandFont;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXNew;
    HotKey:scNoKey;
    HelpCtx : hcNew),

    { иконка восстановления символа }

   (KeyType:Standart;
    X:120;
    Y:33;
    DX:25;
    DY:25;
    PushProc: UndoSym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXUndo;
    HotKey:scWAlt+scBackSpace;
    HelpCtx : hcUndo),

    { иконка копирования символа }

   (KeyType:Standart;
    X:150;
    Y:33;
    DX:25;
    DY:25;
    PushProc: CopySym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXCopy;
    HotKey:scIns+scWCtrl;
    HelpCtx : hcCopy),

     { иконка размещения символа }

   (KeyType:Standart;
    X:180;
    Y:33;
    DX:25;
    DY:25;
    PushProc: PasteSym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXPaste;
    HotKey:scIns+scWShift;
    HelpCtx : hcPaste),

    { иконка стирания символа(ов) }

   (KeyType:Standart;
    X:220;
    Y:33;
    DX:25;
    DY:25;
    PushProc: ClearSym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXClear;
    HotKey:scDel+scWCtrl;
    HelpCtx : hcClear),

    { иконка сдвигания символа(ов) влево }

   (KeyType:Standart;
    X:250;
    Y:33;
    DX:25;
    DY:25;
    PushProc: ScrollLeft;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXLeft;
    HotKey:scLeft+scWCtrl;
    HelpCtx : hcLeftSc),

    { иконка сдвигания символа(ов) вниз }

   (KeyType:Standart;
    X:280;
    Y:33;
    DX:25;
    DY:25;
    PushProc: ScrollDown;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXDown;
    HotKey:scDown+scWCtrl;
    HelpCtx : hcDownSc),

    { иконка сдвигания символа(ов) вверх }

   (KeyType:Standart;
    X:310;
    Y:33;
    DX:25;
    DY:25;
    PushProc: ScrollUp;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXUp;
    HotKey: scUp+scWCtrl;
    HelpCtx : hcUpSc),

    { иконка сдвигания символа(ов) вправо }

   (KeyType:Standart;
    X:340;
    Y:33;
    DX:25;
    DY:25;
    PushProc: ScrollRight;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXRight;
    HotKey:scRight+scWCtrl;
    HelpCtx : hcRightSc),

    { иконка инвертирования символа(ов) }

   (KeyType:Standart;
    X:370;
    Y:33;
    DX:25;
    DY:25;
    PushProc: InverseSym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXInverse;
    HotKey:scTab+scWCtrl;
    HelpCtx : hcInverse),

    { иконка поворачивания символа(ов) по вертикали }

   (KeyType:Standart;
    X:400;
    Y:33;
    DX:25;
    DY:25;
    PushProc: VertSym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXFlipVer;
    HotKey:scD+scWCtrl;
    HelpCtx : hcVert),

    { иконка поворачивания символа(ов) по горизонтали }

   (KeyType:Standart;
    X:430;
    Y:33;
    DX:25;
    DY:25;
    PushProc: HorizSym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXFlipHor;
    HotKey:scU+scWCtrl;
    HelpCtx : hcHoriz),

    { иконка поворачивания символа(ов) на 90° }

   (KeyType:Standart;
    X:460;
    Y:33;
    DX:25;
    DY:25;
    PushProc: RotateSym;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXRotate;
    HotKey:scG+scWCtrl;
    HelpCtx : hcRotate),

    { иконка помощи }

   (KeyType:Standart;
    X:510;
    Y:33;
    DX:25;
    DY:25;
    PushProc: Help;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap: @PCXHelp;
    HotKey:scF1;
    HelpCtx : hcHelp),

   (KeyType:Simple;
    X:0;
    Y:0;
    DX:0;
    DY:0;
    PushProc: ExitEd;
    PushWind: nil;
    Name:'';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scX+scWAlt));

  { ОСНОВНОЕ ОКНО }

  MainWindow:TWindows=(
    WindType:WStandart;
    x:0;
    y:0;
    dx:639;
    dy:65;
    HelpCtx : hcF_EDITOR;
    BefOpenPr: nul;
    OpenProc: MainProc;
    ContProc: HandleEvent;
    Shadow:false;
    Keys:@KeyMainWind;
    NumKeys:21);

var
  OldHeapPtr : pointer;
  F : text;
  MaxPages : byte;                { количество страниц помощи данной темы }
  Page: byte;                     { текущая страница помощи               }
  HelpCtx : byte;                 { тема помощи                           }

Procedure ChangeTarget;                                     { КОМАНДЫ ДЛЯ }
begin
  if FSymbolOnly then
    begin
      FSymbolOnly:=false;
      ModWindKeys[13].Ext:='шрифта';
    end
  else
    begin
      FSymbolOnly:=true;
      ModWindKeys[13].Ext:='символа';
    end;
end;

Function FindTopic : boolean;                         { найти тему помощи }
var Line : string[60];
    E : integer;

begin
  Reset(F);
  FindTopic:=false;
  while not EOf(F) do
    begin
      ReadLn(F,Line);
      if copy(Line,1,7)=' .topic' then
        begin
          name:=copy(line,9,3);
          val(name,Topic,E);
          if Topic=HelpCtx then
            begin
              FindTopic:=true;
              Break
            end;
        end;
    end;
end;

Procedure ShowPage( Page : byte );             { показать страницу помощи }
var _str : string[60];
    i,k : byte;

begin
  FindTopic;
  for i:=1 to Page do
    for k:=1 to 19 do
      begin
        ReadLn(F,_str);
        if copy(_str,1,7)=' .topic' then
          Exit;
      end;
  SetFillStyle(SolidFill,LightGray);
  Bar(100,58,578,359);
  for i:=0 to 18 do
    begin
      ReadLn(F,_str);
      if copy(_str,1,7)<>' .topic' then
        WriteStrXY2(100,57+i shl 4,cNormText,CopyWrite,_str)
      else Break;
    end;
end;

Procedure PageUp; FAR;                                { на страницу вверх }
begin
  if Page>0 then
    begin
      Page:=Page-1;
      MouseHide;
      ShowPage(Page);
      MouseShow;
    end;
end;

Procedure PageDown; FAR;                               { на страницу вниз }
begin
  if Page<MaxPages-1 then
    begin
      Page:=Page+1;
      MouseHide;
      ShowPage(Page);
      MouseShow;
    end;
end;

Procedure DrawWind; FAR;           { процедура после открытия окна помощи }
var i : byte;
    _str : string[60];
    hEnd : boolean;

begin
  Page:=0;
  PutImage(50,60,@PCXQuest^,COPYPut);
  DoubleFrame(90,56,491,305,cNewColor1,cNewColor2);
  MaxPages:=0;
  FindTopic;
  repeat
    for i:=0 to 18 do
      begin
        ReadLn(F,_str);
        if (copy(_str,1,7)=' .topic') or Eof(F) then Break;
      end;
    MaxPages:=MaxPages+1;
  until (copy(_str,1,7)=' .topic') or Eof(F);
  ShowPage(Page);
end;

Procedure Help;                 { процедура выдачи справки по данной теме }
var E : integer;
    Name : string[79];

const
  HelpKeys:array[1..3] of TKeys =
  ((KeyType:Standart;
    X:467;
    Y:321;
    DX:70;
    DY:20;
    PushProc: nul;
    PushWind: nil;
    Name:'Закрыть';
    Ext:'';
    CloseAfPr: true;
    BitMap:nil;
    HotKey:scEnter;
    HelpCtx: hcClose;
    CanActive : true;
    Centered : true;
    Color : cNormText),
   (KeyType:Standart;
    X:307;
    Y:321;
    DX:70;
    DY:20;
    PushProc: PageUp;
    PushWind: nil;
    Name:'Вверх';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scPgUp;
    HelpCtx: hcUp;
    CanActive : true;
    Centered : true;
    Color : cNormText),
   (KeyType:Standart;
    X:387;
    Y:321;
    DX:70;
    DY:20;
    PushProc: PageDown;
    PushWind: nil;
    Name:'Вниз';
    Ext:'';
    CloseAfPr:false;
    BitMap:nil;
    HotKey:scPgDn;
    HelpCtx: hcDown;
    CanActive : true;
    Centered : true;
    Color : cNormText));

  HelpWindow:TWindows=(
    WindType:WStandart;
    x:40;
    y:45;
    dx:555;
    dy:356;
    HelpCtx : hcNoContext;
    BefOpenPr: nul;
    OpenProc: DrawWind;
    ContProc: nul;
    Shadow: false;
    Keys:@HelpKeys;
    NumKeys:3);

begin
  if Topic<>0 then
    HelpCtx:=Topic
  else
    HelpCtx:=ptSimpleWindow(Windows.Last)^.HelpCtx;
  if HelpCtx<>hcNoContext then
    begin
      FSplit(ParamStr(0),Dir,Name,Ext);
      Name:=Dir+'F_STUDIO.HLP';
      {$IFDEF Debug}
      Assign(F,'F_STUDIO.HLP');
      {$ELSE}
      Assign(F,Name);
      {$ENDIF}
      Reset(F);
      E:=IOResult;
      if E<>0 then
        begin
          Error(103);
          Exit;
        end;
      if FindTopic then
        begin
          MouseType:=false;
          SetNewGCursor(1,1,@Arrow2);
          MakeWindow(@HelpWindow);
        end
      else Error(103);
      Close(F);
    end;
  Topic:=0;
end;

        { ОСНОВНАЯ ПРОЦЕДУРА }

BEGIN
  {$IFDEF Debug}
  OldHeapPtr:=HeapPtr;
  {$ENDIF}
  if ParamCount<>0 then
    begin
      FontName:=ParamStr(1);
      FSplit(FontName,Dir,Name,Ext);
      if Ext='' then FontName:=FontName+'.FNT';
    end;
  AInitGraph;
  SetRGBPalette(EGABlue,5,15,25);
  SetRGBPalette(EGABrown,55,55,55);
  SetRGBPalette(EGALightMagenta,25,25,25);
  SetFillStyle(solidfill,Blue);
  Bar(0,0,639,479);
  InitMouse;
  SetNewGCursor(1,1,@Arrow2);
  if MouseError<>0 then
    begin
      CloseGraph;
      Beep;
      WriteLn('F_STUDIO : Драйвер мыши не установлен.');
      Halt;
    end;
{  KeyIntInit;}
  MouseShow;
  InitBuf;
  InitFont(nil,'');
  LoadFNT(FontName,false);
  if FontName='' then
    begin
      Move(@STFONT^,FontBuf^,4178);
      FontName:=Untitled;
    end;
  if FontError<>0 then
    begin
      Error(FontError);
      FontName:=Untitled;
      Move(@STFONT^,FontBuf^,4178);
    end;
  FontType:=FontHeight;
  LoadFNT('',false);
  Windows.Init;
  if ParamCount=0 then
    MakeWindow(@AboutWindow);
  MakeWindow(@MainWindow);
  Windows.Done;
  CloseGraph;
  DoneBuf;
  ClearBuf;
{  KeyIntDone;  }
  {$IFDEF Debug}
  WriteLn(seg(OldHeapPtr^),':',ofs(OldHeapPtr^));
  WriteLn(seg(HeapPtr^),':',ofs(HeapPtr^));
  if OldHeapPtr<>HeapPtr then
    begin
      Beep;
      RunError;
    end;
  {$ENDIF}
  {$IFNDEF Debug}
  TextColor(LightCyan);
  WriteLn(#13#10+
          '      РЕДАКТОР МАТРИЧНЫХ ШРИФТОВ      '+#13#10+
          '              Версия  1.1             '+#13#10+
          ' Copyright (c) 1996 Лядвинский Кирилл '+#13#10+
          '       http://www.codeatcpp.com       ');
  {$ENDIF}
END.

