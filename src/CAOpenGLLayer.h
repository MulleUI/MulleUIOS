//
//  CAOpenGLLayer.h
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
#import "import.h"

@class CAOpenGLLayer;


typedef void   CAOpenGLLayerViewPortCallback_t( CAOpenGLLayer *layer, CGContext *context);

@interface CAOpenGLLayer : CGGraphicsLayer
{
   CGRect   _viewPort;
   CGRect   _scissor;
@private
   CGRect   _previousViewPort;

   // just needed to draw a default triangle (sigh)
   unsigned int   _program;
   unsigned int   _vao;
   unsigned int   _vbo;
}

@property( assign) CAOpenGLLayerViewPortCallback_t  *viewPortDidChangeCallback;
@property( readonly) CGRect                         viewPort;
@property( readonly) CGRect                         scissor;

// setup viewport and scissor
- (void) beginOpenGLWithContext:(CGContext *) context;


// will always return YES for proper texture mapping(sic!)
- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha;

// actual openGL drawing. if you are doing texture mapping the background
// needs to be cleared, otherwise the stencil buffer
- (void) drawOpenGLInContext:(CGContext *) context;
// this flushes
- (void) endOpenGLWithContext:(CGContext *) context;


// call callback, if you didn't override it
// this is called from beginOpenGLWithContext, when the viewport and
// scissor as well as the projections have been set up
- (void) viewPortDidChange:(CGContext *) context;

@end 
