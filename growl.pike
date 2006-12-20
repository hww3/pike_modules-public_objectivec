import Public.ObjectiveC;
int i;
object pool;
/*
int isKindOfClass_(program p)
{
  return 1;
}
*/
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


mapping registrationDictionaryForGrowl(mixed ... args) {

	mapping n = ([]);
	
	n->ApplicationName = "PGrowl";
	n->AllNotifications = ({"New Announcement"});
	n->DefaultNotifications = ({"New Announcement"});
    n->ApplicationIcon = Cocoa.NSWorkspace.sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation();

	return n;
}

void notify()
{
	mapping n = ([]);

	n->ApplicationName = "PGrowl";
	n->NotificationName = "New Announcement";
	n->NotificationPriority = Cocoa.NSNumber.numberWithInt_(2);
	n->NotificationSticky = Cocoa.NSNumber.numberWithBool_(0);
	n->NotificationTitle = "notification from PGrowl";
	n->NotificationDescription = "whooo, it's " + Calendar.now()->format_smtp() + "!\ngreetings from Public.ObjectiveC!";
	n->NotificationIcon = Cocoa.NSWorkspace.sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation();
	n->NotificationAppIcon = Cocoa.NSWorkspace.sharedWorkspace()->iconForFileType_("jpg")->TIFFRepresentation();

	get_dynamic_class("GrowlApplicationBridge")->notifyWithDictionary_(n);

    // lather, rinse and repeat.
	call_out(notify, 5);
}
