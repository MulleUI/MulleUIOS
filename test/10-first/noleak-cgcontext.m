#import <MulleUIOS/MulleUIOS.h>


int   main( int argc, char *argv[])
{
   UIApplication           *app;
   UIWindow                *window;
   NSUInteger              styleMask;
   id <UIGraphicsContext>  context;

   app        = [UIApplication object];

   assert( ! UIApp); // because we don't use sharedInstance
   styleMask  = UIWindowStyleMaskDefault;
   styleMask &= ~UIWindowStyleRetained;
   styleMask |= UIWindowStyleInvisible;
   window     = [UIWindow windowWithFrame:CGRectMake( 0, 0, 100, 100)
                          titleUTF8String:NULL
                                styleMask:styleMask];
   assert( ! UIApp); // because we don't use convenience constructor
   [app addWindow:window];

   context = [window activateWindowGraphicsContext];
   [window deactivateGraphicsContext:context];

   [app terminate];

   return( 0);
}


/*
 * extension : mulle-sde/objc-test-library-demo
 * directory : demo/all
 * template  : .../noleak.m
 * Suppress this comment with `export MULLE_SDE_GENERATE_FILE_COMMENTS=NO`
 */
