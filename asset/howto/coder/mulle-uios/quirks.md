<!-- keywords: mulle-uios quirks, UIWindow, CALayer, CATextLayer, CAOpenGLLayer, CGContext, CGLayer, CGImage -->
# Quirks

## Mixed-level API surface

- `mulle-uios` is an umbrella topic here. Do not assume a GLFW or NanoVG demo exercises the same lifecycle as `UIWindow`/`UIView`.
- Prefer the exported root headers in `src/MulleUIOS.h` over support or dependency headers when deciding where a change belongs.

## Headless and null-window drawing are intentional

- `test/10-first/nullwindow-cgcontext.m` and `test/10-first/uinullwindow-cgcontext.m` show that headless/offscreen drawing is part of the local surface.
- Do not hardwire a visible window or a single global display context into CoreGraphics-facing changes.

## Ownership is part of the contract

- The `test/10-first/noleak-cgcontext.m`, `test/10-first/noleak-cgimage.m`, and `test/10-first/noleak-cglayer.m` cases are not incidental smoke tests; they document local ownership expectations.
- Do not treat `CGContext`, `CGImage`, or `CGLayer` cleanup as optional just because a demo exits quickly.

## Layer subclasses are the specialization points

- `CAOpenGLLayer` is a layer-side integration point. Do not treat it as a window replacement or bypass the layer hierarchy when adding GL content.
- `CATextLayer` has explicit paint coverage in `test/20-paint/catextlayer-render.m`; text changes should not be justified only with a visual demo.
- If the change is really about rendered content, start from `CALayer`/subclass behavior first and only then look at the window wrapper.

## Apple naming is only a comparison aid

- The names echo UIKit/CoreAnimation, but local behavior is defined by this repository's headers, demos, and tests.
- Do not assume a missing Apple feature, property default, or lifecycle rule exists here unless you can find it in `src/` or a repo example.

## `UIWindowFrameRateAsync` is `INFINITY` — the framerate gate

The default window display mode is `UIWindowFrameRateAsync = INFINITY`. In this mode the window only presents a frame when a display event fires. For event-driven apps (dialogs, forms, most UI) this is correct and efficient.

For anything that drives display changes *outside* a `CAAnimation` — manual state updates, explicit draw loops — no frame will ever be presented unless the framerate is explicitly set:

```objc
[window setFrameRate:60.0];          // explicit Hz
[window setFrameRateSynced];         // tied to monitor refresh
[window setFrameRateHz:60.0];        // convenience form
```

`CAAnimation` is exempt: it automatically lifts the window from async to fps mode for its duration, then drops back. You only need a framerate call when animating outside the CA system.
