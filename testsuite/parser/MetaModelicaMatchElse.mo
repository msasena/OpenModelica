// name: MetaModelicaMatchElse
// status: correct
// cflags: +g=MetaModelica
//
// Tests that the parser can handle all sorts of match/matchcontinue

within MetaModelicaMatchElse;
function f1
algorithm
  _ := match x case 1 then ();  end match;
  _ := match (x,y,z) case 1 then (); end match;
  _ := match () case 1 then (); end match;
  _ := match (x) case 1 then fail(); else equation fail(); then 2; end match;
  _ := match (x) case 1 then fail(); else then 2; end match;
  _ := match (x) case 1 then fail(); else 2; end match;
  _ := match (x) case 1 then fail(); else "comment" then 2; end match;
  _ := matchcontinue x case 1 then ();  end matchcontinue;
  _ := matchcontinue (x,y,z) case 1 then (); end matchcontinue;
  _ := matchcontinue () case 1 then (); end matchcontinue;
  _ := matchcontinue (x) case 1 then fail(); else equation fail(); then 2; end matchcontinue;
  _ := matchcontinue (x) case 1 then fail(); else then 2; end matchcontinue;
  _ := matchcontinue (x) case 1 then fail(); else 2; end matchcontinue;
  _ := matchcontinue (x) case 1 then fail(); else "comment" then 2; end matchcontinue;
end f1;

class A
constant Real x = 1.0;
end A;
// Result:
// class A
//   constant Real x = 1.0;
// end A;
// endResult
