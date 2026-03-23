#import <MulleUIWindow/MulleUIWindow.h>


int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;

   app       = [UIApplication sharedInstance];

   styleMask = UIWindowStyleNoDrawing|UIWindowStyleClearType;
   window    = [UIWindow windowWithFrame:CGRectMake( 0, 0, 128, 128)
                         titleUTF8String:"Test"
                               styleMask:styleMask];
   if( ! window)
   {
      fprintf( stderr, "windowWithFrame: failed\n");
      exit( 1);
   }
   [app addWindow:window];
   [app terminate];
   return( 0);
}