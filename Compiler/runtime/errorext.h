/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef __ERROREXT_H
#define __ERROREXT_H

#ifdef __cplusplus
  extern "C" {
#endif

enum enumErrorType {ErrorType_syntax=0,ErrorType_grammar,ErrorType_translation,ErrorType_symbolic,ErrorType_runtime,ErrorType_scripting};
enum enumErrorLevel {ErrorLevel_error=0,ErrorLevel_warning,ErrorLevel_notification};
typedef enum enumErrorType ErrorType;
typedef enum enumErrorLevel ErrorLevel;
extern const char* ErrorLevel_toStr[3];
extern const char* ErrorType_toStr[6];

void c_add_message(int errorID,
       ErrorType type,
       ErrorLevel severity,
       const char* message,
       const char** ctokens,
       int nTokens);
void c_add_source_message(int errorID,
       ErrorType type,
       ErrorLevel severity,
       const char* message,
       const char** ctokens,
       int nTokens,
       int startLine,
       int startCol,
       int endLine,
       int endCol,
       int isReadOnly,
       const char* filename);
void ErrorImpl__setCheckpoint(const char* id);
void ErrorImpl__delCheckpoint(const char* id);
void ErrorImpl__rollBack(const char* id);
char* ErrorImpl__rollBackAndPrint(const char* id); // Returns the error string that we rolled back. free this resource

#ifdef __cplusplus
  }
#endif

#ifdef ERROREXT_CPLUSPLUS /* Not needed and messes up ANTLR3 parser */

#include <string>
#include <list>

  void add_message(int errorID,
       const char* type,
       const char* severity,
       const char* message,
       std::list<std::string> tokens);
       
  void add_source_message(int errorID,
        const char* type,
        const char* severity,
        const char* message,
        std::list<std::string> tokens,
        int startLine,
        int startCol,
        int endLine,
        int endCol,
        bool isReadOnly,
        const char* filename);

extern int showErrorMessages;

#endif

#endif
