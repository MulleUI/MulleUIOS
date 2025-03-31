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

#import "import.h"

#define MULLE_UI_OS_VERSION   ((0 << 20) | (0 << 8) | 1)

#import "_MulleUIOS-export.h"
#include "_MulleUIOS-provide.h"

#ifdef __has_include
# if __has_include( "_MulleUIOS-versioncheck.h")
#  include "_MulleUIOS-versioncheck.h"
# endif
#endif


@interface UIWindow( OSWindowClass) <UIEventReceiver>

+ (void) setOSWindowClass:(Class) cls;
+ (void) setOSGraphicsContextClass:(Class) cls;
+ (Class) osWindowClass;
+ (Class) osGraphicsContextClass;

@end


@interface CGContext( UIWindow) <UIGraphicsContext>

//
// Make sure that image is completely drawn by the GPU before calling this.
// (use [CGContext barrier])
// this is used to create a local image from a layer acquired from an
// offscreen context (otherwise you could just use the layer as a CGImage)
//

@end


@interface CGImage( UIImage) <UIImage>
@end


@interface CGFramebuffer( UIFramebuffer) <UIFramebuffer>
@end


@interface CALayer( UIOSWindow) < MulleUINamedObject>

- (instancetype) initWithFrame:(CGRect) frame
                      OSWindow:(id <UIOSWindow>) window;
@end



@interface CGGraphicsLayer( UILayer) <UILayer>
@end


//
// these all get fowarded to the "main" layer
//
@interface UIView( CGGraphicsLayerForwarding)

@property( assign) CGGraphicsLayerDrawCallback_t    *drawCallback;
@property( observable) MulleCornerInsets            cornerInsets;
@property( observable) CGFloat                      borderWidth;
@property( observable) CGFloat                      opacity;
@property( observable) CGPaint                      *borderPaint;
@property( observable) CGPaint                      *backgroundPaint;
@property( observable) CGPoint                      pixelCenter;
@property( assign) BOOL                             masksToBounds;

- (void) setBorderColor:(CGColor) color;
- (void) setBackgroundColor:(CGColor) color;
- (void) setCornerRadius:(CGFloat) radius;

@end


@interface UIWindow( CGGraphicsLayer)

@property( dynamic) CGGraphicsLayerDrawCallback_t    *drawCallback;

@end 


