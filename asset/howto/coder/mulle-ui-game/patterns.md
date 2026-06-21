<!-- keywords: game, patterns, drawing, CGContext, color, text, input, CGGraphicsLayer -->
# Patterns

## Drawing primitives in the draw callback

```objc
// Colors
struct MulleColor  red   = MulleColorMake( 1.0, 0.0, 0.0, 1.0);
struct MulleColor  white = MulleColorMake( 1.0, 1.0, 1.0, 1.0);

// Fill a rectangle
CGContextFillRectWithColor( context, CGRectMake( x, y, w, h), red);

// Stroke a line
CGContextStrokeLineWithColor( context, CGPointMake( x1, y1),
                                       CGPointMake( x2, y2), 2.0, white);

// Fill a polygon (triangle, quad, any shape) using the path API
CGContextBeginPath( context);
CGContextMoveTo( context, CGPointMake( x1, y1));
CGContextLineTo( context, CGPointMake( x2, y2));
CGContextLineTo( context, CGPointMake( x3, y3));
CGContextClosePath( context);
CGContextFillWithColor( context, red);

// Render text (one-liner, auto-selects "sans" font if none set)
CGContextDrawText( context, x, y, "Score: 42", 24.0, white);

// Formatted text in a rect (requires font to be set beforehand)
CGContextFontFace( context, "sans");
CGContextFontSize( context, 18.0);
CGContextFormatInRect( context, rect, CGContentModeCenter, 0, "Score: %d", score);
```

> **Font note:** `CGContextDrawText` handles font selection internally (defaults
> to "sans"). Functions like `CGContextFormatInRect` and `CGContextTextInRect`
> do NOT — you must call `CGContextFontFace( context, "sans")` first.
> Inside a `CGGraphicsLayer drawInContext:` the font is already set by the
> framework. In a raw `UIPureWindow` frame callback it is not.

## Sprite texturing from pixel data

Define an 8×8 RGBA bitmap as a C array, create a `CGImage` from it, then
draw or tile it. The image is uploaded to the GPU once and cached via
`resourceKey`.

```objc
// 8x8 checkerboard sprite (R=red, G=green, _=transparent)
#define R   { 0xFF, 0x00, 0x00, 0xFF }
#define G   { 0x00, 0xFF, 0x00, 0xFF }

static uint8_t   sprite_pixels[8][8][4] =
{
   { R, R, R, R, G, G, G, G },
   { R, R, R, R, G, G, G, G },
   { R, R, R, R, G, G, G, G },
   { R, R, R, R, G, G, G, G },
   { G, G, G, G, R, R, R, R },
   { G, G, G, G, R, R, R, R },
   { G, G, G, G, R, R, R, R },
   { G, G, G, G, R, R, R, R },
};

static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   static MulleUIResourceStorageKeyDefine( my_sprite);
   CGImage   *image;
   CGRect     dst;

   // Create (or retrieve cached) GPU texture from pixel data
   image = [context imageWithRGBABytes:sprite_pixels
                            bitmapSize:CGPixelSizeMake( 8, 8)
                          textureFlags:0
                        nameUTF8String:NULL
                           resourceKey:MulleUIResourceStorageKey( my_sprite)];

   // Draw the sprite scaled to a 32x32 rect at position (100, 50)
   dst = CGRectMake( 100, 50, 32, 32);
   [image drawRect:dst options:NULL context:context];

   return( YES);
}
```

For tiling (repeating pattern fill), add `CGImageFlagRepeatX|CGImageFlagRepeatY`
to `textureFlags`.

## CGGraphicsLayer game object

```objc
@interface SpriteLayer : CGGraphicsLayer
{
   CGColorRef   _color;
}
@end

@implementation SpriteLayer

- (void) drawInContext:(CGContext *) context
{
   [super drawInContext:context];
   CGContextFillRectWithColor( context, [self canvas], _color);
}

@end
```

## Input polling (simple draw-callback path)

```objc
static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   CGPoint   mouse;
   int       buttons;

   mouse   = [context mouseLocation];
   buttons = [context buttonStates];

   // Left button: buttons & 1
   // Right button: buttons & 2
   // Middle button: buttons & 4

   return( YES);
}
```

## Keyboard polling (draw-callback path)

```objc
static UIWindowDisplayBits   display( UIPureWindow *window,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *frameInfo,
                                      UIWindowDisplayBits displayBits)
{
   NSUInteger   keys[ 32];
   NSUInteger   count;

   count = [(id <UIOSWindow>) [context OSWindow] pressedKeys:keys
                                                       count:32];

   for( NSUInteger i = 0; i < count; i++)
   {
      switch( keys[ i])
      {
      case UIEventKeyW:     /* up    */ break;
      case UIEventKeyS:     /* down  */ break;
      case UIEventKeyA:     /* left  */ break;
      case UIEventKeyD:     /* right */ break;
      case UIEventKeySpace: /* fire  */ break;
      }
   }
   return( displayBits);
}
```

The OSWindow maintains pressed-key state from events and resyncs from the OS
on focus regain. Up to 32 simultaneous keys are tracked.

## Input via responder chain (structured path)

```objc
@implementation GameView

- (BOOL) canBecomeFirstResponder
{
   return( YES);
}

- (void) mouseDown:(UIEvent *) event
{
   CGPoint   point;

   point = [self convertPoint:[event locationInWindow] fromView:nil];
   // point is now in view-local coordinates
   [self setNeedsDisplay];
}

- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event
{
   switch( [event key])
   {
   case UIEventKeyUp:    _keyUp    = YES; break;
   case UIEventKeyDown:  _keyDown  = YES; break;
   case UIEventKeyLeft:  _keyLeft  = YES; break;
   case UIEventKeyRight: _keyRight = YES; break;
   }
   return( nil);  // consume event
}

- (UIInputEvent *) keyUp:(UIKeyboardEvent *) event
{
   switch( [event key])
   {
   case UIEventKeyUp:    _keyUp    = NO; break;
   case UIEventKeyDown:  _keyDown  = NO; break;
   case UIEventKeyLeft:  _keyLeft  = NO; break;
   case UIEventKeyRight: _keyRight = NO; break;
   }
   return( nil);
}

@end
```

Activate keyboard focus after window creation:

```objc
[[window contentView] becomeFirstResponder];
```

## Collision detection with UIView hitTest

```objc
// Check what game object is at a screen point
UIView   *hit;

hit = [[window contentView] hitTest:point withEvent:nil];
if( hit == enemyView)
{
   // collision with enemy
}
```

## Game loop with state

For games using the UIView hierarchy (not the simple draw-callback), use
`setFrameCallback:` with `UIWindowDefaultRenderViews`:

```objc
static UIWindowDisplayBits   display( UIPureWindow *window,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *frameInfo,
                                      UIWindowDisplayBits displayBits)
{
   Game   *game;

   game = [window userInfo];
   [game updateWithTime:frameInfo->now];   // mulle_absolutetime_t

   displayBits |= UIWindowDisplayNeedsRedraw;
   displayBits  = UIWindowDefaultRenderViews( window, context, frameInfo, displayBits);
   return( displayBits);
}
```

Wire it up:

```objc
[window setFrameCallback:display];
[window setFrameRateHz:60.0];
[window setUserInfo:game];
```

`UIWindowDefaultRenderViews` performs layout, renders all views/layers, and
runs animations. Call it AFTER your game state update so views reflect the
current frame. Return its result.

`struct CGFrameInfo` fields:
- `now` — current time (`mulle_absolutetime_t`, seconds as double)
- `frameRate` — target frame rate
- `refreshRate` — display refresh rate

`UIWindowDisplayBits` flags:
- `UIWindowDisplayNeedsRedraw` — force all views to redraw
- `UIWindowDisplayNeedsLayout` — recalculate view layout

### Simple draw-callback variant (no view hierarchy)

```objc
static struct GameState   state;

static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   CGPoint   mouse;
   int       buttons;

   // 1. Input
   mouse   = [context mouseLocation];
   buttons = [context buttonStates];

   // 2. Update
   updateGameState( &state, mouse, buttons);

   // 3. Render
   renderGameState( &state, context);

   return( state.running);
}
```

## Animation with CAAnimation (recommended)

For property-driven animation on `CGGraphicsLayer`, use `CAAnimation` rather
than manual frame counting. CA handles interpolation, timing, and
automatically lifts the window from async to fps mode for the animation
duration.

```objc
CABasicAnimation   *anim;

anim = [CABasicAnimation animationWithKeyPath:@"position"];
[anim setFromValue:[NSValue valueWithCGPoint:CGPointMake( 0, 0)]];
[anim setToValue:[NSValue valueWithCGPoint:CGPointMake( 400, 300)]];
[anim setDuration:1.0];
[layer addAnimation:anim forKey:@"move"];
```

See `mulle-sde howto cat mulle-ca/coder` for the full animation API.

## Frame counter and delta time (manual path)

If you need manual timing inside the draw callback, `CGContext` provides:

```objc
static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   NSUInteger   frame;
   double       dt;

   frame = [context frameCounter];
   dt    = [context deltaTime];       // seconds since last frame

   // use dt for time-based movement: position += velocity * dt
   return( YES);
}
```

Prefer `CAAnimation` for smooth property animation. Use `deltaTime` only for
game-logic updates that need per-frame time (physics, cooldowns, spawn timers).

## Sound

See `mulle-sde howto cat mulle-audio/coder` for PCM generation, voice registration,
and playback patterns. MulleAudio is included in the game-developer template.

## Window with explicit framerate

```objc
UIWindow   *window;

window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 800, 600)
                   titleUTF8String:"Game"
                         styleMask:UIWindowStyleMaskDefault];
[window setFrameRateHz:60.0];           // fixed 60 fps
// or: [window setFrameRateSynced];     // match monitor
```

## Headless testing with UIEventPlayer

Run game logic without a display by using `UIWindowStyleNoDrawing` and
scripted input via `UIEventPlayer`. This enables CI testing and automated
verification of game state.

```objc
#import "import-private.h"
#import "GameView.h"

int   main( int argc, char *argv[])
{
   UIApplication   *app;
   UIWindow        *window;
   GameView        *view;
   UIEventPlayer   *player;

   app  = [UIApplication sharedInstance];
   view = [GameView viewWithFrame:CGRectMake( 0, 0, 800, 600)];

   // UIWindowStyleNoDrawing: no GPU, no display required
   window = [UIWindow windowWithView:view
                     titleUTF8String:"Headless Test"
                           styleMask:UIWindowStyleNoDrawing];
   [app addWindow:window];

   // Script input events (timestamps in seconds)
   player = [UIEventPlayer instance];
   [player loadScriptFromUTF8String:
      "0.05 mouseDown button=Left x=400 y=300\n"
      "0.10 mouseUp   button=Left x=400 y=300\n"
      "0.50 terminate\n"];

   [app setEventPlayer:player];
   [player startPlayback];

   // Run until script finishes or app terminates
   while( [app runLoopIteration] && [app numberOfWindows] > 0)
      ;

   // Assert game state here
   assert( [view score] == expectedScore);
   return( 0);
}
```

Use `--headless` as a command-line flag or `MULLE_UI_TEST_HEADLESS=YES` as
an environment variable to switch between visual and headless mode at runtime.
See `MulleMemoryGame/demo/click_test.m` for a complete working example.
