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

encapsulated package BackendEquation
" file:         BackendEquation.mo
  package:     BackendEquation
  description: BackendEquation contains functions that do something with
               BackendDAEEquation datatype.

  RCS: $Id$  
"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendVariable;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import Util;

public function getWhenEquationExpr
"function: getWhenEquationExpr
  Get the left and right hand parts from an equation appearing in a when clause"
  input BackendDAE.WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  (outComponentRef,outExp) := match (inWhenEquation)
    local DAE.ComponentRef cr; DAE.Exp e;
    case (BackendDAE.WHEN_EQ(left = cr,right = e)) then (cr,e);
  end match;
end getWhenEquationExpr;

public function getWhenCondition
"function: getWhenCodition
  Get expression's of condition by when equation"
  input list<BackendDAE.WhenClause> inWhenClause;
  input Integer inIndex;
  output list<DAE.Exp> conditionList;
algorithm
  conditionList := matchcontinue (inWhenClause, inIndex)
    local
      list<BackendDAE.WhenClause> wc;
      Integer ind;
      list<DAE.Exp> condlst;
      DAE.Exp e;
    case (wc, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=DAE.ARRAY(_,_,condlst)) = listNth(wc, ind);
      then condlst;
    case (wc, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=e) = listNth(wc, ind);
      then {e};
  end matchcontinue;
end getWhenCondition;

public function getZeroCrossingIndicesFromWhenClause "function: getZeroCrossingIndicesFromWhenClause
  Returns a list of indices of zerocrossings that a given when clause is dependent on.
"
  input BackendDAE.BackendDAE inBackendDAE;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inBackendDAE,inInteger)
    local
      list<BackendDAE.Value> res;
      list<BackendDAE.ZeroCrossing> zcLst;
      BackendDAE.Value when_index;
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst))),when_index)
      equation
        res = getZeroCrossingIndicesFromWhenClause2(zcLst, 0, when_index);
      then
        res;
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause;

protected function getZeroCrossingIndicesFromWhenClause2 "function: getZeroCrossingIndicesFromWhenClause2
  helper function to get_zero_crossing_indices_from_when_clause
"
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inZeroCrossingLst1,inInteger2,inInteger3)
    local
      BackendDAE.Value count_1,count,when_index;
      list<BackendDAE.Value> resx,whenClauseList;
      list<BackendDAE.ZeroCrossing> rest;
    case ({},_,_) then {};
    case ((BackendDAE.ZERO_CROSSING(occurWhenLst = whenClauseList) :: rest),count,when_index)
      equation
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        Util.if_(listMember(when_index, whenClauseList), count::resx, resx);
    else
      equation
        print("- BackendEquation.getZeroCrossingIndicesFromWhenClause2 failed\n");
      then
        fail();
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause2;

public function equationsLstVars
"function: equationsLstVars
  author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occuring variables form the array."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inVars1;
  output BackendDAE.Variables outVars;
algorithm
  (_,(_,outVars)) := traverseBackendDAEExpsEqnList(inEquationLst,checkEquationsVars,(inVars,inVars1));
end equationsLstVars;

public function equationsVars
"function: equationsVars
  author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occuring variables form the array."
  input BackendDAE.EquationArray inEquations;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
algorithm
  outVars := BackendDAEUtil.emptyVars();
  ((_,outVars)) := BackendDAEUtil.traverseBackendDAEExpsEqns(inEquations,checkEquationsVars,(inVars,outVars));
end equationsVars;

protected function checkEquationsVars
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case ((exp,(vars,vars1)))
      equation
         ((_,(_,vars1))) = Expression.traverseExp(exp,checkEquationsVarsExp,(vars,vars1));
       then
        ((exp,(vars,vars1)));
    case inTpl then inTpl;
  end matchcontinue;
end checkEquationsVars;

protected function checkEquationsVarsExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.ExpVar> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var var;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));
    
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.ET_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1)))
      equation
        expl = Util.listMap1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,vars1))) = Expression.traverseExpList(expl,checkEquationsVarsExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.ET_ARRAY(ty=_)),(vars,vars1)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,vars1))) = Expression.traverseExp(e1,checkEquationsVarsExp,(vars,vars1));
      then
        ((e, (vars,vars1)));
    
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.ET_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
      then
        ((e, (vars,vars1)));

    // already there
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (_,_) = BackendVariable.getVar(cr, vars1);
      then
        ((e, (vars,vars1)));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (var::_,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVar(var,vars1);
      then
        ((e, (vars,vars1)));
    
    case inTuple then inTuple;
  end matchcontinue;
end checkEquationsVarsExp;

public function equationsStates
"function: equationsStates
  author: Frenkel TUD
  From a list of equations return all
  occuring state variables references."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars; 
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_,(outExpComponentRefLst,_)) := traverseBackendDAEExpsEqnList(inEquationLst,extractStatesFromExp,({},inVars));
end equationsStates;

protected function extractStatesFromExp "function: extractStatesFromExp
  author: Frenkel TUD 2011-05
  helper for equationsCrefs"
 input tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> inTpl;
 output tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> outTpl;
algorithm 
  outTpl := match(inTpl)
    local 
      tuple<list<DAE.ComponentRef>,BackendDAE.Variables> arg,arg1;
      DAE.Exp e,e1;
    case((e,arg))
      equation
        ((e1,arg1)) = Expression.traverseExp(e, traversingStateRefFinder, arg);
      then
        ((e1,arg1));
  end match;
end extractStatesFromExp;

public function traversingStateRefFinder "
Author: Frenkel TUD 2011-05"
  input tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> inExp;
  output tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      BackendDAE.Variables vars;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef cr;
      DAE.Exp e;
    
    case((e as DAE.CREF(componentRef=cr), (crefs,vars)))
      equation
        true = BackendVariable.isState(cr,vars);
        crefs = Util.listUnionEltOnTrue(cr,crefs,ComponentReference.crefEqual);
      then
        ((e, (crefs,vars) ));
    
    case(inExp) then inExp;
    
  end matchcontinue;
end traversingStateRefFinder;

public function equationsCrefs
"function: equationsCrefs
  author: PA
  From a list of equations return all
  occuring variables/component references."
  input list<BackendDAE.Equation> inEquationLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_,outExpComponentRefLst) := traverseBackendDAEExpsEqnList(inEquationLst,extractCrefsFromExp,{});
end equationsCrefs;

public function getAllCrefFromEquations
  input BackendDAE.EquationArray inEqns;
  output list<DAE.ComponentRef> cr_lst;
algorithm
  cr_lst := traverseBackendDAEEqns(inEqns,traversingEquationCrefFinder,{});
end getAllCrefFromEquations;

protected function traversingEquationCrefFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Equation, list<DAE.ComponentRef>> inTpl;
 output tuple<BackendDAE.Equation, list<DAE.ComponentRef>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Equation e;
      list<DAE.ComponentRef> cr_lst,cr_lst1;
    case ((e,cr_lst))
      equation
        (_,cr_lst1) = traverseBackendDAEExpsEqn(e,extractCrefsFromExp,cr_lst);
      then ((e,cr_lst1));
    case inTpl then inTpl;
  end matchcontinue;
end traversingEquationCrefFinder;

protected function extractCrefsFromExp "function: extractCrefsFromExp
  author: Frenkel TUD 2010-11
  helper for equationsCrefs"
 input tuple<DAE.Exp, list<DAE.ComponentRef>> inTpl;
 output tuple<DAE.Exp, list<DAE.ComponentRef>> outTpl;
algorithm 
  outTpl := match(inTpl)
    local 
      list<DAE.ComponentRef> crefs,crefs1;
      DAE.Exp e,e1;
    case((e,crefs))
      equation
        ((e1,crefs1)) = Expression.traverseExp(e, Expression.traversingComponentRefFinder, crefs);
      then
        ((e1,crefs1));
  end match;
end extractCrefsFromExp;

public function traverseBackendDAEExpsEqnList"function: traverseBackendDAEExpsEqnList
  author: Frenkel TUD 2010-11
  traverse all expressions of a list of Equations. It is possible to change the equations"
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.Equation> outEquations;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquations,outTypeA) := match(inEquations,func,inTypeA)
  local 
       BackendDAE.Equation e,e1;
       list<BackendDAE.Equation> res,eqns;
       Type_a ext_arg_1,ext_arg_2;
    case({},func,inTypeA) then ({},inTypeA);
    case(e::res,func,inTypeA)
     equation
      (e1,ext_arg_1) = traverseBackendDAEExpsEqn(e,func,inTypeA);
      (eqns,ext_arg_2)  = traverseBackendDAEExpsEqnList(res,func,ext_arg_1);
    then 
      (e1::eqns,ext_arg_2);
    end match;
end traverseBackendDAEExpsEqnList;

public function traverseBackendDAEExpsEqn "function: traverseBackendDAEExpsEqn
  author: Frenkel TUD 2010-11
  traverse all expressions of a Equation. It is possible to change the equation"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outTypeA):= match (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,e_1,e_2;
      list<DAE.Exp> expl,expl1,exps,exps1;
      DAE.ExpType tp;
      DAE.ComponentRef cr,cr1;
      BackendDAE.WhenEquation elsePart,elsePart1;
      DAE.ElementSource source;
      Integer index;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.EQUATION(e_1,e_2,source),ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(index=index,crefOrDerCref = expl,source=source),func,inTypeA)
      equation
        (exps,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
      then
        (BackendDAE.ARRAY_EQUATION(index,exps,source),ext_arg_1);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e_2,source),ext_arg_2);
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source),ext_arg_1);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left = cr,right = e2,elsewhenPart=NONE()),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
       (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,NONE()),source),ext_arg_2);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left=cr,right=e2,elsewhenPart=SOME(elsePart)),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
        (BackendDAE.WHEN_EQUATION(whenEquation=elsePart1),ext_arg_3) = traverseBackendDAEExpsEqn(BackendDAE.WHEN_EQUATION(elsePart,source),func,ext_arg_2);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,SOME(elsePart1)),source),ext_arg_3);
    case (BackendDAE.ALGORITHM(index = index,in_ = expl,out = exps,source=source),func,inTypeA)
      equation
        (expl1,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
        (exps1,ext_arg_2) = traverseBackendDAEExpList(exps,func,ext_arg_1);
      then
        (BackendDAE.ALGORITHM(index,expl1,exps1,source),ext_arg_2);
    case (BackendDAE.COMPLEX_EQUATION(index = index, lhs = e1, rhs = e2,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.COMPLEX_EQUATION(index,e_1,e_2,source),ext_arg_2);
  end match;
end traverseBackendDAEExpsEqn;

public function traverseBackendDAEExpsEqnListOutEqn
"function: traverseBackendDAEExpsEqnList
  author: Frenkel TUD 2010-11
  traverse all expressions of a list of Equations. It is possible to change the equations"
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Equation> inlistchangedEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outchangedEquations;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquations,outchangedEquations,outTypeA) := matchcontinue(inEquations,inlistchangedEquations,func,inTypeA)
  local 
       BackendDAE.Equation e,e1;
       list<BackendDAE.Equation> res,eqns, changedeqns;
       Type_a ext_arg_1,ext_arg_2;
    case({},changedeqns,func,inTypeA) then ({},changedeqns,inTypeA);
    case(e::res,changedeqns,func,inTypeA)
     equation
      (e1,false,ext_arg_1) = traverseBackendDAEExpsEqnOutEqn(e,func,inTypeA);
      (eqns,changedeqns,ext_arg_2)  = traverseBackendDAEExpsEqnListOutEqn(res,changedeqns,func,ext_arg_1);
    then 
      (e1::eqns,changedeqns,ext_arg_2);
    case(e::res,changedeqns,func,inTypeA)
     equation
      (e1,true,ext_arg_1) = traverseBackendDAEExpsEqnOutEqn(e,func,inTypeA);
      changedeqns = listAppend(changedeqns,{e1});
      (eqns,changedeqns,ext_arg_2)  = traverseBackendDAEExpsEqnListOutEqn(res,changedeqns,func,ext_arg_1);
    then 
      (e1::eqns,changedeqns,ext_arg_2);
    end matchcontinue;
end traverseBackendDAEExpsEqnListOutEqn;

public function traverseBackendDAEExpsEqnOutEqn
 "function: traverseBackendDAEExpsEqnOutEqn
  copy of traverseBackendDAEExpsEqn
  author: Frenkel TUD 2010-11
  traverse all expressions of a Equation. It is possible to change the equation.
  additinal the equation is passed to FuncExpTyp.
  "
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output Boolean outflag;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outflag,outTypeA):= match (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,e_1,e_2;
      list<DAE.Exp> expl,exps;
      DAE.ExpType tp;
      DAE.ComponentRef cr,cr1;
      BackendDAE.WhenEquation elsePart,elsePart1;
      DAE.ElementSource source;
      Integer index;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      BackendDAE.Equation eq;
      Boolean b1,b2,b3,bres;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source),func,inTypeA)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.EQUATION(e_1,e_2,source),bres,ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(index=index,crefOrDerCref = expl,source=source),func,inTypeA)
      equation
        //(exps,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
      then
        (BackendDAE.ARRAY_EQUATION(index,expl,source),false,inTypeA);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e_2,source),bres,ext_arg_2);
    case (eq as BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source),func,inTypeA)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source),b1,ext_arg_1);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left = cr,right = e2,elsewhenPart=NONE()),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
       (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,NONE()),source),bres,ext_arg_2);
    case (eq as BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left=cr,right=e2,elsewhenPart=SOME(elsePart)),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        (BackendDAE.WHEN_EQUATION(whenEquation=elsePart1),b3,ext_arg_3) = traverseBackendDAEExpsEqnOutEqn(BackendDAE.WHEN_EQUATION(elsePart,source),func,ext_arg_2);
        bres = Util.boolOrList({b1,b2,b3});
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,SOME(elsePart1)),source),bres,ext_arg_3);
    case (BackendDAE.ALGORITHM(index = index,in_ = expl,out = exps,source=source),func,inTypeA)
      equation
        //(expl1,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
        //(exps1,ext_arg_2) = traverseBackendDAEExpList(exps,func,ext_arg_1);
      then
        (BackendDAE.ALGORITHM(index,expl,exps,source),false,inTypeA);
    case (BackendDAE.COMPLEX_EQUATION(index = index, lhs = e1, rhs = e2,source=source),func,inTypeA)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.COMPLEX_EQUATION(index,e_1,e_2,source),bres,ext_arg_2);
  end match;
end traverseBackendDAEExpsEqnOutEqn;

public function traverseBackendDAEExpList
"function traverseBackendDAEExps
 author Frenkel TUD:
 Calls user function for each element of list."
  replaceable type Type_a subtypeof Any;
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input Type_a ext_arg;
  output list<DAE.Exp> outExpl;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outExpl,outTypeA) := match(inExpl,rel,ext_arg)
  local 
      DAE.Exp e,e1;
      list<DAE.Exp> expl1,res;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    case({},_,ext_arg_1) then ({},ext_arg_1);
    case(e::res,rel,ext_arg_1) equation
      ((e1,ext_arg_2)) = rel((e, ext_arg_1));
      (expl1,ext_arg_3) = traverseBackendDAEExpList(res,rel,ext_arg_2);
    then (e1::expl1,ext_arg_3);
  end match;
end traverseBackendDAEExpList;

public function traverseBackendDAEEqns "function: traverseBackendDAEEqns
  author: Frenkel TUD

  traverses all equations of a BackendDAE.EquationArray.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA :=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      array<Option<BackendDAE.Equation>> equOptArr;
    case ((BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr)),func,inTypeA)
      then BackendDAEUtil.traverseBackendDAEArrayNoCopy(equOptArr,func,traverseBackendDAEOptEqn,1,arrayLength(equOptArr),inTypeA);
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendEquation.traverseBackendDAEEqns failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqns;

protected function traverseBackendDAEOptEqn "function: traverseBackendDAEOptEqn
  author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqns."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=  matchcontinue (inEquation,func,inTypeA)
    local
      BackendDAE.Equation eqn;
     Type_a ext_arg;
    case (NONE(),func,inTypeA) then inTypeA;
    case (SOME(eqn),func,inTypeA)
      equation
        ((_,ext_arg)) = func((eqn,inTypeA));
      then
        ext_arg;
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendEquation.traverseBackendDAEOptEqn failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEOptEqn;

public function traverseBackendDAEEqnsWithStop "function: traverseBackendDAEEqns
  author: Frenkel TUD

  traverses all equations of a BackendDAE.EquationArray.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA :=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      array<Option<BackendDAE.Equation>> equOptArr;
    case ((BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr)),func,inTypeA)
      then BackendDAEUtil.traverseBackendDAEArrayNoCopyWithStop(equOptArr,func,traverseBackendDAEOptEqnWithStop,1,arrayLength(equOptArr),inTypeA);
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendEquation.traverseBackendDAEEqnsWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqnsWithStop;

protected function traverseBackendDAEOptEqnWithStop "function: traverseBackendDAEOptEqnWithStop
  author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqnsWithStop."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outBoolean,outTypeA):=  matchcontinue (inEquation,func,inTypeA)
    local
      BackendDAE.Equation eqn;
     Type_a ext_arg;
     Boolean b;
    case (NONE(),func,inTypeA) then (true,inTypeA);
    case (SOME(eqn),func,inTypeA)
      equation
        ((_,b,ext_arg)) = func((eqn,inTypeA));
      then
        (b,ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendEquation.traverseBackendDAEOptEqnWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEOptEqnWithStop;

public function traverseBackendDAEEqnsWithUpdate "function: traverseBackendDAEEqnsWithUpdate
  author: Frenkel TUD

  traverses all equations of a BackendDAE.EquationArray.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.EquationArray outEquationArray;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquationArray,outTypeA) :=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      Integer numberOfElement, arrSize;
      array<Option<BackendDAE.Equation>> equOptArr;
      Type_a ext_arg;
    case ((BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfElement,arrSize=arrSize,equOptArr = equOptArr)),func,inTypeA)
      equation
        (equOptArr,ext_arg) = BackendDAEUtil.traverseBackendDAEArrayNoCopyWithUpdate(equOptArr,func,traverseBackendDAEOptEqnWithUpdate,1,arrayLength(equOptArr),inTypeA);
      then (BackendDAE.EQUATION_ARRAY(numberOfElement,arrSize,equOptArr),ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendEquation.traverseBackendDAEEqnsWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqnsWithUpdate;

protected function traverseBackendDAEOptEqnWithUpdate "function: traverseBackendDAEOptEqnWithUpdate
  author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqnsWithUpdate."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Option<BackendDAE.Equation> outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outTypeA):=  matchcontinue (inEquation,func,inTypeA)
    local
      Option<BackendDAE.Equation> oeqn;
      BackendDAE.Equation eqn,eqn1;
     Type_a ext_arg;
    case (oeqn as NONE(),func,inTypeA) then (oeqn,inTypeA);
    case (oeqn as SOME(eqn),func,inTypeA)
      equation
        ((eqn1,ext_arg)) = func((eqn,inTypeA));
        oeqn = Util.if_(referenceEq(eqn,eqn1),oeqn,SOME(eqn1));
      then
        (oeqn,ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendEquation.traverseBackendDAEOptEqnWithUpdate failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEOptEqnWithUpdate;

public function traverseBackendDAEExpsArrayEqnWithUpdate "function: traverseBackendDAEExpsArrayEqn
  author: Frenkel TUD

  It is possible to change the equation.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.MultiDimEquation outMultiDimEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outMultiDimEquation,outTypeA):=
  match (inMultiDimEquation,func,inTypeA)
    local 
      BackendDAE.MultiDimEquation meqn;
      DAE.Exp e1,e2,e1_1,e2_1;
      list<Integer> dims;
      DAE.ElementSource source;
      Type_a ext_arg_1,ext_arg_2;
    case (meqn as BackendDAE.MULTIDIM_EQUATION(dims,e1,e2,source),func,inTypeA)
      equation
        ((e1_1,ext_arg_1)) = func((e1,inTypeA));
        ((e2_1,ext_arg_2)) = func((e2,ext_arg_1));
        meqn = Util.if_(referenceEq(e1,e1_1) and referenceEq(e2,e2_1),meqn,BackendDAE.MULTIDIM_EQUATION(dims,e1_1,e2_1,source));
      then
        (meqn,ext_arg_2);
  end match;
end traverseBackendDAEExpsArrayEqnWithUpdate;

public function traverseBackendDAEExpsAlgortihmWithUpdate "function: traverseBackendDAEExpsAlgortihmWithUpdate
  author: Frenkel TUD

  It is possible to change the equation.
"
  replaceable type Type_a subtypeof Any;
  input DAE.Algorithm inAlg;
  input FuncExpType func;
  input Type_a inTypeA;
  output DAE.Algorithm outAlg;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outAlg,outTypeA):=
  match (inAlg,func,inTypeA)
    local 
      DAE.Algorithm alg;
      list<DAE.Statement> stmts,stmts1;
      Type_a ext_arg_1;
    case (alg as DAE.ALGORITHM_STMTS(stmts),func,inTypeA)
      equation
        (stmts1,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts,func,inTypeA);
        alg = Util.if_(referenceEq(stmts,stmts1),alg,DAE.ALGORITHM_STMTS(stmts));
      then
        (alg,ext_arg_1);
  end match;
end traverseBackendDAEExpsAlgortihmWithUpdate;

public function equationEqual "Returns true if two equations are equal"
  input BackendDAE.Equation e1;
  input BackendDAE.Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    local
      DAE.Exp e11,e12,e21,e22,exp1,exp2;
      Integer i1,i2;
      DAE.ComponentRef cr1,cr2;
    case (BackendDAE.EQUATION(exp = e11,scalar = e12),
          BackendDAE.EQUATION(exp = e21, scalar = e22))
      equation
        res = boolAnd(Expression.expEqual(e11,e21),Expression.expEqual(e12,e22));
      then res;

    case(BackendDAE.ARRAY_EQUATION(index = i1),
         BackendDAE.ARRAY_EQUATION(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case(BackendDAE.SOLVED_EQUATION(componentRef = cr1,exp = exp1),
         BackendDAE.SOLVED_EQUATION(componentRef = cr2,exp = exp2))
      equation
        res = boolAnd(ComponentReference.crefEqualNoStringCompare(cr1,cr2),Expression.expEqual(exp1,exp2));
      then res;

    case(BackendDAE.RESIDUAL_EQUATION(exp = exp1),
         BackendDAE.RESIDUAL_EQUATION(exp = exp2))
      equation
        res = Expression.expEqual(exp1,exp2);
      then res;

    case(BackendDAE.ALGORITHM(index = i1),
         BackendDAE.ALGORITHM(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i1)),
          BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i2)))
      equation
        res = intEq(i1,i2);
      then res;

    case(_,_) then false;

  end matchcontinue;
end equationEqual;

public function addEquations "function: addEquations
  author: wbraun
  Adds a list of BackendDAE.Equation to BackendDAE.EquationArray"
  input list<BackendDAE.Equation> eqnlst;
  input BackendDAE.EquationArray eqns;
  output BackendDAE.EquationArray eqns_1;
algorithm
  eqns_1 := Util.listFold(eqnlst, equationAdd, eqns);
end addEquations;

public function equationAdd "function: equationAdd
  author: PA

  Adds an equation to an EquationArray.
"
  input BackendDAE.Equation inEquation;
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquation,inEquationArray)
    local
      BackendDAE.Value n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<BackendDAE.Equation>> arr_1,arr,arr_2;
      BackendDAE.Equation e;
      Real rsize,rexpandsize;
    case (e,BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr))
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n_1, SOME(e));
      then
        BackendDAE.EQUATION_ARRAY(n_1,size,arr_1);
    case (e,BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr)) /* Do NOT Have space to add array elt. Expand array 1.4 times */
      equation
        (n < size) = false;
        rsize = intReal(size);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n_1, SOME(e));
      then
        BackendDAE.EQUATION_ARRAY(n_1,newsize,arr_2);
    case (e,BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr))
      equation
        print("- BackendEquation.equationAdd failed\n");
      then
        fail();
  end matchcontinue;
end equationAdd;

public function equationAddDAE
"function: equationAddDAE
  author: Frenkel TUD 2011-05"
  input BackendDAE.Equation inEquation;
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:=
  match (inEquation,inDAE)
    local
      BackendDAE.Variables ordvars,knvars,exobj;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Shared shared;
    case (inEquation,BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars,eqns,inieqns)::{},shared))
      equation
        eqns1 = equationAdd(inEquation,eqns);
      then BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars,eqns1,inieqns)::{},shared);
  end match;
end equationAddDAE;

public function equationSetnthDAE
"function: equationSetnthDAE
  author: Frenkel TUD 2011-04"
  input Integer inInteger;
  input BackendDAE.Equation inEquation;
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:=
  match (inInteger,inEquation,inDAE)
    local
      BackendDAE.Variables ordvars,knvars,exobj;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Shared shared;
    case (inInteger,inEquation,BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars,eqns,inieqns)::{},shared))
      equation
        eqns1 = equationSetnth(eqns,inInteger,inEquation);
      then BackendDAE.DAE(BackendDAE.EQSYSTEM(ordvars,eqns1,inieqns)::{},shared);
  end match;
end equationSetnthDAE;

public function equationSetnth "function: equationSetnth
  author: PA
  Sets the nth array element of an EquationArray."
  input BackendDAE.EquationArray inEquationArray;
  input Integer inInteger;
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := match (inEquationArray,inInteger,inEquation)
    local
      array<Option<BackendDAE.Equation>> arr_1,arr;
      BackendDAE.Value n,size,pos;
      BackendDAE.Equation eqn;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),pos,eqn)
      equation
        arr_1 = arrayUpdate(arr, pos + 1, SOME(eqn));
      then
        BackendDAE.EQUATION_ARRAY(n,size,arr_1);
  end match;
end equationSetnth;

public function getEqns "function: getEqns
  author: Frenkel TUD 2011-05
  retursn the equations given by the list of indexes"
  input list<BackendDAE.Value> inIndxes;
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEqns;
protected
  list<BackendDAE.Value> indxs;
algorithm
  indxs := Util.listMap1(inIndxes, intSub, 1);
  outEqns := Util.listMap1r(indxs, BackendDAEUtil.equationNth, inEquationArray);  
end getEqns;
  
public function equationDelete "function: equationDelete
  author: Frenkel TUD 2010-12
  Delets the equations from the list of Integers."
  input BackendDAE.EquationArray inEquationArray;
  input list<Integer> inIntLst;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := match (inEquationArray,inIntLst)
    local
      list<BackendDAE.Equation> eqnlst,eqnlst1;
    case (inEquationArray,{})
      then
        inEquationArray;
    case (inEquationArray,inIntLst)
      equation
        eqnlst = BackendDAEUtil.equationList(inEquationArray);
        eqnlst1 = Util.listDeletePositions(eqnlst,inIntLst);
        outEquationArray =  BackendDAEUtil.listEquation(eqnlst1);
      then
        outEquationArray;
  end match;   
end equationDelete;

public function equationToResidualForm "function: equationToResidualForm
  author: PA
  This function transforms an equation to its residual form.
  For instance, a=b is transformed to a-b=0"
  input BackendDAE.Equation inEquation;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation)
    local
      DAE.Exp e,e1,e2,exp;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      BackendDAE.Equation backendEq;
    
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
        //ExpressionDump.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source = source))
      equation
        //ExpressionDump.dumpExpWithTitle("equationToResidualForm 2\n",exp);
        e1 = Expression.crefExp(cr);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    
    case (backendEq as BackendDAE.RESIDUAL_EQUATION(exp = _,source = source)) then backendEq;
    
    case (backendEq as BackendDAE.ALGORITHM(index = _)) then backendEq;
    
    case (backendEq as BackendDAE.ARRAY_EQUATION(index = _)) then backendEq;
    
    case (backendEq as BackendDAE.WHEN_EQUATION(whenEquation = _)) then backendEq;
    
    case (backendEq)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.equationToResidualForm failed");
      then
        fail();
  end matchcontinue;
end equationToResidualForm;

public function equationToExp
  input tuple<BackendDAE.Equation, tuple<BackendDAE.Variables,array<BackendDAE.MultiDimEquation>,list<tuple<Integer,list<list<DAE.Subscript>>>>,list<DAE.Exp>,list<DAE.ElementSource>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.Variables,array<BackendDAE.MultiDimEquation>,list<tuple<Integer,list<list<DAE.Subscript>>>>,list<DAE.Exp>,list<DAE.ElementSource>>> outTpl;  
algorithm
  outTpl := matchcontinue inTpl
    local
      Integer   index;
      DAE.Exp e;
      DAE.Exp e1,e2,new_exp,new_exp1,rhs_exp,rhs_exp_1,rhs_exp_2;
      list<Integer> ds;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs;
      BackendDAE.Equation eqn;
      BackendDAE.Variables v;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst,entrylst1;
      list<DAE.Exp> explst;
      list<DAE.ElementSource> sources;
      DAE.ElementSource source;
      
    case ((eqn as BackendDAE.RESIDUAL_EQUATION(exp=e,source=source),(v, arrayEqs,entrylst,explst,sources)))
      equation
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(e, v);
        (rhs_exp_1,_) = ExpressionSimplify.simplify(rhs_exp);
      then ((eqn,(v, arrayEqs,entrylst,rhs_exp_1::explst,source::sources)));
        
    case ((eqn as BackendDAE.EQUATION(exp=e1, scalar=e2,source=source),(v, arrayEqs,entrylst,explst,sources)))
      equation
        new_exp = Expression.expSub(e1,e2);
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = Expression.negate(rhs_exp);
        (rhs_exp_2,_) = ExpressionSimplify.simplify(rhs_exp_1);
      then ((eqn,(v, arrayEqs,entrylst,rhs_exp_2::explst,source::sources)));
        
    case ((eqn as BackendDAE.ARRAY_EQUATION(index=index,source=source),(v, arrayEqs,entrylst,explst,sources)))
      equation
        BackendDAE.MULTIDIM_EQUATION(dimSize=ds,left=e1, right=e2) = arrayEqs[index+1];
        new_exp = Expression.expSub(e1,e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = BackendDAEUtil.getArrayEquationSub(index,ad,entrylst);
        new_exp1 = Expression.applyExpSubscripts(new_exp,subs);
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(new_exp1, v);
        rhs_exp_1 = Expression.negate(rhs_exp);
        (rhs_exp_2,_) = ExpressionSimplify.simplify(rhs_exp_1);
      then ((eqn,(v, arrayEqs,entrylst1,rhs_exp_2::explst,source::sources)));
        
    case ((eqn,_))
      equation
        BackendDump.dumpEqns({eqn});
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"dlowEqToExp failed"},equationInfo(eqn));
      then
        fail();
  end matchcontinue;
end equationToExp;

public function equationInfo "Retrieve the line number information from a BackendDAE.BackendDAE equation"
  input BackendDAE.Equation eq;
  output Absyn.Info info;
algorithm
  info := DAEUtil.getElementSourceFileInfo(equationSource(eq));
end equationInfo;

public function equationAlgorithm "Retrieve the true if input is algorithm equation"
  input BackendDAE.Equation eq;
  output Boolean out;
algorithm
  out := matchcontinue eq
    case BackendDAE.ALGORITHM(index=_) then true;
    case _ then false;
  end matchcontinue;
end equationAlgorithm;

public function getUsedAlgorithmsfromEquations
  input BackendDAE.EquationArray inEqns;
  input array<DAE.Algorithm> algarr;
  output list<DAE.Algorithm> algs;
algorithm
  ((_,_,algs)) := traverseBackendDAEEqns(inEqns,traverseAlgorithmFinder,({},algarr,{}));
end getUsedAlgorithmsfromEquations;

public function traverseAlgorithmFinder "function: traverseAlgorithmFinder
  author: Frenkel TUD 2010-12
  collect all used algorithms"
  input tuple<BackendDAE.Equation, tuple<list<Integer>,array<DAE.Algorithm>,list<DAE.Algorithm>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<list<Integer>,array<DAE.Algorithm>,list<DAE.Algorithm>>> outTpl;
algorithm
  outTpl := matchcontinue (inTpl)
    local
      BackendDAE.Equation eqn;
      array<DAE.Algorithm> algarr;
      DAE.Algorithm alg;
      list<DAE.Algorithm> algs;
      list<Integer> indexes;
      Integer indx;
      case ((eqn as BackendDAE.ALGORITHM(index=indx),(indexes,algarr,algs)))
        equation
          false = Util.listMemberWithCompareFunc(indx,indexes,intEq);
          alg = algarr[indx + 1];
        then
          ((eqn,(indx::indexes,algarr,alg::algs)));
    case (inTpl) then inTpl;
  end matchcontinue;
end traverseAlgorithmFinder;

public function markedEquationSource
  input BackendDAE.BackendDAE dae;
  input Integer i;
  output DAE.ElementSource source;
protected
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedEqs = eqns)::{}) := dae;
  source := equationSource(BackendDAEUtil.equationNth(eqns,i-1));
end markedEquationSource;

public function equationSource "Retrieve the source from a BackendDAE.BackendDAE equation"
  input BackendDAE.Equation eq;
  output DAE.ElementSource source;
algorithm
  source := match eq
    case BackendDAE.EQUATION(source=source) then source;
    case BackendDAE.ARRAY_EQUATION(source=source) then source;
    case BackendDAE.SOLVED_EQUATION(source=source) then source;
    case BackendDAE.RESIDUAL_EQUATION(source=source) then source;
    case BackendDAE.WHEN_EQUATION(source=source) then source;
    case BackendDAE.ALGORITHM(source=source) then source;
    case BackendDAE.COMPLEX_EQUATION(source=source) then source;
  end match;
end equationSource;

public function generateEQUATION "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inTpl;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := match(inTpl,Source)
  local
    DAE.Exp e1,e2;
    DAE.ElementSource source;
  case ((e1,e2),source) then BackendDAE.EQUATION(e1,e2,source);
 end match;
end generateEQUATION;

public function equationAlgorithmEqnsNr 
"Retrieve a list equation numbers for a given algorithm index"
  input list<BackendDAE.Equation> eqlst;
  input Integer index;
  input Integer count;
  output list<Integer> out;
algorithm
  out := matchcontinue (eqlst,index,count)
    local 
      BackendDAE.Equation e;
      list<BackendDAE.Equation> rest;
      Integer i, count_1;
      list<Integer> res;
    case ({},_,_) then {};
    case ((BackendDAE.ALGORITHM(index=i)::rest),index,count)
      equation
        true = (index == i);
        count_1 = count+1;
        //print("Equation e = "+& intString(count_1) +&" for algorithm index = "+& intString(index)+&" !\n");
        res = equationAlgorithmEqnsNr(rest,index,count_1);
      then (count_1::res);
    case (e::rest,index,count)
      equation
        count = count+1;
        res = equationAlgorithmEqnsNr(rest,index,count);
      then res;
  end matchcontinue;
end equationAlgorithmEqnsNr;


public function daeEqns
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns := match (inBackendDAE)
    local BackendDAE.EquationArray eqnarr;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedEqs = eqnarr)::{}))
      then eqnarr;
  end match;
end daeEqns;

public function daeArrayEqns
  input BackendDAE.BackendDAE inBackendDAE;
  output array<BackendDAE.MultiDimEquation> outEqns;
algorithm
  outEqns := match (inBackendDAE)
    local array<BackendDAE.MultiDimEquation> eqnarr;
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(arrayEqs = eqnarr)))
      then eqnarr;
  end match;
end daeArrayEqns;

public function aliasEquation
"function aliasEquation
  autor Frenkel TUD 2011-04
  Returns the two sides of an alias equation as expressions and cref.
  If the equation is not simple, this function will fail."
  input BackendDAE.Equation eqn;
  output DAE.ComponentRef cr1;
  output DAE.ComponentRef cr2;
  output DAE.Exp e1;
  output DAE.Exp e2;
  output Boolean negate;
algorithm
  (cr1,cr2,e1,e2,negate) := match (eqn)
      local
        DAE.Exp e,ne,ne1;
      // a = b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2,false);
      // a = -b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr2))))
        equation
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,true);
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr2))))
        equation
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,true);
      // -a = b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        equation
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        equation
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      // a + b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      // a - b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      // -a + b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      // -a - b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      // 0 = a + b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      // 0 = a - b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      // 0 = -a + b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      // 0 = -a - b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
  end match;
end aliasEquation;

public function derivativeEquation
"function derivativeEquation
  autor Frenkel TUD 2011-04
  Returns the two sides of an derivative equation as expressions and cref.
  If the equation is not a derivative equaiton, this function will fail."
  input BackendDAE.Equation eqn;
  output DAE.ComponentRef cr;
  output DAE.ComponentRef dcr "the derivative of cr";
  output DAE.Exp e;
  output DAE.Exp de "der(cr)";
  output Boolean negate;
algorithm
  (cr,dcr,e,de,negate) := match (eqn)
      local
        DAE.Exp e,ne,ne1;
      // a = der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr),scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})))
        then (cr,dcr,e,de,false);
      // der(a) = b;
      case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),scalar=e as DAE.CREF(componentRef = dcr)))
        then (cr,dcr,e,de,false);
      // a = -der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = cr),scalar=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = dcr)}))))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = cr),scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = dcr)}))))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      // -der(a) = b;
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.CREF(componentRef = dcr)))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.CREF(componentRef = dcr)))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      // -a = der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      // der(a) = -b;
      case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),scalar=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr))))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),scalar=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr))))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      // -a = -der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))))
        then (cr,dcr,e,de,false);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))))
        then (cr,dcr,e,de,false);     
      // -der(a) = -b;
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr))))
        then (cr,dcr,e,de,false);
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr))))
        then (cr,dcr,e,de,false);               
  end match;
end derivativeEquation;

end BackendEquation;
