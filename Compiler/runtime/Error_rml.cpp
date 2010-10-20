/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�pings University, either from the above address,
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

extern "C" {
#include "rml.h"
}
#include "errorext.cpp"
extern "C" {

void ErrorExt_5finit(void)
{
  // empty the queue.
  while(!errorMessageQueue.empty()) {
      delete errorMessageQueue.top();
    errorMessageQueue.pop();
  }
}

RML_BEGIN_LABEL(ErrorExt__setCheckpoint)
{
  setCheckpoint(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__delCheckpoint)
{
  delCheckpoint(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__rollBack)
{
  rollBack(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__isTopCheckpoint)
{
  rmlA0 = isTopCheckpoint(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getLastDeletedCheckpoint)
{
  rmlA0 = getLastDeletedCheckpoint();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__errorOn)
{
  error_on = true;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__errorOff)
{
  error_on = false;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* Function to give feedback to the user on which component the error is "on" */
RML_BEGIN_LABEL(ErrorExt__updateCurrentComponent)
{
char* newVar = RML_STRINGDATA(rmlA0);
bool write = RML_STRINGDATA(rmlA1);
char* fileName = RML_STRINGDATA(rmlA2);
int rs = RML_UNTAGFIXNUM(rmlA3);
int re = RML_UNTAGFIXNUM(rmlA4);
int cs = RML_UNTAGFIXNUM(rmlA5);
int ce = RML_UNTAGFIXNUM(rmlA6);
update_current_component(newVar,write,fileName,rs,re,cs,ce);
RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__addMessage)
{
  int errorID = RML_UNTAGFIXNUM(rmlA0);
  char* tp = RML_STRINGDATA(rmlA1);
  char* severity = RML_STRINGDATA(rmlA2);
  char* message = RML_STRINGDATA(rmlA3);
  void* tokenlst = rmlA4;
  std::list<std::string> tokens;
  if (error_on) {
    while(RML_GETHDR(tokenlst) != RML_NILHDR) {
tokens.push_back(string(RML_STRINGDATA(RML_CAR(tokenlst))));
tokenlst=RML_CDR(tokenlst);
    }
    add_message(errorID,tp,severity,message,tokens);
    //printf(" Adding message, size: %d, %s\n",errorMessageQueue.size(),message);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__addSourceMessage)
{
  int errorID = RML_UNTAGFIXNUM(rmlA0);
  char* tp = RML_STRINGDATA(rmlA1);
  char* severity = RML_STRINGDATA(rmlA2);
  int sline = RML_UNTAGFIXNUM(rmlA3);
  int scol = RML_UNTAGFIXNUM(rmlA4);
  int eline = RML_UNTAGFIXNUM(rmlA5);
  int ecol = RML_UNTAGFIXNUM(rmlA6);
  bool isReadOnly = RML_UNTAGFIXNUM(rmlA7)?true:false;
  char* filename = RML_STRINGDATA(rmlA8);
  char* message = RML_STRINGDATA(rmlA9);
  void* tokenlst = rmlA10;
  std::list<std::string> tokens;

  if (error_on) {
    while(RML_GETHDR(tokenlst) != RML_NILHDR) {
tokens.push_back(string(RML_STRINGDATA(RML_CAR(tokenlst))));
tokenlst=RML_CDR(tokenlst);
    }

    add_source_message(errorID,tp,severity,message,tokens,sline,scol,eline,ecol,isReadOnly,filename);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getNumMessages)
  {
    rmlA0 = mk_icon((errorMessageQueue.size()));
    RML_TAILCALLK(rmlSC);
  }
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getNumErrorMessages)
    {
  int res=0;

  stack<ErrorMessage*> queueCopy(errorMessageQueue);
  while (!queueCopy.empty()) {
  if (queueCopy.top()->getSeverity().compare(std::string("Error")) == 0) {
    res++;
  }
  queueCopy.pop();
  }
    rmlA0 = mk_icon(res);
    RML_TAILCALLK(rmlSC);
    }
  RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__printErrorsNoWarning)
{
  std::string res("");
  while(!errorMessageQueue.empty()) {
    //if(strncmp(errorMessageQueue.top()->getSeverity(),"Error")==0){
    if(errorMessageQueue.top()->getSeverity().compare(std::string("Error"))==0){

      res = errorMessageQueue.top()->getMessage()+string("\n")+res;
    }
    delete errorMessageQueue.top();
    errorMessageQueue.pop();
  }
  rmlA0 = mk_scon((char*)res.c_str());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__printMessagesStr)
{
  std::string res("");
  while(!errorMessageQueue.empty()) {
    res = errorMessageQueue.top()->getMessage()+string("\n")+res;
    delete errorMessageQueue.top();
    errorMessageQueue.pop();
  }
  rmlA0 = mk_scon((char*)res.c_str());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getMessagesStr)
{
  std::string res("}");
  while(!errorMessageQueue.empty()) {
    res = errorMessageQueue.top()->getFullMessage() + res;
    delete errorMessageQueue.top();
    errorMessageQueue.pop();
    if (!errorMessageQueue.empty()) { res = string(",") + res; }
  }
  res = string("{") + res;
  rmlA0 = mk_scon((char*)res.c_str());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__clearMessages)
 {
   while(!errorMessageQueue.empty()) {
    delete errorMessageQueue.top();
    errorMessageQueue.pop();
   }
   RML_TAILCALLK(rmlSC);
 }
 RML_END_LABEL

} //extern "C"
