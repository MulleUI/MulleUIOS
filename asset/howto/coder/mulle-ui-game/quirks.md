<!-- keywords: game, quirks, framerate, UIWindowFrameRateAsync, polling, input, CGContext -->
# Quirks

## Layers must not reference their owning view

`CGGraphicsLayer` subclasses must NOT hold a pointer to their `UIView`. The
layer ↔ view relationship is one-way: views own layers, not the reverse.
This will be enforced in the future by process separation. If a layer needs
to signal a state change, use a callback or flag that the view polls.

```objc
// WRONG — layer holds view reference
@implementation HUDLayer
- (void) setScore:(NSInteger) score
{
   _score = score;
   [_ownerView setNeedsDisplay];  // NO! layer must not know about its view
}
@end
```

## Do not retain or release views that are in the view hierarchy

Views in a superview are retained by the hierarchy. Do not `retain`/`release`
them yourself — just `addSubview:` and `removeFromSuperview`. Extra retains
create ownership confusion and crash-prone over-releases.

## Factor out duplicated code into a shared helper

If two methods contain the same logic, extract it into a single helper and
call it from both. Do not copy-paste code between methods.

## Never call -release outside of -dealloc

Use `autorelease` if you must relinquish ownership outside of `dealloc`.
Calling `release` directly risks dangling pointers if the object is still
referenced elsewhere in the current scope or call stack.

## Do not reimplement inherited methods that add nothing

If a superclass already provides a method (e.g. `+layerWithFrame:`), do not
redefine it in your subclass unless the override changes behaviour. Redundant
reimplementations mask the actual class hierarchy and confuse readers.

## Sprite textures replicate border pixels when scaled

OpenGL stretches the outermost pixels of a texture when drawing it larger than
its native size. This causes visible colored edges on sprites. Add a 1-pixel
transparent border around your sprite pixel data to avoid fringing.

## UIView frame rounds to integer pixels

`setFrame:` and `frame` round coordinates to integer pixels for crisp UI
rendering. For sub-pixel game physics and animation, use `rawFrame` /
`setRawFrame:` instead — these bypass the rounding.

## Coordinate system is top-left origin, Y-down

Both UIView frames and CGContext drawing use screen coordinates: origin (0,0)
is at the top-left corner, Y increases downward. This applies everywhere —
views, layers, and drawing calls. Do not assume OpenGL conventions.

## Foundation collection classes are not available

`NSArray`, `NSDictionary`, `NSSet` and other Foundation collection classes are
not part of MulleObjC. Use mulle-container C types instead:
`mulle_pointerarray`, `mulle_array`, `mulle_map`. To get Foundation collections,
migrate your project to MulleFoundation.

## `UIWindowFrameRateAsync` is the silent game-killer

The default framerate is `INFINITY`. With this setting, the window only
presents a frame when a display event fires. For a game that updates every
frame, **nothing will ever render** unless you explicitly set a framerate.

There is no error, no log, no assertion. The draw callback runs, game logic
executes, everything looks correct — except no frame reaches the screen.

Fix: call `[window setFrameRateSynced]` or `[window setFrameRateHz:60.0]`
before entering the run loop. `UIApplicationRunDrawCallbackHz` handles this
for you via its last parameter.

## Input polling is only valid inside the draw callback

`[context mouseLocation]` and `[context buttonStates]` reflect the state at
the time of the current frame. Do not cache the context or call these outside
the draw callback — the values are undefined.

## The draw callback does not receive events

The draw callback is a render opportunity, not an event handler. If you need
event-granularity input (e.g. distinguishing a click from a drag, detecting
double-clicks), use the `UIView` responder chain path instead of polling.

## CGGraphicsLayer vs raw CGContext

Inside `drawInContext:`, use `[self canvas]` for the drawable bounds. Do not
assume the context size matches the layer frame — transforms and scaling may
differ.

## setNeedsDisplay and setNeedsLayout are unnecessary in game frame callbacks

In a game loop that sets
`displayBits |= UIWindowDisplayNeedsLayout|UIWindowDisplayNeedsRedraw` in the
frame callback, all layers are relayouted and redrawn every frame.

## No NSTimer in game loops

MulleUI games do not use `NSTimer` to drive rendering. The window's framerate
setting drives the display loop directly. The run loop order is:
DrawAndSwap → FireTimers → PollEvents(sleep). Timers fire *between* frames,
not as frame triggers.

## Non-retained mode avoids threading complications

Games should use `UIWindowStyleMaskNonRetained` (the template default). Retained
mode spawns a separate render thread, which means objects created in `main` or
the draw callback live in a different thread's autorelease pool. You'd need
`MulleObject` or explicit thread-safe patterns to share state. Non-retained
mode is single-threaded — everything runs on main, no thread boundary to cross.

## UITrackingArea collision detection is for moderate object counts

The quadtree backing `getTrackingAreasIntersectingRect:areas:maxAreas:` handles
hundreds of tracking areas efficiently. For thousands of rapidly moving objects
(bullets, particles), a spatial hash or sweep-and-prune is more appropriate.
The tracking area quadtree is optimized for spatial queries on semi-static
geometry, not mass physics simulation.

## CGColor is a struct, not a pointer

`CGColor` is `struct NVGcolor` — four floats (r, g, b, a) passed by value.
There is no `CGColorRef`. You cannot nil-check it. You cannot heap-allocate it.

```objc
// WRONG
CGColor  *color;                         // not a pointer type
if( ! color) ...                         // cannot nil-check a struct
CGColor  bg = CGColorMakeWithRGBA(...);  // cannot use in a static initializer

// RIGHT
CGColor  color;
if( color.a == 0.0f) ...                 // check transparency for "unset"
static CGColor  bg = CGColorDataWithRGBA( 0.2, 0.1, 0.3, 1.0);  // compile-time constant
```

Use `CGColorMakeWithRGBA()` at runtime, `CGColorDataWithRGBA()` for static/global
initializers. Use `mulle-sde code search CGColor` or `mulle-sde api cat MulleCG`
to discover the full API.
