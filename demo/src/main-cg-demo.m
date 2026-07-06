//
// CGContext kitchen sink demo, adapted from nanovg/example/demo.c
// (c) 2013 Mikko Mononen memon@inside.org
// Ported to CGContext API
//
#define _GNU_SOURCE

#import "import-private.h"

#ifndef HAVE_IMPORT__MULLE_GLFW
int  main( int argc, char *argv[])
{
   return( 0);
}
#else


// nanovg.h is NOT needed — all drawing goes through CGContext
#include <stdio.h>
#include <string.h>
#include <math.h>

//
// DemoData (from demo.h)
//
struct DemoData {
   int fontNormal, fontBold, fontIcons, fontEmoji;
   int images[12];
};
typedef struct DemoData DemoData;

#define ICON_SEARCH 0x1F50D
#define ICON_CIRCLED_CROSS 0x2716
#define ICON_CHEVRON_RIGHT 0xE75E
#define ICON_CHECK 0x2713
#define ICON_LOGIN 0xE740
#define ICON_TRASH 0xE729

//static float minf(float a, float b) { return a < b ? a : b; }
//static float maxf(float a, float b) { return a > b ? a : b; }
//static float absf(float a) { return a >= 0.0f ? a : -a; }
static float clampf(float a, float mn, float mx) { return a < mn ? mn : (a > mx ? mx : a); }

// Returns 1 if col.rgba is 0.0f,0.0f,0.0f,0.0f, 0 otherwise
int isBlack(CGColor col)
{
   if( col.r == 0.0f && col.g == 0.0f && col.b == 0.0f && col.a == 0.0f )
   {
      return( 1);
   }
   return( 0);
}

static char* cpToUTF8(int cp, char* str)
{
   int n = 0;
   if( cp < 0x80) n = 1;
   else if( cp < 0x800) n = 2;
   else if( cp < 0x10000) n = 3;
   else if( cp < 0x200000) n = 4;
   else if( cp < 0x4000000) n = 5;
   else if( cp <= 0x7fffffff) n = 6;
   str[n] = '\0';
   switch( n) {
   case 6: str[5] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x4000000;
   case 5: str[4] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x200000;
   case 4: str[3] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x10000;
   case 3: str[2] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x800;
   case 2: str[1] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0xc0;
   case 1: str[0] = cp;
   }
   return( str);
}


void drawWindow(CGContext *context, const char* title, float x, float y, float w, float h)
{
   float cornerRadius = 3.0f;

   CGContextDo( context)
   {
      // Window
      CGContextBeginPath( context);
      CGContextRoundedRect( context, CGRectMake( x, y, w, h), cornerRadius);
      CGContextFillColor( context, CGColorMakeWithRGBABytes(28,30,34,192));
      CGContextFill( context);

      // Drop shadow
      CGContextSetFillBoxGradient( context,
                                   CGRectMake( x, y+2, w, h),
                                   cornerRadius*2,
                                   CGColorMakeWithRGBABytes(0,0,0,128),
                                   10,
                                   CGColorMakeWithRGBABytes(0,0,0,0));
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( x-10, y-10, w+20, h+30));
      CGContextRoundedRect( context, CGRectMake( x, y, w, h), cornerRadius);
      CGContextPathWinding( context, CGPathFillStyleHole);
      CGContextFill( context);

      // Header
      CGContextSetFillLinearGradient( context,
                                      CGPointMake( x, y),
                                      CGPointMake( x, y+15),
                                      CGColorMakeWithRGBABytes(255,255,255,8),
                                      CGColorMakeWithRGBABytes(0,0,0,16));
      CGContextBeginPath( context);
      CGContextRoundedRect( context, CGRectMake( x+1, y+1, w-2, 30), cornerRadius-1);
      CGContextFill( context);
      CGContextBeginPath( context);
      CGContextMoveTo( context, CGPointMake( x+0.5f, y+0.5f+30));
      CGContextLineTo( context, CGPointMake( x+0.5f+w-1, y+0.5f+30));
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,32));
      CGContextStroke( context);

      CGContextFontSize( context, 15.0f);
      CGContextFontFace( context, "sans-bold");
      CGContextCombinedTextAlignment( context, CGTextAlignCenter|CGTextAlignMiddle);

      CGContextFontBlur( context, 2);
      CGContextFillColor( context, CGColorMakeWithRGBABytes(0,0,0,128));
      CGContextText( context, CGPointMake( x+w/2, y+16+1), title, (size_t) -1);

      CGContextFontBlur( context, 0);
      CGContextFillColor( context, CGColorMakeWithRGBABytes(220,220,220,160));
      CGContextText( context, CGPointMake( x+w/2, y+16), title, (size_t) -1);
   }
}

void drawSearchBox(CGContext *context, const char* text, float x, float y, float w, float h)
{
   char icon[8];
   float cornerRadius = h/2-1;

   // Edit
   CGContextSetFillBoxGradient( context, CGRectMake( x, y+1.5f, w, h), h/2,
                                         CGColorMakeWithRGBABytes(0,0,0,16),
                                         5,
                                         CGColorMakeWithRGBABytes(0,0,0,92));
   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x, y, w, h), cornerRadius);
   CGContextFill( context);

/* CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+0.5f, y+0.5f, w-1, h-1), cornerRadius-0.5f);
   CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,48));
   CGContextStroke( context);*/

   CGContextFontSize( context, h*1.3f);
   CGContextFontFace( context, "icons");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,64));
   CGContextCombinedTextAlignment( context,CGTextAlignCenter|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+h*0.55f, y+h*0.55f), cpToUTF8(ICON_SEARCH,icon), (size_t) -1);

   CGContextFontSize( context, 17.0f);
   CGContextFontFace( context, "sans");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,32));

   CGContextCombinedTextAlignment( context,CGTextAlignLeft|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+h*1.05f, y+h*0.5f), text, (size_t) -1);

   CGContextFontSize( context, h*1.3f);
   CGContextFontFace( context, "icons");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,32));
   CGContextCombinedTextAlignment( context,CGTextAlignCenter|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+w-h*0.55f, y+h*0.55f), cpToUTF8(ICON_CIRCLED_CROSS,icon), (size_t) -1);
}

void drawDropDown(CGContext *context, const char* text, float x, float y, float w, float h)
{
   char icon[8];
   float cornerRadius = 4.0f;

   CGContextSetFillLinearGradient( context, CGPointMake( x, y),
                                            CGPointMake( x, y+h),
                                            CGColorMakeWithRGBABytes(255,255,255,16),
                                            CGColorMakeWithRGBABytes(0,0,0,16));
   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+1, y+1, w-2, h-2), cornerRadius-1);
   CGContextFill( context);

   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+0.5f, y+0.5f, w-1, h-1), cornerRadius-0.5f);
   CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,48));
   CGContextStroke( context);

   CGContextFontSize( context, 17.0f);
   CGContextFontFace( context, "sans");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,160));
   CGContextCombinedTextAlignment( context,CGTextAlignLeft|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+h*0.3f, y+h*0.5f), text, (size_t) -1);

   CGContextFontSize( context, h*1.3f);
   CGContextFontFace( context, "icons");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,64));
   CGContextCombinedTextAlignment( context,CGTextAlignCenter|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+w-h*0.5f, y+h*0.5f), cpToUTF8(ICON_CHEVRON_RIGHT,icon), (size_t) -1);
}

void drawLabel(CGContext *context, const char* text, float x, float y, float w, float h)
{
   MULLE_C_UNUSED(w);

   CGContextFontSize( context, 15.0f);
   CGContextFontFace( context, "sans");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,128));

   CGContextCombinedTextAlignment( context,CGTextAlignLeft|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x, y+h*0.5f), text, (size_t) -1);
}

void drawEditBoxBase(CGContext *context, float x, float y, float w, float h)
{
   // Edit
   CGContextSetFillBoxGradient( context, CGRectMake( x+1, y+1+1.5f, w-2, h-2),
                                                  3,
                                                  CGColorMakeWithRGBABytes(255,255,255,32),
                                                  4,
                                                  CGColorMakeWithRGBABytes(32,32,32,32));
   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+1, y+1, w-2, h-2), 4-1);
   CGContextFill( context);

   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+0.5f, y+0.5f, w-1, h-1), 4-0.5f);
   CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,48));
   CGContextStroke( context);
}

void drawEditBox(CGContext *context, const char* text, float x, float y, float w, float h)
{

   drawEditBoxBase(context, x,y, w,h);

   CGContextFontSize( context, 17.0f);
   CGContextFontFace( context, "sans");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,64));
   CGContextCombinedTextAlignment( context,CGTextAlignLeft|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+h*0.3f, y+h*0.5f), text, (size_t) -1);
}

void drawEditBoxNum(CGContext *context,
               const char* text, const char* units, float x, float y, float w, float h)
{
   float uw;

   drawEditBoxBase(context, x,y, w,h);

   uw = CGContextTextBoundsInfo( context, CGPointMake( 0, 0), (char *) units, (size_t) -1).size;

   CGContextFontSize( context, 15.0f);
   CGContextFontFace( context, "sans");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,64));
   CGContextCombinedTextAlignment( context,CGTextAlignRight|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+w-h*0.3f, y+h*0.5f), units, (size_t) -1);

   CGContextFontSize( context, 17.0f);
   CGContextFontFace( context, "sans");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,128));
   CGContextCombinedTextAlignment( context,CGTextAlignRight|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+w-uw-h*0.5f, y+h*0.5f), text, (size_t) -1);
}

void drawCheckBox(CGContext *context, const char* text, float x, float y, float w, float h)
{
   char icon[8];
   (void)(w);

   CGContextFontSize( context, 15.0f);
   CGContextFontFace( context, "sans");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,160));

   CGContextCombinedTextAlignment( context,CGTextAlignLeft|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+28, y+h*0.5f), text, (size_t) -1);

   CGContextSetFillBoxGradient( context, CGRectMake( x+1, y+(int)(h*0.5f)-9+1, 18, 18),
                                         3,
                                         CGColorMakeWithRGBABytes(0,0,0,32),
                                         3,
                                         CGColorMakeWithRGBABytes(0,0,0,92));
   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+1, y+(int)(h*0.5f)-9, 18, 18), 3);
   CGContextFill( context);

   CGContextFontSize( context, 33);
   CGContextFontFace( context, "icons");
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,128));
   CGContextCombinedTextAlignment( context,CGTextAlignCenter|CGTextAlignMiddle);
   CGContextText( context, CGPointMake( x+9+2, y+h*0.5f), cpToUTF8(ICON_CHECK,icon), (size_t) -1);
}

void drawButton(CGContext *context, int preicon, const char* text, float x, float y, float w, float h, CGColor col)
{
   char icon[8];
   float cornerRadius = 4.0f;
   float tw = 0, iw = 0;

   CGContextSetFillLinearGradient( context, CGPointMake( x, y),
                                            CGPointMake( x, y+h),
                                            CGColorMakeWithRGBABytes(255,255,255,isBlack(col)?16:32),
                                            CGColorMakeWithRGBABytes(0,0,0,isBlack(col)?16:32));
   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+1, y+1, w-2, h-2), cornerRadius-1);
   if( !isBlack(col)) {
      CGContextFillColor( context, col);
      CGContextFill( context);
   }
   CGContextFill( context);

   CGContextBeginPath( context);
   CGContextRoundedRect( context, CGRectMake( x+0.5f, y+0.5f, w-1, h-1), cornerRadius-0.5f);
   CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,48));
   CGContextStroke( context);

   CGContextFontSize( context, 17.0f);
   CGContextFontFace( context, "sans-bold");
   tw = CGContextTextBoundsInfo( context, CGPointMake( 0, 0), (char *) text, (size_t) -1).size;
   if( preicon != 0) {
      CGContextFontSize( context, h*1.3f);
      CGContextFontFace( context, "icons");
      iw = CGContextTextBoundsInfo( context, CGPointMake( 0, 0), cpToUTF8(preicon,icon), (size_t) -1).size;
      iw += h*0.15f;
   }

   if( preicon != 0) {
      CGContextFontSize( context, h*1.3f);
      CGContextFontFace( context, "icons");
      CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,96));
      CGContextCombinedTextAlignment( context,CGTextAlignLeft|CGTextAlignMiddle);
      CGContextText( context, CGPointMake( x+w*0.5f-tw*0.5f-iw*0.75f, y+h*0.5f), cpToUTF8(preicon,icon), (size_t) -1);
   }

   CGContextFontSize( context, 17.0f);
   CGContextFontFace( context, "sans-bold");
   CGContextCombinedTextAlignment( context,CGTextAlignLeft|CGTextAlignMiddle);
   CGContextFillColor( context, CGColorMakeWithRGBABytes(0,0,0,160));
   CGContextText( context, CGPointMake( x+w*0.5f-tw*0.5f+iw*0.25f, y+h*0.5f-1), text, (size_t) -1);
   CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,160));
   CGContextText( context, CGPointMake( x+w*0.5f-tw*0.5f+iw*0.25f, y+h*0.5f), text, (size_t) -1);
}

void drawSlider(CGContext *context, float pos, float x, float y, float w, float h)
{
   float cy = y+(int)(h*0.5f);
   float kr = (int)(h*0.25f);
   float kx = x+(int)(pos*w);

   CGContextDo( context)
   {
      // Slot
      CGContextSetFillBoxGradient( context,
                                   CGRectMake( x, cy-2+1, w, 4),
                                   2,
                                   CGColorMakeWithRGBABytes(0,0,0,32),
                                   2,
                                   CGColorMakeWithRGBABytes(0,0,0,128));
      CGContextBeginPath( context);
      CGContextRoundedRect( context, CGRectMake( x, cy-2, w, 4), 2);
      CGContextFill( context);

      // Knob Shadow
      {
         CACircle shadow = CACircleMake( kx, cy+1, kr+3);

         CGContextSetFillRadialGradient( context,
                                         shadow,
                                         CGColorMakeWithRGBABytes(0,0,0,0),
                                         kr-3,
                                         CGColorMakeWithRGBABytes(0,0,0,64));
      }
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( kx-kr-5, cy-kr-5, kr*2+5+5, kr*2+5+5+3));
      CGContextCircle( context, CACircleMake( kx, cy, kr));
      CGContextPathWinding( context, CGPathFillStyleHole);
      CGContextFill( context);

      // Knob
      CGContextSetFillLinearGradient( context,
                                      CGPointMake( x, cy-kr),
                                      CGPointMake( x, cy+kr),
                                      CGColorMakeWithRGBABytes(255,255,255,16),
                                      CGColorMakeWithRGBABytes(0,0,0,16));
      CGContextBeginPath( context);
      CGContextCircle( context, CACircleMake( kx, cy, kr-1));
      CGContextFillColor( context, CGColorMakeWithRGBABytes(40,43,48,255));
      CGContextFill( context);
      CGContextFill( context);

      CGContextBeginPath( context);
      CGContextCircle( context, CACircleMake( kx, cy, kr-0.5f));
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,92));
      CGContextStroke( context);
   }
}

void drawEyes(CGContext *context, float x, float y, float w, float h, float mx, float my, float t)
{
   float ex = w *0.23f;
   float ey = h * 0.5f;
   float lx = x + ex;
   float ly = y + ey;
   float rx = x + w - ex;
   float ry = y + ey;
   float dx,dy,d;
   float br = (ex < ey ? ex : ey) * 0.5f;
   float blink = 1 - pow(sinf(t*0.5f),200)*0.8f;

   CGContextSetFillLinearGradient( context,
                                   CGPointMake( x, y+h*0.5f),
                                   CGPointMake( x+w*0.1f, y+h),
                                   CGColorMakeWithRGBABytes(0,0,0,32),
                                   CGColorMakeWithRGBABytes(0,0,0,16));
   CGContextBeginPath( context);
   CGContextEllipse( context, CGPointMake( lx+3.0f, ly+16.0f), ex, ey);
   CGContextEllipse( context, CGPointMake( rx+3.0f, ry+16.0f), ex, ey);
   CGContextFill( context);

   CGContextSetFillLinearGradient( context,
                                   CGPointMake( x, y+h*0.25f),
                                   CGPointMake( x+w*0.1f, y+h),
                                   CGColorMakeWithRGBABytes(220,220,220,255),
                                   CGColorMakeWithRGBABytes(128,128,128,255));
   CGContextBeginPath( context);
   CGContextEllipse( context, CGPointMake( lx, ly), ex, ey);
   CGContextEllipse( context, CGPointMake( rx, ry), ex, ey);
   CGContextFill( context);

   dx = (mx - rx) / (ex * 10);
   dy = (my - ry) / (ey * 10);
   d = sqrtf(dx*dx+dy*dy);
   if( d > 1.0f) {
      dx /= d; dy /= d;
   }
   dx *= ex*0.4f;
   dy *= ey*0.5f;
   CGContextBeginPath( context);
   CGContextEllipse( context, CGPointMake( lx+dx, ly+dy+ey*0.25f*(1-blink)), br, br*blink);
   CGContextFillColor( context, CGColorMakeWithRGBABytes(32,32,32,255));
   CGContextFill( context);

   dx = (mx - rx) / (ex * 10);
   dy = (my - ry) / (ey * 10);
   d = sqrtf(dx*dx+dy*dy);
   if( d > 1.0f) {
      dx /= d; dy /= d;
   }
   dx *= ex*0.4f;
   dy *= ey*0.5f;
   CGContextBeginPath( context);
   CGContextEllipse( context, CGPointMake( rx+dx, ry+dy+ey*0.25f*(1-blink)), br, br*blink);
   CGContextFillColor( context, CGColorMakeWithRGBABytes(32,32,32,255));
   CGContextFill( context);

   {
      CACircle glossCircle = CACircleMake( lx-ex*0.25f, ly-ey*0.5f, ex*0.75f);

      CGContextSetFillRadialGradient( context,
                                      glossCircle,
                                      CGColorMakeWithRGBABytes(255,255,255,0),
                                      ex*0.1f,
                                      CGColorMakeWithRGBABytes(255,255,255,128));
   }
   CGContextBeginPath( context);
   CGContextEllipse( context, CGPointMake( lx, ly), ex, ey);
   CGContextFill( context);

   {
      CACircle glossCircle = CACircleMake( rx-ex*0.25f, ry-ey*0.5f, ex*0.75f);

      CGContextSetFillRadialGradient( context,
                                      glossCircle,
                                      CGColorMakeWithRGBABytes(255,255,255,0),
                                      ex*0.1f,
                                      CGColorMakeWithRGBABytes(255,255,255,128));
   }
   CGContextBeginPath( context);
   CGContextEllipse( context, CGPointMake( rx, ry), ex, ey);
   CGContextFill( context);
}

void drawGraph(CGContext *context, float x, float y, float w, float h, float t)
{
   float samples[6];
   float sx[6], sy[6];
   float dx = w/5.0f;
   int i;

   samples[0] = (1+sinf(t*1.2345f+cosf(t*0.33457f)*0.44f))*0.5f;
   samples[1] = (1+sinf(t*0.68363f+cosf(t*1.3f)*1.55f))*0.5f;
   samples[2] = (1+sinf(t*1.1642f+cosf(t*0.33457)*1.24f))*0.5f;
   samples[3] = (1+sinf(t*0.56345f+cosf(t*1.63f)*0.14f))*0.5f;
   samples[4] = (1+sinf(t*1.6245f+cosf(t*0.254f)*0.3f))*0.5f;
   samples[5] = (1+sinf(t*0.345f+cosf(t*0.03f)*0.6f))*0.5f;

   for( i = 0; i < 6; i++)
   {
      sx[i] = x+i*dx;
      sy[i] = y+h*samples[i]*0.8f;
   }

   // Graph background
   CGContextSetFillLinearGradient( context,
                                   CGPointMake( x, y),
                                   CGPointMake( x, y+h),
                                   CGColorMakeWithRGBABytes(0,160,192,0),
                                   CGColorMakeWithRGBABytes(0,160,192,64));
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake( sx[0], sy[0]));
   for( i = 1; i < 6; i++)
      CGContextBezierTo( context,
                         CGPointMake( sx[i-1]+dx*0.5f, sy[i-1]),
                         CGPointMake( sx[i]-dx*0.5f, sy[i]),
                         CGPointMake( sx[i], sy[i]));
   CGContextLineTo( context, CGPointMake( x+w, y+h));
   CGContextLineTo( context, CGPointMake( x, y+h));
   CGContextFill( context);

   // Graph line
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake( sx[0], sy[0]+2));
   for( i = 1; i < 6; i++)
      CGContextBezierTo( context,
                         CGPointMake( sx[i-1]+dx*0.5f, sy[i-1]+2),
                         CGPointMake( sx[i]-dx*0.5f, sy[i]+2),
                         CGPointMake( sx[i], sy[i]+2));
   CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,32));
   CGContextStrokeWidth( context, 3.0f);
   CGContextStroke( context);

   CGContextBeginPath( context);
   CGContextMoveTo( context, CGPointMake( sx[0], sy[0]));
   for( i = 1; i < 6; i++)
      CGContextBezierTo( context,
                         CGPointMake( sx[i-1]+dx*0.5f, sy[i-1]),
                         CGPointMake( sx[i]-dx*0.5f, sy[i]),
                         CGPointMake( sx[i], sy[i]));
   CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,160,192,255));
   CGContextStrokeWidth( context, 3.0f);
   CGContextStroke( context);

   // Graph sample pos
   for( i = 0; i < 6; i++)
   {
      CACircle sampleCircle = CACircleMake( sx[i], sy[i]+2, 8.0f);

      CGContextSetFillRadialGradient( context,
                                      sampleCircle,
                                      CGColorMakeWithRGBABytes(0,0,0,0),
                                      3.0f,
                                      CGColorMakeWithRGBABytes(0,0,0,32));
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( sx[i]-10, sy[i]-10+2, 20, 20));
      CGContextFill( context);
   }

   CGContextBeginPath( context);
   for( i = 0; i < 6; i++)
      CGContextCircle( context, CACircleMake( sx[i], sy[i], 4.0f));
   CGContextFillColor( context, CGColorMakeWithRGBABytes(0,160,192,255));
   CGContextFill( context);
   CGContextBeginPath( context);
   for( i = 0; i < 6; i++)
      CGContextCircle( context, CACircleMake( sx[i], sy[i], 2.0f));
   CGContextFillColor( context, CGColorMakeWithRGBABytes(220,220,220,255));
   CGContextFill( context);

   CGContextStrokeWidth( context, 1.0f);
}

void drawSpinner(CGContext *context, float cx, float cy, float r, float t)
{
   float a0 = 0.0f + t*6;
   float a1 = M_PI + t*6;
   float r0 = r;
   float r1 = r * 0.75f;
   float ax,ay, bx,by;

   CGContextDo( context)
   {
      CGContextBeginPath( context);
      CGContextArcRadians( context, CACircleMake( cx, cy, r0), a0, a1, CARotationDirectionClockWise);
      CGContextArcRadians( context, CACircleMake( cx, cy, r1), a1, a0, CARotationDirectionCounterClockWise);
      CGContextClosePath( context);
      ax = cx + cosf(a0) * (r0+r1)*0.5f;
      ay = cy + sinf(a0) * (r0+r1)*0.5f;
      bx = cx + cosf(a1) * (r0+r1)*0.5f;
      by = cy + sinf(a1) * (r0+r1)*0.5f;
      CGContextSetFillLinearGradient( context, CGPointMake( ax, ay),
                                               CGPointMake( bx, by),
                                               CGColorMakeWithRGBABytes(0,0,0,0),
                                               CGColorMakeWithRGBABytes(0,0,0,128));
      CGContextFill( context);
   }
}

void drawThumbnails(CGContext *context, float x, float y, float w, float h, const int* images, int nimages, float t)
{
   float cornerRadius = 3.0f;
   float ix,iy,iw,ih;
   float thumb = 60.0f;
   float arry = 30.5f;
   int imgw, imgh;
   float stackh = (nimages/2) * (thumb+10) + 10;
   int i;
   float u = (1+cosf(t*0.5f))*0.5f;
   float u2 = (1-cosf(t*0.2f))*0.5f;
   float scrollh, dv;

   CGContextDo( context)
   {

      // Drop shadow
      /* shadowPaint */
      CGContextSetFillBoxGradient( context,
                                   CGRectMake( x, y+4, w, h),
                                   cornerRadius*2,
                                   CGColorMakeWithRGBABytes(0,0,0,128),
                                   20,
                                   CGColorMakeWithRGBABytes(0,0,0,0));
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( x-10, y-10, w+20, h+30));
      CGContextRoundedRect( context, CGRectMake( x, y, w, h), cornerRadius);
      CGContextPathWinding( context, CGPathFillStyleHole);
      CGContextFill( context);

      // Window
      CGContextBeginPath( context);
      CGContextRoundedRect( context, CGRectMake( x, y, w, h), cornerRadius);
      CGContextMoveTo( context, CGPointMake( x-10, y+arry));
      CGContextLineTo( context, CGPointMake( x+1, y+arry-11));
      CGContextLineTo( context, CGPointMake( x+1, y+arry+11));
      CGContextFillColor( context, CGColorMakeWithRGBABytes(200,200,200,255));
      CGContextFill( context);

      CGContextDo( context)
      {
         CGContextScissor( context, CGRectMake( x, y, w, h));
         CGContextTranslate( context, CGPointMake( 0, -(stackh - h)*u));

         dv = 1.0f / (float)(nimages-1);

         for( i = 0; i < nimages; i++)
         {
            float tx, ty, v, a;
            tx = x+10;
            ty = y+10;
            tx += (i%2) * (thumb+10);
            ty += (i/2) * (thumb+10);
            {
               CGPixelSize  _isz = CGContextImageSize( context, images[i]);
               imgw = _isz.width;
               imgh = _isz.height;
            }
            if( imgw < imgh) {
               iw = thumb;
               ih = iw * (float)imgh/(float)imgw;
               ix = 0;
               iy = -(ih-thumb)*0.5f;
            }
            else
            {
               ih = thumb;
               iw = ih * (float)imgw/(float)imgh;
               ix = -(iw-thumb)*0.5f;
               iy = 0;
            }

            v = i * dv;
            a = clampf((u2-v) / dv, 0, 1);

            if( a < 1.0f)
               drawSpinner(context, tx+thumb/2,ty+thumb/2, thumb*0.25f, t);

            CGContextBeginPath( context);
            CGContextRoundedRect( context, CGRectMake( tx, ty, thumb, thumb), 5);
            CGContextSetFillImagePattern( context, images[i], CGRectMake( tx+ix, ty+iy, iw, ih), 0.0f, a);
            CGContextFill( context);

            CGContextSetFillBoxGradient( context,
                                         CGRectMake( tx-1, ty, thumb+2, thumb+2),
                                         5,
                                         CGColorMakeWithRGBABytes(0,0,0,128),
                                         3,
                                         CGColorMakeWithRGBABytes(0,0,0,0));
            CGContextBeginPath( context);
            CGContextRect( context, CGRectMake( tx-5, ty-5, thumb+10, thumb+10));
            CGContextRoundedRect( context, CGRectMake( tx, ty, thumb, thumb), 6);
            CGContextPathWinding( context, CGPathFillStyleHole);
               CGContextFill( context);

            CGContextBeginPath( context);
            CGContextRoundedRect( context, CGRectMake( tx+0.5f, ty+0.5f, thumb-1, thumb-1), 4-0.5f);
            CGContextStrokeWidth( context, 1.0f);
            CGContextStrokeColor( context, CGColorMakeWithRGBABytes(255,255,255,192));
            CGContextStroke( context);
         }
      }

      // Hide fades
      CGContextSetFillLinearGradient( context,
                                      CGPointMake( x, y),
                                      CGPointMake( x, y+6),
                                      CGColorMakeWithRGBABytes(200,200,200,255),
                                      CGColorMakeWithRGBABytes(200,200,200,0));
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( x+4, y, w-8, 6));
      CGContextFill( context);

      CGContextSetFillLinearGradient( context,
                                      CGPointMake( x, y+h),
                                      CGPointMake( x, y+h-6),
                                      CGColorMakeWithRGBABytes(200,200,200,255),
                                      CGColorMakeWithRGBABytes(200,200,200,0));
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( x+4, y+h-6, w-8, 6));
      CGContextFill( context);

      // Scroll bar
      CGContextSetFillBoxGradient( context,
                                   CGRectMake( x+w-12+1, y+4+1, 8, h-8),
                                   3,
                                   CGColorMakeWithRGBABytes(0,0,0,32),
                                   4,
                                   CGColorMakeWithRGBABytes(0,0,0,92));
      CGContextBeginPath( context);
      CGContextRoundedRect( context, CGRectMake( x+w-12, y+4, 8, h-8), 3);
   // CGContextFillColor( context, CGColorMakeWithRGBABytes(255,0,0,128));
      CGContextFill( context);

      scrollh = (h/stackh) * (h-8);
      CGContextSetFillBoxGradient( context,
                                   CGRectMake( x+w-12-1, y+4+(h-8-scrollh)*u-1, 8, scrollh),
                                   3,
                                   CGColorMakeWithRGBABytes(220,220,220,255),
                                   4,
                                   CGColorMakeWithRGBABytes(128,128,128,255));
      CGContextBeginPath( context);
      CGContextRoundedRect( context, CGRectMake( x+w-12+1, y+4+1 + (h-8-scrollh)*u, 8-2, scrollh-2), 2);
   // CGContextFillColor( context, CGColorMakeWithRGBABytes(0,0,0,128));
      CGContextFill( context);
   }
}

void drawColorwheel(CGContext *context, float x, float y, float w, float h, float t)
{
   int i;
   float r0, r1, ax,ay, bx,by, cx,cy, aeps, r;
   float hue = sinf(t * 0.12f);

   CGContextDo( context)
   {

   /* CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( x, y, w, h));
      CGContextFillColor( context, CGColorMakeWithRGBABytes(255,0,0,128));
      CGContextFill( context);*/

      cx = x + w*0.5f;
      cy = y + h*0.5f;
      r1 = (w < h ? w : h) * 0.5f - 5.0f;
      r0 = r1 - 20.0f;
      aeps = 0.5f / r1; // half a pixel arc length in radians (2pi cancels out).

      for( i = 0; i < 6; i++)
      {
         float a0 = (float)i / 6.0f * M_PI * 2.0f - aeps;
         float a1 = (float)(i+1.0f) / 6.0f * M_PI * 2.0f + aeps;
         CGContextBeginPath( context);
         CGContextArcRadians( context, CACircleMake( cx, cy, r0), a0, a1, CARotationDirectionClockWise);
         CGContextArcRadians( context, CACircleMake( cx, cy, r1), a1, a0, CARotationDirectionCounterClockWise);
         CGContextClosePath( context);
         ax = cx + cosf(a0) * (r0+r1)*0.5f;
         ay = cy + sinf(a0) * (r0+r1)*0.5f;
         bx = cx + cosf(a1) * (r0+r1)*0.5f;
         by = cy + sinf(a1) * (r0+r1)*0.5f;
         CGContextSetFillLinearGradient( context,
                                         CGPointMake( ax, ay),
                                         CGPointMake( bx, by),
                                         CGColorMakeWithHSL(a0/(M_PI*2),1.0f,0.55f),
                                         CGColorMakeWithHSL(a1/(M_PI*2),1.0f,0.55f));
            CGContextFill( context);
      }

      CGContextBeginPath( context);
      CGContextCircle( context, CACircleMake( cx, cy, r0-0.5f));
      CGContextCircle( context, CACircleMake( cx, cy, r1+0.5f));
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,64));
      CGContextStrokeWidth( context, 1.0f);
      CGContextStroke( context);

      // Selector
      CGContextDo( context)
      {
         CGContextTranslate( context, CGPointMake( cx, cy));
         CGContextRotate( context, hue*M_PI*2);

         // Marker on
         CGContextStrokeWidth( context, 2.0f);
         CGContextBeginPath( context);
         CGContextRect( context, CGRectMake( r0-1, -3, r1-r0+2, 6));
         CGContextStrokeColor( context, CGColorMakeWithRGBABytes(255,255,255,192));
         CGContextStroke( context);

         CGContextSetFillBoxGradient( context,
                                      CGRectMake( r0-3, -5, r1-r0+6, 10),
                                      2,
                                      CGColorMakeWithRGBABytes(0,0,0,128),
                                      4,
                                      CGColorMakeWithRGBABytes(0,0,0,0));
         CGContextBeginPath( context);
         CGContextRect( context, CGRectMake( r0-2-10, -4-10, r1-r0+4+20, 8+20));
         CGContextRect( context, CGRectMake( r0-2, -4, r1-r0+4, 8));
         CGContextPathWinding( context, CGPathFillStyleHole);
         CGContextFill( context);

         // Center triangle
         r = r0 - 6;
         ax = cosf(120.0f/180.0f*M_PI) * r;
         ay = sinf(120.0f/180.0f*M_PI) * r;
         bx = cosf(-120.0f/180.0f*M_PI) * r;
         by = sinf(-120.0f/180.0f*M_PI) * r;
         CGContextBeginPath( context);
         CGContextMoveTo( context, CGPointMake( r, 0));
         CGContextLineTo( context, CGPointMake( ax, ay));
         CGContextLineTo( context, CGPointMake( bx, by));
         CGContextClosePath( context);
         CGContextSetFillLinearGradient( context,
                                         CGPointMake( r, 0),
                                         CGPointMake( ax, ay),
                                         CGColorMakeWithHSL(hue,1.0f,0.5f),
                                         CGColorMakeWithRGBABytes(255,255,255,255));
         CGContextFill( context);
         CGContextSetFillLinearGradient( context,
                                         CGPointMake( (r+ax)*0.5f, (0+ay)*0.5f),
                                         CGPointMake( bx, by),
                                         CGColorMakeWithRGBABytes(0,0,0,0),
                                         CGColorMakeWithRGBABytes(0,0,0,255));
         CGContextFill( context);
         CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,64));
         CGContextStroke( context);

         // Select circle on triangle
         ax = cosf(120.0f/180.0f*M_PI) * r*0.3f;
         ay = sinf(120.0f/180.0f*M_PI) * r*0.4f;
         CGContextStrokeWidth( context, 2.0f);
         CGContextBeginPath( context);
         CGContextCircle( context, CACircleMake( ax, ay, 5));
         CGContextStrokeColor( context, CGColorMakeWithRGBABytes(255,255,255,192));
         CGContextStroke( context);

         {
            CACircle selectCircle = CACircleMake( ax, ay, 9);

            CGContextSetFillRadialGradient( context,
                                            selectCircle,
                                            CGColorMakeWithRGBABytes(0,0,0,0),
                                            7,
                                            CGColorMakeWithRGBABytes(0,0,0,64));
         }
         CGContextBeginPath( context);
         CGContextRect( context, CGRectMake( ax-20, ay-20, 40, 40));
         CGContextCircle( context, CACircleMake( ax, ay, 7));
         CGContextPathWinding( context, CGPathFillStyleHole);
         CGContextFill( context);
      }
   }
}

void drawLines(CGContext *context, float x, float y, float w, float h, float t)
{
   int i, j;
   float pad = 5.0f, s = w/9.0f - pad*2;
   float pts[4*2], fx, fy;
   int joins[3] = {CGLineCapMiter, CGLineCapRound, CGLineCapBevel};
   int caps[3] = {CGLineCapButt, CGLineCapRound, CGLineCapSquare};
   (void)(h);

   CGContextDo( context)
   {
      pts[0] = -s*0.25f + cosf(t*0.3f) * s*0.5f;
      pts[1] = sinf(t*0.3f) * s*0.5f;
      pts[2] = -s*0.25;
      pts[3] = 0;
      pts[4] = s*0.25f;
      pts[5] = 0;
      pts[6] = s*0.25f + cosf(-t*0.3f) * s*0.5f;
      pts[7] = sinf(-t*0.3f) * s*0.5f;

      for( i = 0; i < 3; i++)
      {
         for( j = 0; j < 3; j++)
         {
            fx = x + s*0.5f + (i*3+j)/9.0f*w + pad;
            fy = y - s*0.5f + pad;

            CGContextLineCap( context, caps[i]);
            CGContextLineJoin( context, joins[j]);

            CGContextStrokeWidth( context, s*0.3f);
            CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,160));
            CGContextBeginPath( context);
            CGContextMoveTo( context, CGPointMake( fx+pts[0], fy+pts[1]));
            CGContextLineTo( context, CGPointMake( fx+pts[2], fy+pts[3]));
            CGContextLineTo( context, CGPointMake( fx+pts[4], fy+pts[5]));
            CGContextLineTo( context, CGPointMake( fx+pts[6], fy+pts[7]));
            CGContextStroke( context);

            CGContextLineCap( context, CGLineCapButt);
            CGContextLineJoin( context, CGLineCapBevel);

            CGContextStrokeWidth( context, 1.0f);
            CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,192,255,255));
            CGContextBeginPath( context);
            CGContextMoveTo( context, CGPointMake( fx+pts[0], fy+pts[1]));
            CGContextLineTo( context, CGPointMake( fx+pts[2], fy+pts[3]));
            CGContextLineTo( context, CGPointMake( fx+pts[4], fy+pts[5]));
            CGContextLineTo( context, CGPointMake( fx+pts[6], fy+pts[7]));
            CGContextStroke( context);
         }
      }
   }
}

int loadDemoData(CGContext *context, DemoData* data)
{
   int i;

   if( context == NULL)
      return( -1);

   for( i = 0; i < 12; i++)
   {
      char file[128];
      snprintf(file, 128, "images/image%d.jpg", i+1);
      data->images[i] = CGContextCreateImage( context, file, 0);
      if( data->images[i] == 0) {
         printf("Could not load %s.\n", file);
         return( -1);
      }
   }

   data->fontIcons = CGContextCreateFont( context, "icons", "entypo.ttf");
   if( data->fontIcons == -1) {
      printf("Could not add font icons.\n");
      return( -1);
   }
   data->fontNormal = CGContextCreateFont( context, "sans", "Roboto-Regular.ttf");
   if( data->fontNormal == -1) {
      printf("Could not add font italic.\n");
      return( -1);
   }
   data->fontBold = CGContextCreateFont( context, "sans-bold", "Roboto-Bold.ttf");
   if( data->fontBold == -1) {
      printf("Could not add font bold.\n");
      return( -1);
   }
   data->fontEmoji = CGContextCreateFont( context, "emoji", "NotoEmoji-Regular.ttf");
   if( data->fontEmoji == -1) {
      printf("Could not add font emoji.\n");
      return( -1);
   }
   CGContextAddFallbackFontId( context, data->fontNormal, data->fontEmoji);
   CGContextAddFallbackFontId( context, data->fontBold, data->fontEmoji);

   return( 0);
}

void freeDemoData(CGContext *context, DemoData* data)
{
   int i;

   if( context == NULL)
      return;

   for( i = 0; i < 12; i++)
      CGContextDeleteImage( context, data->images[i]);
}

void drawParagraph(CGContext *context, float x, float y, float width, float height, float mx, float my)
{
   struct UITextRow rows[3];
   struct UIGlyphPosition glyphs[100];
   char* text = "This is longer chunk of text.\n  \n  Would have used lorem ipsum but she    was busy jumping over the lazy dog with the fox and all the men who came to the aid of the party.\xF0\x9F\x8E\x89";
   char* start;
   size_t remaining;
   int nrows, i, nglyphs, j, lnum = 0;
   float lineh;
   float caretx, px;
   float bounds[4];
   float a;
   const char* hoverText = "Hover your mouse over the text to see calculated caret position.";
   float gx,gy;
   int gutter = 0;
   const char* boxText = "Testing\nsome multiline\ntext.";
   (void)(height);

   CGContextDo( context)
   {
      CGContextFontSize( context, 15.0f);
      CGContextFontFace( context, "sans");
      CGContextCombinedTextAlignment( context, CGTextAlignLeft|CGTextAlignTop);
      lineh = CGContextTextMetrics( context).lineHeight;

      // The text break API can be used to fill a large buffer of rows,
      // or to iterate over the text just few lines (or just one) at a time.
      start     = text;
      remaining = strlen( text);
      while( (nrows = CGContextTextBreakLines( context, start, remaining, width, rows, 3, sizeof( struct UITextRow))))
      {
         for( i = 0; i < nrows; i++)
         {
            struct UITextRow* row = &rows[i];
            char   *rowStart  = start + row->range.location;
            size_t  rowLength = row->range.length;
            int hit = mx > x && mx < (x+width) && my >= y && my < (y+lineh);

            CGContextBeginPath( context);
            CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,hit?64:16));
            CGContextRect( context, CGRectMake( x + row->minx, y, row->maxx - row->minx, lineh));
            CGContextFill( context);

            CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,255));
            CGContextText( context, CGPointMake( x, y), rowStart, rowLength);

            if( hit) {
               caretx = (mx < x+row->width/2) ? x : x+row->width;
               px = x;
               nglyphs = CGContextTextGlyphPositions( context, CGPointMake( x, y), rowStart, rowLength, glyphs, 100);
               for( j = 0; j < nglyphs; j++)
               {
                  float x0 = glyphs[j].x;
                  float x1 = (j+1 < nglyphs) ? glyphs[j+1].x : x+row->width;
                  float gx = x0 * 0.3f + x1 * 0.7f;
                  if( mx >= px && mx < gx)
                     caretx = glyphs[j].x;
                  px = gx;
               }
               CGContextBeginPath( context);
               CGContextFillColor( context, CGColorMakeWithRGBABytes(255,192,0,255));
               CGContextRect( context, CGRectMake( caretx, y, 1, lineh));
               CGContextFill( context);

               gutter = lnum+1;
               gx = x - 10;
               gy = y + lineh/2;
            }
            lnum++;
            y += lineh;
         }
         // Keep going...
         {
            struct UITextRow *lastRow = &rows[nrows-1];
            size_t consumed = lastRow->range.location + lastRow->range.length;
            start     += consumed;
            remaining -= consumed;
         }
      }

      if( gutter) {
         char txt[16];
         snprintf(txt, sizeof(txt), "%d", gutter);
         CGContextFontSize( context, 12.0f);
         CGContextCombinedTextAlignment( context, CGTextAlignRight|CGTextAlignMiddle);

         {
            CGTextBoundsInfo  binfo;
            binfo = CGContextTextBoundsInfo( context, CGPointMake( gx, gy), txt, (size_t) -1);
            bounds[0] = CGRectGetMinX( binfo.bounds);
            bounds[1] = CGRectGetMinY( binfo.bounds);
            bounds[2] = CGRectGetMaxX( binfo.bounds);
            bounds[3] = CGRectGetMaxY( binfo.bounds);
         }

         CGContextBeginPath( context);
         CGContextFillColor( context, CGColorMakeWithRGBABytes(255,192,0,255));
         {
            int bw = (int)(bounds[2]-bounds[0]) + 8;
            int bh = (int)(bounds[3]-bounds[1]) + 4;

            CGContextRoundedRect( context,
                                  CGRectMake( (int)bounds[0]-4, (int)bounds[1]-2, bw, bh),
                                  bh/2-1);
         }
         CGContextFill( context);

         CGContextFillColor( context, CGColorMakeWithRGBABytes(32,32,32,255));
         CGContextText( context, CGPointMake( gx, gy), txt, (size_t) -1);
      }

      y += 20.0f;

      CGContextFontSize( context, 11.0f);
      CGContextCombinedTextAlignment( context, CGTextAlignLeft|CGTextAlignTop);
      CGContextTextLineHeight( context, 1.2f);

      {
         CGRect  bbox;
         bbox = CGContextTextBoxBounds( context, CGPointMake( x, y), (char *) hoverText, (size_t) -1, 150);
         bounds[0] = CGRectGetMinX( bbox);
         bounds[1] = CGRectGetMinY( bbox);
         bounds[2] = CGRectGetMaxX( bbox);
         bounds[3] = CGRectGetMaxY( bbox);
      }

      // Fade the tooltip out when close to it.
      gx = clampf(mx, bounds[0], bounds[2]) - mx;
      gy = clampf(my, bounds[1], bounds[3]) - my;
      a = sqrtf(gx*gx + gy*gy) / 30.0f;
      a = clampf(a, 0, 1);
      CGContextGlobalAlpha( context, a);

      CGContextBeginPath( context);
      CGContextFillColor( context, CGColorMakeWithRGBABytes(220,220,220,255));
      CGContextRoundedRect( context,
                            CGRectMake( bounds[0]-2, bounds[1]-2,
                                        (int)(bounds[2]-bounds[0])+4,
                                        (int)(bounds[3]-bounds[1])+4),
                            3);
      px = (int)((bounds[2]+bounds[0])/2);
      CGContextMoveTo( context, CGPointMake( px, bounds[1] - 10));
      CGContextLineTo( context, CGPointMake( px+7, bounds[1]+1));
      CGContextLineTo( context, CGPointMake( px-7, bounds[1]+1));
      CGContextFill( context);

      CGContextFillColor( context, CGColorMakeWithRGBABytes(0,0,0,220));
      CGContextTextBox( context, CGPointMake( x, y), 150, hoverText, (size_t) -1);
   }
}

void drawWidths(CGContext *context, float x, float y, float width)
{
   int i;

   CGContextDo( context)
   {
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,255));

      for( i = 0; i < 20; i++)
      {
         float w = (i+0.5f)*0.1f;
         CGContextStrokeWidth( context, w);
         CGContextBeginPath( context);
         CGContextMoveTo( context, CGPointMake( x, y));
         CGContextLineTo( context, CGPointMake( x+width, y+width*0.3f));
         CGContextStroke( context);
         y += 10;
      }
   }
}

void drawCaps(CGContext *context, float x, float y, float width)
{
   int i;
   int caps[3] = {CGLineCapButt, CGLineCapRound, CGLineCapSquare};
   float lineWidth = 8.0f;

   CGContextDo( context)
   {
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( x-lineWidth/2, y, width+lineWidth, 40));
      CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,32));
      CGContextFill( context);

      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( x, y, width, 40));
      CGContextFillColor( context, CGColorMakeWithRGBABytes(255,255,255,32));
      CGContextFill( context);

      CGContextStrokeWidth( context, lineWidth);
      for( i = 0; i < 3; i++)
      {
         CGContextLineCap( context, caps[i]);
         CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,255));
         CGContextBeginPath( context);
         CGContextMoveTo( context, CGPointMake( x, y + i*10 + 5));
         CGContextLineTo( context, CGPointMake( x+width, y + i*10 + 5));
         CGContextStroke( context);
      }
   }
}

void drawScissor(CGContext *context, float x, float y, float t)
{
   CGContextDo( context)
   {
      // Draw first rect and set scissor to it's area.
      CGContextTranslate( context, CGPointMake( x, y));
      CGContextRotate( context, (5 / 180.0f * (float) M_PI));
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( -20, -20, 60, 40));
      CGContextFillColor( context, CGColorMakeWithRGBABytes(255,0,0,255));
      CGContextFill( context);
      CGContextScissor( context, CGRectMake( -20, -20, 60, 40));

      // Draw second rectangle with offset and rotation.
      CGContextTranslate( context, CGPointMake( 40, 0));
      CGContextRotate( context, t);

      // Draw the intended second rectangle without any scissoring.
      CGContextDo( context)
      {
         CGContextResetScissor( context);
         CGContextBeginPath( context);
         CGContextRect( context, CGRectMake( -20, -10, 60, 30));
         CGContextFillColor( context, CGColorMakeWithRGBABytes(255,128,0,64));
         CGContextFill( context);
      }

      // Draw second rectangle with combined scissoring.
      CGContextIntersectScissor( context, CGRectMake( -20, -10, 60, 30));
      CGContextBeginPath( context);
      CGContextRect( context, CGRectMake( -20, -10, 60, 30));
      CGContextFillColor( context, CGColorMakeWithRGBABytes(255,128,0,255));
      CGContextFill( context);
   }
}

void renderDemo(CGContext *context, float mx, float my, float width, float height,
            float t, int blowup, DemoData* data)
{
   float x,y,popy;

   drawEyes(context, width - 250, 50, 150, 100, mx, my, t);
   drawParagraph(context, width - 450, 50, 150, 100, mx, my);
   drawGraph(context, 0, height/2, width, height/2, t);
   drawColorwheel(context, width - 300, height - 300, 250.0f, 250.0f, t);

   // Line joints
   drawLines(context, 120, height-50, 600, 50, t);

   // Line caps
   drawWidths(context, 10, 50, 30);

   // Line caps
   drawCaps(context, 10, 300, 30);

   drawScissor(context, 50, height-80, t);

   CGContextDo( context)
   {
      if( blowup) {
         CGContextRotate( context, sinf(t*0.3f)*5.0f/180.0f*M_PI);
         CGContextScale( context, CGVectorMake( 2.0f, 2.0f));
      }

      // Widgets
      drawWindow(context, "Widgets `n Stuff", 50, 50, 300, 400);
      x = 60; y = 95;
      drawSearchBox(context, "Search", x,y,280,25);
      y += 40;
      drawDropDown(context, "Effects", x,y,280,28);
      popy = y + 14;
      y += 45;

      // Form
      drawLabel(context, "Login", x,y, 280,20);
      y += 25;
      drawEditBox(context, "Email",  x,y, 280,28);
      y += 35;
      drawEditBox(context, "Password", x,y, 280,28);
      y += 38;
      drawCheckBox(context, "Remember me", x,y, 140,28);
      drawButton(context, ICON_LOGIN, "Sign in", x+138, y, 140, 28, CGColorMakeWithRGBABytes(0,96,128,255));
      y += 45;

      // Slider
      drawLabel(context, "Diameter", x,y, 280,20);
      y += 25;
      drawEditBoxNum(context, "123.00", "px", x+180,y, 100,28);
      drawSlider(context, 0.4f, x,y, 170,28);
      y += 55;

      drawButton(context, ICON_TRASH, "Delete", x, y, 160, 28, CGColorMakeWithRGBABytes(128,16,8,255));
      drawButton(context, 0, "Cancel", x+170, y, 110, 28, CGColorMakeWithRGBABytes(0,0,0,0));

      // Thumbnails box
      drawThumbnails(context, 365, popy-30, 160, 300, data->images, 12, t);
   }
}



//
// MulleUIOS main() — GLFWOSWindow with CGContext rendering
//

static DemoData   demoData;
static int        blowup;
static int        screenshot;
static int        frameCount;


@interface MyWindow : GLFWOSWindow

@property( retain) CGContext  *context;

@end

@implementation MyWindow

- (void) finalize
{
   [self os_activateGraphicsContext];
   {
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


static UIWindowDisplayBits   display( id <UIOSWindow> osWindow)
{
   MyWindow       *window = (MyWindow *) osWindow;
   CGContext      *context;
   CGFrameInfo    frameInfo;
   CGRect         canvas;
   double         mx, my, t;

   canvas.origin = CGPointZero;
   canvas.size   = [window os_windowSize];

   context   = [window context];
   assert( context);

   frameInfo = CGFrameInfoSFMake( canvas, [window os_framebufferSize], 1.0);

   [context beginRender:&frameInfo];
   {
      [context clearFramebufferWithHexColor:0x4D4D51FF];  // 0.3, 0.3, 0.32, 1.0

      if( ! frameCount)
      {
         if( loadDemoData( context, &demoData) == -1)
         {
            fprintf( stderr, "Could not load demo data.\n");
            exit( 1);
         }
      }

      t  = glfwGetTime();

      glfwGetCursorPos( [window os_window], &mx, &my);

      renderDemo( context, mx, my, canvas.size.width, canvas.size.height, t, blowup, &demoData);
   }
   [context endRender];

   frameCount++;
   if( screenshot && frameCount >= screenshot)
   {
      struct CGBitmap   bitmap;
      UIBitmapImage     *image;

      bitmap = [window screenshotBitmap];
      image  = [UIBitmapImage imageWithBitmap:bitmap
                                 freeWhenDone:YES];
      [image writeToPNGUTF8String:"screenshot.png"];
      fprintf( stderr, "Saved screenshot.png\n");
      exit( 0);
   }

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
      {
         int   i;

         for( i = 1; i < argc; i++)
         {
            if( ! strcmp( argv[ i], "-s"))
               screenshot = 3;  // screenshot after 3 frames
            else if( ! strcmp( argv[ i], "-b"))
               blowup = 1;
         }
      }

      hints = GLFWGraphicsHintsDefault;
      switch( [MyWindow defaultBackend])
      {
      case CG_GL3     : hints = GLFWGraphicsHintsGL3; break;
      case CG_GL3_2   : hints = GLFWGraphicsHintsGL3_2; break;
      case CG_GLES2   : hints = GLFWGraphicsHintsGLES2; break;
      case CG_GLES3   : hints = GLFWGraphicsHintsGLES3; break;
      case CG_GLES3_2 : hints = GLFWGraphicsHintsGLES3_2; break;
      }

      window = [[[MyWindow alloc] initWithFrame:CGRectMake( 0, 0, 1000, 600)
                                titleUTF8String:"CG Kitchen Sink"
                                      styleMask:GLFWOSWindowStyleMaskDefault
                                  graphicsHints:hints] autorelease];
      assert( window);

      [window os_activateGraphicsContext];
      context = [[[CGContext alloc] initWithOSGraphicsContext:window
                                                     shareID:[window shareID]
                                                     options:UIGraphicsDefaultOptions] autorelease];
      [window os_deactivateGraphicsContext];

      [window setContext:context];

      [window setFrameCallback:display];
      [window setFrameRate:UIWindowFrameRateSynced];

      [app addWindow:window];
   }
   return( [app runApp]);
}

#endif /* HAVE_IMPORT__MULLE_GLFW */
