import Public.ObjectiveC;
int i;
object pool;

int isKindOfClass_(program p)
{
  return 1;
}

void create()
{
  Public.ObjectiveC.load_bundle("Growl.framework");
  program g = get_dynamic_class("GrowlApplicationBridge");
  werror("%O\n", g);
  g->setGrowlDelegate_(this);
}


int main()
{
	call_out(notify, 6);
	return -1;
}
object p;

object registrationDictionaryForGrowl(mixed ... args) {

	object n = Cocoa.NSMutableDictionary.dictionaryWithCapacity_(2); 

	n->setObject_forKey_("PGrowl", "ApplicationName");  
	n->setObject_forKey_(({"New Announcement"}), "AllNotifications");
	n->setObject_forKey_(({"New Announcement"}), "DefaultNotifications");

  n->setObject_forKey_(Cocoa.NSWorkspace.sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation(), 
    "ApplicationIcon");
	return n;
}

void notify()
{
	object n = Cocoa.NSMutableDictionary.dictionaryWithCapacity_(6); 
	n->setObject_forKey_("PGrowl", "ApplicationName");
	n->setObject_forKey_("New Announcement", "NotificationName");
	n->setObject_forKey_(Cocoa.NSNumber.numberWithInt_(2), "NotificationPriority");
	n->setObject_forKey_(Cocoa.NSNumber.numberWithBool_(0), "NotificationSticky");
	n->setObject_forKey_("notification from PGrowl", "NotificationTitle");
	n->setObject_forKey_("whooo, it's " + Calendar.now()->format_smtp() + "!\ngreetings from Public.ObjectiveC!", "NotificationDescription");
	n->setObject_forKey_(Cocoa.NSWorkspace.sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation(), "NotificationIcon");
	n->setObject_forKey_(Cocoa.NSWorkspace.sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation(), "NotificationAppIcon");

	get_dynamic_class("GrowlApplicationBridge")->notifyWithDictionary_(n);
	call_out(notify, 5);
}
