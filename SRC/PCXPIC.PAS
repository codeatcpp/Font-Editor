{$R-,S-,I-,V-}
{$X+}
{**********************************************************}
{ unit PcxPic - �����㬥��� ��� ࠡ��� � ����᪨��      }
{               ��ࠧ��� � �ଠ�  PC PaintBrush          }
{ Cohyright (c) 1991, �.��宭��                            }
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

     Count    :word;{ ���稪 }
     W        :Byte;
     Ps       :Word;
     EndFile  :Boolean;{ ������ ���� 䠩�� }
     BufSize  :word; { ������ ���� ��� ����᪮�� ��ࠧ� }
     PcxBuf   :array[1..PcxBufSize] of Byte; { ���� }
     Pm       :PMem;

  Type
     PcxPalette  = array[0..15,0..2] of Byte; {��ଠ� ������� PC PaintBrush}
     {��������� PCX-䠩��}
     PcxHeader = Record  {��������� PCX-䠩��}
       Creator   :   Byte; {ZSoft =10}
       Version   :   Byte; {����� PCX:
                             0 - ����� 2.5 ��� �������;
                             2 - ����� 2.8 � �����ன;
                             3 - ����� 2.8/3.0 ��� �������;
                             5 - ����� 3.0 � �����ன.
                           }
        Encoding :   Byte; {1 - ⨯ ᦠ�� RLE}
        Bits     :   Byte; { ��᫮ ��⮢ �� ���ᥫ }
        Xmin,
        Ymin,
        Xmax,
        Ymax     :   integer;{ ������� ���⨭�� }
        Hres,
        Vres     :   integer;{ ����襭�� }
        Palette  :   PcxPalette; {������}
        Vmode    :   Byte; { �����}
        Planes   :   Byte; { ��᫮ 梥⮢�� ���᪮�⥩}
        BytesPerLine: Word; { ��᫮ ���⮢ �� ��ப�}
        PaletteInfo: Word; { ���ଠ�� � ������:
                               1 - 梥⭠� / �୮-�����;
                               2 - �ࠤ�樨 �ண�;
                            }
        shres,
        svres     :    Word; { ����襭�� ᪠���}
        xtra     : array[0..53] of Byte;{ ����ࢨ஢��� }
     end;

     Procedure SetPcxPalette(Screen:Integer;Pal:PcxPalette);{��⠭����
                       ������� �� ��������� Pcx - ��ࠧ�  }
        var
          P:PaletteType;
          i,j,BkCol,CgaPal:integer;
          c:real;
          B,BB:shortint;

        begin
          GetDefaultPalette(P);{ ⥪��� ������ }
          case Screen of
           0: begin   { EGA, VGA, 16 梥⮢}
                for i:=0 to P.Size-1 do begin
                  B:=0;
                  for j:=0 to 2 do begin
                    c:=Pal[i,j];
                    BB:=trunc(c/255.0*3.0);
                    case j of
                     0: begin { ��४���஢�� ��᭮�� 梥� � �ଠ� rgbRGB}
                          if (BB and 1)>0 then B:=B or $20;
                          if (BB and 2)>0 then B:=B or $04;
                     end;
                     1: begin { ��४���஢�� �������� 梥� � �ଠ� rgbRGB}
                          if (BB and 1)>0 then B:=B or $10;
                          if (BB and 2)>0 then B:=B or $02;
                     end;
                     2: begin { ��४���஢�� ᨭ��� 梥� � �ଠ� rgbRGB}
                          if (BB and 1)>0 then B:=B or $08;
                          if (BB and 2)>0 then B:=B or $01;
                        end;
                    end;{case}
                  end; {j}
                  P.Colors[i]:=B;
                end;{i}
                SetallPalette(P);
           end;{0}
           2: begin { CGA, 4 梥� }
              BkCol :=(Pal[0,0] div $10) mod 8;
              CgaPal:=(Pal[1,0] div $20) mod 4;
              SetBkColor(BkCol);
              SetGraphMode(CgaPal);
           end;
           else;
          end;{case Screen}
        end;

 {�ᯮ����⥫�� �㭪樨}

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
                {�⥭�� ��������� PCX 䠩��}
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
      if ((tmp and $C0) = $C0) then begin {���稪 ����७��}
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
      if ((tmp and $C0) = $C0) then begin {���稪 ����७��}
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
      ImageMem = record { ���⮪ ����᪮�� ��࠭� }
         x,y:integer;  {������� �� ��ਧ��⠫� � ���⨪��� � ���ᥫ��}
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
         case Gd of   { ��⠭���� �ਧ���� �������}
            EGA,VGA : Screen:=0;
            HercMono: Screen:=1;
            CGA     : Screen:=2;
            else      Screen:= -Gd;
         end;
        if (SetPalette and
            (Header.Version in [2,5])) then  { ��⠭���� �������}
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

        GetMem(PI,ImgSize); { �뤥��� ������ ��� ��ப� ����ࠦ����}
        { �������� ��ப� ��ࠧ� � �ଠ� BGI }
       MyPixelsPerLine := endx-x+1;
        PI^.x:= MyPixelsPerLine-1;
        PI^.y:=0;
       MyBytesPerLine := MyPixelsPerLine div Divisor;
       if (MyPixelsPerLine mod Divisor)<>0 then Inc(MyBytesPerLine);

        For L:=y to endy  do begin { ����
                                            �� ��ப�� ����ࠦ���� }
           for j:= Header.Planes - 1 downto 0 do begin { ���� ��
                                               梥⮢� ���᪮��� }
              JJ:=j*MyBytesPerLine;
              if Mode = FromFile then begin { ���������� ��ப�
                                              ����ࠦ���� �� 䠩��  }
                  for i:=0 to BytesPerLine-1 do
                     if (i) < MyBytesPerLine then
                      PI^.mem[i+JJ]:=ReadByte
                     else
                        skip := ReadByte;
                 if BytesPerLine<>Header.BytesPerLine  then ReadByte
              end
              else begin { ����뫪� ��ப� ����ࠦ����, �࠭�饣���
                           � ����⨢��� �����}
                  for i:=0 to BytesPerLine-1 do
                      PI^.mem[i+JJ]:=ReadMemoryByte;
                 if BytesPerLine<>Header.BytesPerLine then ReadMemoryByte
              end;
           end;
{           setviewport(x, y, getmaxx-40,getmaxy-158,true);}
           PutImage(x,L,PI^,PutMode); { �뢮� ��ப� ����ࠦ���� �� ��࠭}
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
