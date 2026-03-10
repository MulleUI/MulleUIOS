#import <MulleUIOS/MulleUIOS.h>

@class UINullWindow;

int main( void)
{
   UINullWindow            *window;
   id <UIGraphicsContext>  context;

   window = [[[UINullWindow alloc] init] autorelease];
   if( ! window)
   {
      fprintf( stderr, "UINullWindow alloc/init failed\n");
      return( 1);
   }

   context = [window renderGraphicsContext];
   if( ! context)
   {
      fprintf( stderr, "UINullWindow did not auto-create OSWindow/CGContext; expected headless no-draw path.\n");
   }
   return( 0);
}
