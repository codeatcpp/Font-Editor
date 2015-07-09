(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Модуль работы со строками                                  *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 10.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT LString;

INTERFACE

Function CountSymbols(const Str
                            : string ;
                            Symbol
                            : char )
                            : byte; { считает кол-во заданных
                                      символов в строке                  }
Function UpString(Str
                     : string)
                     : string;      { преобразует строчные буквы в
                                      заглавные                          }

IMPLEMENTATION

Function CountSymbols;
var q : byte;
    n : byte;

begin
  n:=0;
  for q:=1 to byte(Str[0]) do
    if Str[q]=Symbol then n:=n+1;
  CountSymbols:=n;
end;

Function UpString;
var
  i:integer;
  a,b:byte;

begin
  for i:=1 to byte(str[0]) do
    begin
      str[i]:=upcase(str[i]);
      a:=byte(str[i]);
      if (a>127) and (a<144)
        then
          b:=32
      else if (a>143) and (a<160)
        then
          b:=80
      else b:=0;
      str[i]:=char(a+b);
    end;
  UpString:=str;
end;

END.