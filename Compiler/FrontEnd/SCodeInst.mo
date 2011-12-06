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

encapsulated package SCodeInst
" file:        SCodeInst.mo
  package:     SCodeInst
  description: SCode instantiation

  RCS: $Id$

  Prototype SCode instantiation, enable with +d=scodeInst.
"

public import Absyn;
public import SCodeEnv;

protected import Dump;
protected import List;
protected import SCode;
protected import SCodeLookup;
protected import SCodeFlattenRedeclare;
protected import System;
protected import Util;

public type Env = SCodeEnv.Env;
protected type Item = SCodeEnv.Item;

protected type Prefix = list<tuple<String, Absyn.ArrayDim>>;

public function instClass
  "Flattens a class and prints out an estimate of how many variables there are."
  input Absyn.Path inClassPath;
  input Env inEnv;
protected
algorithm
  _ := match(inClassPath, inEnv)
    local
      Item item;
      Absyn.Path path;
      Env env; 
      String name;
      Integer var_count;

    case (_, _)
      equation
        System.startTimer();
        name = Absyn.pathLastIdent(inClassPath);
        print("class " +& name +& "\n");
        (item, path, env) = 
          SCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
        var_count = instClassItem(item, env, {});
        print("end " +& name +& ";\n");
        System.stopTimer();
        print("SCodeInst took " +& realString(System.getTimerIntervalTime()) +&
          " seconds.\n");
        print("Found at least " +& intString(var_count) +& " variables.\n");
      then
        ();

  end match;
end instClass;

protected function instClassItem
  input Item inItem;
  input Env inEnv;
  input Prefix inPrefix;
  output Integer outVarCount;
algorithm
  outVarCount := match(inItem, inEnv, inPrefix)
    local
      list<SCode.Element> el;
      list<Integer> var_counts;
      Integer var_count;
      Absyn.TypeSpec ty;
      Item item;
      Env env;
      Absyn.Info info;
      SCodeEnv.AvlTree cls_and_vars;

    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef = SCode.PARTS(elementLst = el)), 
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _)
      equation
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        el = List.map1(el, lookupElement, cls_and_vars);
        var_counts = List.map2(el, instElement, env, inPrefix);
        // Add a 0 so we have something to reduce if the class is empty.
        var_counts = 0 :: var_counts;
        var_count = List.reduce(var_counts, intAdd);
      then
        var_count;

    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.DERIVED(typeSpec = ty), info = info)), _, _)
      equation
        (item, env) = SCodeLookup.lookupTypeSpec(ty, inEnv, info);
      then
        instClassItem(item, env, inPrefix);

    else 0;
  end match;
end instClassItem;

protected function lookupElement
  "This functions might seem a little odd, why look up elements in the
   environment when we already have them? This is because they might have been
   redeclared, and redeclares are only applied to the environment and not the
   SCode itself. So we need to look them up in the environment to make sure we
   have the right elements."
  input SCode.Element inElement;
  input SCodeEnv.AvlTree inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    local
      String name;
      SCode.Element el;

    case (SCode.COMPONENT(name = name), _)
      equation
        SCodeEnv.VAR(var = el) = SCodeEnv.avlTreeGet(inEnv, name);
      then
        el;

    // Only components need to be looked up. Extends are not allowed to be
    // redeclared, while classes are not instantiated by instElement.
    else inElement;
  end match;
end lookupElement;
        
protected function instElement
  input SCode.Element inVar;
  input Env inEnv;
  input Prefix inPrefix;
  output Integer outVarCount;
algorithm
  outVarCount := match(inVar, inEnv, inPrefix)
    local
      String name;
      Absyn.TypeSpec ty;
      Absyn.Info info;
      Item item;
      Env env;
      Absyn.Path path;
      Absyn.ArrayDim ad;
      Prefix prefix;
      Integer var_count, dim_count;
      SCode.Mod mod;
      list<SCodeEnv.Redeclaration> redecls;
      SCodeEnv.ExtendsTable exts;

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
            typeSpec = Absyn.TPATH(path = path), modifications = mod, info = info), _, _)
      equation
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        // Apply the redeclarations.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(mod, inEnv);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        prefix = (name, ad) :: inPrefix;
        var_count = instClassItem(item, env, prefix);
        // Print the variable if it's a basic type.
        printVar(prefix, path, var_count);
        dim_count = countVarDims(ad);

        // Set var_count to one if it's zero, since it counts as an element by
        // itself if it doesn't contain any components.
        var_count = intMax(1, var_count);
      then
        var_count * dim_count;

    // An extends, look up the extended class and instantiate it.
    case (SCode.EXTENDS(baseClassPath = path, modifications = mod, info = info),
        SCodeEnv.FRAME(extendsTable = exts) :: _, _)
      equation
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        path = SCodeEnv.mergePathWithEnvPath(path, env);
        // Apply the redeclarations.
        redecls = SCodeFlattenRedeclare.lookupExtendsRedeclaresInTable(path, exts);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        var_count = instClassItem(item, env, inPrefix);
      then
        var_count;
        
    else 0;
  end match;
end instElement;

protected function printVar
  input Prefix inName;
  input Absyn.Path inClassPath;
  input Integer inVarCount;
algorithm
  _ := match(inName, inClassPath, inVarCount)
    local
      String name, cls;

    // Only print the variable if it doesn't contain any components, i.e. if
    // it's of basic type. This needs to be better checked, since some models
    // might be empty.
    case (_, _, 0)
      equation
        cls = Absyn.pathString(inClassPath);
        name = printPrefix(inName);
        print("  " +& cls +& " " +& name +& ";\n");
      then
        ();

    else ();
  end match;
end printVar;

protected function printPrefix
  input Prefix inPrefix;
  output String outString;
algorithm
  outString := match(inPrefix)
    local
      String id;
      Absyn.ArrayDim dims;
      Prefix rest_pre;

    case {} then "";
    case {(id, dims)} then id +& Dump.printArraydimStr(dims);
    case ((id, dims) :: rest_pre)
      then printPrefix(rest_pre) +& "." +& id +& Dump.printArraydimStr(dims);

  end match;
end printPrefix;

protected function countVarDims
  "Make an attempt at counting the number of components a variable contains."
  input Absyn.ArrayDim inDims;
  output Integer outVarCount;
algorithm
  outVarCount := match(inDims)
    local
      Integer int_dim;
      Absyn.ArrayDim rest_dims;

    // A scalar.
    case ({}) then 1;
    // An array with constant integer subscript.
    case (Absyn.SUBSCRIPT(subscript = Absyn.INTEGER(int_dim)) :: rest_dims)
      then int_dim * countVarDims(rest_dims);
    // Skip everything else for now, were only estimating how many variables
    // there are.
    case (_ :: rest_dims)
      then countVarDims(rest_dims);

  end match;
end countVarDims;
      
end SCodeInst;
