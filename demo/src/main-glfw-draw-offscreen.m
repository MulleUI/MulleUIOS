#define _GNU_SOURCE

#import "import-private.h"

#include "draw-flag.inc"


//
// This demo shows how CGContext draws into a offscreen buffer first and
// then uses this to draw into the window buffer. The offscreen buffer is
// just a regular CGFramebuffer.
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



//
// This needs to be implemented by the context owner. This is not a bug.
// setActive: is not supposed to be seen outside of the window setting this
// context active. (Locking is done in GLFWOSWindow with the implicit context!)
//

static UIWindowDisplayBits   display( id <UIOSWindow> window_in)
{
   MyWindow               *window = MULLE_OBJC_CLASS_CAST( MyWindow, window_in);
   CGRect                 canvas;
   CGContext              *context;
   CGFrameInfo            frameInfo;
   CGFramebuffer          *layer;
   CGFramebuffer          *check;
   static CGFramebuffer   *previous;

   canvas.origin = CGPointZero;
   canvas.size   = [window os_windowSize];
   context       = [window context];

   frameInfo = CGFrameInfoSFMake( canvas, [window os_framebufferSize], 1.0);

   // tell the context to render offscreen
   [context setRendersOffScreen:YES];
   [context beginRender:&frameInfo];
   {
      drawRedWhiteBlueFlag( context, canvas);
   }

   // do what endRender does, but get the offscreen framebuffer
   [context suspendRender];
   layer = [context _endRender];

   if( previous != layer)
      fprintf( stderr, "new offscreen framebuffer (should only be seen on init and resize)\n");

   // draw layer in window framebuffer
   [context setRendersOffScreen:NO];
   [context beginRender:&frameInfo];
   {
      [context clearFramebuffer];
      [layer drawRect:CGRectInset( canvas, 10, 10)
              options:NULL
              context:context];
   }
   [context endRender];

   // we could just let the layer, die but we want to reuse it next time
   // so we recycle it
   [context recycleRenderedFramebuffer:layer];

   // remember it, and check next time that it's been reused
   previous = layer;

   return( 0);
}


int   main( int argc, char *argv[])
{
   UIApplication            *app;
   MyWindow                 *window;
   CGContext                *context;
   GLFWGraphicsHints   hints;

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
                                      styleMask:GLFWOSWindowStyleMaskDefault|UIWindowStyleResizable
                                  graphicsHints:hints] autorelease];
      [window os_activateGraphicsContext];
      {
         context = [[[CGContext alloc] initWithOSGraphicsContext:window
                                                         shareID:[window shareID]
                                                         options:UIGraphicsDefaultOptions] autorelease];
         // remember context for "display" callback
         [window setContext:context];
         [window setFrameCallback:display];
         [window setFrameRate:UIWindowFrameRateAsync];
      }
      [window os_deactivateGraphicsContext];

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

