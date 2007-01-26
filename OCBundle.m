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
    pop_stack();

}

