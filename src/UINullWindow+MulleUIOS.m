//
//  UINullWindow+MulleUIOS.m
//  MulleUIOS
//
//  Backend wiring for UINullWindow
//

#import "MulleUIOS.h"
#import "import-private.h"

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UINullWindow( OSWindowMulleUIOS)

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
   return( ClassStatic.windowClass ? ClassStatic.windowClass : [UINullOSWindow class]);
}

@end
