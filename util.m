#include "piobjc.h"

id get_NSObject()
{
  struct object * o;
  struct NSObject_struct * d;
 
  o = Pike_fp->current_object;

  d = (struct NSObject_struct *) get_storage(o, NSObject_program);
  if(d == NULL)
  Pike_error("Object is not an NSObject!\n");

  return d->object_data->object;

}
int is_nsobject_initialized()
{
struct object * o;
struct NSObject_struct * d;

o = Pike_fp->current_object;

d = (struct NSObject_struct *) get_storage(o, NSObject_program);  
if(d == NULL)
  Pike_error("Object is not an NSObject!\n");

  if(d->object_data->object == NULL)
    return 0;
  else return 1;
}