(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Графический модуль                                         *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT LGraph;

INTERFACE
{
const

  Black        = 00;
  Blue         = 01;
  Green        = 02;
  Cyan         = 03;
  Red          = 04;
  Magenta      = 05;
  Yellow       = 06;
  White        = 07;
  DarkBlue     = 08;
  DarkGreen    = 09;
  DarkCyan     = 10;
  DarkRed      = 11;
  DarkMagenta  = 12;
  DarkYellow   = 13;
  DarkGray     = 14;
  LightGray    = 15; }

Procedure AInitGraph;              { иницилизирует графический режим     }
Procedure SimpleFrame(x,y,
                      dx,dy,
                      Col1,Col2
                      : word );    { рисует простую рамку                }
Procedure InputFrame(x,y,
                      dx,dy,
                      Col1,Col2
                      : word );    { рисует рамку строки ввода           }
Procedure DoubleFrame(x,y,
                      dx,dy,
                      Col1,Col2
                      : word );    { рисует двойную рамку                }

IMPLEMENTATION

uses Graph,
     Resourse;

Procedure AInitGraph;
var   Driver,
      Mode,
      Res   : integer;


begin
  DetectGraph(Driver,Mode);
  if (Driver<9) or (Mode<2) then
    begin
      WriteLn(' Error : VGA display not detected.');
      Halt;
    end;
  RegisterBGIDriver(@EGAVGADriver);
  InitGraph(Driver,Mode,'');
{ SetRGBPalette(00,00,00,00);
  SetRGBPalette(01,00,00,63);
  SetRGBPalette(02,00,63,00);
  SetRGBPalette(03,00,63,63);
  SetRGBPalette(04,63,00,00);
  SetRGBPalette(05,63,00,63);
  SetRGBPalette(20,63,63,00);
  SetRGBPalette(07,63,63,63);
  SetRGBPalette(56,00,00,32);
  SetRGBPalette(57,00,32,00);
  SetRGBPalette(58,00,32,32);
  SetRGBPalette(59,32,00,00);
  SetRGBPalette(60,32,00,32);
  SetRGBPalette(61,32,32,00);
  SetRGBPalette(62,32,32,32);
  SetRGBPalette(63,48,48,48); }
end;

Procedure SimpleFrame;
begin
  MoveTo(x+dx,y);
  SetColor(Col1);
  LineRel(-dx,0);
  LineRel(0,dy);
  SetColor(Col2);
  LineRel(dx,0);
  LineRel(0,-dy+1);
end;

Procedure InputFrame;
var i:byte;

begin
  SetFillStyle(SolidFill,Col2);
  Bar(x+2,y+2,x+dx-3,y+dy-3);
  SetColor(Col1);
  for i:=1 to 2 do
    begin
      MoveTo(x+dx-i,y+i);
      LineRel(-dx+i*2,0);
      LineRel(0,dy-i*2);
    end;
  SetColor(Col2);
  MoveTo(x+dx-1,y+1);
  LineRel(0,dy-2);
  LineRel(-dx+2,0);
end;

Procedure DoubleFrame;
begin
  SetColor(Col2);
  Rectangle(x+1,y+1,dx+x,dy+y);
  SetColor(Col1);
  Rectangle(x,y,dx+x-1,dy+y-1)
end;

END.