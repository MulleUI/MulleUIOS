#define _GNU_SOURCE

#import "import-private.h"
#define AntiAlias  1
#define Thick      2
static void   drawRect( CALayer *layer, CGContext *context, NSUInteger mode)
{
   CGRect               canvas;
   CGRect               rect;
   char                 buf[ 64];
   CGFloat              strokeWidth;

   canvas = [layer canvas];
   CGContextResetScissor( context); // see if it makes a difference

   canvas = CGRectInset( canvas, 2.0, 2.0);

   strokeWidth = 1.0;
   if( mode & Thick)
      strokeWidth = 2.5;

   rect = CGRectMakeStrokeRect( canvas, strokeWidth, CGInside);

   CGContextBeginPath( context);
   CGContextShapeAntiAlias( context, (mode & AntiAlias) ? 1 : 0);
   CGContextRect( context, rect);
   CGContextStrokeColor( context, CGColorMakeRed());
   CGContextStrokeWidth( context, strokeWidth);
   CGContextStroke( context);

   sprintf( buf, "%s%.0f",
                 (mode & AntiAlias) ? "AA " : "No AA ",
                 strokeWidth);

   [context fontWithNameUTF8String:"sans"];

   CGContextFontFace( context, "sans");
   CGContextCombinedTextAlignment( context, CGTextAlignCenter | CGTextAlignBaseline); // Converted from CGTextAlignCenter | CGTextAlignBaseline
   CGContextTextColor( context, CGColorMakeBlack());
   CGContextTextBackgroundColor( context, CGColorMakeWhite());
   CGContextFontSize( context, 13.0);
   CGContextText( context, CGPointMake( CGRectGetMidX( canvas), CGRectGetMidY( canvas)), buf, 0);
}
static void   drawStuff0( CALayer *layer, CGContext *context)
{
   drawRect( layer, context, 0);
}

static void   drawStuff1( CALayer *layer, CGContext *context)
{
   drawRect( layer, context, 0x1);
}

static void   drawStuff2( CALayer *layer, CGContext *context)
{
   drawRect( layer, context, 0x2);
}

static void   drawStuff3( CALayer *layer, CGContext *context)
{
   drawRect( layer, context, 0x3);
}
static void   fillRect( CALayer *layer, CGContext *context, NSUInteger mode)
{
   CGRect               canvas;
   CGRect               rect;
   char                 buf[ 64];
   CGFloat              strokeWidth;

   canvas = [layer canvas];
   CGContextResetScissor( context); // see if it makes a difference

   canvas = CGRectInset( canvas, 2.0, 2.0);

   strokeWidth = 1.0;
   if( mode & Thick)
      strokeWidth = 2.5;

   rect = CGRectMakeStrokeRect( canvas, strokeWidth, CGOverlap);
   rect = CGRectMakeFillRect( rect, strokeWidth, CGOverlap);

   CGContextBeginPath( context);
   CGContextShapeAntiAlias( context, (mode & AntiAlias) ? 1 : 0);
   CGContextRect( context, rect);
   CGContextFillColor( context, CGColorMakeRed());
   CGContextFill( context);

   sprintf( buf, "%s%.0f",
                 (mode & AntiAlias) ? "AA " : "No AA ",
                 strokeWidth);

   [context fontWithNameUTF8String:"sans"];

   CGContextFontFace( context, "sans");
   CGContextCombinedTextAlignment( context, CGTextAlignCenter | CGTextAlignBaseline); // Converted from CGTextAlignCenter | CGTextAlignBaseline
   CGContextTextColor( context, CGColorMakeWhite());
   CGContextTextBackgroundColor( context, CGColorMakeRed());

   CGContextFontSize( context, 13.0);
   CGContextText( context, CGPointMake( CGRectGetMidX( canvas), CGRectGetMidY( canvas)), buf, 0);
}
static void   fillStuff0( CALayer *layer, CGContext *context)
{
   fillRect( layer, context, 0x0);
}

static void   fillStuff1( CALayer *layer, CGContext *context)
{
   fillRect( layer, context, 0x1);
}

static void   fillStuff2( CALayer *layer, CGContext *context)
{
   fillRect( layer, context, 0x2);
}

static void   fillStuff3( CALayer *layer, CGContext *context)
{
   fillRect( layer, context, 0x3);
}
typedef CGGraphicsLayerDrawCallback_t  *CALayerDrawCallbackPointer_t;

static CALayerDrawCallbackPointer_t   drawStuff[ 8] =
{
   (CGGraphicsLayerDrawCallback_t *) drawStuff0,
   (CGGraphicsLayerDrawCallback_t *) drawStuff1,
   (CGGraphicsLayerDrawCallback_t *) drawStuff2,
   (CGGraphicsLayerDrawCallback_t *) drawStuff3,

   (CGGraphicsLayerDrawCallback_t *) fillStuff0,
   (CGGraphicsLayerDrawCallback_t *) fillStuff1,
   (CGGraphicsLayerDrawCallback_t *) fillStuff2,
   (CGGraphicsLayerDrawCallback_t *) fillStuff3
};
int   main( int argc, char *argv[])
{
   UIApplication   *app;
   UIWindow        *window[ 8];
   NSUInteger      i;

   app = [UIApplication sharedInstance];

   for( i = 0; i < 8; i++)
   {
      window[ i] = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 100, 100)];
      [window[ i] setDrawCallback:drawStuff[ i]];
      [window[ i] setBackgroundColor:CGColorMakeWhite()];
      [app addWindow:window[ i]];
     // [app runLoopIteration];  // process some events and redraws in between
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
