<!-- keywords: mulle-uios debugger patterns, UIWindow, UINullWindow, CAOpenGLLayer, CATextLayer, CGContext -->
# Patterns

## Reproduce backend and window wiring first

- Use `test/50-render/oneframe.m` when you need one frame of `UIApplication`/`UIWindow` behavior without a full event loop.
- Use `test/10-first/nullwindow-cgcontext.m` to prove that a hidden, offscreen `UIWindow` can still create and activate a graphics context.
- Use `test/10-first/uinullwindow-cgcontext.m` and `test/20-retained/uinullwindow-cgcontext.m` to isolate `UINullWindow`/`UINullOSWindow` behavior from real OS-window code.

```objc
styleMask  = UIWindowStyleMaskDefault;
styleMask &= ~UIWindowStyleRetained;
styleMask |= UIWindowStyleHidden;
styleMask |= UIWindowStyleOffscreen;

window  = [UIWindow windowWithFrame:CGRectMake( 0, 0, 64, 64)
                   titleUTF8String:NULL
                         styleMask:styleMask];
[app addWindow:window];
context = [window activateWindowGraphicsContext];
[window deactivateGraphicsContext:context];
```

- If this passes and the visible demo fails, the bug is usually in backend/window presentation code, not in basic context creation.

## Follow the repo's manual context-activation order

- `demo/src/main-glfw-cglayer.m` and `demo/src/main-glfw-two-windows.m` both activate the OS graphics context before building or finalizing a `CGContext`.
- Keep that order when debugging: activate OS context, create or use `CGContext`, do the rendering work, then deactivate.
- The multi-window demo is the best reproducer when only teardown or the second window breaks.

```objc
[window os_activateGraphicsContext];
context = [[[CGContext alloc] initWithOSGraphicsContext:window
                                                shareID:[window shareID]
                                                options:UIGraphicsDefaultOptions] autorelease];
/* draw or finalize while active */
[window os_deactivateGraphicsContext];
```

## Debug `CAOpenGLLayer` as a bracketed lifecycle

- `src/CAOpenGLLayer.h` exposes the local shape directly: `beginOpenGLWithContext:`, then `drawOpenGLInContext:`, then `endOpenGLWithContext:`.
- `viewPortDidChange:` is not an independent hook; the header says it is called from `beginOpenGLWithContext:` after viewport, scissor, and projections are set.
- Use `demo/src/main-glfw-cglayer.m` when you need the lowest-level GL reproduction. It creates an invisible window only to obtain the OS/OpenGL context, then binds a `CGFramebuffer` and dumps the result.

```objc
[layer beginOpenGLWithContext:context];
[layer drawOpenGLInContext:context];
[layer endOpenGLWithContext:context];
```

## Split CATextLayer layout from CATextLayer rendering

- Use `test/40-layout/catextlayer.m` for layout-only bugs. It uses `CGLayoutContext` and never needs a window or GL context.
- Use `test/20-paint/catextlayer-render.m` for render-path bugs. It creates a dummy `UIOSGraphicsContext`, wraps it in a `CGContext`, begins a frame, lays out the layer, and renders it.

```objc
context = [CGLayoutContext instance];
layer   = [CATextLayer layerWithFrame:CGRectMake( 0, 0, 200, 100)];
[layer setTextUTF8String:"VfL Bochum 1848"];
size = [layer sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                   context:context];
```

```objc
CGContextBeginFrame( context, CGSizeMake( 400, 300), 1.0);
[layer layoutWithLayoutInfo:&layoutInfo];
[layer renderInContext:context];
CGContextEndFrame( context);
```

## Use leak tests as ownership reproducers

- `test/10-first/noleak-cgcontext.m`, `test/10-first/noleak-cgimage.m`, and `test/10-first/noleak-cglayer.m` are the shortest local reproducers for context, image, and framebuffer lifetime.
- Keep the test shape when debugging ownership issues: `UIApplication instance`, hidden non-retained window, activate context, create the suspect object, terminate app.
- Do not switch those reproducers to `sharedInstance` or a visible window unless the bug only appears there.

## Diagnose "nothing renders / animation frozen" in two independent steps

`styleMask` and `frameRate` are independent settings. Fixing one does not imply the other is correct. Work through both before concluding:

**Step 1 — check `frameRate`:**

```objc
NSLog(@"frameRate: %f", [window frameRate]);
```

If it returns `INFINITY` (`UIWindowFrameRateAsync`), `displayFrameIfNeeded:` will always skip presentation because `remainingFrameTime` is never zero. Set a rate:

```objc
[window setFrameRateSynced];          // tied to monitor refresh
[window setFrameRateHz:60.0];         // explicit Hz
[window setFrameRate:interval];       // match your update interval
```

This step is skippable if display changes are entirely inside `CAAnimation` blocks — CA lifts the window to fps mode automatically for animation duration.

**Step 2 — check `styleMask`:**

Retained-mode windows (`UIWindowStyleMaskDefault`) require explicit thread coordination to push renders. For simpler debugging, use `UIWindowStyleMaskNonRetained` (volatile/single-threaded model). Do not cargo-cult it into production code.

**Run loop order for reference:** DrawAndSwap → FireTimers → PollEvents(sleep). The sleep duration is `min(nextTimerFire, nextWindowDisplay)`. With `frameRate = INFINITY`, `nextWindowDisplay` is never, so draws happen but nothing is ever presented.
