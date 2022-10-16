#import <MulleUIOS/MulleUIOS.h>


int   main( int argc, char *argv[])
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;
   CGContext       *offScreenContext;
   CGContext       *context;
   CGLayer         *layer;

   app        = [UIApplication object];
   assert( ! UIApp); // because we don't use sharedInstance
   styleMask  = UIWindowStyleMaskDefault;
   styleMask |= UIWindowStyleInvisible;
   window     = [[[UIWindow alloc] initWithFrame:CGRectMake( 0, 0, 100, 100)
                                 titleUTF8String:NULL
                                       styleMask:styleMask] autorelease];
   assert( ! UIApp); // because we don't use convenience constructor

   offScreenContext = [window activateOffscreenGraphicsContext];
   layer = [CGLayer layerWithBitmapSize:MulleIntegerSizeMake( 20, 20)
                             imageFlags:0
                                context:offScreenContext];
   [offScreenContext recycleFramebuffer:layer];
   [window deactivateGraphicsContext:offScreenContext];

   context = [window activateWindowGraphicsContext];
   layer   = [offScreenContext acquireRecycledFramebuffer];
   [window deactivateGraphicsContext:context];

   [app addWindow:window];
   [app terminate];

   return( 0);
}


/*
 * extension : mulle-sde/objc-test-library-demo
 * directory : demo/all
 * template  : .../noleak.m
 * Suppress this comment with `export MULLE_SDE_GENERATE_FILE_COMMENTS=NO`
 */
