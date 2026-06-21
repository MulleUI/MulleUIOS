#define _GNU_SOURCE

#import "import-private.h"
//
// This is a step towards threaded drawing. This demo by itself just shows
// how two single-threaded windows can run with different frameRates.
//
static void   drawStuff( CGRect canvas,
                         NSUInteger counter,
                         CGColor leftColor,
                         CGColor middleColor,
                         CGColor rightColor,
                         CGContext *context)
{
   auto char           buf[ 64];
   CGFont              *font;
   canvas.size.width  /= 3.0;

   // red stripe
   CGContextBeginPath( context);
   CGContextRect( context, CGRectMake( canvas.origin.x, canvas.origin.y, canvas.size.width, canvas.size.height));
   CGContextFillColor( context, leftColor);
   CGContextFill( context);

   // white stripe
   CGContextBeginPath( context);
   CGContextRect( context, CGRectMake( canvas.origin.x + canvas.size.width * 1, canvas.origin.y, canvas.size.width, canvas.size.height));
   CGContextFillColor( context, middleColor);
   CGContextFill( context);

   // blue stripe
   CGContextBeginPath( context);
   CGContextRect( context, CGRectMake( canvas.origin.x + canvas.size.width * 2, canvas.origin.y, canvas.size.width, canvas.size.height));
   CGContextFillColor( context, rightColor);
   CGContextFill( context);

   sprintf( buf, "%td", counter);

   font = [context fontWithNameUTF8String:"sans"];
   [context useFont:font];

   canvas.size.width  *= 3.0;

   CGContextFontSize( context, 32);
   CGContextCombinedTextAlignment( context, CGTextAlignCenter | CGTextAlignMiddle); // Converted from CGTextAlignCenter | CGTextAlignMiddle
   CGContextTextColor( context, CGColorMakeWithHexColor( 0x0000000FF));
   CGContextTextBackgroundColor( context, middleColor);
   CGContextText( context, CGPointMake( CGRectGetMidX( canvas), CGRectGetMidY( canvas)), buf, 0);
}
@interface MyWindow : GLFWOSWindow <UIOSWindow>

@property( retain) CGContext    *context;

@property( assign) CGColor      leftColor;
@property( assign) CGColor      middleColor;
@property( assign) CGColor      rightColor;

@property( assign) NSUInteger   counter;
// just for debugging
@property( assign) CGFramebuffer      *previousLayer;

@end

@implementation MyWindow

- (NSUInteger) incrementCounter
{
   return( ++_counter);
}
- (void) finalize
{
   [self os_activateGraphicsContext];
   {
      // have to do this manually
      [_context mullePerformFinalize];
   }
   [self os_deactivateGraphicsContext];

   [super finalize];
}

+ (UIGraphicsBackend) defaultBackend
{
   return( UIGraphicsBackendDefault);
}
@end
//
// window will already have activated the os_activateGraphicsContext
//
static UIWindowDisplayBits   display( id <UIOSWindow> window_in)
{
   MyWindow            *window = MULLE_OBJC_CLASS_CAST( MyWindow, window_in);
   CGRect              canvas;
   CGContext           *context;
   CGFrameInfo         frameInfo;
   CGFramebuffer       *layer;
   CGFramebuffer       *check;

   canvas.origin = CGPointZero;
   canvas.size   = [window os_windowSize];
   context       = [window context];

   frameInfo = CGFrameInfoSFMake( canvas, [window os_framebufferSize], 1.0);
   [context beginRender:&frameInfo];
   {
      drawStuff( canvas, [window incrementCounter],
                         [window leftColor],
                         [window middleColor],
                         [window rightColor],
                         context);
   }
   [context endRender];

   return( 0);
}

static MyWindow   *create_window( unsigned int i,
                                  double frameRate)
{
   MyWindow            *window;
   GLFWGraphicsHints   hints;
   CGContext           *context;

   hints = GLFW_DEFAULT_CONTEXT;
   switch( [MyWindow defaultBackend])
   {
   case CG_GL3     : hints = GLFW_GL3_CONTEXT; break;
   case CG_GL3_2   : hints = GLFW_GL3_2_CONTEXT; break;
   case CG_GLES2   : hints = GLFW_GLES2_CONTEXT; break;
   case CG_GLES3   : hints = GLFW_GLES3_CONTEXT; break;
   case CG_GLES3_2 : hints = GLFW_GLES3_2_CONTEXT; break;
   }

   window = [[[MyWindow alloc] initWithFrame:CGRectMake( 200 + 200 * i, 200, 200, 200)
                             titleUTF8String:"Demo"
                                   styleMask:GLFWOSWindowStyleMaskDefault|UIWindowStyleResizable
                               graphicsHints:hints
                               sharingWindow:nil] autorelease];

   [window os_activateGraphicsContext];
   {
      context = [[[CGContext alloc] initWithOSGraphicsContext:window
                                                      shareID:[window shareID]
                                                      options:UIGraphicsDefaultOptions] autorelease];      // have to do this manually, because the context is created manually
      // have to do this manually

      // remember context for "display" callback
      [window setContext:context];
      [window setFrameCallback:display];
      [window setFrameRate:frameRate];

      [window setLeftColor:CGColorMakeWithHexColor( 0x008C45FF)];
      [window setMiddleColor:CGColorMakeWithHexColor( 0xF4F5F0FF)];
      [window setRightColor:CGColorMakeWithHexColor( 0xCD212AFF)];
   }
   [window os_deactivateGraphicsContext];

   return( window);
}

#define N_WINDOWS  2

int   main( int argc, char *argv[])
{
   UIApplication   *app;
   MyWindow        *window[ N_WINDOWS];
   NSUInteger      i;

   app = [UIApplication sharedInstance];
   @autoreleasepool
   {
      for( i = 0; i < N_WINDOWS; i++)
      {
         window[ i] = create_window( i, 1.0 / (15.0 * (i + 1)));
         [app addWindow:window[ i]];
      }
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

