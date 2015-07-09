(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Модуль работы с дисками                                    *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                   Все права защищены    *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT LDos;

INTERFACE

Function NumDrives : byte;                { количество дисководов        }

IMPLEMENTATION

Function NumDrives;
var  Info : word;
begin
  asm
    int 11h
    mov info,ax
  end;
  if Info and 1 <> 0 then
    begin
      if Info and 64 = 0 then NumDrives:=1
      else
      if Info and 64 <> 0 then NumDrives:=2
      else
      if Info and 128 = 0 then NumDrives:=3
      else
      if Info and 128 <> 0 then NumDrives:=4;
    end
  else
    NumDrives:=0;
end;

END.
