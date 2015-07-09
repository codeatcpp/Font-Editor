(*************************************************************************)
(*  è‡Æ•™‚ :  Font Editor for DOS                                        *)
(*            ÄÅëíêÄäíçõâ ëèàëéä                                         *)
(*            http://www.codeatcpp.com                                   *)
(*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*)
(*    Ä¢‚Æ‡  : ãÔ§¢®≠·™®© å. Ç.                                          *)
(*    Ñ†‚†   : · 16.11.95 ØÆ 16.11.95                    åàùí á•´•≠Æ£‡†§ *)
(*************************************************************************)
{$I PARAMS}
UNIT LMLIST;

INTERFACE

TYPE
  PTListElem=^TListElem;
  TListElem=object
    Prev,
    Next:PTListElem;
    Destructor Done; virtual;
    Function EQU(Elem:PTListElem):boolean; virtual;
  end;
  PTList=^TList;
  TList=object(TListElem)
    First,
    Last,
    Act:PTListElem;
    NumberOfElem:word;
    Constructor Init;
    Procedure AddElem(Elem:PTListElem);
    Procedure AddList(List:PTList);
    Function FindElem(Elem:PTListElem):PTListElem;
    Function DeleteElem(Elem:PTListElem):PTListElem;
    Procedure Replace(Elem1,Elem2:PTListElem);
    Destructor Done; virtual;
  end;

IMPLEMENTATION

Function TListElem.EQU(Elem:PTListElem):boolean;
 begin
   EQU:=(@Self = Elem);
 end;

Destructor TListElem.Done;
 begin
 end;

Constructor TList.Init;
 begin
   First:=nil;
   Act:=nil;
   Last:=nil;
   NumberOfElem:=0;
 end;

Procedure TList.AddElem(Elem:PTListElem);
 begin
   if Last=nil
     then
       begin
         First:=Elem;
         Last:=First;
         Act:=First;
         First^.Prev:=nil;
       end
     else
       begin
         Last^.Next:=Elem;
         Elem^.Prev:=Last;
         Last:=Elem;
       end;
   Last^.Next:=nil;
   inc(NumberOfElem);
 end;

Procedure TList.AddList(List:PTList);
 var
   WorkElem:PTListElem;
 begin
   WorkElem:=List^.First;
   while WorkElem<>nil do
     begin
       AddElem(WorkElem);
       WorkElem:=WorkElem^.Next;
     end;
   Dispose(List,Done);
 end;

Function TList.FindElem(Elem:PTListElem):PTListElem;
 var
   WorkElem:PTListElem;
 begin
   FindElem:=nil;
   WorkElem:=First;
   while WorkElem<>nil do
     begin
       if WorkElem^.EQU(Elem)
         then
           begin
             FindElem:=WorkElem;
             WorkElem:=nil;
           end
         else
           WorkElem:=WorkElem^.Next;
     end;
 end;

Function TList.DeleteElem(Elem:PTListElem):PTListElem;
 begin
   Elem:=FindElem(Elem);
   DeleteElem:=Elem;
   if Elem<>nil
     then
       begin
         if Elem^.Prev<>nil
           then
             Elem^.Prev^.Next:=Elem^.Next
           else
             First:=Elem^.Next;
         if Elem^.Next<>nil
           then
             Elem^.Next^.Prev:=Elem^.Prev
           else
             Last:=Elem^.Prev;
         Act:=First;
         dec(NumberOfElem);
       end;
 end;

Procedure TList.Replace(Elem1,Elem2:PTListElem);
 var
   N,P,F,L:PTListElem;
 begin
   Elem1:=FindElem(Elem1);
   Elem2:=FindElem(Elem2);
   if (Elem1<>nil) and
      (Elem2<>nil)
     then
       begin
         F:=First;
         L:=Last;
         if Elem1=First
           then
             F:=Elem2
         else if Elem1=Last
           then
             L:=Elem2;
         if Elem2=First
           then
             F:=Elem1
         else if Elem2=Last
           then
             L:=Elem1;
         First:=F;
         Last:=L;
         with Elem1^ do
           begin
             N:=Next;
             P:=Prev;
             Next:=Elem2^.Next;
             Prev:=Elem2^.Prev;
           end;
         with Elem2^ do
           begin
             Prev:=P;
             Next:=N;
           end;
       end;
 end;

Destructor TList.Done;
 var
   WorkElem,
   WorkElem2:PTListElem;
 begin
   WorkElem:=First;
   while WorkElem<>nil do
     begin
       WorkElem2:=WorkElem^.Next;
       Dispose(WorkElem,Done);
       WorkElem:=WorkElem2;
     end;
 end;

END.