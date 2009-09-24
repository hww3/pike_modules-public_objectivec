import Public.ObjectiveC;
array fields = ({
  Cocoa.ABAddressBook.kABOrganizationProperty,
  Cocoa.ABAddressBook.kABLastNameProperty,
  Cocoa.ABAddressBook.kABFirstNameProperty,
  Cocoa.ABAddressBook.kABEmailProperty
});

    array row = ({});

int main()
{
  object book = Cocoa.ABAddressBook.sharedAddressBook();
  mixed e;
  object p = book->people();
  foreach(p;; object person)
  {
    row = ({});
    foreach(fields;; object f)
    {
       object fv = person->valueForKey_(f);
       describe_value(fv);
    }
    werror((row*",") + "\n");
  }
  purge_autorelease_pool();
  return 0;
}

void describe_value(object fv)
{
  mixed e;
  if(object_program(fv) == Cocoa.ABMultiValueCoreDataWrapper)
  {
	for(int i = 0; i < fv->count(); i++)
  		describe_value(fv->valueAtIndex_(i));  

  }
  else 
  {
    e = catch {
      row += ({(string )fv});
    };
    if(e){
	werror("error!\n");
/*
	werror("error casting %O, %O to string.\n",  
		fv?fv->__objc_classname:"",
		fv?sort(indices(fv)):fv);
*/ 
exit(1);}
  }
}
