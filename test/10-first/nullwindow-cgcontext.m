#import <MulleUIOS/MulleUIOS.h>

int main( int argc, char *argv[])
{
   UIApplication           *app;
   UIWindow                *window;
   NSUInteger              styleMask;
   id <UIGraphicsContext>  context;

   app       = [UIApplication instance];
   styleMask = UIWindowStyleMaskDefault;
   styleMask &= ~UIWindowStyleRetained;
   styleMask |= UIWindowStyleHidden;    // headless
   styleMask |= UIWindowStyleOffscreen; // no swap/draw

   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 64, 64)
                      titleUTF8String:NULL
                            styleMask:styleMask];
   if( ! window)
   {
      fprintf( stderr, "UIWindow creation failed\n");
      return( 1);
   }

   [app addWindow:window];

   context = [window activateWindowGraphicsContext];
   if( ! context)
   {
      fprintf( stderr, "No graphics context returned\n");
      return( 1);
   }
   [window deactivateGraphicsContext:context];

   [app terminate];
   return( 0);
}
