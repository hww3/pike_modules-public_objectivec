
import Public.ObjectiveC;
object NSApp;

int main(int argc, array argv)
{
  NSApp = Cocoa.NSApplication.sharedApplication();
  add_constant("NSApp", NSApp);
  NSApp->activateIgnoringOtherApps_(1);

  add_backend_to_runloop(Pike.DefaultBackend, 0.3);
  return AppKit()->NSApplicationMain(argc, argv);
}

