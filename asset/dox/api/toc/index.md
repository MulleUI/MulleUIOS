# MulleUIOS Library Documentation for AI
<!-- Keywords: platform, windowing, graphics, GLFW, SDL, OpenGL, headless -->
## 1. Introduction & Purpose

MulleUIOS is the platform integration layer that wires the MulleUICore UIWindow/CALayer hierarchy to the underlying OS window system and graphics rendering stack. It acts as the glue between abstract UI concepts (UIWindow, UIView) and concrete platform implementations (GLFW/SDL for windowing, CGContext/NanoVG for rendering). The library is thin by design—it is composed of Objective-C categories that configure backend classes at class-load time, and a single `CAOpenGLLayer` class for embedding raw OpenGL drawing within the layer tree.

**Key features:**
- Platform-specific window system integration via GLFW or SDL (selectable at build time)
- Graphics context binding via MulleCGNanovg with multiple backends (OpenGL GL3/GLES2/GLES3, Direct3D 11)
- Headless/offscreen rendering support through `UINullWindow` and `UINullOSWindow`
- `CAOpenGLLayer` for embedding raw OpenGL drawing within the UIView/CALayer hierarchy
- Build-time config switching: `mulle-sde config switch glfw,sdl,sdl-d3d11`
- Central per-thread layout context via `CGLayoutContext` (provided by MulleUICore)

## 2. Key Concepts & Design Philosophy

### Category-Based Architecture

MulleUIOS uses Objective-C categories to extend classes from dependencies without modifying their source. Categories are conditionally compiled based on which backends are available (`#ifdef HAVE_IMPORT__MULLE_GLFW`, `#ifdef HAVE_IMPORT__MULLE_CG`, etc.).

### Consolidated Backend Implementation

Rather than scattered per-backend files, all backend wiring lives in a small set of consolidation files:

- **`UIWindow+MulleUIOS.m`** — `UIWindow( OSWindowClass)` handles both GLFW and SDL via `#ifdef` guards. It selects the OS window class, conforms `UIWindow` to `<UIEventReceiver>`, and provides `+osGraphicsHints` mapped from the active NanoVG backend.

- **`UINullWindow+MulleUIOS.m`** — `UINullWindow( OSWindowMulleUIOS)` unconditionally defaults to `[UINullOSWindow class]` for headless use. No `#ifdef` gating required.

- **`UIWindow+CG.m`** — `UIWindow( OSGraphicsContextClass)` defaults to `[CGContext class]` for the graphics context. Guarded by `#ifdef HAVE_IMPORT__MULLE_CG`.

- **`UINullWindow+CG.m`** — `UINullWindow( OSWindowCG)` mirrors the CG context configuration for null windows. Guarded by `#ifdef HAVE_IMPORT__MULLE_CG`.

### Backend Selection Pattern

Class methods `+setOSWindowClass:` and `+setOSGraphicsContextClass:` on both `UIWindow` and `UINullWindow` allow runtime backend overrides. Defaults are per-platform but can be changed (e.g., `[UINullOSWindow class]` for headless tests, `Nil` for `osGraphicsContextClass` to skip CGContext creation). **These must be called before any window is created;** changing backends mid-run is not supported.

### Conditional Compilation & Configs

Categories are wrapped in `#ifdef HAVE_IMPORT__MULLE_GLFW` / `#ifdef HAVE_IMPORT__MULLE_SDL` / `#ifdef HAVE_IMPORT__MULLE_CG`. Build-time configs (`glfw`, `sdl`, `sdl-d3d11`) select which dependencies are pulled in, determining which conditional blocks are active. Switch via `mulle-sde config switch <name>`.

## 3. Core API & Data Structures

### 3.1. `MulleUIOS.h` — Main Public Header

#### `@interface UIWindow( OSWindowClass) <UIEventReceiver>`

**Purpose:** Declares `UIWindow` as conforming to `<UIEventReceiver>` and provides class methods for configuring the OS window backend.

**Class Configuration Methods:**
- `+ (void) setOSWindowClass:(Class) cls` — Override the default OS window class. Call before first window creation.
- `+ (Class) osWindowClass` — Returns the currently configured OS window class. Defaults to `[GLFWOSWindow class]` (under `#ifdef HAVE_IMPORT__MULLE_GLFW`) or `[SDLOSWindow class]` (under `#ifdef HAVE_IMPORT__MULLE_SDL`), or `ClassStatic.windowClass` (may be `Nil`) if neither backend is compiled in.

**Platform Graphics Hints (implementation-only, in `UIWindow+MulleUIOS.m`, not declared in public header):**
- `+ (UIOSWindowGraphicsHints) osGraphicsHints` — Returns a `UIOSWindowGraphicsHints` struct with platform-specific GL context settings (version, profile). Derived from `[CGContext nanoVGBackend]` and mapped to GLFW or SDL hint constants. Returns a zeroed struct if neither backend is compiled.

#### `@interface UIWindow( OSGraphicsContextClass)`

**Purpose:** Provides class configuration for the graphics context class used by the window.

- `+ (void) setOSGraphicsContextClass:(Class) cls` — Override the default graphics context class. Set to `Nil` for headless/vibecoding mode without CGContext creation.
- `+ (Class) osGraphicsContextClass` — Returns the configured class or `[CGContext class]`.

### 3.2. `CAOpenGLLayer.h` — OpenGL Layer

#### `@interface CAOpenGLLayer : CGGraphicsLayer`

**Purpose:** A `CGGraphicsLayer` subclass that allows raw OpenGL drawing within the UIView/CALayer hierarchy. It computes viewport and scissor rects (y-flipped for OpenGL), suspends NanoVG rendering, executes OpenGL, then resumes NanoVG. Supports both deprecated (immediate mode) and modern (shader-based) OpenGL.

**Public Instance Variables:**
- `CGRect _viewPort` — Computed viewport in screen coordinates (y-flipped, integral). Read via `viewPort` property.
- `CGRect _scissor` — Computed scissor rect in screen coordinates (y-flipped, integral). Read via `scissor` property.

**Properties:**
- `@property( assign) CAOpenGLLayerViewPortCallback_t *viewPortDidChangeCallback` — Optional C callback invoked when the viewport changes (resize/move). Signature:

  `typedef void CAOpenGLLayerViewPortCallback_t( CAOpenGLLayer *layer, CGContext *context)`

- `@property( readonly) CGRect viewPort` — Readonly accessor for `_viewPort`.
- `@property( readonly) CGRect scissor` — Readonly accessor for `_scissor`.

**Lifecycle:**
- `- (instancetype) initWithFrame:(CGRect) frame` — Sets canvas to `CGRectMake( -1.0, 1.0, 2.0, -2.0)`.
- `- (void) finalize` — Cleans up OpenGL resources (program, VBO, optionally VAO on non-GLES2).
- `- (id) copy` — Overrides to delegate to `[super copy]`.

**Core Methods:**
- `- (void) beginOpenGLWithContext:(CGContext *) context` — Sets `glViewport` and `glScissor`. For deprecated GL also configures MODELVIEW/PROJECTION identity matrices. Invokes `viewPortDidChange:` if viewport changed since last frame.
- `- (void) drawOpenGLInContext:(CGContext *) context` — Default draws a colored triangle using deprecated GL (`glBegin`/`glEnd`) or modern GL (compiled shaders + VAO/VBO). Override this for custom GL drawing.
- `- (void) endOpenGLWithContext:(CGContext *) context` — Calls `glFlush()` and disables `GL_SCISSOR_TEST`.
- `- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha` — Returns `YES` (always, for proper stencil buffer behavior with texture mapping).
- `- (BOOL) drawInContext:(CGContext *) context` — Overrides super. Suspends NanoVG (`suspendRender`), runs begin/draw/end OpenGL, resumes NanoVG (`resumeRender`). Falls back to `drawNonOpenGLInContext:` if backend lacks OpenGL support.
- `- (void) viewPortDidChange:(CGContext *) context` — Invokes `viewPortDidChangeCallback` if set. Called from `beginOpenGLWithContext:`.

**Non-OpenGL Fallback:**
- `- (void) drawNonOpenGLInContext:(CGContext *) context` — Draws a placeholder text ("No compatible GL version available") via CGContext when the backend lacks OpenGL.

**Internals (subclassing awareness):**
- `- (void) compileDefaultShaders` — Compiles vertex/fragment shaders versioned per `MULLE_CG_GLVERSION` (GL3 `#version 150 core`, GLES2 `#version 100`, GLES3 `#version 300 es`). Called lazily by `drawOpenGLInContext:`.
- `- (void) setupDefaultVertexData` — Creates VBO (and VAO on non-GLES2) with triangle positions/colors.

### 3.3. `MulleObjCDeps+MulleUIOS.h` — Runtime Loader

#### `@interface MulleObjCDeps( MulleUIOS)`

**Purpose:** Declares mulle-objc runtime dependency chain for proper class initialization order.

- `+ (struct _mulle_objc_dependency *) dependencies` — Returns dependency array from generated `objc-deps.inc`. Users do not typically call this directly. Required by the mulle-objc runtime to ensure classes are loaded in dependency order.

### 3.4. Implementation-Only Categories (No Separate Headers)

These categories are implemented in `.m` files. Their method declarations are inherited from the main `MulleUIOS.h` header or from protocol conformance. They provide the actual backend wiring.

#### `UINullWindow( OSWindowMulleUIOS)` — in `UINullWindow+MulleUIOS.m`

- `+ (void) setOSWindowClass:(Class) cls` — Override the window class for null windows. Default: `[UINullOSWindow class]` (unconditional; no `#ifdef` gating unlike `UIWindow`'s variant).
- `+ (Class) osWindowClass` — Returns the configured class or `[UINullOSWindow class]`.

#### `UINullWindow( OSWindowCG)` — in `UINullWindow+CG.m`

- `+ (void) setOSGraphicsContextClass:(Class) cls` — Override graphics context class for null windows. Set to `Nil` for fully headless operation.
- `+ (Class) osGraphicsContextClass` — Defaults to `[CGContext class]`.

## 4. Performance Characteristics

### Overhead

- **Near-zero runtime overhead:** Categories add no storage overhead; they only extend method dispatch tables at load time.
- **Graphics context hints:** `osGraphicsHints` is a class method run once during window creation. Its cost is negligible.

### Memory

- **No additional allocations:** Categories configure classes, they do not allocate objects.
- **CAOpenGLLayer:** Allocates OpenGL resources (shader program, VAO, VBO) lazily on first `drawOpenGLInContext:` call. Cleanup is done in `finalize`.

### Threading

- **Single-threaded UI model:** All UIWindow, UIView, and CAOpenGLLayer operations should occur on the main thread.
- **Graphics context:** CGContext and backend GL contexts are not thread-safe without external synchronization.

### Graphics Context Creation

- **Lazy initialization:** Graphics contexts are created on first use, not at window creation.
- **Backend selection:** Must be done before first window creation.

## 5. AI Usage Recommendations & Patterns

### Best Practices

1. **Backend Selection Early:** Call `[UIWindow setOSWindowClass:]` and `[UIWindow setOSGraphicsContextClass:]` before creating any windows.

2. **Headless Testing Setup:**
   ```objc
   [UIWindow setOSWindowClass:[UINullOSWindow class]];
   [UIWindow setOSGraphicsContextClass:Nil];
   ```

3. **Use Factory Methods:** Prefer `[UIWindow windowWithFrame:titleUTF8String:styleMask:]` over manual `initWithOSWindow:` construction. The factory method internally resolves the backend via `+osWindowClass`.

4. **Style Masks:** Use `UIWindowStyleMaskBySetting()` for clean flag toggling:
   ```objc
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleOffscreen, YES);
   ```

5. **Activate/Deactivate Pairing:** When using `activateWindowGraphicsContext`, always pair with `deactivateGraphicsContext:`.

6. **CAOpenGLLayer:** Override `drawOpenGLInContext:` for custom GL drawing. Call `[super drawInContext:context]` if overriding `drawInContext:`.

7. **Changing Configs:** Switch backend configs at build time with `mulle-sde config switch glfw,sdl,sdl-d3d11`. Each config has its own reflect directory and dependency set.

### Common Pitfalls

1. **Late Backend Selection:** Calling `setOSWindowClass:` after windows exist is undefined behavior.

2. **Backend Mismatch:** Do not mix SDL and GLFW in the same build run. Use conditional compilation or separate configs.

3. **OpenGL Version Compatibility:** CAOpenGLLayer uses different code paths for deprecated GL vs. modern GL (ES2/ES3/GL3). Ensure your GL version macros match the runtime backend.

4. **Set `osGraphicsContextClass` to `Nil` for vibecoding:** If no graphics are needed, set to `Nil`; otherwise `CGContext` defaults may try to create backends that fail in headless environments.

5. **UINullWindow has independent backend configuration:** `UINullWindow` has its own `+osWindowClass` (from `UINullWindow+MulleUIOS.m`) and `+osGraphicsContextClass` (from `UINullWindow+CG.m`), separate from `UIWindow`. Configure them independently if using `UINullWindow` directly.

6. **Category names have changed:** Old category names like `OSWindowGLFW`, `OSWindowSDL`, and `OSWindowCG` were consolidated into `OSWindowClass`, `OSWindowMulleUIOS`, `OSWindowCG`, and `OSGraphicsContextClass`. Code referencing the old names directly (rare) will not compile.

## 6. Integration Examples

### Example 1: Basic Window with GLFW (Default Config)

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 640, 480)
                      titleUTF8String:"My Application"
                            styleMask:UIWindowStyleMaskDefault];
   [app addWindow:window];
   [app run];

   return( 0);
}
```

### Example 2: Headless Testing with UINullWindow

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;

   [UIWindow setOSWindowClass:[UINullOSWindow class]];
   [UIWindow setOSGraphicsContextClass:Nil];

   app       = [UIApplication instance];
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleHidden, YES);

   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 100, 100)
                      titleUTF8String:NULL
                            styleMask:styleMask];
   [app addWindow:window];
   [window processOneFrame:0.016];
   [app terminate];

   return( 0);
}
```

### Example 3: Explicit UINullWindow Construction

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication     *app;
   id <UIWindow>     window;
   UINullOSWindow    *osWindow;
   id <UIGraphicsContext>   context;

   app      = [UIApplication instance];
   osWindow = [[[UINullOSWindow alloc] initWithFrame:CGRectMake( 0, 0, 64, 64)
                                      titleUTF8String:NULL
                                            styleMask:UIWindowStyleMaskDefault] autorelease];
   window   = (id <UIWindow>) [[[UINullWindow alloc] initWithOSWindow:osWindow
                                                            styleMask:UIWindowStyleMaskDefault] autorelease];
   [app addWindow:window];
   context  = [window renderGraphicsContext];
   [app terminate];

   return( 0);
}
```

### Example 4: Offscreen Rendering

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;

   app       = [UIApplication instance];
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleOffscreen, YES);

   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 256, 256)
                      titleUTF8String:NULL
                            styleMask:styleMask];
   [app addWindow:window];
   [window processOneFrame:0.016];
   [app terminate];

   return( 0);
}
```

### Example 5: OpenGL Layer in a View

```objc
#import <MulleUIOS/MulleUIOS.h>

static void   viewPortDidChange( CAOpenGLLayer *layer, CGContext *context)
{
   MulleUILog( "Viewport changed to %g,%g %gx%g",
               [layer viewPort].origin.x,
               [layer viewPort].origin.y,
               [layer viewPort].size.width,
               [layer viewPort].size.height);
}

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   UIView          *view;
   CAOpenGLLayer   *layer;

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 640, 480)
                      titleUTF8String:"OpenGL Demo"
                            styleMask:UIWindowStyleMaskDefault];

   view  = [UIView viewWithFrame:CGRectMake( 50, 50, 300, 300)];
   layer = [[[CAOpenGLLayer alloc] initWithFrame:[view frame]] autorelease];
   [layer setViewPortDidChangeCallback:viewPortDidChange];
   [view setMainLayer:layer];
   [[window contentView] addSubview:view];
   [app addWindow:window];
   [app run];

   return( 0);
}
```

## 7. Dependencies

Direct mulle-sde library dependencies per config (from `.mulle/etc/sourcetree/<config>`):

| Config       | Window System | Renderer Core | Backend           | Extra              |
|--------------|---------------|---------------|--------------------|--------------------|
| `glfw`       | MulleGLFW     | MulleCGNanovg | MulleCGNanovgGL    | —                  |
| `sdl`        | MulleSDL      | MulleCGNanovg | MulleCGNanovgGL    | —                  |
| `sdl-d3d11`  | MulleSDL      | MulleCGNanovg | (D3D11 craftinfo)  | craftinfo overlay  |

Common to all configs:
- **MulleUICore** — Core window/view hierarchy, event handling, application lifecycle, layout context
- **MulleCGNanovg** — NanoVG-based CGContext and CGGraphicsLayer rendering abstraction
- **mulle-objc-list** — Build-time runtime introspection tool (no-header, no-link)

The `sdl-d3d11` config uses a craftinfo overlay (`craftinfo/MulleCGNanovg-craftinfo.d3d11`) instead of `MulleCGNanovgGL`; this sets the `MULLE_CG_BACKEND` definition to compile for Direct3D 11.

All dependencies cascade their own transitive dependencies (MulleObjC, mulle-core, mulle-allocator, etc.). For the full rendering pipeline architecture, see `asset/dox/RENDERING-SYSTEM.md`.
