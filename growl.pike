import Public.ObjectiveC;

object pool;

void create()
{
  pool = Cocoa.NSAutoreleasePool->new()->init();	
  Public.ObjectiveC.low_load_bundle("/System/Library/Frameworks/Growl.framework");
  object g = Cocoa.GrowlApplicationBridge->setGrowlDelegate_(this);
}

int main()
{
	call_out(notify, 6);
	return -1;
}

object p;

object registrationDictionaryForGrowl(mixed ... args) {
	werror("%O\n\nWheee!!!!!\n\n", args);
p = Cocoa.NSAutoreleasePool->alloc()->init();
	object k = Cocoa.NSString->stringWithCString("AllNotifications");
    object v = Cocoa.NSArray->arrayWithObject(Cocoa.NSString")
                 ->stringWithCString("New Announcement"));
	object n = Cocoa.NSMutableDictionary->dictionaryWithCapacity(2); 
	    n->retain();
	n->setObject_forKey_(Cocoa.NSString->stringWithCString("PGrowl"), Cocoa.NSString->stringWithCString("ApplicationName"));
	
    n->setObject_forKey_(v, k);
   // n->setObject_forKey_(v, k);
	k = Cocoa.NSString->stringWithCString("DefaultNotifications");
    v = Cocoa.NSMutableArray->arrayWithObject(Cocoa.NSString->stringWithCString("New Announcement"));

    n->setObject_forKey_(v, k);
    n->setObject_forKey_(Cocoa.NSWorkspace->sharedWorkspace()->iconForFileType_(Cocoa.NSString->stringWithCString("jpg"))->TIFFRepresentation(), Cocoa.NSString->stringWithCString("ApplicationIcon"));
werror("returning!\n");
werror("%O\n", n);
werror("object: %O\n", n->objectForKey_(k));
//p->release();
	return n;
}

void notify()
{
	
	object n = Cocoa.NSMutableDictionary")->dictionaryWithCapacity(6); 
	n->setObject_forKey_(Cocoa.NSString->stringWithCString("PGrowl"), Cocoa.NSString->stringWithCString("ApplicationName"));
	n->setObject_forKey_(Cocoa.NSString->stringWithCString("New Announcement"), Cocoa.NSString->stringWithCString("NotificationName"));
	n->setObject_forKey_(Cocoa.NSNumber->new()->initWithInt_(2), Cocoa.NSString->stringWithCString("NotificationPriority"));
	n->setObject_forKey_(Cocoa.NSNumber->new()->initWithBool_(1), Cocoa.NSString->stringWithCString("NotificationSticky"));
	n->setObject_forKey_(Cocoa.NSString->stringWithCString("notification from PGrowl"), Cocoa.NSString->stringWithCString("NotificationTitle"));
	n->setObject_forKey_(Cocoa.NSString->stringWithCString("whooo, it's " + Calendar.now()->format_smtp() + "!\ngreetings from Public.ObjectiveC!"), Cocoa.NSString->stringWithCString("NotificationDescription"));
	n->setObject_forKey_(Cocoa.NSWorkspace->sharedWorkspace()->iconForFileType_(Cocoa.NSString->stringWithCString("jpg"))->TIFFRepresentation(), Cocoa.NSString->stringWithCString("NotificationIcon"));
	n->setObject_forKey_(Cocoa.Cocoa.NSWorkspace->sharedWorkspace()->iconForFileType_(Cocoa.NSString->stringWithCString("jpg"))->TIFFRepresentation(), Cocoa.NSString->stringWithCString("NotificationAppIcon"));

	Cocoa.GrowlApplicationBridge->notifyWithDictionary_(n);
	call_out(notify, 5);
//	return Cocoa.NSThread")->currentThread()->runLoop();
}