#import <Foundation/NSObject.h>
#import "piobjc.h"

@interface OC_PikeInterpreter : NSObject
{
  int is_started;
  id master_location;
  JMP_BUF jmploc;
}

+ (OC_PikeInterpreter *)sharedInterpreter;
- (id)init;
- (void)dealloc;
- (void)setMaster:(id)master;
- (int)startInterpreter;
- (BOOL)isStarted;
- (BOOL)stopInterpreter;
- (struct program *)compileString: (id)code;
- (struct svalue *)evalString: (id)expression;

@end /* interface OC_PikeInterpreter */
