#import <MulleUIWindow/MulleUIWindow.h>


int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;

   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleHidden, YES);

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 128, 128)
                      titleUTF8String:"Demo"
                            styleMask:styleMask];
   [app addWindow:window];
   [window processOneFrame:0.0001];
   [app terminate];

   return( 0);
}
