import Public.ObjectiveC;
int i;
object pool;

void create()
{
 // pool = Cocoa.NSAutoreleasePool->new()->init();	
  Public.ObjectiveC.low_load_bundle("/System/Library/Frameworks/Growl.framework");
  object g = NSClass("GrowlApplicationBridge")->setGrowlDelegate_(this);
}

int main()
{
	call_out(notify, 6);
	return -1;
}

object p;

object registrationDictionaryForGrowl(mixed ... args) {

	object n = Cocoa.NSMutableDictionary->dictionaryWithCapacity(2); 

	n->setObject_forKey_("PGrowl", "ApplicationName");  
	n->setObject_forKey_(Cocoa.NSMutableArray->arrayWithObject("New Announcement"), "AllNotifications");
	n->setObject_forKey_(Cocoa.NSMutableArray->arrayWithObject("New Announcement"), "DefaultNotifications");

  n->setObject_forKey_(NSClass("NSWorkspace")->sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation(), 
    "ApplicationIcon");

	return n;
}

void notify()
{
	object n = Cocoa.NSMutableDictionary->dictionaryWithCapacity(6); 
	n->setObject_forKey_("PGrowl", "ApplicationName");
	n->setObject_forKey_("New Announcement", "NotificationName");
	n->setObject_forKey_(Cocoa.NSNumber->new()->initWithInt_(2), "NotificationPriority");
	n->setObject_forKey_(Cocoa.NSNumber->new()->initWithBool_(0), "NotificationSticky");
	n->setObject_forKey_("notification from PGrowl", "NotificationTitle");
	n->setObject_forKey_("whooo, it's " + Calendar.now()->format_smtp() + "!\ngreetings from Public.ObjectiveC!", "NotificationDescription");
	n->setObject_forKey_(NSClass("NSWorkspace")->sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation(), "NotificationIcon");
	n->setObject_forKey_(NSClass("NSWorkspace")->sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation(), "NotificationAppIcon");

	NSClass("GrowlApplicationBridge")->notifyWithDictionary_(n);
	call_out(notify, 1);
//	pool->release();
//	pool = Cocoa.NSAutoreleasePool->new()->init();
  if(i%10 ==0) {purge_autorelease_pool();werror("!!!!!!! purge!\n");}
  i ++;
}
