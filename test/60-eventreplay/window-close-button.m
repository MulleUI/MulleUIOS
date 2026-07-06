#import <MulleUIWindow/MulleUIWindow.h>
#import <MulleUIApplication/UIEventPlayer.h>


int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   UIEventPlayer   *player;

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 128, 128)
                      titleUTF8String:"CloseButtonTest"
                            styleMask:UIWindowStyleNoDrawing];
   if( ! window)
   {
      mulle_fprintf( stderr, "windowWithFrame: failed\n");
      return( 1);
   }
   [app addWindow:window];

   player = [UIEventPlayer instance];
   if( ! [player loadScriptWithUTF8String:"2.0 closeButton\n"])
   {
      mulle_fprintf( stderr, "loadScriptWithUTF8String: failed\n");
      return( 1);
   }
   [app setEventPlayer:player];
   [player startPlayback];

   while( [app runLoopIteration] && [app numberOfWindows] > 0)
      ;

   mulle_printf( "window closed\n");
   return( 0);
}
