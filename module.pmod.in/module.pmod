inherit Public.___ObjectiveC;
object pool;
object Cocoa;

class NSNil {};

object nil = NSNil();

array bundle_locations = ({
 
  "/System/Library/Frameworks",
  "/Library/Frameworks"
});

void idler()
{
  while(1)
  {
    sleep(5); 
  };
}

static void create()
{
	
  bundle_locations += ({(getenv("HOME") + "/Library/Frameworks")});
  
  Cocoa = ClassFinder();

  ::create();
}

int cocoa_gui_error_handler(object|array trace)
{
	werror("cocoa_gui_error_handler\n");
   	int x = AppKit()->NSRunAlertPanel("An Exception has Occurred", describe_backtrace(trace), "Continue", "Abort", "");	
    werror("x: " + x + "\n");
    if(!x) Cocoa.NSApplication.sharedApplication()->stop_(this);
    return x;
}

int register_new_dynamic_program(string programname, program p)
{
//  master()->programs["Cocoa." + programname] = p;
  return 0;
}

string get_signature_for_func(function f, string selector, int numargs)
{
  string osig = "";
  string ssig = sprintf("%O", _typeof(f));
  
  if(!sscanf(ssig, "function(%s)", ssig))
  {
    throw(Error.Generic("bad function signature!\n"));
  }
  
  werror("Signature: %O\n", ssig);
  
  string rt;
  catch(rt = (ssig / " : ")[-1]);
  if(!rt)
  {
    throw(Error.Generic("bad function signature: no return type!\n"));
  }
  
  werror("Return type: %O\n", rt);
  
  if(search(rt, "void")!=-1)
  {
    osig = "v";
  }
  else if(search(rt, "zero")!=-1)
  {
    osig = "v";
  }
  else if(search(rt, "int")!=-1)
  {
    osig = "i";
  }
  else
  {
    osig = "@";
  }
  
  osig += "@:";
  osig += ("@"*numargs);
  
  
  return osig;
}

int load_bundle(string bundlename)
{
  foreach(bundle_locations;; string loc)
  {
    string p = combine_path(loc, bundlename);
    if(file_stat(p))
    { 
      return low_load_bundle(p);
    }
  }

  return -1;
}

class ClassFinder
{
  mapping cache = ([]);

  int _is_type(string t)
  {
    if(t == "mapping")
    { 
      return 1;
    }
    else return 0;
  }
  
  static void create()
  {
    
  }

//   mixed `->(mixed a)
//   {
//     return `[](a);
//   }
// 
  
  static program `[](mixed a)
  {
    if(!stringp(a))
    {
      throw(Error.BadArgument(sprintf("argument %O is invalid.\n", a)));
    }
   
   else return get_dynamic_class(a);
    
  }
  
}

class NSArrayIterator(object arr)
{
	inherit Iterator;
	
	int current_index = 0;

	int(0..1) first()
	{
	  current_index = 0;	
	}
	
	mixed index()
	{
		if(!arr->count())
			return UNDEFINED;
		else return current_index;
	}
	
	int next()
	{
		if(arr->count() <= (current_index +1))
		  return 0;
		else current_index ++;
		
		return 1;
		
	}
	
	mixed value()
	{
		return arr->objectAtIndex_(current_index);
	}
	
	static int `!()
	{
	  return 0;
	}
	
	static Iterator `+=(int steps)
	{
		if((arr->count() <= (current_index + steps)) || (current_index + steps < 0))
		{
			return 0;
		}
		else
		{
			current_index += steps;
		}
		return this;
	}
}
/*
class NSDictionaryIterator(object dict)
{
	inherit Iterator;
	
	int current_index = 0;

	int(0..1) first()
	{
	  current_index = 0;	
	}
	
	mixed index()
	{
		if(!dict->count())
			return UNDEFINED;
		else return current_index;
	}
	
	int next()
	{
		if(dict->count() <= (current_index +1))
		  return 0;
		else current_index ++;
		
		return 1;
		
	}
	
	mixed value()
	{
		return dict->objectForKey_(current_index);
	}
	
	static int `!()
	{
	  return 0;
	}
	
	static Iterator `+=(int steps)
	{
		if((arr->count() <= (current_index + steps)) || (current_index + steps < 0))
		{
			return 0;
		}
		else
		{
			current_index += steps;
		}
		return this;
	}
}
*/
