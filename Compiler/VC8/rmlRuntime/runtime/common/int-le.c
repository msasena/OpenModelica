/* int_le.c */
#include "rml.h"

RML_BEGIN_LABEL(RML__int_5fle)
{
    rmlA0 = RML_PRIM_INT_LE(rmlA0, rmlA1);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
