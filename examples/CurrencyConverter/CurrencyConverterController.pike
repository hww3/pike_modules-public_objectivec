import Public.ObjectiveC;
inherit Public.ObjectiveC.Cocoa.NSObjectController;

float exchangeRate;

object dollarsToConvert;
object convertedAmount;

object currencyList;
object spinner;

object c = Protocols.XMLRPC.Client("http://foxrate.org/rpc/");

object app;

static void create()
{
  ::create();

   app = Cocoa.NSApplication.sharedApplication();
}

void _finishedMakingConnections()
{
   werror("*\n*\n*\n*\n*\n*\n");	
   currencyList->addItemsWithTitles_( ({"Choose", "CAD", "EUR", "DKK", "SEK", "GBP", "CHF"}) );
}

void chooseCurrency_(object action)
{
  spinner->startAnimation_(this);
  string selected = (string)currencyList->selectedItem()->title();

  float exr = 0.0;
  mapping res = c["foxrate.currencyConvert"]("USD", selected, 1.00)[0];

  if(res && !res->flerror)
    exr = res->amount;

  exchangeRate = exr;

  spinner->stopAnimation_(this);
}

void convert_(object action)
{
   float x;
   x = exchangeRate * dollarsToConvert->floatValue();
   convertedAmount->setFloatValue_(x);
}