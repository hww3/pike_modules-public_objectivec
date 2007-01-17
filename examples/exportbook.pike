import Public.ObjectiveC;
array fields = ({
  Cocoa.ABAddressBook.kABLastNameProperty,
  Cocoa.ABAddressBook.kABFirstNameProperty,
  Cocoa.ABAddressBook.kABEmailProperty
});


int main()
{

  object book = Cocoa.ABAddressBook.sharedAddressBook();
  do{
  object p = book->people();
//  int count = p->count();
  foreach(p;; object person)
//  for(int i = 0; i < count; i++)
  {
//    object person = p->objectAtIndex_(i);
    array row = ({});
    foreach(fields;; object f)
    {
       object fv = person->valueForKey_(f);
       if(object_program(fv) == Cocoa.ABMultiValue)       
         row += ({(string)fv->valueAtIndex_(0) });  
       else row += ({(string)fv});
    }
    write((row*",") + "\n");
//    person = 0;
  }
//p=0;
} while(0);
//book = 0;
sleep(60);
  return 0;
}

