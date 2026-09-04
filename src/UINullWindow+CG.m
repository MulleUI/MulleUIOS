//
//  UINullWindow+CG.m
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
//  UINullWindow+CG.m
//  MulleUIOS
//
//  CG wiring for UINullWindow (no-draw/vibecoding path)
//

#import "MulleUIOS.h"

#import "import-private.h"

#ifdef HAVE_IMPORT__MULLE_CG

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UINullWindow( OSWindowCG)

static struct
{
   Class   contextClass;
} ClassStatic;


+ (void) setOSGraphicsContextClass:(Class) cls
{
   ClassStatic.contextClass = cls;
}

+ (Class) osGraphicsContextClass
{
   return( ClassStatic.contextClass ? ClassStatic.contextClass : [CGContext class]);
}

@end


//
// The OS window itself dictates which graphics context class to use, because
// it owns the backend. A UINullOSWindow has no GPU backend, so it always wants
// the no-draw CGNullContext -- regardless of whether the owning window is a
// UINullWindow or a regular UIWindow created with UIWindowStyleNoDrawing (both
// route to a UINullOSWindow). GPU-backed OS windows do not implement this and
// the window layer falls back to its class default (CGContext).
//
@implementation UINullOSWindow( CG)

- (Class) osGraphicsContextClass
{
   return( [CGNullContext class]);
}

@end

#endif
