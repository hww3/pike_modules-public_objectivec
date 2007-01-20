import Public.ObjectiveC;
array fields = ({
  Cocoa.ABAddressBook.kABLastNameProperty,
  Cocoa.ABAddressBook.kABFirstNameProperty,
  Cocoa.ABAddressBook.kABEmailProperty
});


int main()
{

  object book = Cocoa.ABAddressBook.sharedAddressBook();
int qq = 0;
  do{
  object p = book->people();
  foreach(p;; object person)
  {
    array row = ({});
    foreach(fields;; object f)
    {
       object fv = person->valueForKey_(f);
       if(object_program(fv) == Cocoa.ABMultiValue)       
         row += ({(string)fv->valueAtIndex_(0) });  
       else row += ({(string)fv});
    }
    write((row*",") + "\n");
  }
  purge_autorelease_pool();
  qq++;
} while(qq<1000);
  return 0;
}

