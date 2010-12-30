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

package MetaModelicaBuiltinImports
  /* These imports are added to the top environment frame.
   * This special hack is due to Modelica not allowing top-level imports.
   */
  import listStringCharString = stringAppendList;
  import stringCharListString = stringAppendList;
  import stringEqual = stringEq;
  import realCos = cos;
  import realCosh = cosh;
  import realAcos = acos;
  import realSin = sin;
  import realSinh = sinh;
  import realAsin = asin;
  import realAtan = atan;
  import realAtan2 = atan2;
  import realTanh = tanh;
  import realExp = exp;
  import realLn = log;
  import realLog10 = log10;
  import realCeil = ceil;
  import realFloor = floor;
  import realSqrt = sqrt;
end MetaModelicaBuiltinImports;