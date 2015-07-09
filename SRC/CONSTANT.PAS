(*************************************************************************)
(*  Проект : Font Editor for DOS                                         *)
(*           Константы редактора матричных шрифтов (F_EDITOR)            *)
(*           http://www.codeatcpp.com                                    *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 20.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT Constant;

INTERFACE

const

  { константы помощи }

  hcNoContext = 000;
  hcFile      = 010;
  hcSave      = 100;
  hcSaveAs    = 101;
  hcOpen      = 102;
  hcExit      = 103;
  hcNew       = 104;
  hcEdit      = 011;
  hcUndo      = 110;
  hcCopy      = 111;
  hcPaste     = 112;
  hcHelp      = 012;
  hcF_Editor  = 120;
  hcAbout     = 121;
  hcModif     = 013;
  hcClear     = 130;
  hcLeftSc    = 131;
  hcRightSc   = 132;
  hcUpSc      = 133;
  hcDownSc    = 134;
  hcInverse   = 135;
  hcRotate    = 136;
  hcHoriz     = 137;
  hcVert      = 138;
  hcTarget    = 139;

  hcClose     = 001;
  hcCancel    = 002;
  hcUp        = 003;
  hcDown      = 004;

IMPLEMENTATION

END.
