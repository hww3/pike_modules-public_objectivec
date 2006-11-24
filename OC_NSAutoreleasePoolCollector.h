@interface OC_NSAutoreleasePoolCollector: NSObject
{ id release_pool; id main_thread;}
-(void)newAutoreleasePool;
-(id)getAutoreleasePool;
-(void)targetForBecomingMultiThreaded:(id)sender;
-(void)purgeAndNew;
@end

