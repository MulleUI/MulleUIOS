#define _GNU_SOURCE

#import "import-private.h"

//
// just shows that the pixel center is 0.5
//

static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *context)
{
   CGRect              canvas_rect; // Keep the original CGRect for getting canvas size
   float               canvas_x, canvas_y, canvas_w, canvas_h;
   float               rect_x, rect_y, rect_w, rect_h;
   float               x, y;

   canvas_rect = [layer canvas];
   canvas_x = canvas_rect.origin.x;
   canvas_y = canvas_rect.origin.y;
   canvas_w = canvas_rect.size.width;
   canvas_h = canvas_rect.size.height;

   CGContextFillColor( context, CGColorMakeWithRGBBytes(0, 0, 0)); // Black background
   CGContextFill( context);

   // inviso
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(0 * canvas_w / 3, -1.0));
   CGContextLineTo( context,CGPointMake((0 * canvas_w / 3) + canvas_w / 3, -1.0));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 0, 0)); // Red line
   CGContextStrokeWidth( context, 2.0);
   CGContextStroke( context);

   // semiviso
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(1 * canvas_w / 3, -0.0));
   CGContextLineTo( context,CGPointMake((1 * canvas_w / 3) + canvas_w / 3, -0.0));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(0, 255, 0)); // Green line
   CGContextStrokeWidth( context, 2.0);
   CGContextStroke( context);

   // viso
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(2 * canvas_w / 3, +1.0));
   CGContextLineTo( context,CGPointMake((2 * canvas_w / 3) + canvas_w / 3, +1.0));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(0, 0, 255)); // Blue line
   CGContextStrokeWidth( context, 2.0);
   CGContextStroke( context);

   // Calculate inset rect using float variables
   float inset_amount = 50.0;
   rect_x = canvas_x + inset_amount;
   rect_y = canvas_y + inset_amount;
   rect_w = canvas_w - 2 * inset_amount;
   rect_h = canvas_h - 2 * inset_amount;

   CGContextShapeAntiAlias( context, YES);

   // Horizontal lines in inset rect
   x = rect_x + 0 * (rect_w / 4);
   y = rect_y;
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x + rect_w / 4, y));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   x = rect_x + 1 * (rect_w / 4);
   y = rect_y + 0.5;
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x + rect_w / 4, y));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   CGContextShapeAntiAlias( context, NO);
   x = rect_x + 2 * (rect_w / 4);
   y = rect_y;
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x + rect_w / 4, y));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   x = rect_x + 3 * (rect_w / 4);
   y = rect_y + 0.5;
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x + rect_w / 4, y)); // Corrected to x + rect_w / 4
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   // Vertical lines in inset rect
   CGContextShapeAntiAlias( context, YES);
   x = rect_x;
   y = rect_y + 0 * (rect_h / 4);
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x, y + rect_h / 4));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   x = rect_x + 0.5;
   y = rect_y + 1 * (rect_h / 4);
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x, y + rect_h / 4));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   CGContextShapeAntiAlias( context, NO);
   x = rect_x;
   y = rect_y + 2 * (rect_h / 4);
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x, y + rect_h / 4));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   x = rect_x + 0.5;
   y = rect_y + 3 * (rect_h / 4);
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake(x, y));
   CGContextLineTo( context, CGPointMake(x, y + rect_h / 4));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White line
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   return( NO);
}
int   main( int argc, char *argv[])
{
   return( UIApplicationRunDrawCallbackHz( (CGGraphicsLayerDrawCallback_t *) drawStuff,
                                           CGSizeMake( 400, 300),
                                           NULL,
                                           0.0f));
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
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
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
