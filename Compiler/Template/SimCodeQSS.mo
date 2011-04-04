encapsulated package SimCodeQSS

public import Tpl;

public import SimCode;
public import BackendDAE;
public import System;
public import Absyn;
public import DAE;
public import ClassInf;
public import SCode;
public import Util;
public import ComponentReference;
public import Expression;
public import ExpressionDump;
public import RTOpts;
public import Settings;
public import Patternm;
public import Error;
public import Values;
public import ValuesUtil;
public import BackendQSS;
public import DAEDump;
protected import SimCodeC;

protected function fun_22
  input Tpl.Text in_txt;
  input Option<SimCode.SimulationSettings> in_a_simulationSettingsOpt;
  input String in_a_fileNamePrefix;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simulationSettingsOpt, in_a_fileNamePrefix, in_a_simCode)
    local
      Tpl.Text txt;
      String a_fileNamePrefix;
      SimCode.SimCode a_simCode;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           NONE(),
           _,
           _ )
      then txt;

    case ( txt,
           _,
           a_fileNamePrefix,
           a_simCode )
      equation
        txt_0 = SimCodeC.simulationInitFile(Tpl.emptyTxt, a_simCode);
        txt_1 = Tpl.writeStr(Tpl.emptyTxt, a_fileNamePrefix);
        txt_1 = Tpl.writeTok(txt_1, Tpl.ST_STRING("_init.txt"));
        Tpl.textFile(txt_0, Tpl.textString(txt_1));
      then txt;
  end matchcontinue;
end fun_22;

public function translateModel
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode)
    local
      Tpl.Text txt;
      Option<SimCode.SimulationSettings> i_simulationSettingsOpt;
      list<DAE.Exp> i_literals;
      list<SimCode.RecordDeclaration> i_recordDecls;
      list<SimCode.Function> i_modelInfo_functions;
      String i_fileNamePrefix;
      SimCode.SimCode i_simCode;
      Tpl.Text txt_10;
      Tpl.Text txt_9;
      Tpl.Text txt_8;
      Tpl.Text txt_7;
      Tpl.Text txt_6;
      Tpl.Text txt_5;
      Tpl.Text txt_4;
      Tpl.Text txt_3;
      Tpl.Text txt_2;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(functions = i_modelInfo_functions), fileNamePrefix = i_fileNamePrefix, recordDecls = i_recordDecls, literals = i_literals, simulationSettingsOpt = i_simulationSettingsOpt)) )
      equation
        txt_0 = simulationFile(Tpl.emptyTxt, i_simCode);
        txt_1 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_1 = Tpl.writeTok(txt_1, Tpl.ST_STRING(".cpp"));
        Tpl.textFile(txt_0, Tpl.textString(txt_1));
        txt_2 = SimCodeC.simulationFunctionsHeaderFile(Tpl.emptyTxt, i_fileNamePrefix, i_modelInfo_functions, i_recordDecls);
        txt_3 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_3 = Tpl.writeTok(txt_3, Tpl.ST_STRING("_functions.h"));
        Tpl.textFile(txt_2, Tpl.textString(txt_3));
        txt_4 = SimCodeC.simulationFunctionsFile(Tpl.emptyTxt, i_fileNamePrefix, i_modelInfo_functions, i_literals);
        txt_5 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_5 = Tpl.writeTok(txt_5, Tpl.ST_STRING("_functions.cpp"));
        Tpl.textFile(txt_4, Tpl.textString(txt_5));
        txt_6 = SimCodeC.recordsFile(Tpl.emptyTxt, i_fileNamePrefix, i_recordDecls);
        txt_7 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_7 = Tpl.writeTok(txt_7, Tpl.ST_STRING("_records.c"));
        Tpl.textFile(txt_6, Tpl.textString(txt_7));
        txt_8 = SimCodeC.simulationMakefile(Tpl.emptyTxt, i_simCode);
        txt_9 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_9 = Tpl.writeTok(txt_9, Tpl.ST_STRING(".makefile"));
        Tpl.textFile(txt_8, Tpl.textString(txt_9));
        txt_10 = structureFile(Tpl.emptyTxt, i_simCode);
        Tpl.textFile(txt_10, "modelica_struct.pds");
        txt = fun_22(txt, i_simulationSettingsOpt, i_fileNamePrefix, i_simCode);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateModel;

public function simulationFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode)
    local
      Tpl.Text txt;
      list<DAE.Statement> i_algorithmAndEquationAsserts;
      list<DAE.ComponentRef> i_discreteModelVars;
      list<SimCode.SimEqSystem> i_removedEquations;
      list<SimCode.SimEqSystem> i_algebraicEquations;
      list<SimCode.SimEqSystem> i_parameterEquations;
      list<SimCode.SimEqSystem> i_residualEquations;
      list<SimCode.SimEqSystem> i_initialEquations;
      SimCode.DelayedExpression i_delayedExps;
      list<SimCode.SimEqSystem> i_sampleEquations;
      list<SimCode.SampleCondition> i_sampleConditions;
      SimCode.ExtObjInfo i_extObjInfo;
      list<SimCode.SimEqSystem> i_allEquations;
      list<SimCode.JacobianMatrix> i_JacobianMatrixes;
      list<SimCode.HelpVarInfo> i_helpVarInfo;
      list<SimCode.SimWhenClause> i_whenClauses;
      list<BackendDAE.ZeroCrossing> i_zeroCrossings;
      list<SimCode.SimEqSystem> i_odeEquations;
      Integer i_modelInfo_varInfo_numZeroCrossings;
      String i_fileNamePrefix;
      SimCode.ModelInfo i_modelInfo;
      list<String> i_externalFunctionIncludes;
      SimCode.SimCode i_simCode;
      list<SimCode.SimEqSystem> ret_2;
      list<SimCode.SimEqSystem> ret_1;
      list<SimCode.SimWhenClause> ret_0;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = (i_modelInfo as SimCode.MODELINFO(varInfo = SimCode.VARINFO(numZeroCrossings = i_modelInfo_varInfo_numZeroCrossings))), externalFunctionIncludes = i_externalFunctionIncludes, fileNamePrefix = i_fileNamePrefix, odeEquations = i_odeEquations, zeroCrossings = i_zeroCrossings, whenClauses = i_whenClauses, helpVarInfo = i_helpVarInfo, JacobianMatrixes = i_JacobianMatrixes, allEquations = i_allEquations, extObjInfo = i_extObjInfo, sampleConditions = i_sampleConditions, sampleEquations = i_sampleEquations, delayedExps = i_delayedExps, initialEquations = i_initialEquations, residualEquations = i_residualEquations, parameterEquations = i_parameterEquations, algebraicEquations = i_algebraicEquations, removedEquations = i_removedEquations, discreteModelVars = i_discreteModelVars, algorithmAndEquationAsserts = i_algorithmAndEquationAsserts)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.simulationFileHeader(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.externalFunctionIncludes(txt, i_externalFunctionIncludes);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "#ifdef _OMC_MEASURE_TIME\n",
                                    "int measure_time_flag = 1;\n",
                                    "#else\n",
                                    "int measure_time_flag = 0;\n",
                                    "#endif\n",
                                    "\n"
                                }, true));
        txt = SimCodeC.globalData(txt, i_modelInfo, i_fileNamePrefix);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "// fbergero, xfloros: Code for QSS methods\n",
                                    "#ifdef _OMC_QSS\n",
                                    "\n",
                                    "bool cond["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_modelInfo_varInfo_numZeroCrossings));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "];\n",
                                    "\n",
                                    "void set_condition_to(unsigned int c, bool b) { cond[c]=b; }\n",
                                    "bool condition(unsigned int c) { return cond[c]; }\n",
                                    "\n",
                                    "//for QSS solver\n",
                                    "double rel_accuracy = 1e-5;\n",
                                    "double abs_accuracy = 1e-5;\n",
                                    "char* method = \"QSS3\";\n",
                                    "\n",
                                    "double state_values(int state)\n",
                                    "{\n",
                                    "  return 0.0;\n",
                                    "}\n",
                                    "\n",
                                    "double quantum_values(int state)\n",
                                    "{\n",
                                    "  return 0.0;\n",
                                    "}\n",
                                    "\n",
                                    "// integration method\n",
                                    "char* int_method() {\n",
                                    "  return method;\n",
                                    "}\n",
                                    "\n",
                                    "// settings\n",
                                    "double function_rel_acc() {\n",
                                    "  return rel_accuracy;\n",
                                    "}\n",
                                    "\n",
                                    "double function_abs_acc() {\n",
                                    "  return abs_accuracy;\n",
                                    "}\n",
                                    "\n",
                                    "\n"
                                }, true));
        txt = functionQssStaticBlocks(txt, i_odeEquations, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        ret_0 = BackendQSS.replaceCondWhens(i_whenClauses, i_helpVarInfo, i_zeroCrossings);
        txt = functionQssWhen(txt, ret_0, i_helpVarInfo, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionQssSample(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionQssUpdateDiscrete(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#endif\n",
                                    "\n"
                                }, true));
        ret_1 = SimCode.appendAllequation(i_JacobianMatrixes);
        ret_2 = SimCode.appendLists(ret_1, i_allEquations);
        txt = SimCodeC.equationInfo(txt, ret_2);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionGetName(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionSetLocalData(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionInitializeDataStruc(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionCallExternalObjectConstructors(txt, i_extObjInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionDeInitializeDataStruc(txt, i_extObjInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionExtraResiduals(txt, i_allEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionInput(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionOutput(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionInitSample(txt, i_sampleConditions);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionSampleEquations(txt, i_sampleEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionStoreDelayed(txt, i_delayedExps);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionInitial(txt, i_initialEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionInitialResidual(txt, i_residualEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionBoundParameters(txt, i_parameterEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionODE(txt, i_odeEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionODE_residual(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionAlgebraic(txt, i_algebraicEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionAliasEquation(txt, i_removedEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionDAE(txt, i_allEquations, i_whenClauses, i_helpVarInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionOnlyZeroCrossing(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionCheckForDiscreteChanges(txt, i_discreteModelVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionAssertsforCheck(txt, i_algorithmAndEquationAsserts);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.generateLinearMatrixes(txt, i_JacobianMatrixes);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = SimCodeC.functionlinearmodel(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationFile;

protected function fun_25
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;
  input Tpl.Text in_a_connections;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode, in_a_connections)
    local
      Tpl.Text txt;
      Tpl.Text a_connections;
      list<SimCode.HelpVarInfo> i_helpVarInfo;
      list<SimCode.SimWhenClause> i_whenClauses;
      list<BackendDAE.ZeroCrossing> i_zeroCrossings;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(varInfo = SimCode.VARINFO(numHelpVars = _)), zeroCrossings = i_zeroCrossings, whenClauses = i_whenClauses, helpVarInfo = i_helpVarInfo),
           a_connections )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "Root-Coordinator\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = generateIntegrators(txt);
        txt = Tpl.softNewLine(txt);
        txt = generateStaticBlocks(txt);
        txt = Tpl.softNewLine(txt);
        txt = generateZeroCrossingFunctions(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = generateCrossingDetectors(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = generateWhenBlocks(txt, i_whenClauses, i_helpVarInfo);
        txt = Tpl.softNewLine(txt);
        txt = generateSampleBlocks(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "Simulator\n",
                                    "  {\n",
                                    "    Path = modelica/outvars.h\n",
                                    "    Parameters = 1.0\n",
                                    "  }\n",
                                    "EIC\n",
                                    "  {\n",
                                    "  }\n",
                                    "EIC\n",
                                    "  {\n",
                                    "  }\n",
                                    "IC\n",
                                    "  {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.writeText(txt, a_connections);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("  }\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_25;

public function structureFile
  input Tpl.Text txt;
  input SimCode.SimCode a_simCode;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_connections;
  Tpl.Text l_models;
algorithm
  l_models := Tpl.emptyTxt;
  l_connections := generateConnections(Tpl.emptyTxt);
  out_txt := fun_25(txt, a_simCode, l_connections);
end structureFile;

public function functionQssSample
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_sampleCode;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  (l_sampleCode, l_varDecls) := functionQssSample2(Tpl.emptyTxt, a_zeroCrossings, l_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "void functionQssSample(unsigned int sampleIndex, double *out)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "mem_state = get_memory_state();\n",
                                       "switch (sampleIndex)\n",
                                       "{\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_sampleCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "restore_memory_state(mem_state);\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionQssSample;

protected function lm_28
  input Tpl.Text in_txt;
  input list<BackendDAE.ZeroCrossing> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.ZeroCrossing> rest;
      Tpl.Text a_varDecls;
      Integer x_i0;
      DAE.Exp i_interval;
      DAE.Exp i_start;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval})) :: rest,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls) = functionQssSample3(txt, x_i0, i_start, i_interval, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_28(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_28(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_28;

public function functionQssSample2
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls) := lm_28(out_txt, a_zeroCrossings, a_varDecls);
  out_txt := Tpl.popIter(out_txt);
end functionQssSample2;

public function functionQssSample3
  input Tpl.Text txt;
  input Integer a_index1;
  input DAE.Exp a_start;
  input DAE.Exp a_interval;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_e2;
  Tpl.Text l_e1;
  Tpl.Text l_preExp;
algorithm
  l_preExp := Tpl.emptyTxt;
  (l_e1, l_preExp, out_a_varDecls) := SimCodeC.daeExp(Tpl.emptyTxt, a_start, SimCode.contextOther, l_preExp, a_varDecls);
  (l_e2, l_preExp, out_a_varDecls) := SimCodeC.daeExp(Tpl.emptyTxt, a_interval, SimCode.contextOther, l_preExp, out_a_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("case "));
  out_txt := Tpl.writeStr(out_txt, intString(a_index1));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(":\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_preExp);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("out[0] = "));
  out_txt := Tpl.writeText(out_txt, l_e1);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "out[1] = "
                                   }, false));
  out_txt := Tpl.writeText(out_txt, l_e2);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "break;"
                                   }, false));
  out_txt := Tpl.popBlock(out_txt);
end functionQssSample3;

public function functionQssWhen
  input Tpl.Text txt;
  input list<SimCode.SimWhenClause> a_whenClauses;
  input list<SimCode.HelpVarInfo> a_helpVars;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_whenCases;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  (l_whenCases, l_varDecls) := functionQssWhen2(Tpl.emptyTxt, a_whenClauses, a_helpVars, l_varDecls, a_zeroCrossings);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "bool functionQssWhen(unsigned int whenIndex, double *out, double *in)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "mem_state = get_memory_state();\n",
                                       "switch (whenIndex)\n",
                                       "{\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(3));
  out_txt := Tpl.writeText(out_txt, l_whenCases);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "restore_memory_state(mem_state);\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionQssWhen;

protected function lm_32
  input Tpl.Text in_txt;
  input list<SimCode.SimWhenClause> in_items;
  input list<BackendDAE.ZeroCrossing> in_a_zeroCrossings;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_zeroCrossings, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimWhenClause> rest;
      list<BackendDAE.ZeroCrossing> a_zeroCrossings;
      Tpl.Text a_varDecls;
      Integer x_i0;
      Option<BackendDAE.WhenEquation> i_whenEq;
      list<BackendDAE.WhenOperator> i_reinits;
      list<tuple<DAE.Exp, Integer>> i_conditions;
      Tpl.Text l_equations;
      Tpl.Text l_cond;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           _,
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           SimCode.SIM_WHEN_CLAUSE(conditions = i_conditions, reinits = i_reinits, whenEq = i_whenEq) :: rest,
           a_zeroCrossings,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        l_preExp = Tpl.emptyTxt;
        (l_cond, a_varDecls, l_preExp) = functionPreWhenCondition(Tpl.emptyTxt, i_conditions, a_varDecls, l_preExp, a_zeroCrossings);
        (l_equations, a_varDecls) = generateWhenEquations(Tpl.emptyTxt, i_reinits, i_whenEq, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ":\n",
                                    "  #ifdef _OMC_OMPD\n",
                                    "  #endif\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, l_cond);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_equations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "} else {\n",
                                    "}\n",
                                    "#ifdef _OMC_OMPD\n",
                                    "#endif\n",
                                    "break;"
                                }, false));
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_32(txt, rest, a_zeroCrossings, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_zeroCrossings,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_32(txt, rest, a_zeroCrossings, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_32;

public function functionQssWhen2
  input Tpl.Text txt;
  input list<SimCode.SimWhenClause> a_whenClauses;
  input list<SimCode.HelpVarInfo> a_helpVars;
  input Tpl.Text a_varDecls;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls) := lm_32(out_txt, a_whenClauses, a_zeroCrossings, a_varDecls);
  out_txt := Tpl.popIter(out_txt);
end functionQssWhen2;

protected function fun_34
  input Tpl.Text in_txt;
  input Option<BackendDAE.WhenEquation> in_a_whenEq;
  input list<BackendDAE.WhenOperator> in_a_reinits;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_whenEq, in_a_reinits, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.WhenOperator> a_reinits;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_left;
      DAE.Exp i_right;
      Tpl.Text l_exp;
      Tpl.Text l_preExp;

    case ( txt,
           SOME(BackendDAE.WHEN_EQ(right = i_right, left = i_left)),
           a_reinits,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_exp, l_preExp, a_varDecls) = SimCodeC.daeExp(Tpl.emptyTxt, i_right, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = SimCodeC.cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  = "));
        txt = Tpl.writeText(txt, l_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        (txt, a_varDecls) = generateReinits(txt, a_reinits, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           NONE(),
           a_reinits,
           a_varDecls )
      equation
        (txt, a_varDecls) = generateReinits(txt, a_reinits, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_34;

public function generateWhenEquations
  input Tpl.Text txt;
  input list<BackendDAE.WhenOperator> a_reinits;
  input Option<BackendDAE.WhenEquation> a_whenEq;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) := fun_34(txt, a_whenEq, a_reinits, a_varDecls);
end generateWhenEquations;

protected function lm_36
  input Tpl.Text in_txt;
  input list<BackendDAE.WhenOperator> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.WhenOperator> rest;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_stateVar;
      DAE.Exp i_value;
      Tpl.Text l_val;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.REINIT(stateVar = i_stateVar, value = i_value) :: rest,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_val, l_preExp, a_varDecls) = SimCodeC.daeExp(Tpl.emptyTxt, i_value, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = SimCodeC.cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_val);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; // Reinit of var "));
        txt = SimCodeC.cref(txt, i_stateVar);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_36(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_36(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_36;

public function generateReinits
  input Tpl.Text txt;
  input list<BackendDAE.WhenOperator> a_reinits;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls) := lm_36(out_txt, a_reinits, a_varDecls);
  out_txt := Tpl.popIter(out_txt);
end generateReinits;

protected function fun_38
  input Tpl.Text in_txt;
  input DAE.Exp in_a_e;
  input Integer in_a_hvar;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_e, in_a_hvar, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      Integer a_hvar;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp i_e;
      Integer i_i;
      Tpl.Text l_helpInit;

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "samplecondition"), expLst = {DAE.ICONST(integer = i_i)}),
           _,
           a_varDecls,
           a_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("condition("));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_e,
           a_hvar,
           a_varDecls,
           a_preExp )
      equation
        (l_helpInit, a_preExp, a_varDecls) = SimCodeC.daeExp(Tpl.emptyTxt, i_e, SimCode.contextSimulationDiscrete, a_preExp, a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("localData->helpVars["));
        a_preExp = Tpl.writeStr(a_preExp, intString(a_hvar));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("] = "));
        a_preExp = Tpl.writeText(a_preExp, l_helpInit);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING_LIST({
                                              ";\n",
                                              "\n"
                                          }, true));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(a_hvar));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_38;

protected function lm_39
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Integer>> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<tuple<DAE.Exp, Integer>> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Integer i_hvar;
      DAE.Exp i_e;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           (i_e, i_hvar) :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = fun_38(txt, i_e, i_hvar, a_varDecls, a_preExp);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_39(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_39(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_39;

public function functionPreWhenCondition
  input Tpl.Text txt;
  input list<tuple<DAE.Exp, Integer>> a_conditions;
  input Tpl.Text a_varDecls;
  input Tpl.Text a_preExp;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls, out_a_preExp) := lm_39(out_txt, a_conditions, a_varDecls, a_preExp);
  out_txt := Tpl.popIter(out_txt);
end functionPreWhenCondition;

public function functionQssStaticBlocks
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_derivativEquations;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_staticFun;
  Integer ret_2;
  Tpl.Text l_zeroCross;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  ret_2 := listLength(a_derivativEquations);
  (l_zeroCross, l_varDecls) := generateZeroCrossingsEq(Tpl.emptyTxt, ret_2, a_zeroCrossings, l_varDecls);
  (l_staticFun, l_varDecls) := generateStaticFunc(Tpl.emptyTxt, a_derivativEquations, a_zeroCrossings, l_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "void functionQssStaticBlocks(int staticFunctionIndex, double t, double *in, double *out)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "mem_state = get_memory_state();\n",
                                       "switch (staticFunctionIndex)\n",
                                       "{\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_staticFun);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_zeroCross);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "restore_memory_state(mem_state);\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionQssStaticBlocks;

protected function fun_42
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input Tpl.Text in_a_varDecls;
  input list<BackendDAE.ZeroCrossing> in_a_zeroCrossings;
  input Integer in_a_i0;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_varDecls, in_a_zeroCrossings, in_a_i0)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      list<BackendDAE.ZeroCrossing> a_zeroCrossings;
      Integer a_i0;
      SimCode.SimEqSystem i_eq;
      SimCode.SimEqSystem ret_0;

    case ( txt,
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)),
           a_varDecls,
           a_zeroCrossings,
           a_i0 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "case "
                                }, false));
        txt = Tpl.writeStr(txt, intString(a_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ":\n",
                                    "  // Read inputs from in[]\n",
                                    "  #ifdef _OMC_OMPD\n",
                                    "  #endif\n",
                                    "\n",
                                    "  // Evalute the static function\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        ret_0 = BackendQSS.replaceZC(i_eq, a_zeroCrossings);
        (txt, a_varDecls) = SimCodeC.equation_(txt, ret_0, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "// Write outputs to out[]\n",
                                    "#ifdef _OMC_OMPD\n",
                                    "#endif\n",
                                    "break;"
                                }, false));
        txt = Tpl.popBlock(txt);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls,
           _,
           _ )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_42;

protected function lm_43
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;
  input list<BackendDAE.ZeroCrossing> in_a_zeroCrossings;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_zeroCrossings)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      list<BackendDAE.ZeroCrossing> a_zeroCrossings;
      Integer x_i0;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls,
           a_zeroCrossings )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls) = fun_42(txt, i_eq, a_varDecls, a_zeroCrossings, x_i0);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_43(txt, rest, a_varDecls, a_zeroCrossings);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_zeroCrossings )
      equation
        (txt, a_varDecls) = lm_43(txt, rest, a_varDecls, a_zeroCrossings);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_43;

public function generateStaticFunc
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_odeEq;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls) := lm_43(out_txt, a_odeEq, a_varDecls, a_zeroCrossings);
  out_txt := Tpl.popIter(out_txt);
end generateStaticFunc;

protected function fun_45
  input Tpl.Text in_txt;
  input DAE.Exp in_a_relation__;
  input Tpl.Text in_a_zcExp;
  input Tpl.Text in_a_preExp;
  input Integer in_a_offset;
  input Integer in_a_i0;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_relation__, in_a_zcExp, in_a_preExp, in_a_offset, in_a_i0)
    local
      Tpl.Text txt;
      Tpl.Text a_zcExp;
      Tpl.Text a_preExp;
      Integer a_offset;
      Integer a_i0;
      Integer ret_1;
      Integer ret_0;

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "sample")),
           _,
           _,
           a_offset,
           a_i0 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "case "
                                }, false));
        ret_0 = intAdd(a_i0, a_offset);
        txt = Tpl.writeStr(txt, intString(ret_0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ":\n",
                                    "  // This zero crossing is a sample. This case should not be called\n",
                                    "  break;"
                                }, false));
      then txt;

    case ( txt,
           _,
           a_zcExp,
           a_preExp,
           a_offset,
           a_i0 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "case "
                                }, false));
        ret_1 = intAdd(a_i0, a_offset);
        txt = Tpl.writeStr(txt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ":\n",
                                    "  #ifdef _OMC_OMPD\n",
                                    "  // Read inputs from in[]\n",
                                    "  #endif\n",
                                    "  // Evalute the ZeroCrossing function\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, a_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "// Write outputs to out[]\n",
                                    "out[0] = "
                                }, false));
        txt = Tpl.writeText(txt, a_zcExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "break;"
                                }, false));
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_45;

protected function lm_46
  input Tpl.Text in_txt;
  input list<BackendDAE.ZeroCrossing> in_items;
  input Integer in_a_offset;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_offset, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.ZeroCrossing> rest;
      Integer a_offset;
      Tpl.Text a_varDecls;
      Integer x_i0;
      DAE.Exp i_relation__;
      Tpl.Text l_zcExp;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           _,
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.ZERO_CROSSING(relation_ = i_relation__) :: rest,
           a_offset,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        l_preExp = Tpl.emptyTxt;
        (l_zcExp, l_preExp, a_varDecls) = SimCodeC.daeExp(Tpl.emptyTxt, i_relation__, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = fun_45(txt, i_relation__, l_zcExp, l_preExp, a_offset, x_i0);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_46(txt, rest, a_offset, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_offset,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_46(txt, rest, a_offset, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_46;

public function generateZeroCrossingsEq
  input Tpl.Text txt;
  input Integer a_offset;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls) := lm_46(out_txt, a_zeroCrossings, a_offset, a_varDecls);
  out_txt := Tpl.popIter(out_txt);
end generateZeroCrossingsEq;

public function functionQssUpdateDiscrete
  input Tpl.Text txt;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "void functionQssUpdateDiscrete(double time)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "mem_state = get_memory_state();\n",
                                       "// Code\n",
                                       "restore_memory_state(mem_state);\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionQssUpdateDiscrete;

public function generateIntegrators
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "Simulator\n",
                                   "  {\n",
                                   "    Path = modelica/modelica_integrator.h\n",
                                   "    Parameters = 1.0\n",
                                   "  }"
                               }, false));
end generateIntegrators;

public function generateStaticBlocks
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "Simulator\n",
                                   "  {\n",
                                   "    Path = modelica/modelica_qss_static.h\n",
                                   "    Parameters = 1.0,2.0,3.0\n",
                                   "  }"
                               }, false));
end generateStaticBlocks;

protected function lm_51
  input Tpl.Text in_txt;
  input list<BackendDAE.ZeroCrossing> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<BackendDAE.ZeroCrossing> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Integer x_i0;
      DAE.Exp i_relation__;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           BackendDAE.ZERO_CROSSING(relation_ = (i_relation__ as DAE.RELATION(exp1 = _))) :: rest,
           a_varDecls,
           a_preExp )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "Simulator\n",
                                    "  {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Path = modelica/modelica_qss_static.h // Crossing function "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" for "));
        (txt, a_preExp, a_varDecls) = SimCodeC.daeExp(txt, i_relation__, SimCode.contextOther, a_preExp, a_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Parameters = (double)("));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("),2.0,1.0\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  }"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_51(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_51(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_51;

public function generateZeroCrossingFunctions
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_preExp;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_preExp := Tpl.emptyTxt;
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, l_varDecls, l_preExp) := lm_51(out_txt, a_zeroCrossings, l_varDecls, l_preExp);
  out_txt := Tpl.popIter(out_txt);
end generateZeroCrossingFunctions;

protected function lm_53
  input Tpl.Text in_txt;
  input list<BackendDAE.ZeroCrossing> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<BackendDAE.ZeroCrossing> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Integer x_i0;
      DAE.Exp i_relation__;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           BackendDAE.ZERO_CROSSING(relation_ = (i_relation__ as DAE.RELATION(exp1 = _))) :: rest,
           a_varDecls,
           a_preExp )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "Simulator\n",
                                    "  {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Path = modelica/modelica_qss_crossdetect.h // Crossing detector "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" for "));
        (txt, a_preExp, a_varDecls) = SimCodeC.daeExp(txt, i_relation__, SimCode.contextOther, a_preExp, a_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Parameters = (double)("));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("),2.0,3.0\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  }"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_53(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_53(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_53;

public function generateCrossingDetectors
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_preExp;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_preExp := Tpl.emptyTxt;
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, l_varDecls, l_preExp) := lm_53(out_txt, a_zeroCrossings, l_varDecls, l_preExp);
  out_txt := Tpl.popIter(out_txt);
end generateCrossingDetectors;

protected function lm_55
  input Tpl.Text in_txt;
  input list<SimCode.SimWhenClause> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimWhenClause> rest;
      Integer x_i0;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           _ :: rest )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "Simulator\n",
                                    "  {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Path = modelica/modelica_when_discrete.h // When clause "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Parameters = (double)("));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("),2.0,3.0\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  }"));
        txt = Tpl.nextIter(txt);
        txt = lm_55(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_55(txt, rest);
      then txt;
  end matchcontinue;
end lm_55;

public function generateWhenBlocks
  input Tpl.Text txt;
  input list<SimCode.SimWhenClause> a_whenClauses;
  input list<SimCode.HelpVarInfo> a_helpVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_55(out_txt, a_whenClauses);
  out_txt := Tpl.popIter(out_txt);
end generateWhenBlocks;

protected function lm_57
  input Tpl.Text in_txt;
  input list<BackendDAE.ZeroCrossing> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<BackendDAE.ZeroCrossing> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Integer x_i0;
      DAE.Exp i_interval;
      DAE.Exp i_start;
      Tpl.Text l_e2;
      Tpl.Text l_e1;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval})) :: rest,
           a_varDecls,
           a_preExp )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        (l_e1, a_preExp, a_varDecls) = SimCodeC.daeExp(Tpl.emptyTxt, i_start, SimCode.contextOther, a_preExp, a_varDecls);
        (l_e2, a_preExp, a_varDecls) = SimCodeC.daeExp(Tpl.emptyTxt, i_interval, SimCode.contextOther, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "Simulator\n",
                                    "  {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Path = modelica/modelica_sample.h // Sample block "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" for sample("));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "Parameters = (double)("
                                }, false));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(")\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  }"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_57(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_57(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_57;

public function generateSampleBlocks
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_preExp;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_preExp := Tpl.emptyTxt;
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, l_varDecls, l_preExp) := lm_57(out_txt, a_zeroCrossings, l_varDecls, l_preExp);
  out_txt := Tpl.popIter(out_txt);
end generateSampleBlocks;

public function generateConnections
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "(0,0) ; (12,45) // Connection between\n",
                                   "(0,0) ; (12,45) // Connection between\n",
                                   "(0,0) ; (12,45) // Connection between\n",
                                   "(0,0) ; (12,45) // Connection between\n",
                                   "(0,0) ; (12,45) // Connection between"
                               }, false));
end generateConnections;

end SimCodeQSS;