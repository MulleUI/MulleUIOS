//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "import-private.h"

#include <string.h>
#define ROWS      2
#define COLUMNS   4
#define SPACING   10
static double  angles[] =
{
   -CA_2xPI,
   -CA_2xPI / 2.0,
   -CA_2xPI / 4.0,
   0,
   CA_2xPI / 4.0,
   CA_2xPI / 2.0,
   CA_2xPI
};
#define n_angles  (sizeof( angles) / sizeof( angles[ 0]))
static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *context)
{
   CAPolarPoint        polar;
   CGColor             color;
   CGFloat             end;
   CGFloat             initial;
   CGFloat             radius;
   CGFloat             start;
   CGPoint             centerPoint;
   CGPoint             leftPoint;
   CGPoint             rightPoint;
   CGRect              bottomRect;
   CGRect              canvas;
   CGRect              rect;
   CGRect              rects[ ROWS][ COLUMNS];
   CGRect              topRect;
   char                buf[ 128];
   int                 dir;
   int                 startingPoint;
   NSUInteger          frameNr;
   unsigned int        i, j;

   frameNr       = [context numberOfFrames] % 240 * 4;
   startingPoint = frameNr / 240;

   canvas  = [layer canvas];

   CGRectPartitionIntoRowsAndColumns( CGRectInset( canvas, SPACING, SPACING),
                                      CGSizeMake( SPACING, SPACING),
                                      ROWS,
                                      COLUMNS,
                                      (CGRect *) rects);
   [context useDefaultFont];

   for( i = 0; i < COLUMNS; i++)
   {
      start = angles[ rand() % n_angles];
      end   = angles[ rand() % n_angles];

      for( j = 0; j < ROWS; j++)
      {
         if( j & 0x1)
            dir = CGPathFillStyleHole;
         else
            dir = CARotationDirectionClockWise;

         rect = CGRectIntegral( rects[ j][ i]);

         CGContextStrokeRectWithColor( context, rect, 0.5, CGColorMakeBlack()); // Converted from mvgStrokeRectWithColor
         CGRectDivide( rect, &bottomRect, &topRect, 20, CADirectionBottom);

         CGContextSave( context);
         {
            CGContextIntersectScissor( context, rect); // Converted from mvgIntersectScissor

            // draw label
            sprintf( buf, "%s %.2g - %.2g", dir == CARotationDirectionClockWise ? "CW" : "CCW",
                                            start, end);
            CGContextTextColor( context, CGColorMakeBlack());
            CGContextTextBackgroundColor( context, CGColorMakeWhite());
            CGContextTextInRect( context, buf, (size_t) -1, bottomRect, CGContentModeCenterPoint, 0); // Converted from mvgTextInRect

            // mvgMoveTo( context, CGRectGetTop( topRect));

            centerPoint = CGRectGetCenter( topRect);
            radius      = CGRectGetInnerRadius( topRect) - 4.0;
            polar       = CAPolarPointMakeWithPoint( centerPoint);
            polar       = CAPolarPointAdd( polar, CAPolarPointMake( radius, start));
            leftPoint   = CGPointMakeWithPolarPoint( polar);
            polar       = CAPolarPointMakeWithPoint( centerPoint);
            polar       = CAPolarPointAdd( polar, CAPolarPointMake( radius, end));
            rightPoint  = CGPointMakeWithPolarPoint( polar);

            CGContextStrokeLineWithColor( context, centerPoint, leftPoint, 0.5, CGColorMakeBlack()); // Converted from mvgStrokeLineWithColor
            CGContextStrokeLineWithColor( context, centerPoint, rightPoint, 0.5, CGColorMakeRed()); // Converted from mvgStrokeLineWithColor

            switch( startingPoint)
            {
            case 0 : CGContextBeginPath( context);
                     break;

            case 1 : CGContextFillCircleWithColor( context, CACircleMakeWithCenterAndRadius( centerPoint, 4.0), CGColorMakeDarkGray()); // Converted from mvgFillCircleWithColor
                     CGContextBeginPath( context);
                     CGContextMoveTo( context, centerPoint); // Converted from mvgMoveTo
                     break;

            case 2 : CGContextFillCircleWithColor( context, CACircleMakeWithCenterAndRadius( leftPoint, 4.0), CGColorMakeDarkGray()); // Converted from mvgFillCircleWithColor
                     CGContextBeginPath( context);
                     CGContextMoveTo( context, leftPoint); // Converted from mvgMoveTo
                     break;

            case 3 : CGContextFillCircleWithColor( context, CACircleMakeWithCenterAndRadius( rightPoint, 4.0), CGColorMakeDarkGray()); // Converted from mvgFillCircleWithColor
                     CGContextBeginPath( context);
                     CGContextMoveTo( context, rightPoint); // Converted from mvgMoveTo
                     break;
            }

            CGContextArcRadians( context,
                          CACircleMakeWithCenterAndRadius( centerPoint, radius),
                          start,
                          end,
                          dir);
            color = CGColorMakeWithHSL( 0.2 + ((i + (j * 4)) / 7.0) * 0.6,
                                        1.0,
                                        0.6);
            CGContextStrokeColor( context, color);
            CGContextStrokeWidth( context, 3);
            CGContextStroke( context);

//            // little check to see if start = end sets moveTo, indeed it does
//            CGContextBeginPath( context);
//            nvgArc( CGContextGetNVGContext( context),
//                                            centerPoint.x,
//                                            centerPoint.y,
//                                            20.0,
//                                            end,
//                                            end,
//                                            dir);
//            nvgLineTo( CGContextGetNVGContext( context), 0, 0);
//            CGContextStrokeColor( context, CGColorMakeIndigo());
//            CGContextStrokeWidth( context, 7);
//            CGContextStroke( context);

         }
         CGContextRestore( context);
      }
   }
   return( YES);
}
void   setupScene( UIWindow *window)
{
   UIView   *view;
   CGRect   frame;

   frame  = [[window contentView] contentRect];
   view   = [UIView viewWithFrame:frame];
   [view setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawStuff];
   [[window contentView] addSubview:view];
}
static void   usage( void)
{
   fprintf( stderr, "\n"
"Usage:\n"
"   arc-cw [options]\n"
"\n"
"Options:\n"
"   -a      : disable default antialias (nvg/glfw)\n"
"   -f      : force edge antialias (nvg)\n"
"   -r      : not retained\n"
"\n");
   exit( 1);
}
int   main( int argc, char *argv[])
{
   UIWindow       *window;
   UIApplication  *app;
   NSUInteger     styleMask;
   int            i;

   styleMask = UIWindowStyleMaskDefault;

   /*
    * window and app
    */
   for( i = 1; i < argc; i++)
   {
      if( argv[ i][ 0] != '-')
         break;
      switch( argv[ i][ 1])
      {
      case 'r' :
         styleMask &= ~UIWindowStyleRetained;
         break;

      case 'f' :
         styleMask |= UIWindowStyleForceEdgeAntiAlias;
         break;

      case 'a' :
         styleMask &= ~UIWindowStyleAntiAlias;
         break;

      default :
         usage();
      }
   }

   if( i != argc)
      usage();

   app = [UIApplication sharedInstance];
   @autoreleasepool
   {
      window = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 600, 400)
                                titleUTF8String:"Demo"
                                      styleMask:styleMask] autorelease];

      assert( window);
      [window setBackgroundColor:CGColorMakeWhite()];
      [window setFrameRateHz:0.2];
      setupScene( window);
      [app addWindow:window];
   }
   return( [app runApp]);
}
//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙███` `╙╙║█  ▐H        █
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`
