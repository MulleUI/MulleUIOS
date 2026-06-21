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
@implementation UIWindow( OSGraphicsContextClass)

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

#endif
