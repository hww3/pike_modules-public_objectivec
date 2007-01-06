import Public.ObjectiveC;

array fields = ({
  Cocoa.ABAddressBook.kABLastNameProperty,
  Cocoa.ABAddressBook.kABFirstNameProperty,
  Cocoa.ABAddressBook.kABEmailProperty
});



int main()
{
  object book = Cocoa.ABAddressBook.sharedAddressBook();

  do {

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
gc();
  } while(1);
  return 0;
}

