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

#endif
