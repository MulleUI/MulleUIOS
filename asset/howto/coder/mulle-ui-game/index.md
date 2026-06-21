<!-- keywords: game, draw-callback, input, mouse, keyboard, polling, CGContext, CGGraphicsLayer, UIView, collision, quadtree, framerate -->
# MulleUI game development

Use this when building a game on top of MulleUI. Games use a fixed-rate
rendering loop with a `CGGraphicsLayer` for drawing and `UIView` for input
handling and collision detection.

## Prerequisites

- Read `mulle-sde howto cat mulle-ui-app-construction` first to understand the
  framerate decision tree. Games are **continuous-rendering** apps (not
  "timer-driven" — there is no NSTimer involved).
- The project template `mulle-ui/game-developer` provides the skeleton. Use
  `mulle-sde init -m mulle-ui/game-developer` to start a new game project.

## Understand first

```bash
mulle-sde api cat MulleCG
mulle-sde api cat MulleUIView
mulle-sde api cat MulleUIWindow
mulle-sde api apropos quadtree
mulle-sde api apropos hitTest
mulle-sde code search UIApplicationRunDrawCallbackHz
mulle-sde code search mouseLocation
mulle-sde code search buttonStates
```

## Architecture guidance

Prefer `CGGraphicsLayer` + `UIView` over a raw draw callback:

| Concern | Use | Why |
| --- | --- | --- |
| Drawing | `CGGraphicsLayer` subclass with `drawInContext:` | Composable, testable, can be headless-verified |
| Input | `UIView` with `mouseDown:`/`mouseUp:`/`mouseDragged:`/`keyDown:` | Responder chain, hit testing, tracking areas |
| Collision | `UITrackingArea` + `getTrackingAreasIntersectingRect:areas:maxAreas:` | Quadtree-backed, efficient rect-vs-rect queries |
| Animation | `CAAnimation` on `CGGraphicsLayer` properties | Interpolation, timing, auto-lifts framerate |
| Sound | MulleAudio PCM voices | Self-contained, no file dependencies |
| Simple prototype | `UIApplicationRunDrawCallbackHz` draw callback | Fast to start, but mixes all concerns into one function |

Even for a simple game, consider one `UIView` backed by one `CGGraphicsLayer`.
This gives you proper input handling and the option to use the view hierarchy's
quadtree-based hit testing for collision detection between game objects.

## The draw callback (simple path)

The template provides:

```objc
CGGraphicsLayer   *layer;
UIWindow          *window;
NSUInteger         styleMask;

layer = [CGGraphicsLayer layerWithFrame:CGRectMake( 0, 0, 800, 600)];
[layer setDrawCallback:draw];

[UIApplication sharedInstance];

styleMask = UIWindowStyleMaskNonRetained;
styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStylePlanes, NO);
styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleInputPolling, YES);

window = [UIWindow windowWithLayer:layer
                   titleUTF8String:"Game"
                         styleMask:styleMask];
[window setFrameRateSynced];

return( UIApplicationRunWindow( window));
```

- `UIWindowStyleMaskNonRetained` runs single-threaded. Objects created in
  `main` are directly usable in the draw callback without MulleObject concerns.
- `UIWindowStyleInputPolling` enables `[context mouseLocation]` /
  `[context buttonStates]` inside the callback.
- `setFrameRateSynced` locks to monitor refresh. Use `setFrameRateHz:` for a
  fixed rate.
- Return `YES` from the draw callback to continue, `NO` to quit.

## Input polling (inside draw callback)

When using the simple draw-callback path without a view hierarchy:

```objc
static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   CGPoint   mouse;
   int       buttons;

   mouse   = [context mouseLocation];
   buttons = [context buttonStates];

   if( buttons & 1)  // left button
   {
      // handle click at mouse.x, mouse.y
   }

   return( YES);
}
```

## Structured path (recommended for non-trivial games)

```objc
@interface GameLayer : CGGraphicsLayer
@end

@implementation GameLayer

- (void) drawInContext:(CGContext *) context
{
   [super drawInContext:context];
   // draw game objects using [self canvas] for bounds
}

@end
```

```objc
@interface GameView : UIView
@end

@implementation GameView

- (void) mouseDown:(UIEvent *) event
{
   CGPoint   point;

   point = [[self window] mouseLocationOutsideOfEventStream];
   // handle click
   [self setNeedsDisplay];
}

@end
```

Wire them together:

```objc
UIWindow   *window;
GameView   *view;

window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 800, 600)
                   titleUTF8String:"Game"
                         styleMask:UIWindowStyleMaskDefault];
[window setFrameRateSynced];
view = [GameView viewWithFrame:[window bounds]];
[[window contentView] addSubview:view];
```

## Collision detection via UITrackingArea

The `UIWindow` uses a quadtree internally for tracking areas. You can leverage
this for game-object collision detection:

- Attach a `UITrackingArea` to each collidable game object
- Query intersections with `getTrackingAreasIntersectingRect:areas:maxAreas:`
- The quadtree makes this efficient for up to ~500-1000 active objects

```objc
UITrackingArea   *areas[16];
NSUInteger        count;
CGRect            playerRect;

playerRect = CGRectMake( playerX, playerY, playerW, playerH);
count      = [window getTrackingAreasIntersectingRect:playerRect
                                               areas:areas
                                            maxAreas:16];
for( NSUInteger i = 0; i < count; i++)
{
   // areas[i] intersects the player — handle collision
}
```

This is efficient for moderate numbers of objects (hundreds). For thousands
of rapidly moving objects (bullet-hell, particle simulations), a spatial hash
or sweep-and-prune broad phase would be more appropriate — but for most games
the tracking area quadtree is a good fit.

## Keyboard input in games

There are three approaches to keyboard input. Choose based on your game's needs:

| Approach | When to use | Limitations |
| --- | --- | --- |
| Keyboard polling (`pressedKeys:count:`) | Draw-callback games needing held-key state | Only available inside frame callback, no event granularity |
| Event-based (`keyDown:`/`keyUp:`) | Held-key movement with event granularity | Requires first responder, manual key state booleans |
| Modifier polling (`[context keyModifiers]`) | Shift-to-sprint, Ctrl-to-crouch | Only modifier keys (Shift, Ctrl, Alt, Super), not WASD/arrows |

### Keyboard polling (inside draw/frame callback)

The OSWindow maintains a `UIKeyboardState` that tracks all currently pressed
keys from events, resyncing from the OS on focus regain. Query it with
`pressedKeys:count:`:

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
      case UIEventKeyW:
      case UIEventKeyUp:    playerY -= speed; break;
      case UIEventKeyS:
      case UIEventKeyDown:  playerY += speed; break;
      case UIEventKeyA:
      case UIEventKeyLeft:  playerX -= speed; break;
      case UIEventKeyD:
      case UIEventKeyRight: playerX += speed; break;
      }
   }
   return( displayBits);
}
```

This is the simplest approach for draw-callback games — no first responder,
no manual booleans. Multiple simultaneous keys are handled automatically.

### Event-based key tracking (structured path)

For the `UIView` responder chain path, or when you need event granularity
(distinguishing press from repeat, detecting specific key sequences):

#### Step 1: Make your view accept keyboard focus

```objc
@interface GameView : UIView
{
   BOOL   _keyUp;
   BOOL   _keyDown;
   BOOL   _keyLeft;
   BOOL   _keyRight;
}
@end

@implementation GameView

- (BOOL) canBecomeFirstResponder
{
   return( YES);
}
```

#### Step 2: Track key state in keyDown:/keyUp:

```objc
- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event
{
   switch( [event key])
   {
   case UIEventKeyW:
   case UIEventKeyUp:    _keyUp    = YES; break;
   case UIEventKeyS:
   case UIEventKeyDown:  _keyDown  = YES; break;
   case UIEventKeyA:
   case UIEventKeyLeft:  _keyLeft  = YES; break;
   case UIEventKeyD:
   case UIEventKeyRight: _keyRight = YES; break;
   }
   return( nil);  // consume event
}

- (UIInputEvent *) keyUp:(UIKeyboardEvent *) event
{
   switch( [event key])
   {
   case UIEventKeyW:
   case UIEventKeyUp:    _keyUp    = NO; break;
   case UIEventKeyS:
   case UIEventKeyDown:  _keyDown  = NO; break;
   case UIEventKeyA:
   case UIEventKeyLeft:  _keyLeft  = NO; break;
   case UIEventKeyD:
   case UIEventKeyRight: _keyRight = NO; break;
   }
   return( nil);
}

@end
```

#### Step 3: Activate first responder after window setup

```objc
UIView   *contentView;

contentView = [window contentView];
[contentView becomeFirstResponder];
```

Then read the key state booleans in your frame callback (via the game object
or directly from the view).

#### Key constants

Key codes are defined in `UIEvent.h` as `UIEventKey` enum values:
`UIEventKeyA`–`UIEventKeyZ`, `UIEventKeyUp`, `UIEventKeyDown`,
`UIEventKeyLeft`, `UIEventKeyRight`, `UIEventKeySpace`, `UIEventKeyEscape`,
etc.

## Event handling — deep dives

For the full story on input beyond what's shown here, see:

- `mulle-sde howto cat mulle-ui-event-handling/coder` — responder chain, first-responder contract, UIControl, return-nil-to-consume
- `mulle-sde howto cat mulle-ui-tracking/coder` — hover detection, mouseEntered/Exited, tracking area quadtree (also used for collision above)
- `mulle-sde howto cat mulle-ui-hit-testing/coder` — which view receives a click, z-order, excluded views
- `mulle-sde howto cat mulle-ui-event-replay/coder` — scripted replay for automated game testing with UINullWindow

## Verify

```bash
mulle-sde craft
mulle-sde run
```

## Property forwarding: View exposes Layer properties

When your `UIView` subclass needs to expose properties that are stored in its
layer, use `@property(forward, assign)` in the view header and `@dynamic` in
the implementation. The view forwards getter/setter calls to the layer
automatically — no boilerplate accessor code needed.

```objc
// EnemyLayer.h — the layer owns the storage
@interface EnemyLayer : CGGraphicsLayer
{
   int    _enemyType;
   BOOL   _alive;
}

@property( assign) int    enemyType;
@property( assign) BOOL   alive;

@end
```

```objc
// EnemyView.h — the view forwards to the layer
@interface EnemyView : UIView

@property( forward, assign) int    enemyType;
@property( forward, assign) BOOL   alive;

@end
```

```objc
// EnemyView.m
@implementation EnemyView

+ (Class) layerClass   { return( [EnemyLayer class]); }

@dynamic enemyType;
@dynamic alive;

@end
```

Now game code uses `[enemyView setEnemyType:2]` and the value lands in the
layer's `_enemyType` ivar. The layer reads it in `drawInContext:`.

Rules:
- The layer property name and the view property name must match exactly.
- Storage (the ivar) lives in the layer, not the view.
- Works with all scalar types: `BOOL`, `int`, `CGFloat`, `CGColor`, etc.
- `setNeedsDisplay` is NOT automatic. If changing the property should trigger
  a redraw, override the setter on the layer side, or call
  `[view setNeedsDisplay]` from game code after setting the property.

## Tip: demo and test code in dependencies

Most MulleUI sub-projects ship with `demo/` and `test/` directories containing
working examples for their APIs. Use `mulle-sde stash-dir` to locate the
fetched dependency sources, then look for `demo/src/main-*.m` files. These are
often the fastest way to find a working usage pattern.

## Tip: asset and resource management

The default game template uses MulleObjC, which has no `NSBundle` or resource
path system. Embed assets as C arrays (see the sprite texturing pattern) or
load files via hardcoded paths.

For proper asset management via `NSBundle` (locating resources relative to the
executable at runtime), migrate your project from MulleObjC to MulleFoundation.
