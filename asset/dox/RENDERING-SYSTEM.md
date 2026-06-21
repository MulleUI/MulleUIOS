# MulleUI Rendering System

A deep dive into how a frame goes from "app code calls `CGContextFill`" to
"pixels appear on screen". This covers the full pipeline: threads, contexts,
framebuffers, the layer render queue, the vtable dispatch system, and the
two-context double-buffering architecture.

---

## The Big Picture

MulleUI uses a **two-context, two-thread** architecture. The window thread
draws into an offscreen framebuffer. The main thread blits that framebuffer
to the visible window. They never touch the same GL context at the same time.

```
  NSMainThread                          UIWindowThread
  ────────────                          ──────────────
  UIApplication runLoop
    │
    ├─ PollEvents (GLFW/SDL)
    │
    ├─ DrawAndSwap
    │    │
    │    ├─ wakeupWindowThread ──────►  windowThreadMain:
    │    │                               │
    │    │                               ├─ renderWithFrameInfo:
    │    │                               │    └─ render_frameWithFrameInfo:
    │    │                               │         └─ UIPureWindowDefaultRawFrameCallback
    │    │                               │              ├─ beginRender:
    │    │                               │              ├─ clearFrame:
    │    │                               │              ├─ UIWindowDefaultRenderViews
    │    │                               │              │    ├─ layout
    │    │                               │              │    ├─ createRenderQueue
    │    │                               │              │    └─ renderLayersInFrame:
    │    │                               │              │         └─ renderObjects: ← YOUR DRAW CODE
    │    │                               │              └─ endRender
    │    │                               │
    │    │                               └─ setNeedsRefresh → wakes main thread
    │    │
    │    └─ displayFrameIfNeeded:
    │         ├─ refresh          ← blits offscreen FB to window context
    │         └─ swapBuffers      ← presents to screen
    │
    └─ PollEvents ...
```

---

## The Two Contexts

Every `UIPureWindow` with `UIWindowBackingStoreRetained` has two GL contexts
that share a texture namespace (created with GLFW's context sharing):

```
  ┌─────────────────────────────────────────────────────────────┐
  │  UIPureWindow                                               │
  │                                                             │
  │  _OSWindow (GLFWOSWindow)          ← visible window        │
  │  _context  (CGContext "Window")    ← main thread context   │
  │                                                             │
  │  _offscreenOSWindow (GLFWOSWindow) ← hidden sharing window │
  │  _offscreenContext  (CGContext "Offscreen") ← render thread │
  └─────────────────────────────────────────────────────────────┘
```

The offscreen OSWindow is created invisible, sharing the GL context of the
visible window. This means textures created in one context are visible in the
other — the key to the blit step.

**Rule**: only one thread touches one context at a time. The window thread
owns `_offscreenContext`. The main thread owns `_context`. They never cross.

---

## Thread Lifecycle and the Condition Lock

The window thread is coordinated via `NSConditionLock` with three states:

```
  State 0 → thread starting up
  State 1 → thread idle, waiting for work
  State 2 → thread has work, running
```

```
  Main thread                         Window thread
  ───────────                         ─────────────
  startWindowThread:
    lock(0) → unlock(1)
    wait for condition 1 ──────────►  lock(0) → unlock(1)   [signals ready]
    lock(1) → unlock(2) ──────────►  lock(2) → ... draw ... → unlock(1)
                                      [repeat]
  wakeupWindowThread:
    tryLock(1) → unlock(2) ───────►  lock(2) → draw → unlock(1)

  finalizeWindowThread:
    lock(1) → cancel thread
    unlock(2) ────────────────────►  sees isCancelled → unlock(1) → exit
    lock(1) → join
```

The window thread loops: wait for condition 2, draw a frame, unlock to 1,
repeat. The main thread wakes it by flipping 1→2.

---

## Frame Rendering Pipeline (Window Thread)

When the window thread gets condition 2, it calls:

```
windowThreadDraw:windowInfo:now:
  └─ renderWithFrameInfo:displayBits:
       ├─ render_adjustFrameWithFrameInfo:   ← resize detection
       └─ render_frameWithFrameInfo:
            ├─ activateRenderGraphicsContext ← binds offscreen GL context
            ├─ _willRenderFrameCallback      ← hook (default: pass-through)
            ├─ _rawFrameCallback             ← UIPureWindowDefaultRawFrameCallback
            │    ├─ beginRender:             ← nvgBeginFrame, bind framebuffer
            │    ├─ clearFrame:             ← glClear
            │    ├─ _frameCallback          ← UIWindowDefaultRenderViews
            │    │    ├─ UIWindowDefaultLayoutViews
            │    │    ├─ UIWindowDefaultPrepareRenderQueue
            │    │    └─ renderLayersInFrame:
            │    │         └─ renderObjects: ← iterates render queue
            │    └─ endRender               ← nvgEndFrame, unbind framebuffer
            ├─ _didRenderFrameCallback       ← hook (default: pass-through)
            ├─ render_drawDebug:            ← debug overlay (if flags set)
            └─ deactivateRenderGraphicsContext
```

After this, `setNeedsRefresh` is called and an empty GLFW event is posted to
wake the main thread.

---

## The Render Queue

The render queue is a flat `mulle_pointerarray` of `CALayer` objects. It is
rebuilt every frame from the `UIView` hierarchy.

```
  UIView tree (hierarchical)          Render queue (flat, ordered)
  ──────────────────────────          ────────────────────────────

  UIWindow
    └─ UIView "root"
         ├─ UIView "A"                [A.layer, B.layer1, B.layer2,
         │    └─ CALayer (sublayer)    C.layer1, C.layer2, C.layer3]
         ├─ UIView "B"
         │    ├─ CALayer
         │    └─ CALayer
         └─ UIView "C"
              ├─ CALayer
              ├─ CALayer
              └─ CALayer
```

`UIWindowDefaultPrepareRenderQueue` calls `createRenderQueueForFrame:` which
does a depth-first traversal of the view tree, collecting each view's layers
into the flat array. Animations are then applied to the collected layers.

`CGContext renderObjects:` iterates the array and calls
`[layer renderInContext:context]` on each one.

---

## Layer Rendering (`CGGraphicsLayer renderInContext:`)

Each layer goes through a fixed sequence:

```objc
- (void) renderInContext:(CGContext *) context
{
    if( _hidden || alpha == 0 || frame < 0.1px) return;

    // 1. Background (uses _frame coords, no bounds transform)
    if( [self drawsBackgroundWithAlpha:alpha])
    {
        [self setupContext:context transform:&_transform alpha:alpha];
        [self drawBackgroundInContext:context];
    }

    // 2. Content
    [self setupContext:context transform:&_transform alpha:alpha];
    if( [self willDrawInContext:context])   // returns NO if bounds == 0
    {
        [self drawInContext:context];       // calls your drawCallback
        [self didDrawInContext:context];
    }

    // 3. Border
    if( [self drawsBorderWithAlpha:alpha])
    {
        if( isDrawing) [self setupContext:...];
        [self drawBorderInContext:context];
    }
}
```

`setupContext:transform:alpha:` pushes the layer's transform (translation +
optional bounds scaling + rotation) onto the nanovg transform stack.

`willDrawInContext:` returns `NO` if `bounds.size` is zero — this is the
guard that prevents drawing into zero-size layers.

`drawInContext:` for `CGGraphicsLayer` calls
`CGGraphicsLayerExecuteDrawCallback` which invokes your `_drawCallback`
function pointer:

```c
static inline BOOL CGGraphicsLayerExecuteDrawCallback(CGGraphicsLayer *self,
                                                      CGContext *context)
{
    return self->_drawCallback
           ? (*self->_drawCallback)(self, context)
           : YES;
}
```

---

## The CGContext and the Vtable

`CGContext` is the drawing surface. All drawing goes through a **vtable**
(`CGFunctionTable`) embedded in the context's `_cgBackend` struct:

```
  CGContextBase
    _cgBackend
      .context          ← NVGcontext* (or cairo_t*, etc.)
      .functions        ← CGFunctionTable (fill, stroke, rect, ...)
      .backendFunctions ← CGBackendFunctionTable (createFramebuffer, ...)
```

The inline wrappers in `CGContext+Drawing.h` dispatch through this:

```c
#define CGContextFN(ctx)  (_CGContextBaseGetFunctionTable((CGContextBase*)(ctx)))
#define CGContextVG(ctx)  (_CGContextBaseGetBackendContext((CGContextBase*)(ctx)))

static inline void CGContextFill(CGContext *context)
{
    if(context) CGContextFN(context)->fill(CGContextVG(context));
}
```

For the nanovg backend, `CGFunctionTable` is populated in
`CGFunctionTable+nanovg.m`:

```c
static void _fill(void *vg) { nvgFill((NVGcontext*)vg); }
static void _rect(void *vg, CGRect r) { nvgRect(vg, r.origin.x, r.origin.y,
                                                    r.size.width, r.size.height); }
// ...
static const CGFunctionTable nanovgFunctionTable = {
    .fill    = _fill,
    .stroke  = _stroke,
    .rect    = _rect,
    .fillColor = _fillColor,
    // ... ~80 function pointers
};
```

This means swapping the renderer (nanovg → cairo → skia) requires only
providing a different `CGFunctionTable` — no changes to drawing code.

---

## beginRender / endRender

`beginRender:` and `endRender` bracket each frame. For nanovg:

```
beginRender:
  ├─ bind the CGFramebuffer (glBindFramebuffer)
  ├─ nvgBeginFrame(vg, width, height, pixelRatio)
  ├─ nvgSave(vg)
  └─ nvgReset(vg)

endRender
  ├─ nvgEndFrame(vg)          ← flushes all nanovg draw calls to GL
  ├─ unbind CGFramebuffer
  └─ glBindFramebuffer(0)     ← restore default
```

nanovg is a **retained** drawing API — calls like `nvgRect`, `nvgFill` etc.
accumulate into an internal command buffer. `nvgEndFrame` is when the actual
GL draw calls happen. This is why you see all the `nvgRect(...)` trace lines
before any GL activity.

---

## The Framebuffer (CGFramebuffer)

The offscreen context doesn't render directly to the window. It renders into
a `CGFramebuffer` — an OpenGL FBO wrapping a texture:

```
  CGFramebuffer "RenderFrame #0"
    ├─ CGImage (wraps GL texture ID)
    ├─ GL FBO handle
    └─ size: 200×200

  Lifecycle:
    beginRender: → _bindToContext   → glBindFramebuffer(FBO)
    endRender   → _unbindFromContext → glBindFramebuffer(0)
    provideRenderedFramebuffer      → makes available to main thread
    acquireRenderedFramebuffer      → main thread picks it up
    recycleAcquiredRenderedFramebuffer → returns it for reuse
```

The framebuffer is created lazily on the first render and reused. The
`MulleUIResourceMap` tracks it by key so it can be found and reused.

---

## The Blit (Main Thread Refresh)

After the window thread finishes a frame, the main thread's
`displayFrameIfNeeded:` calls `refresh`:

```
refresh (main thread, _context "Window")
  ├─ activateWindowGraphicsContext
  ├─ acquireRenderedFramebuffer      ← get the texture from offscreen context
  ├─ beginRender:
  ├─ clearFramebufferWithHexColor:   ← clear window
  ├─ imageWithFramebuffer:           ← wrap texture as CGImage in window context
  ├─ blitRect:image:scale:           ← nvgImagePattern + nvgFill (full-screen quad)
  └─ endRender
```

The key insight: `imageWithFramebuffer:` creates a `CGImage` in the **window
context** that wraps the **same GL texture** that was rendered into by the
offscreen context. Because the two GL contexts share a texture namespace
(created with `glfwCreateWindow(..., shareWindow)`), this works without any
pixel copy.

```
  Offscreen context                   Window context
  ─────────────────                   ──────────────
  renders into texture T ──────────►  reads texture T
  (via FBO)                           (via nvgImagePattern blit)
                         shared GL
                         texture namespace
```

---

## Anti-Aliasing Modes

The nanovg context is created with flags that control AA:

```
UIWindowStyleAntiAlias + hardware MSAA available
  → NVG_ANTIALIAS=0, MSAA4 framebuffer
  → "OpenGL v3.2+ ClearType Stencil MSAA"

UIWindowStyleAntiAlias + no hardware MSAA (GLES2)
  → NVG_ANTIALIAS=1 (software edge AA)
  → "GLES v2.0+ EdgeAA ClearType Stencil"

UIWindowStyleForceEdgeAntiAlias
  → NVG_ANTIALIAS=1 regardless of hardware
```

On Linux/GLES the driver doesn't support MSAA framebuffers, so EdgeAA is
used. On Windows/GL3.2 Core, MSAA4 is available.

---

## Texture Readback (RGBABytesBitmapOfImage:)

Reading pixels back from a GPU texture is needed for PNG export and test
comparison. The method has three paths depending on GL profile:

```
GLES2/GLES3:
  glGetTexImage not available →
  create temp FBO, attach texture, glReadPixels
  (GLES3 + MSAA: blit to resolve FBO first, then glReadPixels)

GL3 Core Profile (forward-compatible):
  glGetTexImage not available in core profile →
  same FBO path as GLES, with glBlitFramebuffer for MSAA resolve

GL Compatibility Profile:
  glGetTexImage available →
  glBindTexture + glGetTexImage (fastest, no FBO needed)
```

Profile detection at runtime:

```c
GLint profileMask = 0;
glGetIntegerv(GL_CONTEXT_PROFILE_MASK, &profileMask);
if(profileMask & GL_CONTEXT_COMPATIBILITY_PROFILE_BIT)
    // use glGetTexImage
else
    // use FBO + glReadPixels (with MSAA resolve if needed)
```

---

## DisplayBits — What Needs Redrawing?

`UIWindowDisplayBits` is a bitmask that flows through the frame pipeline,
accumulating work to do and returning what happened:

```
Bit                          Meaning
───────────────────────────  ──────────────────────────────────────────
UIWindowDisplayNeedsRedraw   Render a new frame right now
UIWindowDisplayNeedsLayout   View hierarchy changed, re-layout first
UIWindowDisplayNeedsStyling  Style properties changed
UIWindowDisplayNeedsAnimation  An animation is running, keep rendering
UIWindowDisplayNeedsMouseEvent  Layout changed, re-track mouse position
UIWindowDisplayDidAnimate    An animation actually ran this frame
```

The bits flow like this:

```
setNeedsDisplay → stores bits in _needsDisplay
windowThreadMain: reads _needsDisplay
  → passes to windowThreadDraw:
    → renderWithFrameInfo:displayBits:
      → render_adjustFrameWithFrameInfo:  (may add NeedsLayout)
        → _willRenderFrameCallback        (may add bits)
          → _rawFrameCallback
            → UIWindowDefaultRenderViews
              → UIWindowDefaultLayoutViews    (consumes NeedsLayout)
              → UIWindowDefaultPrepareRenderQueue
              → renderLayersInFrame:          (consumes NeedsRedraw)
            returns returnBits
          → _didRenderFrameCallback
        returns returnBits
      → render_requestFakeMouseEventIfNeeded: (if NeedsMouseEvent)
    returns: NeedsAnimation if animations ran, else 0
  → setNeedsDisplayBits: (stores animation bit for next frame)
```

---

## The Backend Composition Model

The drawing backend is selected at **link time** by which library is linked.
`CGContext.m` calls category methods that are forward-declared but have no
base implementation — the linked backend provides them:

```
CGContext( nanovg)          ← MulleCGNanovg: sets up CGFunctionTable
  _initNanoVGWithGraphicsOptions:
  _finalizeNanoVG

CGContext( OpenGL)          ← MulleCGNanovgGL: creates NVGcontext via nvgCreateGL3
  _initializeNanoVG:        ← calls nvgCreateGL3, sets up GL state
  _finalizeNanoVG           ← calls nvgDeleteGL3

CGContext( Errors)          ← MulleCGNanovgGL: GL error checking
  _checkBackendError:
  resetBackendError
```

The category load order is enforced via `objc-deps.inc`:
MulleCGNanovgGL declares a dependency on MulleCGNanovg, so it loads first.
MulleCGNanovg's categories load second and do NOT override methods already
provided by MulleCGNanovgGL (no-op stubs were removed for this reason).

---

## Putting It All Together: One Frame

Here is the complete sequence for one frame of `draw-simple`, annotated:

```
[NSMainThread] UIApplication runLoopIteration
  → DrawAndSwap
    → wakeupWindowThread (condition 1→2)

[UIWindowThread] windowThreadMain: wakes up
  → windowThreadDraw:windowInfo:now:
    → renderWithFrameInfo: displayBits=NeedsRedraw|NeedsLayout|NeedsStyling
      → render_adjustFrameWithFrameInfo:  (frame unchanged, no extra bits)
      → render_frameWithFrameInfo:
        → activateRenderGraphicsContext
            → os_activateGraphicsContext (glfwMakeContextCurrent offscreen)
        → _willRenderFrameCallback (pass-through)
        → UIPureWindowDefaultRawFrameCallback
            → beginRender:
                → nvgBeginFrame(vg, 200, 200, 1.0)
                → nvgSave / nvgReset
                → bind CGFramebuffer FBO
            → clearFrame:
                → glClear(COLOR|DEPTH|STENCIL)
            → UIWindowDefaultRenderViews
                → UIWindowDefaultLayoutViews
                    → [UIView layout]  (positions subviews)
                → UIWindowDefaultPrepareRenderQueue
                    → createRenderQueueForFrame:  → [CGGraphicsLayer]
                → renderLayersInFrame:
                    → [context useDefaultFont]  → nvgFontFace("sans")
                    → renderObjects: &_renderQueue
                        → [CGGraphicsLayer renderInContext:]
                            → setupContext: (translate to frame origin)
                            → willDrawInContext: → YES (bounds 200×200)
                            → drawInContext:
                                → CGGraphicsLayerExecuteDrawCallback
                                    → drawRedWhiteBlueFlag(context, canvas)
                                        → CGContextBeginPath → nvgBeginPath
                                        → CGContextRect     → nvgRect
                                        → CGContextFillColor → nvgFillColor
                                        → CGContextFill     → nvgFill
                                        [× 3 stripes]
            → endRender
                → nvgEndFrame(vg)  ← ALL GL draw calls happen here
                → unbind FBO
        → _didRenderFrameCallback (pass-through)
        → render_drawDebug: (debug overlay if UIDebuggingFlags set)
        → deactivateRenderGraphicsContext
      → setNeedsRefresh
      → [UIEvent sendEmptyEvent]  ← wakes main thread

[NSMainThread] PollEvents returns (empty event received)
  → DrawAndSwap
    → displayFrameIfNeeded:
      → needsRefresh? YES
        → refresh
            → activateWindowGraphicsContext
                → glfwMakeContextCurrent (visible window)
            → acquireRenderedFramebuffer  ← gets texture from offscreen
            → beginRender: (window context)
                → nvgBeginFrame
            → clearFramebufferWithHexColor: (background)
            → imageWithFramebuffer:  ← wraps shared texture as CGImage
            → blitRect:image:scale:  ← nvgImagePattern + nvgFill
            → endRender
                → nvgEndFrame  ← blits texture to window framebuffer
            → deactivateWindowGraphicsContext
        → swapBuffers
            → glfwSwapBuffers  ← presents to screen
```

---

## Key Design Principles

**Separation of concerns**: The window thread only draws. The main thread only
handles events and presents. They communicate through the framebuffer
handoff protocol (provide/acquire/recycle).

**Vtable dispatch**: All drawing goes through `CGFunctionTable`. Swapping
backends requires no changes to drawing code — only the linked library
changes.

**Link-time composition**: Backend selection is a linker decision, not a
runtime one. The sourcetree config determines which `.a` files are linked,
which determines which category implementations win.

**Lazy context creation**: Both GL contexts are created on first use, on the
correct thread. The offscreen context is created on the window thread; the
window context on the main thread.

**Shared texture namespace**: The two GL contexts share textures. The
offscreen context renders into a texture; the main context reads it. No pixel
copy, no PBO — just a full-screen textured quad.
