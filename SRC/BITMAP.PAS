(*************************************************************************)
(*  Проект : Font Editor for DOS                                         *)
(*                                                                       *)
(*           http://www.codeatcpp.com                                    *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT BITMAP;

INTERFACE

TYPE

TBitMap=record
  dx:integer;
  dy:integer;
  reserv:word;
  b:array[0..65528] of byte;
end;

PTBitMap=^TBitMap;

IMPLEMENTATION
END.