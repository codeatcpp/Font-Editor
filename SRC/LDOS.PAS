(*************************************************************************)
(*  �஥�� :  Font Editor for DOS                                        *)
(*            ����� ࠡ��� � ��᪠��                                    *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    ����  : �濫��᪨� ��ਫ�                   �� �ࠢ� ���饭�    *)
(*    ���   : 10.08.96                            �. ����ᠭ�஢        *)
(*************************************************************************)
{$I PARAMS}
UNIT LDos;

INTERFACE

Function NumDrives : byte;                { ������⢮ ��᪮�����        }

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
