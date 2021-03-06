(*************************************************************************)
(*  �஥�� :  Font Editor for DOS                                        *)
(*            ������� ।���� ������� ���⮢                        *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    ����  : �濫��᪨� ��ਫ�                                         *)
(*    ���   : 10.08.96                            �. ����ᠭ�஢        *)
(*************************************************************************)

{$I PARAMS}
UNIT Resourse;

INTERFACE

Procedure EGAVGADriver;                   { ����᪨� �ࠩ���           }
Procedure PCXName;                        { �������� � ���᪨� �ࠢ�     }
Procedure PCXQuest;                       { ���� �����                  }

  { ��ப� �����㬥�⮢ }
Procedure PCXOpen;
Procedure PCXSave;
Procedure PCXNew;

Procedure PCXUndo;
Procedure PCXCopy;
Procedure PCXPaste;

Procedure PCXClear;
Procedure PCXLeft;
Procedure PCXDown;
Procedure PCXUp;
Procedure PCXRight;
Procedure PCXInverse;
Procedure PCXFlipHor;
Procedure PCXFlipVer;
Procedure PCXRotate;

Procedure PCXHelp;

IMPLEMENTATION

Procedure EGAVGADriver; EXTERNAL;
{$L egavga}

Procedure PCXName; EXTERNAL;
{$L name}

Procedure PCXQuest; EXTERNAL;
{$L quest}

Procedure PCXHelp; EXTERNAL;
{$L help}

Procedure PCXOpen; EXTERNAL;
{$L open}

Procedure PCXSave; EXTERNAL;
{$L save}

Procedure PCXNew; EXTERNAL;
{$L new}

Procedure PCXUndo; EXTERNAL;
{$L undo}

Procedure PCXCopy; EXTERNAL;
{$L copy}

Procedure PCXPaste; EXTERNAL;
{$L paste}

Procedure PCXClear; EXTERNAL;
{$L clear}

Procedure PCXLeft; EXTERNAL;
{$L left}

Procedure PCXUp; EXTERNAL;
{$L up}

Procedure PCXDown; EXTERNAL;
{$L down}

Procedure PCXRight; EXTERNAL;
{$L right}

Procedure PCXInverse; EXTERNAL;
{$L invert}

Procedure PCXFlipHor; EXTERNAL;
{$L fliphor}

Procedure PCXFlipVer; EXTERNAL;
{$L flipver}

Procedure PCXRotate; EXTERNAL;
{$L rotate}

END.
