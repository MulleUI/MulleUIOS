<!-- keywords: debugger, mulle-uios, UIWindow, UINullWindow, CAOpenGLLayer, CATextLayer, CGContext, headless -->
# mulle-uios

Use this when a failure crosses the local OS-binding layer instead of living entirely in upstream MulleUI or MulleGraphics. The recurring debugger surfaces here are backend selection on `UIWindow`/`UINullWindow`, hidden or offscreen context creation, `CAOpenGLLayer`'s explicit GL bracket, and `CATextLayer` paths that are intentionally testable without a real window.

## Understand first

```bash
mulle-sde api apropos MulleUIOS
mulle-sde api cat MulleUIOS
mulle-sde api cat CAOpenGLLayer
mulle-sde api apropos UIWindow
mulle-sde api apropos UINullWindow
mulle-sde api apropos CATextLayer
mulle-sde code search activateWindowGraphicsContext
mulle-sde code search renderGraphicsContext
mulle-sde code search processOneFrame
```

## Local references

- `asset/dox/TOC.md`
- `src/MulleUIOS.h`
- `src/MulleObjCDeps+MulleUIOS.h`
- `src/UIWindow+MulleUIOS.m`
- `src/UIWindow+CG.m`
- `src/UINullWindow+MulleUIOS.m`
- `src/UINullWindow+CG.m`
- `src/CAOpenGLLayer.h`
- `demo/src/main-glfw-cglayer.m`
- `demo/src/main-glfw-two-windows.m`
- `demo/src/main-glfw-draw-simple.m`
- `demo/src/main-glfw-draw-offscreen.m`
- `test/10-first/nullwindow-cgcontext.m`
- `test/10-first/uinullwindow-cgcontext.m`
- `test/10-first/noleak-cgcontext.m`
- `test/10-first/noleak-cgimage.m`
- `test/10-first/noleak-cglayer.m`
- `test/20-paint/catextlayer-render.m`
- `test/20-retained/uinullwindow-cgcontext.m`
- `test/40-layout/catextlayer.m`
- `test/50-render/oneframe.m`

## Main fault lines

| Scenario | Start here | Evidence |
| --- | --- | --- |
| Window bootstrap or wrong backend class | `+setOSWindowClass:` / `+setOSGraphicsContextClass:` and their defaults | `src/MulleUIOS.h`, `src/UIWindow+MulleUIOS.m`, `src/UIWindow+CG.m` |
| Headless or offscreen context creation | Hidden/offscreen `UIWindow` and `UINullWindow` paths | `test/10-first/nullwindow-cgcontext.m`, `test/10-first/uinullwindow-cgcontext.m`, `test/20-retained/uinullwindow-cgcontext.m` |
| GL/layer draw bug | `CAOpenGLLayer` lifecycle and manual OS-context activation | `src/CAOpenGLLayer.h`, `demo/src/main-glfw-cglayer.m`, `demo/src/main-glfw-two-windows.m` |
| Text/layout bug | Layout-only versus render-in-context split | `test/40-layout/catextlayer.m`, `test/20-paint/catextlayer-render.m` |
| Minimal render loop regression | One hidden frame without full app run loop | `test/50-render/oneframe.m` |

## Local workflow

- Reduce to the smallest local reproducer first: `test/50-render/oneframe.m` for bootstrap, `test/10-first/nullwindow-cgcontext.m` for hidden-window context creation, `test/20-retained/uinullwindow-cgcontext.m` for retained null-window auto-wiring, `test/40-layout/catextlayer.m` for text layout only, and `test/20-paint/catextlayer-render.m` for text rendering.
- Split backend-selection bugs from draw bugs. In this repo the backend classes are global mutable state stored in category statics, so class-selection mistakes can look like rendering failures.
- Treat visible-window demos as a later step. The test suite shows that hidden, offscreen, and no-draw paths are real supported surfaces here.
- For GL regressions, compare the pure demo path in `demo/src/main-glfw-cglayer.m` with the multi-window/context-lifetime path in `demo/src/main-glfw-two-windows.m`.

## Verify/report

- Say which local reproducer fails and whether it is visible-window, hidden/offscreen, or no-draw headless.
- For ownership regressions, name the exact leak-style test that changed: `noleak-cgcontext`, `noleak-cgimage`, or `noleak-cglayer`.
- For text bugs, report whether the break is in `sizeThatFits:context:` / layout or in `renderInContext:`.
