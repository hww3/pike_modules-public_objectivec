#import "OC_PikeInterpreter.h"
#import "piobjc.h"

@implementation OC_PikeInterpreter
- (id) init {
	
    static OC_PikeInterpreter *sharedInstance = nil;
	
    if (sharedInstance) {
        [self autorelease];
        self = [sharedInstance retain];
    } else {
        self = [super init];
        if (self) {
            sharedInstance = [self retain];
			
        }
    }
	
    return self;
}

+(OC_PikeInterpreter *)sharedInterpreter
{
	static * sharedInstance = nil;
	
	if ( sharedInstance == nil )
		sharedInstance = [[self alloc] init];
	
	return sharedInstance;
}


- (void)setMaster:(id) master
{
	  if ([master length] >= MAXPATHLEN*2 ) {
	    fprintf(stderr, "Too long path to master: \"%s\" (limit:%"PRINTPTRDIFFT"d)\n",
	            [master UTF8String], MAXPATHLEN*2 );
	    exit(1);
	  }
	master_location = [master copy];
}

- (BOOL)startInterpreter
{
  	JMP_BUF back;
	int num = 0;
	struct object *m;
    char ** argv = NULL;

	set_default_master();
	init_pike(argv, [master_location UTF8String]);
	init_pike_runtime(exit);

	add_pike_string_constant("__master_cookie",
	                           [master_location UTF8String], 
				strlen([master_location UTF8String]));

	  if(SETJMP(jmploc))
	  {
	    if(throw_severity == THROW_EXIT)
	    {
	      num=throw_value.u.integer;
	    }else{
	      if (throw_value.type == T_OBJECT &&
	          throw_value.u.object->prog == master_load_error_program &&
	          !get_master()) {  
	        /* Report this specific error in a nice way. Since there's no
	         * master it'd be reported with a raw error dump otherwise. */
	        struct generic_error_struct *err;

	        dynamic_buffer buf;
	        dynbuf_string s;
	        struct svalue t;

	        *(Pike_sp++) = throw_value;
	        dmalloc_touch_svalue(Pike_sp-1);
	        throw_value.type=T_INT;  
	        err = (struct generic_error_struct *)
	          get_storage (Pike_sp[-1].u.object, generic_error_program);

	        t.type = PIKE_T_STRING;
	        t.u.string = err->error_message;

	        init_buf(&buf);
	        describe_svalue(&t,0,0);
	        s=complex_free_buf(&buf);

	        fputs(s.str, stderr);
	        free(s.str);
	      } 
	      else
	        call_handle_error();
	    }
	  }else{


	    if ((m = load_pike_master())) {
	      back.severity=THROW_EXIT;
//	      pike_push_argv(argc, argv);
	      pike_push_env();

		}
   return YES;
}
}
- (BOOL)stopInterpreter
{
	UNSETJMP(jmploc);
	pike_do_exit(0);	
    return YES;	
}

- (BOOL)isStarted
{
	return (is_started?YES:NO);
}

@end /* OC_PikeInterpreter */
