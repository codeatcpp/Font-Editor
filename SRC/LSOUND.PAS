(*************************************************************************)
(*  �஥�� :  Font Editor for DOS                                        *)
(*            ����� ࠡ��� � ��㪮�                                    *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    ����  : �濫��᪨� ��ਫ�                                         *)
(*    ���   : 10.08.96                            �. ����ᠭ�஢        *)
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