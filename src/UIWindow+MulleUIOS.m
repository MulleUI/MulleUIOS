//
//  UIWindow+MulleUIOS.m
//  MulleUIOS
//
//  Backend wiring for UIWindow
//

#import "MulleUIOS.h"
#import "import-private.h"
#ifdef HAVE_IMPORT__MULLE_GLFW
# import <MulleCGNanovg/CGContext+nanovg.h>
#endif

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UIWindow( OSWindowClass)

static struct
{
   Class   windowClass;
} ClassStatic;

+ (void) setOSWindowClass:(Class) cls
{
   ClassStatic.windowClass = cls;
}

+ (Class) osWindowClass
{
#ifdef HAVE_IMPORT__MULLE_GLFW
   return( ClassStatic.windowClass ? ClassStatic.windowClass : [GLFWOSWindow class]);
#endif
#ifdef HAVE_IMPORT__MULLE_SDL
   return( ClassStatic.windowClass ? ClassStatic.windowClass : [SDLOSWindow class]);
#endif
   return( ClassStatic.windowClass);
}

+ (UIOSWindowGraphicsHints) osGraphicsHints
{
#ifdef HAVE_IMPORT__MULLE_GLFW
   UIOSWindowGraphicsHints   hints;

   hints = GLFW_DEFAULT_CONTEXT;
   switch( [CGContext nanoVGBackend])
   {
   case CG_GL3     : hints = GLFW_GL3_CONTEXT;   break;
   case CG_GL3_2   : hints = GLFW_GL3_2_CONTEXT; break;
   case CG_GLES2   : hints = GLFW_GLES2_CONTEXT; break;
   case CG_GLES3   : hints = GLFW_GLES3_CONTEXT; break;
   case CG_GLES3_2 : hints = GLFW_GLES3_2_CONTEXT; break;
   }
   return( hints);
#endif
#ifdef HAVE_IMPORT__MULLE_SDL
   UIOSWindowGraphicsHints   hints;

   hints = SDL_DEFAULT_CONTEXT;
   switch( [CGContext nanoVGBackend])
   {
   case CG_GL3   : hints = SDL_GL3_CONTEXT;   break;
   case CG_GL3_2 : hints = SDL_GL3_2_CONTEXT; break;
   case CG_GLES2 : hints = SDL_GLES2_CONTEXT; break;
   case CG_GLES3 : hints = SDL_GLES3_CONTEXT; break;
   case CG_D3D11 : hints = SDL_D3D11_CONTEXT; break;
   default       : break;
   }
   return( hints);
#endif
   return( (UIOSWindowGraphicsHints) { 0 });
}

@end
