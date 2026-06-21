#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


// Test for double-count bug in textOriginInRect:
// CGRectGetMinX/MidX/MaxX already include rect.origin.x, but
// origin.x += rect.origin.x is added again — doubling the offset
// when rect.origin.x != 0.

int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   CGRect               rect;
   CGPoint              origin;

   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];

   [layouter setTextLayer:layer];
   [layer setFontPixelSize:16.0f];
   [layer setFrame:CGRectMake( 0, 0, 200, 40)];

   // rect with non-zero origin to expose the double-count
   rect = CGRectMake( 20, 0, 160, 40);

   [layer setTextUTF8String:"Hi"];

   [layer setTextAlignment:UITextAlignmentLeft];
   [layer setTextVerticalAlignment:UITextAlignmentTop];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "left   origin.x=%.1f  CGRectGetMinX=%.1f  match=%s\n",
           origin.x, CGRectGetMinX( rect),
           origin.x == CGRectGetMinX( rect) ? "YES" : "NO (double-count bug)");

   [layer setTextAlignment:UITextAlignmentCenter];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "center origin.x=%.1f  CGRectGetMidX=%.1f  match=%s\n",
           origin.x, CGRectGetMidX( rect),
           origin.x == CGRectGetMidX( rect) ? "YES" : "NO (double-count bug)");

   [layer setTextAlignment:UITextAlignmentRight];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "right  origin.x=%.1f  CGRectGetMaxX=%.1f  match=%s\n",
           origin.x, CGRectGetMaxX( rect),
           origin.x == CGRectGetMaxX( rect) ? "YES" : "NO (double-count bug)");

   return( 0);
}
