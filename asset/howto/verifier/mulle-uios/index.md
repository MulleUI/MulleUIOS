<!-- keywords: headless, offscreen, UINullWindow, CGContext, CAOpenGLLayer, CATextLayer -->
# mulle-uios

Use this when you need to verify app code that crosses MulleUIOS's local OS-binding layer. No dedicated `MULLE_UIOS_*` trace surface showed up in the public headers or local docs; the repository-specific verifier delta is the supported headless/offscreen paths, backend-class overrides on `UIWindow` and `UINullWindow`, and small demos/tests that isolate each rendering family.

## Understand first

```bash
mulle-sde api apropos MulleUIOS
mulle-sde api cat MulleUIOS
mulle-sde api cat CAOpenGLLayer
mulle-sde api apropos UIWindow
mulle-sde api apropos UINullWindow
mulle-sde code search activateWindowGraphicsContext
mulle-sde code search renderGraphicsContext
mulle-sde code search processOneFrame
```

## Local references

- `asset/dox/TOC.md`
- `asset/dox/RENDERING-SYSTEM.md`
- `src/MulleUIOS.h`
- `src/UIWindow+MulleUIOS.m`
- `src/UIWindow+CG.m`
- `src/UINullWindow+MulleUIOS.m`
- `src/UINullWindow+CG.m`
- `src/CAOpenGLLayer.h`
- `src/CAOpenGLLayer.m`
- `demo/src/main-glfw-cglayer.m`
- `demo/src/main-glfw-draw-offscreen.m`
- `test/10-first/nullwindow-cgcontext.m`
- `test/10-first/uinullwindow-cgcontext.m`
- `test/20-retained/uinullwindow-cgcontext.m`
- `test/20-paint/catextlayer-render.m`
- `test/50-render/oneframe.m`

## Main verifier surfaces

| Scenario | What to verify first | Evidence |
| --- | --- | --- |
| Wrong backend or window binding | `+setOSWindowClass:` and `+setOSGraphicsContextClass:` are process-wide category statics; rule this out before blaming rendering | `src/MulleUIOS.h`, `src/UIWindow+MulleUIOS.m`, `src/UIWindow+CG.m`, `src/UINullWindow+MulleUIOS.m`, `src/UINullWindow+CG.m` |
| Hidden/offscreen `UIWindow` path | A hidden or offscreen window is still expected to create and activate a graphics context | `test/10-first/nullwindow-cgcontext.m`, `test/50-render/oneframe.m` |
| Headless null-window path | `UINullWindow` is expected to auto-create its `UINullOSWindow`/`CGContext` no-draw path | `test/10-first/uinullwindow-cgcontext.m`, `test/20-retained/uinullwindow-cgcontext.m` |
| Pixel proof instead of state proof | Verify pixels via the framebuffer/image path, not just counters or model logs | `src/MulleUIOS.h`, `asset/dox/RENDERING-SYSTEM.md`, `demo/src/main-glfw-draw-offscreen.m` |
| GL/layer failures | `CAOpenGLLayer` is a strict begin/draw/end bracket with backend-error checks around each stage | `src/CAOpenGLLayer.h`, `src/CAOpenGLLayer.m`, `demo/src/main-glfw-cglayer.m` |
| Text rendering without a real window | The repo has a dummy `UIOSGraphicsContext` + `UIGraphicsNoDrawing` render path for deterministic text checks | `test/20-paint/catextlayer-render.m` |

## Local workflow

- Start with the smallest supported surface: `test/50-render/oneframe.m` for one hidden frame, `test/10-first/nullwindow-cgcontext.m` for hidden/offscreen context activation, and `test/20-retained/uinullwindow-cgcontext.m` for the null-window auto-wiring contract.
- Treat backend selection as global mutable state. `UIWindow` and `UINullWindow` both cache their backend classes in category statics, so one reproducer can poison the next if it changes them.
- For rendering proof, prefer the offscreen capture path from `demo/src/main-glfw-draw-offscreen.m` and the `imageWithFramebuffer:nameUTF8String:` contract described in `src/MulleUIOS.h` and `asset/dox/RENDERING-SYSTEM.md`. Call `[context barrier]` before wrapping the framebuffer as an image.
- For GL-only bugs, debug `CAOpenGLLayer` as `beginOpenGLWithContext:` → `drawOpenGLInContext:` → `endOpenGLWithContext:`. `viewPortDidChange:` only runs from that setup path after viewport/scissor setup.
- The only explicit repo-local environment precondition surfaced here is `MULLE_OBJC_EPHEMERAL_SINGLETON=YES` for `demo/src/main-glfw-cglayer.m`. Do not treat that demo's failure as a library regression until the environment matches.

## Verify/report

- State whether the failure is visible-window, hidden/offscreen `UIWindow`, or `UINullWindow` no-draw.
- Name the exact smallest reproducer path you used.
- If you report a rendering failure, include pixel proof from the offscreen/image path or an equivalent capture, not just state changes or counters.
