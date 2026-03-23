#import <MulleUIOS/MulleUIOS.h>

@class UINullWindow;
@class UINullOSWindow;

int main( void)
{
   UIApplication           *app;
   id <UIWindow>           window;
   id <UIGraphicsContext>  context;
   NSUInteger              styleMask;

   app = [UIApplication instance];

   styleMask = UIWindowStyleNoDrawing|UIWindowStyleClearType;
   UINullOSWindow *osw = [[[UINullOSWindow alloc] initWithFrame:CGRectMake( 0, 0, 64, 64)
                                                  titleUTF8String:NULL
                                                        styleMask:styleMask] autorelease];
   window = (id<UIWindow>)[[[UINullWindow alloc] initWithOSWindow:osw
                                                        styleMask:styleMask] autorelease];
   if( ! window)
   {
      fprintf( stderr, "UINullWindow initWithOSWindow: failed\n");
      return( 1);
   }

   [app addWindow:window];

   context = [window renderGraphicsContext];
   if( ! context)
   {
      fprintf( stderr, "No graphics context returned\n");
      return( 1);
   }

   [app terminate];
   return( 0);
}
