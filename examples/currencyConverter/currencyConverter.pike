#!/usr/local/bin/pike

import Public.ObjectiveC;

object NSApp;

int main(int argc, array argv)
{  
  NSApp = Cocoa.NSApplication.sharedApplication();

  Cocoa.NSBundle.loadNibNamed_owner_("MainMenu", NSApp);

  werror("running NSApplicationMain()\n");
  return AppKit()->NSApplicationMain(argc, argv);
}
