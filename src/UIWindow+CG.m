//
//  UIWindow+CG.m
//  MulleUIOS
//
//  CG-related helpers for UIWindow integration
//

#import "MulleUIOS.h"
#import "import-private.h"


#ifdef HAVE_IMPORT__MULLE_CG

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

// UIWindow graphics context class selection lives here
@implementation UIWindow( OSWindowCG)

static struct
{
   Class   contextClass;
} Self;

+ (void) setOSGraphicsContextClass:(Class) cls
{
   Self.contextClass = cls;
}

+ (Class) osGraphicsContextClass
{
   return( Self.contextClass ? Self.contextClass : [CGContext class]);
}

@end

// CG helper
@implementation CGContext( UIWindow)

- (id <UIImage>) imageWithFramebuffer:(id <UILayer>) framebuffer
                       nameUTF8String:(char *) nameUTF8String
{
   CGFramebuffer   *layer = (CGFramebuffer *) framebuffer;
   CGImage         *image;

   assert( [framebuffer isKindOfClass:[CGFramebuffer class]]);

   image = [[[CGImage alloc] initWithSharedGPUTexture:[layer sharedGPUTexture]
                                           bitmapSize:[layer bitmapSize]
                                         textureFlags:[layer textureFlags]
                                       nameUTF8String:nameUTF8String
                                              context:self] autorelease];
   return( image);
}

@end

#endif
