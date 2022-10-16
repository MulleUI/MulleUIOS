#import <MulleUIOS/MulleUIOS.h>

static char   image[ 1][ 1][ 4] =
{
   {
      { 0xFF, 0x80, 0x00, 0xFF }
   }
};



struct CGBitmap  bitmap = CGBitmapData( image, CGBitmapInfoData( 1, 1, 4, CGBitmapEncodingRGBABytes), NULL);



int   main( int argc, char *argv[])
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;
   CGContext       *context;

   app        = [UIApplication object];
   assert( ! UIApp); // because we don't use sharedInstance
   styleMask  = UIWindowStyleMaskDefault;
   styleMask &= ~UIWindowStyleRetained;
   styleMask |= UIWindowStyleInvisible;
   window     = [[[UIWindow alloc] initWithFrame:CGRectMake( 0, 0, 100, 100)
                                 titleUTF8String:NULL
                                       styleMask:styleMask] autorelease];
   assert( ! UIApp); // because we don't use convenience constructor
   [app addWindow:window];

   context = [window activateWindowGraphicsContext];
   [[[CGImage alloc] initWithBitmap:bitmap
                         imageFlags:0
                            context:context] autorelease];
   [app terminate];

   return( 0);
}


/*
 * extension : mulle-sde/objc-test-library-demo
 * directory : demo/all
 * template  : .../noleak.m
 * Suppress this comment with `export MULLE_SDE_GENERATE_FILE_COMMENTS=NO`
 */
