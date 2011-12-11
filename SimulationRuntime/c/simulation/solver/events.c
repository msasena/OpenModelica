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

#include "events.h"
#include "error.h"
#include "simulation_data.h"
#include "openmodelica.h"		/* for modelica types */
#include "openmodelica_func.h"   /* for modelica fucntion */
#include "simulation_runtime.h"
#include "solver_main.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


double Sample(double t, double start, double interval)
{
  double pipi = atan(1.0) * 8.0;
  if(t < (start - interval * 0.25))
    return -1.0;
  return sin(pipi * (t - start) / interval);
}

/*
 * Returns true and triggers time events at time instants
 * start + i*interval (i=0, 1, ...).
 * During continuous integration the operator returns always false.
 * The starting time start and the sample interval interval need to
 * be parameter expressions and need to be a subtype of Real or Integer.
 */
modelica_boolean sample(_X_DATA *data, double start, double interval, int hindex)
{
  /* adrpo - 2008-01-15
   * comparison was tmp >= 0 fails sometimes on x86 due to extended precision in registers
   * TODO - fix the simulation runtime so that the sample event is generated at EXACTLY that time.
   * below should be: if (tmp >= -0.0001 && tmp < 0.0001) but needs more testing as some models from
   * testsuite fail.
   */
  static const double eps = 0.0001;
  double retVal;
  double tmp = 1;
  int tmpindex = data->simulationInfo.curSampleTimeIx;
  
  if(tmpindex < data->simulationInfo.nSampleTimes){
    while((data->simulationInfo.sampleTimes[tmpindex]).activated == 1){
      if((data->simulationInfo.sampleTimes[tmpindex]).zc_index == hindex)
        tmp = 0;
		
      tmpindex++;
	  
      if(tmpindex == data->simulationInfo.nSampleTimes)
        break;
    }
  }

  /*
   * sjoelund - do not sample before the start value !
   */
  if(data->localData[0]->timeValue >= start - eps && tmp >= -eps && tmp < eps){
    DEBUG_INFO2(LOG_EVENTS,"Calling sample(%f, %f)", start, interval);
    DEBUG_INFO2(LOG_EVENTS,"+generating an event at time: %f \t tmp: %f", data->localData[0]->timeValue, tmp);
    retVal = 1;
  } else {
    DEBUG_INFO2(LOG_EVENTS,"Calling sample(%f, %f)", start, interval);
    DEBUG_INFO2(LOG_EVENTS,"-NO event at time: %f \t tmp: %f", data->localData[0]->timeValue, tmp);
    retVal = 0;
  }
  return retVal;
}

static int compdbl(const void* a, const void* b)
{
  const double *v1 = (const double *) a;
  const double *v2 = (const double *) b;
  const double diff = *v1 - *v2;
  const double epsilon = 0.00000000000001;

  if(diff < epsilon && diff > -epsilon)
    return 0;
  return (*v1 > *v2) ? 1 : -1;
}

static int compSample(const void* a, const void* b)
{
  const SAMPLE_TIME *v1 = (const SAMPLE_TIME *) a;
  const SAMPLE_TIME *v2 = (const SAMPLE_TIME *) b;
  const double diff = v1->events - v2->events;
  const double epsilon = 0.0000000001;

  if(diff < epsilon && diff > -epsilon)
    return 0;
  return (v1->events > v2->events) ? 1 : -1;
}

static int compSampleZC(const void* a, const void* b)
{
  const SAMPLE_TIME *v1 = (const SAMPLE_TIME *) a;
  const SAMPLE_TIME *v2 = (const SAMPLE_TIME *) b;
  const double diff = v1->events - v2->events;
  const int diff2 = v1->zc_index - v2->zc_index;
  const double epsilon = 0.0000000001;

  if(diff < epsilon && diff > -epsilon && diff2 == 0)
    return 0;
  return (v1->events > v2->events) ? 1 : -1;
}

static int unique(void *base, size_t nmemb, size_t size,
                  int (*compar)(const void *, const void *))
{
  size_t nuniq = 0;
  size_t i;
  void *a, *b, *c;
  a = base;
  for(i = 1; i < nmemb; i++)
  {
    b = ((char*) base) + i * size;
    if(0 == compar(a, b))
	  nuniq++;
    else
    {
      a = b;
      c = ((char*) base) + (i - nuniq) * size;
      if(b != c)
        memcpy(c, b, size); /* happens when nuniq==0*/
    }
  }
  return nmemb - nuniq;
}

void initSample(_X_DATA* data, double start, double stop)
{
  /* not used yet
   * long measure_start_time = clock();
   */
   
  /* This code will generate an array of time values when sample generates events.
   * The only problem is our backend does not generate this array.
   * Sample() and sample() also need to be changed, but this should be easy to fix.
   */
   
  int i;
  /* double stop = 1.0; */
  double d;
  SAMPLE_TIME* Samples = NULL;
  int num_samples = 0;
  int max_events = 0;
  int ix = 0;
  int nuniq;

  function_sampleInit(data);

  num_samples = data->modelData.nSamples;

  for(i = 0; i < num_samples; i++){
    if(stop >= data->simulationInfo.rawSampleExps[i].start)
	  max_events += (int)(((stop - data->simulationInfo.rawSampleExps[i].start) / data->simulationInfo.rawSampleExps[i].interval) + 1);
  }

  Samples = (SAMPLE_TIME*)calloc(max_events+1, sizeof(SAMPLE_TIME));
  if(Samples == NULL){
    DEBUG_INFO(LOG_EVENTS, "Could not allocate Memory for initSample!");
    THROW("Could not allocate Memory for initSample!");
  }

  for(i = 0; i < num_samples; i++){
    DEBUG_INFO2(LOG_EVENTS, "Generate times for sample(%f, %f)", data->simulationInfo.rawSampleExps[i].start, data->simulationInfo.rawSampleExps[i].interval);
    
    for(d = data->simulationInfo.rawSampleExps[i].start; ix < max_events && d <= stop; d += data->simulationInfo.rawSampleExps[i].interval){
      (Samples[ix]).events = d;
      (Samples[ix++]).zc_index = (data->simulationInfo.rawSampleExps[i]).zc_index;
	  
      DEBUG_INFO3(LOG_EVENTS, "Generate sample(%f, %f, %d)", d, data->simulationInfo.rawSampleExps[i].interval, (data->simulationInfo.rawSampleExps[i]).zc_index);
    }
  }
  
  /* Sort, filter out unique values */
  qsort(Samples, max_events, sizeof(SAMPLE_TIME), compSample);
  nuniq = unique(Samples, max_events, sizeof(SAMPLE_TIME), compSampleZC);
  
  DEBUG_INFO1(LOG_INIT, "Number of sorted, unique sample events: %d", nuniq);
  for(i = 0; i < nuniq; i++)
    DEBUG_INFO_AL3(LOG_INIT, "%f\t HelpVar[%d]=activated(%d)", (Samples[i]).events, (Samples[i]).zc_index,(Samples[i]).activated);

  data->simulationInfo.sampleTimes = Samples;
  data->simulationInfo.curSampleTimeIx = 0;
  data->simulationInfo.nSampleTimes = nuniq;
}

/*
 * All event functions from here, are till now only used in Euler
 *
 */


/* function: checkForSampleEvent
 *
 * ! Function check if a sample expression should be activated
 *
 */
int
checkForSampleEvent(_X_DATA *data, SOLVER_INFO* solverInfo)
{
  double a = solverInfo->currentTime + solverInfo->currentStepSize;
  int b = 0;
  int tmpindex = 0;

  DEBUG_INFO1(LOG_EVENTS, "Check for Sample Events. Current Index: %li", data->simulationInfo.curSampleTimeIx);

  DEBUG_INFO1(LOG_EVENTS, "*** Next step : %f", a);
  DEBUG_INFO1(LOG_EVENTS, "*** Next sample Time : %f", ((data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).events));

  tmpindex = data->simulationInfo.curSampleTimeIx;
  b = compdbl(&a, &((data->simulationInfo.sampleTimes[tmpindex]).events));
  if (b >= 0)
    {
      DEBUG_INFO(LOG_EVENTS, "** Sample Event **");

      if (!(b == 0))
      {
          if ((data->simulationInfo.sampleTimes[tmpindex]).events - solverInfo->currentTime >= 0){
            solverInfo->currentStepSize = (data->simulationInfo.sampleTimes[tmpindex]).events - solverInfo->currentTime;
          }else{
            solverInfo->currentStepSize = 0;
          }

          DEBUG_INFO1(LOG_EVENTS, "** Change Stepsize : %f", solverInfo->currentStepSize);
      }
      return 1;
    }
  else
    {
      return 0;
    }
}

/* function: activateSampleEvents
 *
 * ! Function activated sample expression
 *
 */
int
activateSampleEvents(_X_DATA *data)
{
    if (data->simulationInfo.curSampleTimeIx < data->simulationInfo.nSampleTimes)
    {
        int retVal = 0;
        double a = data->localData[0]->timeValue;
        int b = 0;
        long int tmpindex = data->simulationInfo.curSampleTimeIx;
        DEBUG_INFO(LOG_EVENTS, "Activate Sample Events.");
        DEBUG_INFO1(LOG_EVENTS, "Current Index: %li", data->simulationInfo.curSampleTimeIx);

        b = compdbl(&a, &((data->simulationInfo.sampleTimes[tmpindex]).events));
        while (b >= 0)
        {
            retVal = 1;
            (data->simulationInfo.sampleTimes[tmpindex]).activated = 1;
            DEBUG_INFO1(LOG_EVENTS, "Activate Sample Events index: %li", tmpindex);
            tmpindex++;
            if (tmpindex >= data->simulationInfo.nSampleTimes)
                break;
            b = compdbl(&a, &((data->simulationInfo.sampleTimes[tmpindex]).events));
        }
        return retVal;
    }
    else
    {
        return 0;
    }

}

/* function: activateSampleEvents
 *
 * ! Function deactivate, before activated sample expression
 *
 */
void
deactivateSampleEvents(_X_DATA *data)
{
  int tmpindex = data->simulationInfo.curSampleTimeIx;

  while ((data->simulationInfo.sampleTimes[tmpindex]).activated == 1)
    {
      (data->simulationInfo.sampleTimes[tmpindex++]).activated = 0;
    }
}

/* function: activateSampleEvents
 *
 * ! Function deactivate, before activated sample expression in equations
 *
 */
void
deactivateSampleEventsandEquations(_X_DATA *data)
{
  while ((data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).activated == 1)
    {
      DEBUG_INFO1(LOG_EVENTS, "Deactivate Sample Events index: %li", data->simulationInfo.curSampleTimeIx);

      (data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).activated = 0;
      data->simulationInfo.helpVars[((data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).zc_index)]
                           = 0;
      data->simulationInfo.curSampleTimeIx++;
    }
  function_updateSample(data);
}

/*
   This function checks for Events in Interval=[oldTime, timeValue]
   If a ZeroCrossing Function cause a sign change, root finding
   process will start
*/
int
CheckForNewEvent(_X_DATA* simData, modelica_boolean* sampleactived, double* currentTime)
{
  long i = 0;
  LIST *eventList=NULL;
  LIST_NODE *it;
  double EventTime = 0;

  initializeZeroCrossings(simData);
  eventList = allocList(sizeof(long));

  DEBUG_INFO(LOG_EVENTS, "Check for events ...");
  for (i = 0; i < simData->modelData.nZeroCrossings; i++)
    {
      DEBUG_INFO4(LOG_ZEROCROSSINGS, "ZeroCrossing ID: %ld \t old = %g \t current = %g \t Direction = %d",
                  i, simData->simulationInfo.zeroCrossingsPre[i], simData->simulationInfo.zeroCrossings[i], simData->simulationInfo.zeroCrossingEnabled[i]);

      if (simData->simulationInfo.zeroCrossingsPre[i] == 0)
        {
          if (simData->simulationInfo.zeroCrossings[i] > 0 && simData->simulationInfo.zeroCrossingEnabled[i] <= -1)
            {
              DEBUG_INFO2(LOG_EVENTS, "adding event %ld at time: %f", i, simData->localData[0]->timeValue);

              listPushFront(eventList, &i);
            }
          else if (simData->simulationInfo.zeroCrossings[i] < 0 && simData->simulationInfo.zeroCrossingEnabled[i] >= 1)
            {
              DEBUG_INFO2(LOG_EVENTS, "adding event %ld at time: %f", i, simData->localData[0]->timeValue);

              listPushFront(eventList, &i);
            }
        }
      if ((simData->simulationInfo.zeroCrossings[i] <= 0 && simData->simulationInfo.zeroCrossingsPre[i] > 0) ||
          (simData->simulationInfo.zeroCrossings[i] >= 0 && simData->simulationInfo.zeroCrossingsPre[i] < 0))
        {
          DEBUG_INFO2(LOG_EVENTS, "adding event %ld at time: %f", i, simData->localData[0]->timeValue);

          listPushFront(eventList, &i);
        }
    }
  if (listLen(eventList) > 0)
    {
      DEBUG_INFO(LOG_EVENTS,"Print List");
      for(it=listFirstNode(eventList),i=0; it; it=listNextNode(it)){
        DEBUG_INFO2(LOG_EVENTS,"List Node [%ld] = %ld",i++, *((long*)listNodeData(it)));
      }

      if (*sampleactived == 1)
        {
          *sampleactived = 0;
          deactivateSampleEvents(simData);
        }

      FindRoot(simData, &EventTime, eventList);
      /*Handle event as state event*/
      simData->localData[0]->timeValue = EventTime;
      EventHandle(simData, 0, eventList);

      DEBUG_INFO1(LOG_EVENTS, "Event Handling at EventTime: %f done!", EventTime);
      *currentTime = EventTime;
      freeList(eventList);
      return 1;
    }
  freeList(eventList);
  return 0;
}

/*
 This function handle events and change all
 needed variables for an event
 parameter flag - Indicate the kind of event
 = 0 state event
 = 1 sample event
 */
int EventHandle(_X_DATA* simData, int flag, LIST *eventList) {

  if (flag == 0) {
    long event_id = 0;

    LIST_NODE* it;

    DEBUG_INFO_NEL(LOG_EVENTS, "Handle Event caused by ZeroCrossings: ");
    for (it = listFirstNode(eventList); it; it = listNextNode(it)) {
      event_id = *((long*) listNodeData(it));
      DEBUG_INFO_NELA1(LOG_EVENTS, "%ld", event_id);
      if (listLen(eventList) > 0) {
        DEBUG_INFO_NELA(LOG_EVENTS, ", ");
      }

      /* switch the direction of ZeroCrossing */
      if (simData->simulationInfo.zeroCrossingEnabled[event_id] == -1) {
        simData->simulationInfo.zeroCrossingEnabled[event_id] = 1;
      } else if (simData->simulationInfo.zeroCrossingEnabled[event_id] == 1) {
        simData->simulationInfo.zeroCrossingEnabled[event_id] = -1;
      }
    }
    DEBUG_INFO_NELA(LOG_EVENTS, "\n");

    /* update the whole system */
    update_DAEsystem(simData);

  }
  /* sample event handling */
  else if (flag == 1) {
    DEBUG_INFO1(LOG_EVENTS, "Event Handling for Sample : %f!",
        simData->localData[0]->timeValue);
    sim_result_emit(simData);
    /*evaluate and emit results before sample events are activated */
    /* update the whole system */
    update_DAEsystem(simData);

    storePreValues(simData);
    sim_result_emit(simData);

    /*Activate sample and evaluate again */
    activateSampleEvents(simData);

    /* update the whole system */
    update_DAEsystem(simData);

    deactivateSampleEventsandEquations(simData);
    DEBUG_INFO1(LOG_EVENTS, "Event Handling for Sample : %f done!",
        simData->localData[0]->timeValue);
  }
  SaveZeroCrossingsAfterEvent(simData);
  correctDirectionZeroCrossings(simData);
  return 0;
}

/*
  This function perform a root finding for
  Intervall=[oldTime, timeValue]
*/
void FindRoot(_X_DATA* simData, double *EventTime, LIST *eventList)
{
  long event_id;
  LIST_NODE* it;
  fortran_integer i=0;
  static LIST *tmpEventList = NULL;
  
  double *states_right = (double*) calloc(simData->modelData.nStates, sizeof(double));
  double *states_left = (double*) calloc(simData->modelData.nStates, sizeof(double));

  double time_left = simData->localData[1]->timeValue;
  double time_right = simData->localData[0]->timeValue;

  if(!tmpEventList)
      tmpEventList = allocList(sizeof(long));

  assert(states_right);
  assert(states_left);

  for(it=listFirstNode(eventList); it; it=listNextNode(it)){
    DEBUG_INFO1(LOG_ZEROCROSSINGS, "Search for current event. Events in list: %ld", *((long*)listNodeData(it)));
  }


  /*write states to work arrays*/
  for (i = 0; i < simData->modelData.nStates; i++)
    {
      states_left[i] = simData->localData[1]->realVars[i];
      states_right[i] = simData->localData[0]->realVars[i];
    }

  /* Search for event time and event_id with Bisection method */
  *EventTime = BiSection(simData, &time_left, &time_right, states_left, states_right,
      tmpEventList, eventList);

  if (listLen(tmpEventList) == 0)
    {
        double value = fabs(simData->simulationInfo.zeroCrossings[*((long*)listFirstData(eventList))]);
        for(it=listFirstNode(eventList); it; it=listNextNode(it))
        {
            if(value > fabs(simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))]))
            {
                value = fabs(simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))]);
            }
        }
        DEBUG_INFO1(LOG_ZEROCROSSINGS, "Minimum value: %g", value);
      for (it=listFirstNode(eventList); it; it=listNextNode(it))
        {
            if (value == fabs(simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))]))
            {
              listPushBack(tmpEventList, listNodeData(it));
              DEBUG_INFO1(LOG_ZEROCROSSINGS, "added tmp event : %ld", *((long*)listNodeData(it)));
            }
        }
    }

  listClear(eventList);

  if (listLen(tmpEventList) > 0){
    DEBUG_INFO_NEL(LOG_EVENTS, "Found events: ");
  }else{
    DEBUG_INFO_NEL(LOG_EVENTS, "Found event: ");
  }
  while (listLen(tmpEventList) > 0){
      event_id = *((long*)listFirstData(tmpEventList));
      listPopFront(tmpEventList);
      if (DEBUG_FLAG(LOG_EVENTS)){
        DEBUG_INFO_NELA1(LOG_EVENTS, "%ld ", event_id);
      }
      if (listLen(tmpEventList) > 0){
        DEBUG_INFO_NELA(LOG_EVENTS, ", ");
      }
      listPushFront(eventList, &event_id);
  }
  DEBUG_INFO_NELA(LOG_EVENTS, "\n");

 DEBUG_INFO1(LOG_EVENTS, "at time: %g", *EventTime);
 DEBUG_INFO1(LOG_EVENTS, "Time at Point left: %g", time_left);
 DEBUG_INFO1(LOG_EVENTS, "Time at Point right: %g", time_right);

  /*determined system at t_e - epsilon */
  simData->localData[0]->timeValue = time_left;
  for (i = 0; i < simData->modelData.nStates; i++){
    simData->localData[0]->realVars[i] = states_left[i];
  }
  /*determined continuous system */
  functionODE(simData);
  functionAlgebraics(simData);
  function_storeDelayed(simData);
  storePreValues(simData);
  sim_result_emit(simData);

  /*determined system at t_e + epsilon */
  simData->localData[0]->timeValue = time_right;
  for (i = 0; i < simData->modelData.nStates; i++){
    simData->localData[0]->realVars[i] = states_right[i];
  }
  free(states_left);
  free(states_right);
}

/*
  Method to find root in Intervall[oldTime, timeValue]
 */
double BiSection(_X_DATA* simData, double* a, double* b, double* states_a,
    double* states_b, LIST *tmpEventList, LIST *eventList) {

  /*double TTOL =  DBL_EPSILON*fabs((*b - *a))*100; */
  double TTOL = 1e-9;
  double c;
  int right = 0;
  long i = 0;

  double *backup_gout = (double*) calloc(simData->modelData.nZeroCrossings,
      sizeof(double));
  assert(backup_gout);

  for (i = 0; i < simData->modelData.nZeroCrossings; i++) {
    backup_gout[i] = simData->simulationInfo.zeroCrossings[i];
  }

  DEBUG_INFO2(LOG_ZEROCROSSINGS, "Check interval [%g, %g]", *a, *b);
  DEBUG_INFO1(LOG_ZEROCROSSINGS, "TTOL is set to: %g", TTOL);

  while (fabs(*b - *a) > TTOL) {

    c = (*a + *b) / 2.0;
    simData->localData[0]->timeValue = c;

    /*calculates states at time c */
    for (i = 0; i < simData->modelData.nStates; i++) {
      simData->localData[0]->realVars[i] = (states_a[i] + states_b[i]) / 2.0;
    }

    /*calculates Values dependents on new states*/
    functionODE(simData);
    functionAlgebraics(simData);

    function_onlyZeroCrossings(simData, simData->simulationInfo.zeroCrossings,
        &(simData->localData[0]->timeValue));
    if (CheckZeroCrossings(simData, tmpEventList, eventList)) { /*If Zerocrossing in left Section */

      for (i = 0; i < simData->modelData.nStates; i++) {
        states_b[i] = simData->localData[0]->realVars[i];
      }
      *b = c;
      right = 0;

    } else { /*else Zerocrossing in right Section */

      for (i = 0; i < simData->modelData.nStates; i++) {
        states_a[i] = simData->localData[0]->realVars[i];
      }
      *a = c;
      right = 1;
    }
    if (right) {
      for (i = 0; i < simData->modelData.nZeroCrossings; i++) {
        simData->simulationInfo.zeroCrossingsPre[i] =
            simData->simulationInfo.zeroCrossings[i];
        simData->simulationInfo.zeroCrossings[i] = backup_gout[i];
      }
    } else {
      for (i = 0; i < simData->modelData.nZeroCrossings; i++) {
        backup_gout[i] = simData->simulationInfo.zeroCrossings[i];
      }
    }
  }
  free(backup_gout);
  c = (*a + *b) / 2.0;
  return c;
}

/*
   Check if at least one zerocrossing has change sign
   is used in BiSection
*/
int
CheckZeroCrossings(_X_DATA *simData, LIST *tmpEventList, LIST *eventList)
{

  LIST_NODE *it;
  
  listClear(tmpEventList);
  for(it=listFirstNode(eventList); it; it=listNextNode(it))
    {
      DEBUG_INFO4(LOG_ZEROCROSSINGS, "ZeroCrossing ID: %ld \t old = %g \t current = %g \t Direction = %d",
              *((long*)listNodeData(it)), simData->simulationInfo.zeroCrossingsPre[*((long*)listNodeData(it))], simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))], simData->simulationInfo.zeroCrossingEnabled[*((long*)listNodeData(it))]); fflush(NULL);

      /*Found event in left section*/
      if ((simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))] < 0
              && simData->simulationInfo.zeroCrossingsPre[*((long*)listNodeData(it))] >= 0)
          || (simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))] > 0
              && simData->simulationInfo.zeroCrossingsPre[*((long*)listNodeData(it))] <= 0)
          || (simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))] > 0
              && simData->simulationInfo.zeroCrossingEnabled[*((long*)listNodeData(it))] <= -1)
          || (simData->simulationInfo.zeroCrossings[*((long*)listNodeData(it))] < 0
              && simData->simulationInfo.zeroCrossingEnabled[*((long*)listNodeData(it))] >= 1))
        {
           listPushFront(tmpEventList, listNodeData(it));
        }
    }
  /*Found event in left section*/
  if (listLen(tmpEventList) > 0)
    {
      return 1;
    }
  /* Else event in right section */
  else
    {
      return 0;
    }
}


void
SaveZeroCrossingsAfterEvent(_X_DATA* simData)
{
  long i = 0;

  DEBUG_INFO(LOG_ZEROCROSSINGS, "Save ZeroCrossings after an Event!");

  function_onlyZeroCrossings(simData, simData->simulationInfo.zeroCrossings, &(simData->localData[0]->timeValue));
  for(i=0;i<simData->modelData.nZeroCrossings;i++){
      simData->simulationInfo.zeroCrossingsPre[i] = simData->simulationInfo.zeroCrossings[i];
  }
}


void
initializeZeroCrossings(_X_DATA* simData)
{
  long i = 0;
  for (i = 0; i < simData->modelData.nZeroCrossings; i++)
    {
      if (simData->simulationInfo.zeroCrossingEnabled[i] == 0){
          if (simData->simulationInfo.zeroCrossings[i] > 0)
            simData->simulationInfo.zeroCrossingEnabled[i] = 1;
          else if (simData->simulationInfo.zeroCrossings[i] < 0)
            simData->simulationInfo.zeroCrossingEnabled[i] = -1;
          else
            simData->simulationInfo.zeroCrossingEnabled[i] = 0;
      }
    }
}

void
correctDirectionZeroCrossings(_X_DATA* simData)
{
  long i = 0;
  for (i = 0; i < simData->modelData.nZeroCrossings; i++)
    {
      if (simData->simulationInfo.zeroCrossingEnabled[i] == -1 && simData->simulationInfo.zeroCrossings[i] > 0){
          simData->simulationInfo.zeroCrossingEnabled[i] = 1;
      }else if (simData->simulationInfo.zeroCrossingEnabled[i] == 1 && simData->simulationInfo.zeroCrossings[i] < 0){
            simData->simulationInfo.zeroCrossingEnabled[i] = -1;
      }
    }
}
