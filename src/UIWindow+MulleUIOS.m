//
//  UIWindow+MulleUIOS.m
//  MulleUIOS
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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
   // Metal backend: request a GLFW_NO_API window (.api = 1). GLFWOSWindow
   // then attaches a CAMetalLayer instead of creating a GL context, which
   // the Metal CG backend renders into via -backendMetalLayer.
   case CG_METAL   : hints = GLFWGraphicsHintsNone;  break;
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
