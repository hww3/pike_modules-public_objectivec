import Public.ObjectiveC;
array fields = ({
  Cocoa.ABAddressBook.kABLastNameProperty,
  Cocoa.ABAddressBook.kABFirstNameProperty,
  Cocoa.ABAddressBook.kABEmailProperty
});

    array row = ({});

int main()
{

  object book = Cocoa.ABAddressBook.sharedAddressBook();
int qq = 0;
mixed e;
  do{
  object p = book->people();
  foreach(p;; object person)
  {
row = ({});
    foreach(fields;; object f)
    {
       object fv = person->valueForKey_(f);
       describe_value(fv);
    }
    write((row*",") + "\n");
  }
  purge_autorelease_pool();
  qq++;
} while(qq<1000);
sleep(100);
  return 0;
}

void describe_value(object fv)
{
  mixed e;
  if(object_program(fv) == Cocoa.ABMultiValue)       
    describe_value(fv->valueAtIndex_(0));  
  else 
  {
    e = catch {
      row += ({(string )fv});
    };
    if(e){
//werror("error casting %O, %O to string.\n",  
//fv?fv->__objc_classname:"",
//fv?sort(indices(fv)):fv); 
exit(1);}
  }
}
