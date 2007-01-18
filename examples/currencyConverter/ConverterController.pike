inherit Public.ObjectiveC.Cocoa.NSObject;

object exchangeRate;
object dollarsToConvert;
object convertedAmount;

object currencyList;

void awakeFromNib()
{
  currencyList->addItemsWithTitles_( ({"USD", "CAD", "GBP"}) );
}

void chooseCurrency_(object action)
{
  string selected = (string)currencyList->selectedItem()->title();

  float exr = 0.0;

  switch(selected)
  {
    case "USD":
      exr = 1.0;
      break;

    case "CAD":
      exr = 1.24;
      break;

    case "GBP":
      exr = 0.67;
      break;
  }

  exchangeRate->setFloatValue_(exr);
}

void convert_(object action)
{
  float x;
  x = exchangeRate->floatValue() * dollarsToConvert->floatValue();
  convertedAmount->setFloatValue_(x);
}
