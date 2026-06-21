<!-- keywords: mulle-uios, UIWindow, UIView, CALayer, CATextLayer, CAOpenGLLayer, CGContext, CGLayer, CGImage -->
# mulle-uios

Use this when you are changing exported MulleUIOS code rather than a single backend demo. The local coding surface is split across three recurring families: `UIWindow`/`UIView` composition, `CALayer`-based rendering (`CATextLayer`, `CAOpenGLLayer`), and CoreGraphics surfaces (`CGContext`, `CGLayer`, `CGImage`) that show up in demos and leak tests.

## Understand first

```bash
mulle-sde api apropos MulleUIOS
mulle-sde api cat MulleUIOS
mulle-sde api cat UIWindow
mulle-sde api cat UIView
mulle-sde api cat CALayer
mulle-sde api cat CATextLayer
mulle-sde api cat CAOpenGLLayer
mulle-sde code search CGContext
```

## Local references

- `README.md`
- `asset/dox/TOC.md`
- `src/MulleUIOS.h`
- `src/MulleObjCDeps+MulleUIOS.h`
- `src/UIWindow.h`
- `src/UIView.h`
- `src/CALayer.h`
- `src/CATextLayer.h`
- `src/CAOpenGLLayer.h`
- `demo/README.md`
- `demo/src/main-demo1.m`
- `demo/src/main-glfw-two-windows.m`
- `demo/src/main-glfw-cglayer.m`
- `demo/src/main-glfw-draw-simple.m`
- `demo/src/main-glfw-draw-offscreen.m`
- `demo/src/main-line-nanovg.m`
- `demo/src/main-nanovg-demo.m`
- `test/10-first/nullwindow-cgcontext.m`
- `test/10-first/uinullwindow-cgcontext.m`
- `test/10-first/noleak-cgcontext.m`
- `test/10-first/noleak-cgimage.m`
- `test/10-first/noleak-cglayer.m`
- `test/20-paint/catextlayer-render.m`

## Main families

| Scenario | Start here | Evidence |
| --- | --- | --- |
| Window/view tree, app-style structure, multi-window behavior | `UIWindow`, `UIView` | `src/UIWindow.h`, `src/UIView.h`, `demo/src/main-opengl.m`, `demo/src/main-glfw-two-windows.m` |
| Layer-backed rendering, text, OpenGL content | `CALayer`, `CATextLayer`, `CAOpenGLLayer` | `src/CALayer.h`, `src/CATextLayer.h`, `src/CAOpenGLLayer.h`, `demo/src/main-glfw-cglayer.m`, `test/20-paint/catextlayer-render.m` |
| Offscreen or leak-sensitive drawing surfaces | `CGContext`, `CGLayer`, `CGImage` paths | `demo/src/main-glfw-draw-simple.m`, `demo/src/main-glfw-draw-offscreen.m`, `test/10-first/nullwindow-cgcontext.m`, `test/10-first/noleak-cgcontext.m`, `test/10-first/noleak-cgimage.m`, `test/10-first/noleak-cglayer.m` |

## Local workflow

- Pick the highest exported surface that matches the change. In this repo, raw `CGContext` examples are not interchangeable with the `UIWindow`/`UIView` path, and `CAOpenGLLayer` belongs on the layer side.
- Use demos for happy-path wiring and the `test/10-first` / `test/20-paint` cases for ownership, headless rendering, and paint invariants.
- For umbrella-topic work, cover both sides of the stack: the owning window/view side and the rendered target side (`CALayer`, text layer, GL layer, or a CoreGraphics surface).
- Prefer `src/MulleUIOS.h` and the exported root headers when scoping work. `src/MulleObjCDeps+MulleUIOS.h` is dependency glue, not the main coding surface.
- When you are writing a new demo, the usual shape in `demo/src/main-opengl.m`, `demo/src/main-arc-nanovg.m`, and `demo/src/main-glfw-two-windows.m` is: create `UIApplication`, build one or more windows/views with representative frames and content, add subviews to `[window contentView]` when needed, register the window with the app, then `runApp`.
- Keep trace or debug mode optional. `demo/src/main-opengl.m` gates its extra trace path behind `argc == 2` instead of making verbose diagnostics the default startup path.

## Verify/report

- If a change touches `CGContext`, `CGLayer`, or `CGImage` lifetime, compare it against the existing no-leak tests before reporting it as safe.
- If a change affects layer output, reduce it to the closest demo or `test/20-paint/catextlayer-render.m` style case when describing behavior.
