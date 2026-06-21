<!-- keywords: mulle-uios debugger quirks, UIWindow, UINullWindow, CAOpenGLLayer, CATextLayer, CGContext, headless -->
# Quirks

## Backend selection is process-wide state

- `src/UIWindow+MulleUIOS.m` and `src/UIWindow+CG.m` store backend classes in category statics. A previous test or demo can change the next window's backend.
- `src/UINullWindow+MulleUIOS.m` and `src/UINullWindow+CG.m` do the same for the null-window path, with defaults of `UINullOSWindow` and `CGContext`.

## Headless paths are part of the contract

- `test/10-first/nullwindow-cgcontext.m` expects a hidden, offscreen window to return a graphics context.
- `test/20-retained/uinullwindow-cgcontext.m` expects `UINullWindow` to auto-create its OS window and `CGContext` on the no-draw path.
- Do not assume "no visible window" means "no valid rendering surface" in this repo.

## Context activation is not optional bookkeeping

- `demo/src/main-glfw-cglayer.m` explicitly says the OS context is locked to the current thread during activation.
- `demo/src/main-glfw-two-windows.m` finalizes its stored `CGContext` only while the OS graphics context is active.
- If a bug appears only on teardown, inspect activation/deactivation order before blaming the drawable or framebuffer.

## `CAOpenGLLayer` has local GL-specific invariants

- The header defines a strict sequence: `beginOpenGLWithContext:` sets viewport/scissor state, `drawOpenGLInContext:` does the actual GL work, and `endOpenGLWithContext:` flushes.
- `viewPortDidChange:` is reached from `beginOpenGLWithContext:`. Debug viewport bugs there, not in unrelated layer setup.
- `drawsBackgroundWithAlpha:` is documented as always returning `YES` for proper texture mapping. Do not debug alpha behavior assuming this layer can opt out.

## Text failures split cleanly into layout and paint

- `test/40-layout/catextlayer.m` proves that `CATextLayer` sizing can be debugged without any OS window or GL context.
- `test/20-paint/catextlayer-render.m` uses a dummy `UIOSGraphicsContext` plus `UIGraphicsNoDrawing` to exercise render code deterministically.
- If layout passes but paint fails, focus on frame setup, `layoutWithLayoutInfo:`, and `renderInContext:` rather than font lookup.

## Leak tests encode lifecycle expectations

- The no-leak tests intentionally use `[UIApplication instance]` and assert `! UIApp`; that is part of the repro shape.
- `noleak-cgimage` and `noleak-cglayer` create GPU-backed objects from an activated window context and then terminate the app. Regressions there usually mean a teardown-order change, not just a missing retain/release.

## One demo has an environment precondition

- `demo/src/main-glfw-cglayer.m` fails unless `MULLE_OBJC_EPHEMERAL_SINGLETON=YES` is set.
- If that demo is your reproducer, check the environment first so you do not chase a fake lifecycle failure.

## Model state is not rendering proof

Stdout output showing state changes (positions, counters, flags) only proves that *logic* is running. It says nothing about whether pixels are being presented. Do not declare "rendering confirmed" based on model-layer dumps.

Acceptable rendering proof:
- A frame counter that increments inside `displayFrameIfNeeded:` (or equivalent present call)
- `[window frameRate]` is not `INFINITY`
- A screenshot comparison via `MulleUI` debugging flags

The simplest sanity check: if `[window frameRate]` returns `INFINITY`, nothing will ever be presented regardless of how much state changes.

## `UIWindowFrameRateAsync` is silent — not an error

When `frameRate` is `INFINITY` and the window skips presentation, there is no error, no log, no assertion. The draw callback runs, game logic executes, and everything looks correct — except no frame ever reaches the screen. This makes the framerate gate invisible unless you know to look for it.
