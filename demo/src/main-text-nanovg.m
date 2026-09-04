#define _GNU_SOURCE

#import "import-private.h"
static void   metricsDraw( CGContext *context, float x, float y, float w, float fontSize)
{
   CGTextMetrics   metrics;

      // Set the font size
   CGContextFontSize( context, fontSize);

   // Set text alignment to default left and baseline
   CGContextCombinedTextAlignment( context, CGTextAlignLeft | CGTextAlignBaseline); // Reverted to original NVG_ALIGN_* constants

   metrics = CGContextTextMetrics( context);

   // Set the stroke color to gray and draw bounds markers
   CGContextBeginPath( context);

   CGContextMoveTo( context, CGPointMake(x, y - metrics.ascender));
   CGContextLineTo( context, CGPointMake(x + w, y - metrics.ascender));

   // nvg descender is negative
   CGContextMoveTo( context, CGPointMake(x, y - metrics.descender));
   CGContextLineTo( context, CGPointMake(x + w, y - metrics.descender));

   CGContextStrokeColor( context, CGColorMakeWithRGBBytes( 0, 64, 0)); // green color
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   mulle_printf( "font ascender,descender,lineHeight : %g %g %g\n", metrics.ascender, -metrics.descender, metrics.lineHeight);
}
static void   visualMetricsDraw( CGContext *context, float x, float y, float w, float fontSize)
{
   CGTextMetrics   metrics;

      // Set the font size
   CGContextFontSize( context, fontSize);

   // Set text alignment to default left and baseline
   CGContextCombinedTextAlignment( context, CGTextAlignLeft | CGTextAlignBaseline); // Reverted to original NVG_ALIGN_* constants

   metrics = CGContextTextMetrics( context);

   // Set the stroke color to gray and draw bounds markers
   CGContextBeginPath( context);

   CGContextMoveTo( context, CGPointMake(x, y - metrics.ascender));
   CGContextLineTo( context, CGPointMake(x + w, y - metrics.ascender));

   // nvg descender is negative
   CGContextMoveTo( context, CGPointMake(x, y - metrics.descender));
   CGContextLineTo( context, CGPointMake(x + w, y - metrics.descender));

   CGContextStrokeColor( context, CGColorMakeWithRGBBytes( 0, 64, 0)); // green color
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);

   mulle_printf( "visual ascender,descender,lineHeight : %g %g %g\n", metrics.ascender, -metrics.descender, metrics.lineHeight);
}
static void   codyDraw( CGContext *context, float x, float y, char *s, float fontSize, BOOL visual)
{
   CGRect          bounds;
   CGTextMetrics   metrics;
   float           textWidth;
   float           textHeight;

   // Set the font size
   CGContextFontSize( context, fontSize);

   // Set text alignment to default left and baseline
   CGContextCombinedTextAlignment( context, CGTextAlignLeft | CGTextAlignBaseline);

   // Measure the text bounds
   if( visual)
      bounds = CGContextTextVisualBounds( context, CGPointMake( x, y), s, 0);
   else
      bounds = CGContextTextBoundsInfo( context, CGPointMake( x, y), s, 0).bounds;

   // Calculate width and height of the text
   textWidth  = bounds.size.width;
   textHeight = bounds.size.height;

   // draw strokes and fills w/o antialiasing
   CGContextShapeAntiAlias( context, 1);

   // Set the background color to white and draw a rectangle covering the text area
   CGContextBeginPath( context);
   CGContextRect( context, bounds);
   CGContextFillColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White color
   CGContextFill( context);

   if( visual)
   {
      metrics = CGContextTextMetrics( context);

      // Set the stroke color to gray and draw bounds markers (ascender, descender, baseline)
      CGContextBeginPath( context);

      CGContextMoveTo( context, CGPointMake(bounds.origin.x, y - metrics.ascender));
      CGContextLineTo( context, CGPointMake(CGRectGetMaxX( bounds), y - metrics.ascender));

      CGContextMoveTo( context, CGPointMake(bounds.origin.x, y - metrics.descender));
      CGContextLineTo( context, CGPointMake(CGRectGetMaxX( bounds), y - metrics.descender));

      CGContextMoveTo( context, CGPointMake(bounds.origin.x, y));
      CGContextLineTo( context, CGPointMake(CGRectGetMaxX( bounds), y));

      CGContextStrokeColor( context, CGColorMakeWithRGBBytes( 64, 64, 0)); // yellow color
      CGContextStrokeWidth( context, 1.0);
      CGContextStroke( context);
   }

   // Set the stroke color to red and draw a rectangle around the text
   CGContextBeginPath( context);
   CGContextRect( context, CGRectMake(bounds.origin.x - 1, bounds.origin.y - 1, textWidth + 2, textHeight + 2));
   CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 0, 0)); // Red color
   CGContextStrokeWidth( context, 1.0);
   CGContextStroke( context);
   // Set the fill color to black and draw the character
   CGContextFillColor( context, CGColorMakeWithRGBBytes(0, 0, 0)); // Black color
   CGContextText( context, CGPointMake( x, y), s, 0);

   mulle_printf( "textW/H : %g %g\n", textWidth, textHeight);
   mulle_printf( "bounds  : %g %g %g %g\n",
                 bounds.origin.x, bounds.origin.y,
                 CGRectGetMaxX( bounds), CGRectGetMaxY( bounds));
}
static void   codyDraw2( CGContext *context, float x, float y, char *s, float fontSize) {
    // Set the font size
    CGContextFontSize( context, fontSize);

    // Set text alignment to default left and baseline
    CGContextCombinedTextAlignment( context, CGTextAlignLeft | CGTextAlignBaseline); // Reverted to original NVG_ALIGN_* constants

    // Measure the glyph positions
    struct UIGlyphPosition glyphs[100]; // Assuming the string is not longer than 100 characters
    int numGlyphs = CGContextTextGlyphPositions( context, CGPointMake( x, y), s, 0, glyphs, 100);

    // Calculate the bounding box from the glyph positions
    float minX = glyphs[0].x;
    float maxX = glyphs[numGlyphs - 1].maxx;

    // Use the first and last glyph to determine vertical bounds
    float minY = glyphs[0].miny;
    float maxY = glyphs[0].maxy;

    for (int i = 1; i < numGlyphs; i++) {
        if (glyphs[i].miny < minY) minY = glyphs[i].miny;
        if (glyphs[i].maxy > maxY) maxY = glyphs[i].maxy;
    }

    // Calculate width and height of the text
    float textWidth = maxX - minX;
    float textHeight = maxY - minY;

    // Draw strokes and fills without antialiasing
    CGContextShapeAntiAlias( context, 0);

    // Set the background color to white and draw a rectangle covering the text area
    CGContextBeginPath( context);
    CGContextRect( context, CGRectMake(minX, minY, textWidth, textHeight));
    CGContextFillColor( context, CGColorMakeWithRGBBytes(255, 255, 255)); // White color
    CGContextFill( context);

    // Set the stroke color to red and draw a rectangle around the text
    CGContextBeginPath( context);
    CGContextRect( context, CGRectMake(minX - 1, minY - 1, textWidth + 2, textHeight + 2));
    CGContextStrokeColor( context, CGColorMakeWithRGBBytes(255, 0, 0)); // Red color
    CGContextStrokeWidth( context, 1.0);
    CGContextStroke( context);

    // Set the fill color to black and draw the text
    CGContextFillColor( context, CGColorMakeWithRGBBytes(0, 0, 0)); // Black color
    CGContextText( context, CGPointMake( x, y), s, 0);

   mulle_printf( "textW/H    : %g %g\n", textWidth, textHeight);
   mulle_printf( "minX/maxX  : %g %g\n", minX, maxX);
   mulle_printf( "minY/maxY  : %g %g\n", minY, maxY);
}
static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *context)
{
   float               fontSize;

   fontSize = 20.0;

   metricsDraw( context, 100 - 20, 50, 4 * (fontSize + fontSize / 2) + 20, fontSize);

   codyDraw( context, 100 + 0 * (fontSize + fontSize / 2), 50, "y", fontSize, NO);
   codyDraw( context, 100 + 1 * (fontSize + fontSize / 2), 50, "|", fontSize, NO);
   codyDraw( context, 100 + 2 * (fontSize + fontSize / 2), 50, "`", fontSize, NO);
   codyDraw( context, 100 + 3 * (fontSize + fontSize / 2), 50, "_", fontSize, NO);

   visualMetricsDraw( context, 100 - 20, 125, 4 * (fontSize + fontSize / 2) + 20, fontSize);

   codyDraw( context, 100 + 0 * (fontSize + fontSize / 2), 125, "y", fontSize, YES);
   codyDraw( context, 100 + 1 * (fontSize + fontSize / 2), 125, "|", fontSize, YES);
   codyDraw( context, 100 + 2 * (fontSize + fontSize / 2), 125, "`", fontSize, YES);
   codyDraw( context, 100 + 3 * (fontSize + fontSize / 2), 125, "_", fontSize, YES);

   metricsDraw( context, 100 - 20, 200, 4 * (fontSize + fontSize / 2) + 20, fontSize);

   codyDraw2( context, 100 + 0 * (fontSize + fontSize / 2), 200, "y", fontSize);
   codyDraw2( context, 100 + 1 * (fontSize + fontSize / 2), 200, "|", fontSize);
   codyDraw2( context, 100 + 2 * (fontSize + fontSize / 2), 200, "`", fontSize);
   codyDraw2( context, 100 + 3 * (fontSize + fontSize / 2), 200, "_", fontSize);

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
