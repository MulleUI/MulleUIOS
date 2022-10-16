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

// Make sure that image is completey drawn by the GPU before calling this.
// (use [CGContext barrier])
- (id <UIImage>) shareImage:(id <UIImage>) image
                withContext:(id <UIGraphicsContext>) context;

@end


@interface CGImage( UIImage) <UIImage>
@end


@interface CALayer( UILayer) <UILayer>
@end


//
// these all get fowarded to the "main" layer
//
@interface UIView( CALayerForwarding)

@property void                      (*drawCallback)( CALayer *, CGContext *ctxt);
@property( observable) CGFloat      cornerRadius;
@property( observable) CGFloat      borderWidth;
@property( observable) CGFloat      opacity;
@property( observable) CGColor      borderColor;
@property( observable) CGColor      backgroundColor;
@property( observable) CGPoint      pixelCenter;
@property( observable) BOOL         masksToBounds;

@end


@interface UIWindow( CALayer)

@property( dynamic) CALayerDrawCallback_t    *drawCallback;

@end 


@interface CAOpenGLLayer( GLFW)

- (NSUInteger) windowStyleMaskBits;

@end