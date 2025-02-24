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

//#define ACTIVE_DEBUG

//
// This needs to be implemented by the context owner. This is not a bug.
// setActive: is not supposed to be seen outside of the window setting this
// context active. (Locking is done in GLFWOSWindow with the implicit context!)
//
#pragma clang diagnostic ignored "-Wprotocol"

@implementation CGContext( UIWindow)

- (void) setActive:(BOOL) flag
{
#ifdef ACTIVE_DEBUG
   if( (_activeThread != nil) != flag)
      MulleUILog( "<%@ %p> transitions from %s to %s",
                  self, self,
                  (_activeThread != nil) ? "YES": "NO",
                  flag ? "YES": "NO");
#endif
   _activeThread = flag ? [NSThread currentThread] : nil;
}


- (id <UIImage>) imageWithFramebuffer:(id <UILayer>) framebuffer
{
   CGFramebuffer   *layer = (CGFramebuffer *) framebuffer;
   CGImage         *image;

   assert( [framebuffer isKindOfClass:[CGFramebuffer class]]);

   image = [[[CGImage alloc] initWithSharedGPUTexture:[layer sharedGPUTexture]
                                           bitmapSize:[layer bitmapSize]
                                         textureFlags:[layer textureFlags]
                                              context:self] autorelease];
   return( image);
}


@end


// need this to be able to get protocol into runtime
@implementation UIWindow( UIEventReceiver)
@end


@implementation CALayer( UIOSWindow)

- (instancetype) initWithFrame:(CGRect) frame
                      OSWindow:(id <UIOSWindow>) window
{
   return( [self initWithFrame:frame]);
}

@end


// need this to be able to get protocol into runtime
@implementation CGGraphicsLayer( UILayer)
@end


@implementation CGImage( UIImage)
@end


@implementation CGFramebuffer( UIFramebuffer)
@end


@implementation UIView( CGGraphicsLayer)

+ (Class) layerClass
{
   return( [CGGraphicsLayer class]);
}


//
// a layout context, is stored on a per thread basis. It's actually not
// UIWindow based.
//
// MEMO: maybe pass this like a graphics context to the layout routines
//       breaking a little API compatibilty.
//
- (id <UILayoutContext>) layoutContext
{
   id <UILayoutContext>  context;

   context = MulleThreadObjectForKeyUTF8String( "UILayoutContext");
   if( ! context)
   {
      context = [[CGLayoutContext new] autorelease];
      MulleThreadSetObjectForKeyUTF8String( context, "UILayoutContext");
   }

   return( context);
}

@end


@implementation UIWindow( CGGraphicsLayer)

- (CGGraphicsLayerDrawCallback_t *) drawCallback
{
   return( [[self contentView] drawCallback]);
}


- (void) setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawStuff
{
   // property clearer will hit us on finalize (if things go wrong)
   assert( ! drawStuff || [self contentView]);
   [[self contentView] setDrawCallback:drawStuff];
}

@end 


