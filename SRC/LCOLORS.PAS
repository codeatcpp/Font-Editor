(*************************************************************************)
(*  Проект :  Font Editor for DOS                                        *)
(*            Модуль работы с цветами                                    *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Автор  : Лядвинский Кирилл                                         *)
(*    Дата   : 25.08.96                            г. Александров        *)
(*************************************************************************)
{$I PARAMS}
UNIT LColors;

INTERFACE

uses Graph;

const
   cNewColor1  = LightMagenta;         { измененный цвет               }
   cNewColor2  = Brown;                { измененный цвет               }

   cBackGround = Blue;                 { фон программы                 }
   cNormText   = Blue;                 { нормальный текст              }

   cStatusLine = LightGray;            { фон строки состояния          }
   cSLText     = Black;                { текст строки состояния        }

   cNet        = LightGray;            { сетка для редактирования      }
   cSymbCode   = Yellow;               { код символа                   }
   cNPixel     = White;                { заженный пиксел в сетке       }

   cFontName   = White;                { имя шрифта                    }
   cSymbTable  = White;                { таблица символов              }
   cCursor     = LightCyan;            { курсор                        }

   cErrorWind  = Red;                  { окно 'Сообщение об ошибке'    }
   cEWText     = Yellow;               { текст в ErrorWind             }

IMPLEMENTATION

END.
