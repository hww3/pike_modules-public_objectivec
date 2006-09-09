inherit Public.___ObjectiveC;

object Cocoa;

array bundle_locations = ({
 
  "/System/Library/Frameworks",
  "/Library/Frameworks"
});

class dummythreadrunner()
{
	void run(int i)
    {
	  werror("running...");
	  object pool = .NSClass("NSAutoreleasePool")->alloc()->init();
      pool->release();
      werror("done.\n");
	  return;
    }
}

void setup_threads()
{
	
	.NSClass("NSThread")->detachNewThreadSelector_toTarget_withObject_("run", dummythreadrunner(), .NSClass("NSString")->stringWithCString("foo"));
	
}

static void create()
{
	
  bundle_locations += ({(getenv("HOME") + "/Library/Frameworks")});
  
  Cocoa = ClassFinder();
  
  ::create();
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
  
  static object `[](mixed a)
  {
    if(!stringp(a))
    {
      throw(Error.BadArgument(sprintf("argument %O is invalid.\n", a)));
    }
    
    mixed c;
    
    c = cache[a];
    
    if(!c)
    {
      catch(c = Public.ObjectiveC.NSClass(a));
      
      if(!c)
      {
        // throw(Error.Index("class " + a + " does not exist.\n"));
        return c;
      }
      else
      {
        cache[a] = c;
        return c;
      }
    }
    
    if(c)
    {
      return c;
    }

    return 0;
  }
  
}