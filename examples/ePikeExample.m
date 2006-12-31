#import <PikeInterpreter/OC_PikeInterpreter.h>
#import <Foundation/NSString.h>

int main()
{
  id i;
  struct svalue * sv;

  NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];

  i = [OC_PikeInterpreter sharedInterpreter];
  [i startInterpreter];
  
  f_version(0);
  printf("%s\n", Pike_sp[-1].u.string->str);

  pop_stack();

  sv = [i evalString: @"write(Protocols.HTTP.get_url_data(\"http://www.google.com\"))"];

  printf("type: %d, value: %d\n", sv->type, sv->u.integer);

  [innerPool release];
  free_svalue(sv);
  [i stopInterpreter];
  return 0;
}
