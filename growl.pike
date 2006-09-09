import Public.ObjectiveC;

object pool;

void create()
{
  pool = NSClass("NSAutoreleasePool")->new()->init();	
  Public.ObjectiveC.low_load_bundle("/System/Library/Frameworks/Growl.framework");
  object g = Public.ObjectiveC.NSClass("GrowlApplicationBridge")->setGrowlDelegate_(this);
}

int main()
{
	call_out(notify, 6);
	return -1;
}


object registrationDictionaryForGrowl(mixed ... args) {
	werror("%O\n\nWheee!!!!!\n\n", args);
	object k = NSClass("NSString")->stringWithCString("AllNotifications");
    object v = NSClass("NSArray")->arrayWithObject(NSClass("NSString")
                 ->stringWithCString("New Announcement"));
	object n = NSClass("NSMutableDictionary")->dictionaryWithCapacity(2); 
	    n->retain();
	n->setObject_forKey_(NSClass("NSString")->stringWithCString("PGrowl"), NSClass("NSString")->stringWithCString("ApplicationName"));
	
    n->setObject_forKey_(v, k);
   // n->setObject_forKey_(v, k);
	k = NSClass("NSString")->stringWithCString("DefaultNotifications");
    v = NSClass("NSMutableArray")->arrayWithObject(NSClass("NSString")->stringWithCString("New Announcement"));

    n->setObject_forKey_(v, k);
    n->setObject_forKey_(NSClass("NSWorkspace")->sharedWorkspace()->iconForFileType_(NSClass("NSString")->stringWithCString("jpg"))->TIFFRepresentation(), NSClass("NSString")->stringWithCString("ApplicationIcon"));
werror("returning!\n");
werror("%O\n", n);
werror("object: %O\n", n->objectForKey_(k));
	return n;
}

void notify()
{
	
	object n = NSClass("NSMutableDictionary")->dictionaryWithCapacity(6); 
	n->setObject_forKey_(NSClass("NSString")->stringWithCString("PGrowl"), NSClass("NSString")->stringWithCString("ApplicationName"));
	n->setObject_forKey_(NSClass("NSString")->stringWithCString("New Announcement"), NSClass("NSString")->stringWithCString("NotificationName"));
	n->setObject_forKey_(NSClass("NSNumber")->new()->initWithInt_(2), NSClass("NSString")->stringWithCString("NotificationPriority"));
	n->setObject_forKey_(NSClass("NSNumber")->new()->initWithBool_(1), NSClass("NSString")->stringWithCString("NotificationSticky"));
	n->setObject_forKey_(NSClass("NSString")->stringWithCString("notification from PGrowl"), NSClass("NSString")->stringWithCString("NotificationTitle"));
	n->setObject_forKey_(NSClass("NSString")->stringWithCString("whooo, it's " + Calendar.now()->format_smtp() + "!\ngreetings from Public.ObjectiveC!"), NSClass("NSString")->stringWithCString("NotificationDescription"));
	n->setObject_forKey_(NSClass("NSWorkspace")->sharedWorkspace()->iconForFileType_(NSClass("NSString")->stringWithCString("jpg"))->TIFFRepresentation(), NSClass("NSString")->stringWithCString("NotificationIcon"));
	n->setObject_forKey_(NSClass("NSWorkspace")->sharedWorkspace()->iconForFileType_(NSClass("NSString")->stringWithCString("jpg"))->TIFFRepresentation(), NSClass("NSString")->stringWithCString("NotificationAppIcon"));

	NSClass("GrowlApplicationBridge")->notifyWithDictionary_(n);
	call_out(notify, 5);
//	return NSClass("NSThread")->currentThread()->runLoop();
}