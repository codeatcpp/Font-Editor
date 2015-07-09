{$R-,S-,I-,V-}
{$X+}
{**********************************************************}
{ unit PcxPic - инструменты для работы с графическими      }
{               образами в формате  PC PaintBrush          }
{ Cohyright (c) 1991, А.Тихонов                            }
{**********************************************************}
unit PcxPic;

Interface
   uses Dos, Graph;
   Function ShowPcxFromFile(x, y, dx, dy,
                            Gd :integer;
                            SetPalette:Boolean; PutMode:Word;
                            Name:String):integer;
   Function ShowPcxFromMemory(x,y,dx,dy,Gd :integer;
                              SetPalette:Boolean; PutMode:Word;
                              P: Pointer):integer;

Implementation

   Const
      PcxBufSize = 4096;
   Type
     FromMode  = (FromMemory,FromFile);
     Mem       = array[0..0] of Byte;
     PMem      = ^Mem;
     GetPicByte = Function:Byte;
   var
     F:    File;
     ReadMemoryByte,ReadByte:GetPicByte;

     Count    :word;{ Счетчик }
     W        :Byte;
     Ps       :Word;
     EndFile  :Boolean;{ Флажок конца файла }
     BufSize  :word; { Размер буфера для графического образа }
     PcxBuf   :array[1..PcxBufSize] of Byte; { Буфер }
     Pm       :PMem;

  Type
     PcxPalette  = array[0..15,0..2] of Byte; {Формат палитры PC PaintBrush}
     {Заголовок PCX-файла}
     PcxHeader = Record  {Заголовок PCX-файла}
       Creator   :   Byte; {ZSoft =10}
       Version   :   Byte; {Версия PCX:
                             0 - версия 2.5 без палитры;
                             2 - версия 2.8 с палитрой;
                             3 - версия 2.8/3.0 без палитры;
                             5 - версия 3.0 с палитрой.
                           }
        Encoding :   Byte; {1 - тип сжатия RLE}
        Bits     :   Byte; { Число битов на пиксел }
        Xmin,
        Ymin,
        Xmax,
        Ymax     :   integer;{ Размеры картинки }
        Hres,
        Vres     :   integer;{ Разрешение }
        Palette  :   PcxPalette; {Палитра}
        Vmode    :   Byte; { Резерв}
        Planes   :   Byte; { Число цветовых плоскостей}
        BytesPerLine: Word; { Число байтов на строку}
        PaletteInfo: Word; { Информация о палитре:
                               1 - цветная / черно-белая;
                               2 - градации серого;
                            }
        shres,
        svres     :    Word; { Разрешение сканера}
        xtra     : array[0..53] of Byte;{ Резервировано }
     end;

     Procedure SetPcxPalette(Screen:Integer;Pal:PcxPalette);{Установка
                       палитры из заголовка Pcx - образа  }
        var
          P:PaletteType;
          i,j,BkCol,CgaPal:integer;
          c:real;
          B,BB:shortint;

        begin
          GetDefaultPalette(P);{ текущая палитра }
          case Screen of
           0: begin   { EGA, VGA, 16 цветов}
                for i:=0 to P.Size-1 do begin
                  B:=0;
                  for j:=0 to 2 do begin
                    c:=Pal[i,j];
                    BB:=trunc(c/255.0*3.0);
                    case j of
                     0: begin { Перекодировка красного цвета в формат rgbRGB}
                          if (BB and 1)>0 then B:=B or $20;
                          if (BB and 2)>0 then B:=B or $04;
                     end;
                     1: begin { Перекодировка зеленого цвета в формат rgbRGB}
                          if (BB and 1)>0 then B:=B or $10;
                          if (BB and 2)>0 then B:=B or $02;
                     end;
                     2: begin { Перекодировка синего цвета в формат rgbRGB}
                          if (BB and 1)>0 then B:=B or $08;
                          if (BB and 2)>0 then B:=B or $01;
                        end;
                    end;{case}
                  end; {j}
                  P.Colors[i]:=B;
                end;{i}
                SetallPalette(P);
           end;{0}
           2: begin { CGA, 4 цвета }
              BkCol :=(Pal[0,0] div $10) mod 8;
              CgaPal:=(Pal[1,0] div $20) mod 4;
              SetBkColor(BkCol);
              SetGraphMode(CgaPal);
           end;
           else;
          end;{case Screen}
        end;

 {Вспомогательные функции}

  Function OpenFileRead( Name:String):integer;
    var
       i:word;
    begin
     {$I-}
        Assign(F,Name);
        i:=Ioresult;
        if i=0 then begin
           Reset(F,1);
           OpenFileRead:=IoResult;
        end
        else OpenFileRead:=i;
     {$I+}
    end;

    Function GetPcxHeader(var Header:PcxHeader):integer;
                {Чтение заголовок PCX файла}
      var
         s,size:word;
         i:integer;
      begin
         Size:=SizeOf(Header);
         blockread(F,Header,Size,s);
         i:=IoResult;
         if i=0 then
             if (s=Size) then begin
                if ((Header.version>5)
                    or (Header.version<1)
                    or (Header.Creator<>10)) then GetPcxHeader:=-1
                else GetPcxHeader:=0;
             end
             else GetPcxHeader:=Size
         else GetPcxHeader:=i;
      end;

   Function ReadPcxByte:Byte; Far;
      var
        tmp:Byte;

      procedure readBlock;
         var
            Result:word;
         begin
           if eof(F) then EndFile:=True
           else begin
              BufSize:=SizeOf(PcxBuf);
              blockread(F,PcxBuf,BufSize,Result);
              if result<BufSize then BufSize:=Result;
              Ps:=1;
           end;
         end;

       function GetByte:Byte;
          begin
             if EndFile then GetByte:=0
             else begin
                if Ps = PcxBufSize then ReadBlock
                else Inc(Ps);
                GetByte:=PcxBuf[Ps];
             end;
          end;

   begin
      if count>0 then begin
         Dec(count);
         ReadPcxByte:=w;
         Exit;
      end;
      tmp:=GetByte;
      if ((tmp and $C0) = $C0) then begin {счетчик повторений}
         count:= tmp and $3F - 1;
         w:=GetByte;
      end
      else begin
         count:=0;
         w:=tmp;
      end;
      ReadPcxByte := w;
   end;


   Function ReadNonCompressedByte:Byte; Far;

      procedure readBlock;
         var
            Result:word;
         begin
           if eof(F) then EndFile:=True
           else begin
              BufSize:=SizeOf(PcxBuf);
              blockread(F,PcxBuf,BufSize,Result);
              if result<BufSize then BufSize:=Result;
              Ps:=1;
           end;
         end;

       function GetByte:Byte;
          begin
             if EndFile then GetByte:=0
             else begin
                if Ps = PcxBufSize then ReadBlock
                else Inc(Ps);
                GetByte:=PcxBuf[Ps];
             end;
          end;

   begin
      ReadNoncompressedByte:=GetByte;
   end;

   Function GetByteFromMemory:Byte; Far;
      var
        tmp:Byte;

       function GetByte:Byte;
          begin
            GetByte:=Pm^[Ps];
            Inc(Ps);
           end;

   begin
      if count>0 then begin
         Dec(count);
         GetByteFromMemory:=w;
         Exit;
      end;
      tmp:=GetByte;
      if ((tmp and $C0) = $C0) then begin {счетчик повторений}
         count:= tmp and $3F - 1;
         w:=GetByte;
      end
      else begin
         count:=0;
         w:=tmp;
      end;
      GetByteFromMemory := w;
   end;

   Function GetNonComPressedByteFromMemory:Byte; Far;
   begin
     GetNonComPressedByteFromMemory:=Pm^[Ps];
     Inc(Ps);
   end;

  Procedure ShowPic(Mode:FromMode;EnCoding,
                     x,y,dx,dy,
                     Gd:integer;
                     SetPalette:Boolean; PutMode:Word;
                     var Header:PcxHeader );
    Type
      ImageMem = record { Участок графического экрана }
         x,y:integer;  {Размеры по горизонтали и вертикали в пикселах}
         mem: array[0..0] of Byte;
      end;
      PImageMem =^ImageMem;

    var
      MyPixelsPerLine,Divisor,MyBytesPerLine,BytesPerLine,ImgSize,PixelsPerLine,JJ:Word;
      i,j,L:integer;
      P:pointer;
      PI:PImageMem;
      Screen:integer;
      endy : integer;
      endx : integer;
      skip : word;
      begin
         case Gd of   { Установка признака палитры}
            EGA,VGA : Screen:=0;
            HercMono: Screen:=1;
            CGA     : Screen:=2;
            else      Screen:= -Gd;
         end;
        if (SetPalette and
            (Header.Version in [2,5])) then  { Установка палитры}
              SetPcxPalette(Screen,Header.Palette);
        If Encoding = 1 then begin
           ReadByte:=ReadPcxByte;
           ReadMemoryByte:=GetByteFromMemory;
        end
        else begin
           ReadByte:=ReadNonComPressedByte;
           ReadMemoryByte:=GetNonCompressedByteFromMemory;
        end;
        Divisor := 8 div Header.Bits;
        PixelsPerLine:= Header.Xmax - Header.Xmin +1;
        BytesPerLine:=PixelsPerLine div Divisor;
        if (PixelsPerLine mod Divisor)<>0 then Inc(BytesPerLine);
        if (y+Header.Ymax - Header.Ymin) >
               (GetMaxY) then
                   endy := GetMaxY
               else
                  endy :=  y+Header.Ymax - Header.Ymin;
        if (x+Header.Xmax-Header.Xmin) > (GetMaxX) then
           endx := GetMaxX else endx := x+Header.Xmax-Header.Xmin;
        if (endx-x) > dx then endx := x+dx;
        if (endy-y) > dy then endy := y+dy;
{        ImgSize:=ImageSize(Header.Xmin,0,Header.Xmax,0);}
        ImgSize:=ImageSize(x,0,endx,0);

        GetMem(PI,ImgSize); { выделяю память под строку изображения}
        { Создание строки образа в формате BGI }
       MyPixelsPerLine := endx-x+1;
        PI^.x:= MyPixelsPerLine-1;
        PI^.y:=0;
       MyBytesPerLine := MyPixelsPerLine div Divisor;
       if (MyPixelsPerLine mod Divisor)<>0 then Inc(MyBytesPerLine);

        For L:=y to endy  do begin { Цикл
                                            по строкам изображения }
           for j:= Header.Planes - 1 downto 0 do begin { Цикл по
                                               цветовым плоскостям }
              JJ:=j*MyBytesPerLine;
              if Mode = FromFile then begin { Заполнение строки
                                              изображения из файла  }
                  for i:=0 to BytesPerLine-1 do
                     if (i) < MyBytesPerLine then
                      PI^.mem[i+JJ]:=ReadByte
                     else
                        skip := ReadByte;
                 if BytesPerLine<>Header.BytesPerLine  then ReadByte
              end
              else begin { Пересылка строки изображения, хранящегося
                           в оперативной памяти}
                  for i:=0 to BytesPerLine-1 do
                      PI^.mem[i+JJ]:=ReadMemoryByte;
                 if BytesPerLine<>Header.BytesPerLine then ReadMemoryByte
              end;
           end;
{           setviewport(x, y, getmaxx-40,getmaxy-158,true);}
           PutImage(x,L,PI^,PutMode); { Вывод строки изображения на экран}
        end;{L}
        FreeMem(PI,ImgSize);
      end;

   Function ShowPcxFromFile(x,y,dx,dy,Gd:integer;
                            SetPalette:Boolean; PutMode:Word;
                            Name:String):integer;
   var
      Header:PcxHeader;
      i1,i2,i3,i,j,L:integer;
   begin
      ShowPcxFromFile:=0;
      i1:=OpenFileRead(Name);
      Count:=0;
      EndFile:=False;
      Ps:=PcxBufSize;
      if (i1=0) and (Gd>0) then begin
         i2:= GetPcxHeader(Header);
         if (i2=0) then begin
            if ((x>=0) and
                (y>=0) {and
                ((x+Header.Xmax-Header.Xmin)<=GetMaxX) and
                ((y+Header.Ymax-Header.Ymin)<=GetMaxY)}) then
                    ShowPic(FromFile,Header.Encoding,
                             x,y,dx,dy,Gd,SetPalette,PutMode,Header)
            else ShowPcxFromFile:=-2;
         end
         else ShowPcxFromFile:=-1;
      end
      else ShowPcxFromFile:=i1;
      {$I-}
      Close(F);
      {$I+}
   end;

  Function ShowPcxFromMemory(x,y,dx,dy,Gd:integer;
                            SetPalette:Boolean; PutMode:Word;
                            P:Pointer):integer;
   var
      Header:PcxHeader;
      i1,i2,i3,i,j,L:integer;
   begin
      ShowPcxFromMemory:=0;
      Pm:=P;
      Count:=0;
      Ps:=0;
      if  Gd >0 then begin
         move(Pm^,Header,SizeOf(Header));
         Ps := SizeOf(Header);
         if ((x>=0) and
            (y>=0) and
            ((x+Header.Xmax-Header.Xmin)<=GetMaxX) and
            ((y+Header.Ymax-Header.Ymin)<=GetMaxY)) then
                ShowPic(FromMemory,Header.Encoding,
                        x,y,dx,dy,Gd,SetPalette,PutMode,Header)
       else
          ShowPcxFromMemory:=-2;
      end
      else
      ShowPcxFromMemory:=-1;
   end;

end.
