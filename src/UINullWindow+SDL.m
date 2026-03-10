//
//  UINullWindow+SDL.m
//  MulleUIOS
//
//  SDL wiring for UINullWindow to use UINullOSWindow
//

#import "MulleUIOS.h"
#import "import-private.h"

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

#ifdef HAVE_IMPORT__MULLE_SDL

@class UINullOSWindow;

@implementation UINullWindow( OSWindowSDL)

static struct
{
   Class   windowClass;
} Self;

+ (void) setOSWindowClass:(Class) cls
{
   Self.windowClass = cls;
}

+ (Class) osWindowClass
{
   return( Self.windowClass ? Self.windowClass : [UINullOSWindow class]);
}

@end

#endif
