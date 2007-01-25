/*
 * !!!! THIS IS GENERATED CODE, DO NOT EDIT !!!!
 */

#import <Pike/OCPikeInterpreter.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSString.h>

static void __attribute__ ((constructor)) _piobjc_bundle_load(void);

static const char *bundlePath() {
    int i;
    const struct mach_header *myHeader = _dyld_get_image_header_containing_address(&bundlePath);
    int count = _dyld_image_count();
    for (i = 0; i < count; i++) {
        if (_dyld_get_image_header(i) == myHeader) {
            return _dyld_get_image_name(i);
        }
    }
    abort();
    return NULL;
}


static void _piobjc_bundle_load()
{
	NSBundle* bundle;
	NSString* mainPath;
	OCPikeInterpreter* pi;
	BOOL res = NO;
        char * bundleLoc;

        bundleLoc = (char *)bundlePath();
    printf("bundle loaded from %s!\n", bundleLoc);
	
    NSLog(@"Loading prefpane %(MAINFILE)s %(BUNDLE)s from");
/*
	bundle = [NSBundle bundleForClass:self];

	mainPath = [bundle pathForResource:@"%(MAINFILE)s" ofType:@"pike"];

	if (mainPath == NULL) {
		[NSException raise:NSInternalInconsistencyException 
			format:@"Bundle %%@ does not contain a %(MAINFILE)s file",
			bundle];
	}
*/
	pi = [OCPikeInterpreter sharedInterpreter];

	if (![pi isStarted]) {
		[pi startInterpreter];
	}

/*
	push_text([mainPath cString]);
	SAFE_APPLY_MASTER("compile_file", 1 );
	
	if(Pike_sp[-1].type != T_PROGRAM)
	{
		[NSException raise:NSInternalInconsistencyException 
			format:@"Bundle %%@ does not contain a valid %(MAINFILE)s file",
			bundle];		
	}
	
	res = CreateClassDefinition("%(MAINFILE)s", 
	        "NSObject", Pike_sp[-1].u.program);
	
	pop_stack();
*/	
    
}

