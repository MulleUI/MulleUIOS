#define _GNU_SOURCE

#import "import-private.h"

#include "draw-flag.inc"
//
// This demo shows how to tie MulleCG and MulleGLFW together without
// MulleUIWindow. But what's the point ? MulleUIWindow is that much more
// convenient...
//

@interface MyWindow : GLFWOSWindow

@property( retain) CGContext  *context;

@end

@implementation MyWindow

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



static UIWindowDisplayBits   display( id <UIOSWindow> window_in)
{
   MyWindow      *window = MULLE_OBJC_CLASS_CAST( MyWindow, window_in);
   CGRect        canvas;
   CGContext     *context;
   CGFrameInfo   frameInfo;

   canvas.origin = CGPointZero;
   canvas.size   = [window os_windowSize];

   context = [window context];

   frameInfo = CGFrameInfoSFMake( canvas, [window os_framebufferSize], 1.0);
   [context beginRender:&frameInfo];
   {
      drawRedWhiteBlueFlag( context, canvas);
   }
   [context endRender];
   return( 0);
}


int   main( int argc, char *argv[])
{
   UIApplication      *app;
   MyWindow           *window;
   CGContext          *context;
   GLFWGraphicsHints  hints;

   app = [UIApplication sharedInstance];
   @autoreleasepool
   {
      hints = GLFW_DEFAULT_CONTEXT;
      switch( [MyWindow defaultBackend])
      {
      case CG_GL3     : hints = GLFW_GL3_CONTEXT; break;
      case CG_GL3_2   : hints = GLFW_GL3_2_CONTEXT; break;
      case CG_GLES2   : hints = GLFW_GLES2_CONTEXT; break;
      case CG_GLES3   : hints = GLFW_GLES3_CONTEXT; break;
      case CG_GLES3_2 : hints = GLFW_GLES3_2_CONTEXT; break;
      }

      window = [[[MyWindow alloc] initWithFrame:CGRectMake( 0, 0, 200, 200)
                                titleUTF8String:"Demo"
                                      styleMask:GLFWOSWindowStyleMaskDefault
                                  graphicsHints:hints] autorelease];
      assert( window);

      [window os_activateGraphicsContext];
      context = [[[CGContext alloc] initWithOSGraphicsContext:window
                                                      shareID:[window shareID]
                                                      options:UIGraphicsDefaultOptions] autorelease];      // have to do this manually, because the context is created manually

      [window os_deactivateGraphicsContext];

      // remember context for "display" callback
      [window setContext:context];
      [window setFrameCallback:display];
      [window setFrameRate:UIWindowFrameRateSynced];

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
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
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

