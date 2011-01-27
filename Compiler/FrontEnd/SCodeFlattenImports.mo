/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�ping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SCodeFlattenImports
" file:        SCodeFlattenImports.mo
  package:     SCodeFlattenImports
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import SCodeEnv;

public type Env = SCodeEnv.Env;

protected import Debug;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import SCodeLookup;
protected import SCodeFlattenImports;
protected import SCodeFlattenExtends;
protected import SCodeFlattenRedeclare;
protected import System;
protected import Util;

protected type Item = SCodeEnv.Item;
protected type Extends = SCodeEnv.Extends;
protected type FrameType = SCodeEnv.FrameType;
protected type Import = Absyn.Import;

public function flattenProgram
  input SCode.Program inProgram;
  input Env inEnv;
  output SCode.Program outProgram;
algorithm
  outProgram := Util.listMap1(inProgram, flattenClasses, inEnv);
end flattenProgram;

protected function flattenClasses
  input SCode.Class inClass;
  input Env inEnv;
  output SCode.Class outClass;
protected
  SCode.Ident name;
  Boolean part_pre, encap_pre;
  SCode.Restriction restriction;
  SCode.ClassDef cdef;
  Absyn.Info info;
  Env env;
algorithm
  SCode.CLASS(name, part_pre, encap_pre, restriction, cdef, info) := inClass;
  env := SCodeEnv.enterScope(inEnv, name);
  cdef := flattenClassDefs(cdef, env);
  outClass := SCode.CLASS(name, part_pre, encap_pre, restriction, cdef, info);
end flattenClasses;

protected function flattenClassDefs
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := match(inClassDef, inEnv)
    local
      list<SCode.Element> el, ex, cl, im, co, ud;
      list<SCode.Equation> neql, ieql;
      list<SCode.AlgorithmSection> nal, ial;
      Option<Absyn.ExternalDecl> extdecl;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;
      SCode.ClassDef cdef;
      Env env;

    case (SCode.PARTS(el, neql, ieql, nal, ial, extdecl, annl, cmt), env)
      equation
        // Lookup elements.
        el = Util.listMap1(el, flattenElement, env);
        el = Util.listFilter(el, isNotImport);

        // Lookup equations and algorithm names.
        neql = Util.listMap1(neql, flattenEquation, env);
        ieql = Util.listMap1(ieql, flattenEquation, env);
        nal = Util.listMap1(nal, flattenAlgorithm, env);
        ial = Util.listMap1(ial, flattenAlgorithm, env);
        cdef = SCode.PARTS(el, neql, ieql, nal, ial, extdecl, annl, cmt);
      then
        cdef;

    //case (SCode.CLASS_EXTENDS
    //case (SCode.DERIVED

    case (SCode.ENUMERATION(enumLst = _), _) then inClassDef;

    //case (SCode.OVERLOAD
    //case (SCode.PDER
    else then inClassDef;
  end match;
end flattenClassDefs;

protected function isNotImport
  input SCode.Element inElement;
algorithm
  _ := match(inElement)
    case SCode.IMPORT(imp = _) then fail();
    else then ();
  end match;
end isNotImport;

protected function flattenElement
  input SCode.Element inElement;
  input Env inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    // Lookup component types, modifications and conditions.
    case (SCode.COMPONENT(component = _), _)
      then flattenComponent(inElement, inEnv);

    // Lookup class definitions.
    case (SCode.CLASSDEF(name = _), _)
      then flattenClassDefElements(inElement, inEnv);

    // Lookup base class and modifications in extends clauses.
    case (SCode.EXTENDS(baseClassPath = _), _)
      then flattenExtends(inElement, inEnv);

    else then inElement;
  end match;
end flattenElement;
    
protected function flattenClassDefElements
  input SCode.Element inClassDefElement;
  input Env inEnv;
  output SCode.Element outClassDefElement;
protected
  SCode.Ident name;
  Boolean fp, rp;
  SCode.Class cls;
  Option<Absyn.ConstrainClass> cc;
algorithm
  SCode.CLASSDEF(name, fp, rp, cls, cc) := inClassDefElement;
  cls := flattenClasses(cls, inEnv);
  outClassDefElement := SCode.CLASSDEF(name, fp, rp, cls, cc);
end flattenClassDefElements;

protected function flattenComponent
  input SCode.Element inComponent;
  input Env inEnv;
  output SCode.Element outComponent;
algorithm
  outComponent := matchcontinue(inComponent, inEnv)
    local
      SCode.Ident name;
      Absyn.InnerOuter io;
      Boolean fp, rp, pp;
      SCode.Attributes attr;
      Absyn.TypeSpec type_spec;
      SCode.Mod mod;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cond;
      Option<Absyn.Info> opt_info;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Info info;

    case (SCode.COMPONENT(name, io, fp, rp, pp, attr, type_spec, mod, cmt, cond,
        opt_info, cc), _)
      equation
        ErrorExt.setCheckpoint("flattenComponent");
        info = SCodeEnv.getOptionalInfo(opt_info);
        (_, type_spec, _) = SCodeLookup.lookupTypeSpec(type_spec, inEnv, info);
        mod = flattenModifier(mod, inEnv, info);
        cond = flattenOptExp(cond, inEnv, info);
        ErrorExt.delCheckpoint("flattenComponent");
      then
        SCode.COMPONENT(name, io, fp, rp, pp, attr, type_spec, mod, cmt, cond, opt_info, cc);

    // Something failed in the previous case. This might happen with the MSL
    // which sometimes defines conditional components that use functions that it
    // doesn't really have access to. So check if the component happens to have
    // condition = false, and if that's the case we can just ignore it (along
    // with any error messages from the previous case).
    case (SCode.COMPONENT(condition = cond), _)
      equation
        false = evaluateConditionalExp(cond, inEnv);
        ErrorExt.rollBack("flattenComponent");
      then
        inComponent;

    // Make sure that the checkpoint is deleted properly.
    else
      equation
        ErrorExt.delCheckpoint("lookupComponent");
      then
        fail();

  end matchcontinue;
end flattenComponent;

protected function evaluateConditionalExp
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  output Boolean outResult;
algorithm
  outResult := match(inExp, inEnv)
    local
      Absyn.Exp exp;

    case (SOME(exp), _) then evaluateBinding(exp, inEnv);
  end match;
end evaluateConditionalExp;
        
protected function evaluateBinding
  input Absyn.Exp inExp;
  input Env inEnv;
  output Boolean outResult;
algorithm
  outResult := match(inExp, inEnv)
    local
      Boolean res;
      Absyn.ComponentRef cref;
      Absyn.Path path;
      Absyn.Exp exp;
      Env env;

    case (Absyn.BOOL(value = res), _) then res;
    case (Absyn.CREF(componentRef = cref), _)
      equation
        path = Absyn.crefToPath(cref);
        (SCodeEnv.VAR(var = SCode.COMPONENT(modifications = 
            SCode.MOD(absynExpOption = SOME((exp, _))))), _, SOME(env)) = 
          SCodeLookup.lookupName(path, inEnv, Absyn.dummyInfo);
      then 
        evaluateBinding(exp, env);

  end match;
end evaluateBinding;

protected function flattenExtends
  input SCode.Element inExtends;
  input Env inEnv;
  output SCode.Element outExtends;
protected
  Absyn.Path path;
  SCode.Mod mod;
  Option<SCode.Annotation> ann;
  Absyn.Info info;
  Env env;
algorithm
  SCode.EXTENDS(path, mod, ann, info) := inExtends;
  env := SCodeEnv.removeExtendsFromLocalScope(inEnv);
  (_, path, _) := SCodeLookup.lookupName(path, env, info);
  mod := flattenModifier(mod, inEnv, info);
  outExtends := SCode.EXTENDS(path, mod, ann, info);
end flattenExtends;

protected function flattenEquation
  input SCode.Equation inEquation;
  input Env inEnv;
  output SCode.Equation outEquation;
protected
  SCode.EEquation equ;
algorithm
  SCode.EQUATION(equ) := inEquation;
  (equ, _) := SCode.traverseEEquations(equ, (flattenEEquationTraverser, inEnv));
  outEquation := SCode.EQUATION(equ);
end flattenEquation;

protected function flattenEEquationTraverser
  input tuple<SCode.EEquation, Env> inTuple;
  output tuple<SCode.EEquation, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      SCode.EEquation equ;
      SCode.Ident iter_name;
      Env env;
      Absyn.Info info;

    case ((equ as SCode.EQ_FOR(index = iter_name, info = info), env))
      equation
        env = SCodeEnv.extendEnvWithIterators({(iter_name, NONE())}, env);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
        ((equ, env));

    case ((equ, env))
      equation
        info = SCode.getEEquationInfo(equ);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
        ((equ, env));

  end match;
end flattenEEquationTraverser;

protected function traverseExp
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
protected
  Absyn.Exp exp;
  Env env;
  Absyn.Info info;
algorithm
  (exp, (env, info)) := inTuple;
  (exp, (_, _, (env, info))) := Absyn.traverseExpBidir(exp,
    (flattenExpTraverserEnter, flattenExpTraverserExit, (env, info)));
  outTuple := (exp, (env, info));
end traverseExp;

protected function flattenAlgorithm
  input SCode.AlgorithmSection inAlgorithm;
  input Env inEnv;
  output SCode.AlgorithmSection outAlgorithm;
protected
  list<SCode.Statement> statements;
algorithm
  SCode.ALGORITHM(statements) := inAlgorithm;
  statements := Util.listMap1(statements, flattenStatement, inEnv);
  outAlgorithm := SCode.ALGORITHM(statements);
end flattenAlgorithm;

protected function flattenStatement
  input SCode.Statement inStatement;
  input Env inEnv;
  output SCode.Statement outStatement;
protected
  Env env;
algorithm
  (outStatement, _) := SCode.traverseStatements(inStatement, (flattenStatementTraverser, inEnv));
end flattenStatement;

protected function flattenStatementTraverser
  input tuple<SCode.Statement, Env> inTuple;
  output tuple<SCode.Statement, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.ForIterators iters;
      Env env;
      SCode.Statement stmt;
      Absyn.Info info;

    case ((stmt as SCode.ALG_FOR(iterators = iters, info = info), env))
      equation
        env = SCodeEnv.extendEnvWithIterators(iters, env);
        (stmt, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

    case ((stmt, env)) 
      equation
        info = SCode.getStatementInfo(stmt);
        (stmt, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

  end match;
end flattenStatementTraverser;

protected function flattenModifier
  input SCode.Mod inMod;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod, inEnv, inInfo)
    local
      Boolean fp;
      Absyn.Each ep;
      list<SCode.SubMod> sub_mods;
      Option<tuple<Absyn.Exp, Boolean>> opt_exp;
      list<SCode.Element> el;

    case (SCode.MOD(fp, ep, sub_mods, opt_exp), _, inInfo)
      equation
        opt_exp = flattenModOptExp(opt_exp, inEnv, inInfo);
        sub_mods = Util.listMap2(sub_mods, flattenSubMod, inEnv, inInfo);
      then
        SCode.MOD(fp, ep, sub_mods, opt_exp);

    case (SCode.REDECL(fp, el), _, _)
      equation
        //print("SCodeFlatten.lookupModifier: REDECL\n");
      then
        //fail();
        inMod;

    case (SCode.NOMOD(), _, _) then inMod;
  end match;
end flattenModifier;

protected function flattenModOptExp
  input Option<tuple<Absyn.Exp, Boolean>> inOptExp;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Option<tuple<Absyn.Exp, Boolean>> outOptExp;
algorithm
  outOptExp := match(inOptExp, inEnv, inInfo)
    local
      Absyn.Exp exp;
      Boolean delay_elab;

    case (SOME((exp, delay_elab)), _, _)
      equation
        exp = flattenExp(exp, inEnv, inInfo);
      then
        SOME((exp, delay_elab));

    case (NONE(), _, _) then inOptExp;
  end match;
end flattenModOptExp;

protected function flattenSubMod
  input SCode.SubMod inSubMod;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.SubMod outSubMod;
algorithm
  outSubMod := match(inSubMod, inEnv, inInfo)
    local
      SCode.Ident ident;
      list<SCode.Subscript> subs;
      SCode.Mod mod;

    case (SCode.NAMEMOD(ident = ident, A = mod), _, _)
      equation
        mod = flattenModifier(mod, inEnv, inInfo);
      then
        SCode.NAMEMOD(ident, mod);

    case (SCode.IDXMOD(subscriptLst = subs, an = mod), _, _)
      equation
        subs = Util.listMap2(subs, flattenSubscript, inEnv, inInfo);
        mod = flattenModifier(mod, inEnv, inInfo);
      then
        SCode.IDXMOD(subs, mod);
  end match;
end flattenSubMod;

protected function flattenSubscript
  input SCode.Subscript inSub;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.Subscript outSub;
algorithm
  outSub := match(inSub, inEnv, inInfo)
    local
      Absyn.Exp exp;

    case (Absyn.SUBSCRIPT(subScript = exp), _, _)
      equation
        exp = flattenExp(exp, inEnv, inInfo);
      then
        Absyn.SUBSCRIPT(exp);

    case (Absyn.NOSUB(), _, _) then inSub;
  end match;
end flattenSubscript;

protected function flattenExp
  input Absyn.Exp inExp;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.Exp outExp;
algorithm
  (outExp, _) := Absyn.traverseExpBidir(inExp, (flattenExpTraverserEnter, flattenExpTraverserExit, (inEnv, inInfo)));
end flattenExp;

protected function flattenOptExp
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Option<Absyn.Exp> outExp;
algorithm
  outExp := match(inExp, inEnv, inInfo)
    local
      Absyn.Exp exp;

    case (SOME(exp), _, _)
      equation
        exp = flattenExp(exp, inEnv, inInfo);
      then
        SOME(exp);

    case (NONE(), _, _) then inExp;
  end match;
end flattenOptExp;

protected function flattenExpTraverserEnter
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Env env;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.Exp exp;
      Absyn.ForIterators iters;
      Absyn.Info info;
      tuple<Env, Absyn.Info> tup;

    case ((Absyn.CREF(componentRef = cref), tup as (env, info)))
      equation
        cref = SCodeLookup.lookupComponentRef(cref, env, info);
      then
        ((Absyn.CREF(cref), tup));

    case ((exp as Absyn.CALL(functionArgs = 
        Absyn.FOR_ITER_FARG(iterators = iters)), (env, info)))
      equation
        env = SCodeEnv.extendEnvWithIterators(iters, env);
      then
        ((exp, (env, info)));

    case ((Absyn.CALL(function_ = cref, functionArgs = args), 
        tup as (env, info)))
      equation
        cref = SCodeLookup.lookupComponentRef(cref, env, info);
        // TODO: handle function arguments
      then
        ((Absyn.CALL(cref, args), tup));

    case ((Absyn.PARTEVALFUNCTION(function_ = cref, functionArgs = args), 
        tup as (env, info)))
      equation
        cref = SCodeLookup.lookupComponentRef(cref, env, info);
        // TODO: handle function arguments
      then
        ((Absyn.PARTEVALFUNCTION(cref, args), tup));
    
    else then inTuple;
  end match;
end flattenExpTraverserEnter;

protected function flattenExpTraverserExit
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.Exp e;
      Env env;
      Absyn.Info info;

    case ((e as Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = _)),
        (SCodeEnv.FRAME(frameType = SCodeEnv.IMPLICIT_SCOPE()) :: env, info)))
      then
        ((e, (env, info)));

    else then inTuple;
  end match;
end flattenExpTraverserExit;

public function flattenComponentRefSubs
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnv, inInfo)
    local
      Absyn.Ident name;
      Absyn.ComponentRef cref;
      list<Absyn.Subscript> subs;

    case (Absyn.CREF_IDENT(name, subs), _, _)
      equation
        subs = Util.listMap2(subs, flattenSubscript, inEnv, inInfo);
      then
        Absyn.CREF_IDENT(name, subs);

    case (Absyn.CREF_QUAL(name, subs, cref), _, _)
      equation
        subs = Util.listMap2(subs, flattenSubscript, inEnv, inInfo);
        cref = flattenComponentRefSubs(cref, inEnv, inInfo);
      then
        Absyn.CREF_QUAL(name, subs, cref);

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), _, _)
      equation
        cref = flattenComponentRefSubs(cref, inEnv, inInfo);
      then
        Absyn.CREF_FULLYQUALIFIED(cref);

  end match;
end flattenComponentRefSubs;

        
//protected function expandExtend
//  input SCode.Element inElement;
//  input Env inEnv;
//  input SCode.ClassDef inClassDef;
//  output SCode.ClassDef outClassDef;
//algorithm
//  outClassDef := matchcontinue(inElement, inEnv, inClassDef)
//    local
//      Absyn.Path path;
//      SCode.Mod mods;
//      SCode.ClassDef base_cdef, merged_cdef;
//
//    case (SCode.EXTENDS(baseClassPath = path, modifications = mods), _, _)
//      equation
//        SCode.CLASS(classDef = base_cdef) = SCodeLookup.lookupName(path, inEnv);
//        merged_cdef = mergeClassDefs(base_cdef, inClassDef);
//      then
//        merged_cdef;
//
//  end matchcontinue;
//end expandExtend;
//
//protected function mergeClassDefs
//  input SCode.ClassDef inClassDef1;
//  input SCode.ClassDef inClassDef2;
//  output SCode.ClassDef outClassDef;
//algorithm
//  outClassDef := matchcontinue(inClassDef1, inClassDef2)
//    local
//      list<SCode.Element> el1, el2;
//      list<SCode.Equation> neql1, neql2, ieql1, ieql2;
//      list<SCode.AlgorithmSection> nal1, nal2, ial1, ial2;
//      list<SCode.Annotation> annl;
//      Option<SCode.Comment> cmt;
//
//    case (SCode.PARTS(el1, neql1, ieql1, nal1, ial1, NONE(), _, _),
//          SCode.PARTS(el2, neql2, ieql2, nal2, ial2, NONE(), annl, cmt))
//      equation
//        // TODO: Handle duplicate elements!
//        el1 = listAppend(el1, el2);
//        neql1 = listAppend(neql1, neql2);
//        ieql1 = listAppend(ieql1, ieql2);
//        nal1 = listAppend(nal1, nal2);
//        ial1 = listAppend(ial1, ial2);
//      then
//        SCode.PARTS(el1, neql1, ieql1, nal1, ial2, NONE(), annl, cmt);
//
//    else
//      equation
//        Debug.fprintln("failtrace", "- SCodeFlatten.mergeClassDefs failed.");
//      then
//        fail();
//  end matchcontinue;
//end mergeClassDefs;
// 

end SCodeFlattenImports;