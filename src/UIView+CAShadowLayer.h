// prefer a local UIView over one in import.h
#ifdef __has_include
# if __has_include( "UIView.h")
#  import "UIView.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface UIView( CAShadowLayer)

- (void) setShowsShadow:(BOOL) flag;
- (BOOL) isShowingShadow;

// this will assert, if isShowingShadow returns NO
- (CAShadowLayer *) shadowLayer;

@end
