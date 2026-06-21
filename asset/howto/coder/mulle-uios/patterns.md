<!-- keywords: mulle-uios patterns, UIWindow, UIView, CALayer, CATextLayer, CAOpenGLLayer, CGContext -->
# Patterns

## Window and view composition

- Start from `demo/src/main-demo1.m` for the single-window shape.
- Start from `demo/src/main-glfw-two-windows.m` when ownership, invalidation, or teardown spans more than one `UIWindow`.
- Keep structure on the `UIWindow`/`UIView` side, then push custom rendering down into backing layers or drawing code. Do not use a raw draw-loop demo as the template for a view-tree change.
- Treat `src/UIWindow.h` and `src/UIView.h` as the contract for exported composition points; use demos to confirm the local wiring order.

## Layer-backed rendering

- Mirror `demo/src/main-glfw-cglayer.m` when the real work is a layer tree, not a view tree.
- Use `CATextLayer` as the text-rendering surface and `CAOpenGLLayer` as the GL-rendering surface; both belong in a `CALayer` hierarchy.
- `test/20-paint/catextlayer-render.m` is the best local pattern for deterministic text paint coverage.

```objc
CALayer       *rootLayer;
CATextLayer   *textLayer;
CAOpenGLLayer *glLayer;

[rootLayer addSublayer:textLayer];
[rootLayer addSublayer:glLayer];
```

- Comparison: UIKit/CoreAnimation names help orientation, but the local contract is the repo's layer tree and paint tests, not Apple's undocumented defaults.

## CoreGraphics surfaces and offscreen work

- Use `demo/src/main-glfw-draw-simple.m` for direct draw-to-surface examples.
- Use `demo/src/main-glfw-draw-offscreen.m` when the target is explicitly offscreen or later composited.
- Use `test/10-first/nullwindow-cgcontext.m` and `test/10-first/uinullwindow-cgcontext.m` as the headless-context templates.
- Use `test/10-first/noleak-cgcontext.m`, `test/10-first/noleak-cgimage.m`, and `test/10-first/noleak-cglayer.m` as the ownership template: create, render, and tear down explicitly.

## Backend-oriented demos

- The NanoVG demos (`demo/src/main-line-nanovg.m`, `demo/src/main-nanovg-demo.m`) are useful when the change is really about a GL-style renderer.
- Do not let those demos replace the exported-window or exported-layer entry points in library code. They are backend examples, not the umbrella API contract.

## Window rendering style

Choose the framerate mode at window creation time based on whether the app drives display changes on its own:

| Rendering style | `setFrameRate:` call | Display trigger |
| --- | --- | --- |
| Event-driven (dialog, form, most UI) | none — `UIWindowFrameRateAsync` is the default | `setNeedsDisplay` from a user action or handler |
| Continuous (self-animating, game loop, simulation) | `[window setFrameRate:hz]`, `setFrameRateSynced`, or `setFrameRateHz:` | automatic once rate is set |

**CA animations do not require a framerate call.** `CAAnimation` temporarily lifts the window from async to fps mode for the duration of the animation, then drops back automatically. The framerate gate only matters when display changes are driven *outside* a `CAAnimation` (manual state updates, explicit draw loops, etc.).

The diagnostic question: *"Is my app driving display changes outside a CAAnimation? If yes — is `[window frameRate]` still `INFINITY`?"*
