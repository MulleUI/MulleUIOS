//
//  MulleUIOS.m
//  MulleUIOS
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  Copyright (c) 2021 Codeon GmbH.
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
#import "MulleUIOS.h"

#import "import-private.h"

// OS specifica, currently its all the same though

@implementation UIWindow( OSWindowClass)

+ (Class) osWindowClass
{
   return( [GLFWWindow class]);
}

+ (Class) osGraphicsContextClass
{
   return( [CGContext class]);
}


+ (NSUInteger) osGraphicsHints
{
   NSUInteger   hints;

   hints = GLFW_DEFAULT_CONTEXT;
   switch( [CGContext backend])
   {
   case CG_GL3   : hints = GLFW_GL3_CONTEXT;   break;
   case CG_GL3_2 : hints = GLFW_GL3_2_CONTEXT; break;
   case CG_GLES2 : hints = GLFW_GLES2_CONTEXT; break;
   case CG_GLES3 : hints = GLFW_GLES3_CONTEXT; break;
   }
   return( hints);
}

@end


//
// This needs to be implemented by the context owner. This is not a bug.
// setActive: is not supposed to be seen outside of the window setting this
// context active. (Locking is done in GLFWWindow with the implicit context!)
//
@implementation CGContext( UIWindow)

- (void) setActive:(BOOL) flag
{
   _isActive = flag;
}


- (id) shareImage:(id) image
      withContext:(id <UIOSGraphicsContext>) otherContext
{
   assert( [otherContext isKindOfClass:[CGContext class]]);

   return( [image shareWithContext:(CGContext *) otherContext]);
}

@end


// need this to be able to get protocol into runtime
@implementation UIWindow( UIEventReceiver)
@end


// need this to be able to get protocol into runtime
@implementation CALayer( UILayer)
@end


@implementation UIView( CALayer)

+ (Class) layerClass
{
   return( [CALayer class]);
}

@end

