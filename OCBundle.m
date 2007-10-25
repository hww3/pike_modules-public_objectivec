/*
 * !!!! THIS IS GENERATED CODE, DO NOT EDIT !!!!
 */

/*

	 1054  gcc -arch ppc -FCaster.app/Contents/Frameworks -c BWTestBundle.m -o BWTestBundle.o
	 1055  MACOSX_DEPLOYMENT_TARGET="10.4" gcc -arch ppc BWTestBundle.o -bundle -o TestBundle -FTestBundle.saver/Contents/Frameworks -framework Pike -framework Foundation -undefined dynamic_lookup -framework ScreenSaver
	 1056  install_name_tool -change @executable_path/../Frameworks/Pike.framework/Pike @loader_path/../Frameworks/Pike.framework/Pike TestBundle
	 1057  cp TestBundle TestBundle.saver/Contents/MacOS/TestBundle

*/

#import <Pike/OCPikeInterpreter.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSString.h>

//extern char ** environ;

static void __attribute__ ((constructor)) _piobjc_bundle_load(void);

static const char *bundlePath() {
    int i;
    const struct mach_header *header = _dyld_get_image_header_containing_address(&bundlePath);
    int count = _dyld_image_count();
    for (i = 0; i < count; i++) {
        if (_dyld_get_image_header(i) == header) {
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
	Class cls;
	OCPikeInterpreter* pi;
	BOOL res = NO;
        char * bundleLoc;

    bundleLoc = (char *)bundlePath();

	mainPath = [NSString stringWithCString: bundleLoc];
	mainPath = [mainPath stringByAppendingString: @"/../../Resources/"];
	mainPath = [mainPath stringByStandardizingPath];
    	NSLog(mainPath);


	if (mainPath == NULL) {
		[NSException raise:NSInternalInconsistencyException 
			format:@"Bundle %%@ does not contain a %(MAINFILE)s file",
			bundle];
	}

	pi = [OCPikeInterpreter sharedInterpreter];

	if (![pi isStarted]) {
		[pi startInterpreter];


	}


	push_text([mainPath UTF8String]);
	f_utf8_to_string(1);
	SAFE_APPLY_MASTER("add_program_path", 1);
	//  TODO: shouldn't SAFE_APPLY_MASTER do this for us?
    //	pop_stack();
	NSLog(@"Initialized the embedded Pike Interpreter.\n");
	
	// now, let's initialize the objective c bridge.
	// looking up the module should be enough to do it.	
	push_text("Public.ObjectiveC.module");

	APPLY_MASTER("resolv", 1);
	
	if(Pike_sp[-1].type != T_OBJECT)
	{
	  // ok, we couldn't load the module. what should we do?
	  // for now, we we'll just complain. the classes won't work, though.
	  NSLog(@"Unable to enable the Objective-C Bridge!\n");
	}
	else
	{
	  NSLog(@"Loaded Public.ObjectiveC.\n");
	}
	
	pop_stack();
	
}

/*
int main(int argc, char** argv)
{
	int rv;
	
	
	_piobjc_bundle_load();

	
	return rv;
}
*/