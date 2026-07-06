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

   hints = GLFWGraphicsHintsDefault;
   switch( [CGContext nanoVGBackend])
   {
   case CG_GL3     : hints = GLFWGraphicsHintsGL3;   break;
   case CG_GL3_2   : hints = GLFWGraphicsHintsGL3_2; break;
   case CG_GLES2   : hints = GLFWGraphicsHintsGLES2; break;
   case CG_GLES3   : hints = GLFWGraphicsHintsGLES3; break;
   case CG_GLES3_2 : hints = GLFWGraphicsHintsGLES3_2; break;
   }
   return( hints);
#endif
#ifdef HAVE_IMPORT__MULLE_SDL
   UIOSWindowGraphicsHints   hints;

   hints = SDLGraphicsHintsDefault;
   switch( [CGContext nanoVGBackend])
   {
   case CG_GL3   : hints = SDLGraphicsHintsGL3;   break;
   case CG_GL3_2 : hints = SDLGraphicsHintsGL3_2; break;
   case CG_GLES2 : hints = SDLGraphicsHintsGLES2; break;
   case CG_GLES3 : hints = SDLGraphicsHintsGLES3; break;
   case CG_D3D11 : hints = SDLGraphicsHintsD3D11; break;
   default       : break;
   }
   return( hints);
#endif
   return( (UIOSWindowGraphicsHints) { 0 });
}

@end
