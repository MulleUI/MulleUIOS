#define _GNU_SOURCE

#import "import-private.h"

#ifndef HAVE_IMPORT__MULLE_GLFW
int  main( int argc, char *argv[])
{
   return( 0);
}
#else
#ifdef __APPLE__
# include <OpenGL/gl.h>
#else
# include <GL/gl.h>
#endif

// Run this with: MULLE_OBJC_EPHEMERAL_SINGLETON=YES otherwise it fails.
//
// This demo creates an invisible window to get an OpenGL context. This OpenGL
// context is "wrapped" into a CGContext #1#.
// Once we have a context, an offscreen framebuffer is created, drawn to
// (single color) and the result written to BMP file.
//
// It's very low level. In a UIWindow based setting you wouldn't use different
// code to manage CGLayers.
//
// That's it folks!

#define W   64
#define H   64
#define S   4     // stroke width of circle

static void   draw( CGContext *context)
{
#ifdef _CGLMACRO_H
   CGLContextObj  cgl_ctx = CGLGetCurrentContext();
#endif
   // clearing the framebuffer is usually done by -[CGContext clearFramebuffer]
   // which uses the backgroundColor of the context
   glClearColor( 0.85, 0.0, 0.0, 1.0);
   glClear( GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

   // glViewport and nvgBeginFrame are usually done by
   // -[CGContext beginRender],
   glViewport( 0, 0, W, H);
   CGContextBeginFrame( context, CGSizeMake( W, H), 1.0);
   {
      CGContextBeginPath( context);
      {
         CGContextCircle( context, CACircleMakeWithCenterAndRadius( CGPointMake( W / 2.0, H / 2.0), W / 2.0 - S / 2.0));
         CGContextStrokeColor( context, CGColorMakeWithRGB( 0.85f, 0.85f, 0.85f));
         CGContextStrokeWidth( context, S);
      }
      CGContextStroke( context);
   }

   // nvgEndFrame is usually done by -[CGContext endRender]
   // it flushes the accumulated draw commands into the framebuffer
   CGContextEndFrame( context);
}

int   main( int argc, char *argv[])
{
   GLFWOSWindow     *window;
   CGContext        *context;
   CGFramebuffer          *cgLayer;
   void             *bytes;
   struct CGBitmap  bitmap;

   if( ! getenv( "MULLE_OBJC_EPHEMERAL_SINGLETON"))
   {
      fprintf( stderr, "Run this with: MULLE_OBJC_EPHEMERAL_SINGLETON=YES\n");
      exit( 1);
   }

   [UIApplication os_initialize];

   @autoreleasepool
   {
      // create an invisible window, we need it to be able to create a
      // CGContext
      window = [GLFWOSWindow windowWithFrame:CGRectMake( 0, 0, 200, 200)
                           titleUTF8String:"Demo"
                                 styleMask:UIWindowStyleHidden
                           graphicsHints:GLFWGraphicsHintsDefault];

      // need to explicitly activate the "OS" context, it will be locked and
      // only available to this thread during activation
      [window os_activateGraphicsContext];

      // CGContext can now use the "OS" context
      context = [[[CGContext alloc] initWithOSGraphicsContext:window
                                                      shareID:[window shareID]
                                                      options:UIGraphicsDefaultOptions] autorelease];
      if( ! context)
      {
         fprintf( stderr, "No CGContext for you\n");
         return( 1);
      }

      //
      // create a CGFramebuffer of a certain size. This creates a bitmap on the
      // GPU, where we can draw into (a framebuffer). A CGFramebuffer is a CGImage
      // so it can act as a texture
      //
      cgLayer = [CGFramebuffer framebufferWithBitmapSize:CGPixelSizeMake( W, H)
                               textureFlags:0
                                    context:context];
      if( ! cgLayer)
      {
         fprintf( stderr, "No CGFramebuffer for you\n");
         return( 1);
      }

      // bind the buffer as the drawing destination
      [cgLayer _bindToContext];

      // some OpenGL and NanoVG code to draw something
      draw( context);

      // afterwards we can read the contents, here we dump the with
      // mulle_rgba_dump into a BMP file named dump-0000.bmp

      bitmap = [cgLayer RGBABytesBitmap:NULL];
      CGBitmapDump( bitmap);
      CGBitmapDone( bitmap);
      fprintf( stderr, "Check \"dump-????.bmp\" file for a white circle on red background\n");
      [cgLayer _unbindFromContext];
   }

   [UIApplication os_deinitialize];

   return( 0);
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

// #1#
// it isn't really, it's an implicit
// relationship. There is no OpenGL context pointer in CGContext, as this is
// a thread local variable most likely
#endif /* HAVE_IMPORT__MULLE_GLFW */
