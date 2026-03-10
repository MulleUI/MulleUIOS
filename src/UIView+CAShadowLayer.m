#import "UIView+CAShadowLayer.h"

#import "import-private.h"


@interface CALayer( UILayer) <UILayer>
@end


@implementation UIView ( CAShadowLayer)

- (void) setShowsShadow:(BOOL) flag
{
   // already there ? 
   if( flag && _shadowLayer)
      return;

   [_shadowLayer release];
   _shadowLayer = nil;

   if( flag)
      _shadowLayer = [CAShadowLayer new];
}


- (BOOL) isShowingShadow
{
   return( _shadowLayer ? YES : NO);
}


- (void) layoutShadowLayer:(id <UILayer>) layer
                layoutInfo:(struct UILayoutInfo *) info
{
   CAShadowLayer  *shadowLayer = (CAShadowLayer *) layer;
   CGRect         frame;
   UIEdgeInsets   shadowInsets;

   shadowInsets = [shadowLayer shadowInsets];

   // create new frame for shadow layer and copy insets down
   frame = UIEdgeInsetsExtrudeRect( info->rect, shadowInsets);
   [shadowLayer setFrame:frame];
   [shadowLayer layoutWithLayoutInfo:info];
}  


- (CAShadowLayer *) shadowLayer
{
   assert( _shadowLayer);
   return( (CAShadowLayer *) _shadowLayer);
}

@end
