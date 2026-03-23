//
//  UIWindow+GLFW.m
//  MulleUIOS
//
//  GLFW backend wiring for UIWindow
//

#import "MulleUIOS.h"
#import "import-private.h"
#import <MulleCGNanoVG/CGContext+nanovg.h>

#ifdef HAVE_IMPORT__MULLE_GLFW

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UIWindow( OSWindowGLFW)

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
   return( Self.windowClass ? Self.windowClass : [GLFWOSWindow class]);
}

+ (NSUInteger) osGraphicsHints
{
   NSUInteger   hints;

   hints = GLFW_DEFAULT_CONTEXT;
   switch( [CGContext nanoVGBackend])
   {
   case CG_GL3     : hints = GLFW_GL3_CONTEXT; break;
   case CG_GL3_2   : hints = GLFW_GL3_2_CONTEXT; break;
   case CG_GLES2   : hints = GLFW_GLES2_CONTEXT; break;
   case CG_GLES3   : hints = GLFW_GLES3_CONTEXT; break;
   case CG_GLES3_2 : hints = GLFW_GLES3_2_CONTEXT; break;
   }
   return( hints);
}

@end

#endif
