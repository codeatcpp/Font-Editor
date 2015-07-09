(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Модуль работы со звуком                                    *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT LSound;

INTERFACE

Procedure Beep;

IMPLEMENTATION

uses CRT;

Procedure Beep;
var q : byte;

begin
  for q:=1 to 4 do
    begin
      Sound(600);
      Delay(40);
      Sound(800);
      Delay(40);
    end;
  NoSound;
end;

END.