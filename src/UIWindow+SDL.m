//
//  UIWindow+SDL.m
//  MulleUIOS
//
//  SDL backend wiring for UIWindow
//

#import "MulleUIOS.h"
#import "import-private.h"

#ifdef HAVE_IMPORT__MULLE_SDL

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UIWindow( OSWindowSDL)

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
   return( Self.windowClass ? Self.windowClass : [SDLOSWindow class]);
}

+ (NSUInteger) osGraphicsHints
{
   NSUInteger   hints;

   hints = SDL_DEFAULT_CONTEXT;
   switch( [CGContext nanoVGBackend])
   {
   case CG_GL3   : hints = SDL_GL3_CONTEXT;   break;
   case CG_GL3_2 : hints = SDL_GL3_2_CONTEXT; break;
   case CG_GLES2 : hints = SDL_GLES2_CONTEXT; break;
   case CG_GLES3 : hints = SDL_GLES3_CONTEXT; break;
   }
   return( hints);
}

@end

#endif
