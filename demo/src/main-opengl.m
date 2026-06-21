#define _GNU_SOURCE
#ifdef __APPLE__
# define MULLE_CG_USE_APPLE_GL2
#endif

#import "import-private.h"

#ifdef __APPLE__
# include <OpenGL/gl.h>
#else
# include <GL/gl.h>
#endif
#include <string.h>
#include <stdlib.h>

//
// what does this demo ? It shows the UIWindow render callbacks, and how
// you can place OpenGL behind or in front of the scene. Consequently this
// demo rather belongs in MulleUICore.
//
// This demo only works with OpenGL because OpenGLES does not support the
// used commands. Rewriting it in OpenGLES would be to wordy for a demo.
//
// There is a danger in setting UIWindowOpenGLDeprecated. The nanovg
// backend is hard-compiled against -[window backend], so there could be
// a mismatch. In what way this will impede nanovg needs to be determined
// In this demo, there are no "real" nanovg calls, so it doesn't matter
//

void   drawOpenGL_blue( UIWindow *window,
                        id <UIGraphicsContext> context,
                        struct CGFrameInfo *info)
{
   glColor3f( 0.0f, 0.0f, 1.0f ); // blue color

   glBegin( GL_LINE_LOOP );
      glVertex3f( -0.5f, 0.0f, 0.0f );
      glVertex3f( 0.0f, -0.5f, 0.0f );
      glVertex3f( 0.5f, 0.0f, 0.0f );
      glVertex3f( 0.0f, 0.5f, 0.0f );
   glEnd();

   glFlush();
}


void  drawOpenGL_yellow( UIWindow *window,
                         id <UIGraphicsContext> context,
                         struct CGFrameInfo *info)
{
   glColor3f( 1.0f, 1.0f, 0.0f ); // yellow color

   glBegin( GL_LINE_LOOP );
      glVertex3f( -0.45f, 0.0f, 0.0f );
      glVertex3f( 0.0f, -0.45f, 0.0f );
      glVertex3f( 0.45f, 0.0f, 0.0f );
      glVertex3f( 0.0f, 0.45f, 0.0f );
   glEnd();

   glFlush();
}


UIWindowDisplayBits  drawOpenGL_magenta( UIPureWindow *window,
                                         id <UIGraphicsContext> context,
                                         struct CGFrameInfo *info,
                                         unsigned long displayBits)
{
   glColor3f( 1.0f, 0.0f, 1.0f ); // magenta color

   glBegin( GL_LINE_LOOP );
      glVertex3f( -0.40f, 0.0f, 0.0f );
      glVertex3f( 0.0f, -0.40f, 0.0f );
      glVertex3f( 0.40f, 0.0f, 0.0f );
      glVertex3f( 0.0f, 0.40f, 0.0f );
   glEnd();

   glFlush();

   return( displayBits);
}


void   setupScene( UIWindow *window)
{
   UIView   *view;
   UIView   *contentView;
   CGRect   rect;
   CGRect   frame;

   contentView      = [window contentView];
   rect             = [contentView contentRect];
   rect             = CGRectInset( rect, 40, 40);

   frame            = rect;
   frame.size.width = rect.size.width / 2.0 - 40.0;

   view = [UIView viewWithFrame:frame];
   [view setBackgroundColor:[UIColor redColor]];
   [contentView addSubview:view];

   frame.origin.x = CGRectGetMaxX( rect) - frame.size.width;

   view = [UIView viewWithFrame:frame];
   [view setBackgroundColor:[UIColor greenColor]];
   [contentView addSubview:view];
}


int   main( int argc, char *argv[])
{
   UIWindow       *window;
   UIApplication  *app;
   NSUInteger     bits;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 640.0f, 400.0f)
                      titleUTF8String:"Demo"
                            styleMask:UIWindowOpenGLDeprecated];
   if( ! window)
   {
      fprintf( stderr, "Need OpenGL (Not OpenGLES) for this demo\n");
      return( 1);
   }

   [window setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0)];
   [app addWindow:window];

   setupScene( window);

   bits = 7;
   if( argc == 2)
      bits = atoi( argv[ 1]);
   if( bits & 1)
      [window setWillRenderLayersCallback:drawOpenGL_blue];
   if( bits & 2)
      [window setDidRenderLayersCallback:drawOpenGL_yellow];
   if( bits & 4)
      [window setDidRenderFrameCallback:drawOpenGL_magenta];

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

