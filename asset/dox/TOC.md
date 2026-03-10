# MulleUIOS Library Documentation for AI
<!-- Keywords: platform, binding, windowing, graphics, GLFW, SDL, integration -->

## 1. Introduction & Purpose

MulleUIOS is the platform integration layer that binds the UI framework to the underlying operating system's window system and graphics rendering stack. It acts as the glue between abstract UI concepts (UIWindow, UIView) and concrete platform implementations (GLFW/SDL for windowing, NanoVG/Metal/D3D for rendering). The library enables headless testing through `UINullWindow` and `UINullOSWindow`, allowing the display loop to run without requiring actual OS windows or OpenGL contexts. This is a thin integration layer with minimal code, primarily consisting of Objective-C categories that wire together MulleUIWindow, MulleGraphics, and MulleGLFW (or SDL alternatives).

**Key features:**
- Platform-specific window system integration (GLFW, SDL)
- Graphics context and drawing library binding (NanoVG with Metal/OpenGL/D3D backends)
- Headless/offscreen rendering support for testing and vibecoding
- Bridges CALayer from MulleGraphics to UILayer protocol
- Shadow layer support via CAShadowLayer integration
- Color and paint abstraction helpers

## 2. Key Concepts & Design Philosophy

### Category-Based Architecture
MulleUIOS uses Objective-C categories to extend existing classes from dependencies without modifying their source. Categories are conditionally compiled based on available backends (GLFW vs SDL, CG vs other graphics).

### Backend Selection Pattern
The library provides class methods `+setOSWindowClass:` and `+setOSGraphicsContextClass:` to allow runtime selection of backend implementations. Default classes are provided for each platform combination, but can be overridden (e.g., using `UINullOSWindow` for headless tests).

### Headless Testing Philosophy
`UINullWindow` with `UINullOSWindow` enables display loop execution without creating real OS windows or OpenGL contexts. Setting `+osGraphicsContextClass:` to `Nil` prevents CGContext creation, allowing pure logic testing. This supports "vibecoding" - development without graphical dependencies.

### Protocol Adaptation
The library makes classes from MulleGraphics (CGContext, CGImage, CGFramebuffer, CALayer) conform to UI protocols (UIGraphicsContext, UIImage, UIFramebuffer, UILayer) through category declarations, enabling polymorphic usage across the UI stack.

### Conditional Compilation
Categories are wrapped in `#ifdef HAVE_IMPORT__MULLE_GLFW`, `#ifdef HAVE_IMPORT__MULLE_CG`, etc., ensuring only available backends are compiled. This allows the same codebase to support multiple platform configurations.

## 3. Core API & Data Structures

### 3.1. `MulleUIOS.h` - Main Public Header

#### `@interface UIWindow( OSWindowClass) <UIEventReceiver>`
**Purpose:** Provides class methods for configuring the OS window and graphics context backend classes used by UIWindow instances.

**Class Configuration Methods:**
- `+ (void) setOSWindowClass:(Class) cls` - Override the default OS window class (e.g., GLFWOSWindow, SDLOSWindow, UINullOSWindow)
- `+ (Class) osWindowClass` - Returns the currently configured OS window class
- `+ (void) setOSGraphicsContextClass:(Class) cls` - Override the default graphics context class (e.g., CGContext, or Nil for headless)
- `+ (Class) osGraphicsContextClass` - Returns the currently configured graphics context class

**Usage Pattern:** Call the setter methods early in application initialization before creating any windows to control which backend is used.

#### `@interface CGContext( UIWindow) <UIGraphicsContext>`
**Purpose:** Extends CGContext to conform to the UIGraphicsContext protocol, making it usable as a graphics context in the UI framework.

**Image Creation Method:**
- `- (id <UIImage>) imageWithFramebuffer:(id <UILayer>) framebuffer nameUTF8String:(char *) nameUTF8String` - Creates a CGImage from a CGFramebuffer layer. Must call `[CGContext barrier]` before this to ensure GPU drawing is complete. Used for capturing offscreen-rendered content as images.

#### `@interface CGImage( UIImage) <UIImage>`
**Purpose:** Makes CGImage conform to UIImage protocol for use as image objects in the UI framework.

#### `@interface CGFramebuffer( UIFramebuffer) <UIFramebuffer>`
**Purpose:** Makes CGFramebuffer conform to UIFramebuffer protocol for use as framebuffer objects in rendering pipeline.

#### `@interface CALayer( UIOSWindow) <MulleUINamedObject>`
**Purpose:** Extends CALayer with initialization that takes an OS window reference.

**Initialization:**
- `- (instancetype) initWithFrame:(CGRect) frame OSWindow:(id <UIOSWindow>) window` - Initialize a layer with a frame and associated OS window handle

#### `@interface CGGraphicsLayer( UILayer) <UILayer>`
**Purpose:** Makes CGGraphicsLayer conform to UILayer protocol, enabling use as the main rendering layer in UIView.

### 3.2. `UIView+CGGraphicsLayerForwarding` Category

**Purpose:** Forwards graphics-related properties from UIView to the underlying CGGraphicsLayer, providing a unified API for view rendering properties.

**Properties (all forwarded to the main layer):**
- `@property( assign) CGGraphicsLayerDrawCallback_t *drawCallback` - Custom drawing callback function
- `@property( observable) MulleCornerInsets cornerInsets` - Insets for rounded corners
- `@property( observable) CGFloat borderWidth` - Width of the border
- `@property( observable) CGFloat opacity` - Alpha transparency (0.0 to 1.0)
- `@property( observable) CGPaint *borderPaint` - Paint used for border rendering
- `@property( observable) CGPaint *backgroundPaint` - Paint used for background fill
- `@property( observable) CGPoint anchorPoint` - Anchor point for transformations
- `@property( observable) CARotation rotation` - Layer rotation transform
- `@property( assign) BOOL masksToBounds` - Whether to clip sublayer rendering to bounds

**Convenience Methods:**
- `- (void) setBorderColor:(CGColor) color` - Set border color from CGColor value
- `- (void) setBackgroundColor:(CGColor) color` - Set background color from CGColor value
- `- (void) setCornerRadius:(CGFloat) radius` - Set uniform corner radius

### 3.3. `UIWindow+CGGraphicsLayer` Category

**Purpose:** Provides direct access to the window's draw callback.

**Property:**
- `@property( dynamic) CGGraphicsLayerDrawCallback_t *drawCallback` - The window's custom drawing callback

### 3.4. `UIWindow+CGColor.h` - Color Conversion Helpers

#### `@interface UIWindow( CGColor)`
**Purpose:** Provides color and paint property accessors for UIWindow background, converting between CGColor, hex color, and CGPaint representations.

**Properties:**
- `@property( assign, dynamic) CGColor backgroundColor` - Get/set window background as CGColor

**Paint Methods:**
- `- (CGPaint *) backgroundPaint` - Returns background as a CGPaint object (monochrome colors only)
- `- (void) setBackgroundPaint:(CGPaint *) paint` - Set background from CGPaint object

**Implementation Note:** Uses `_backgroundHexColor` internally for efficient storage, converting to/from CGColor on demand.

### 3.5. `UIView+CAShadowLayer.h` - Shadow Support

#### `@interface UIView( CAShadowLayer)`
**Purpose:** Adds optional drop shadow rendering capability to UIView using CAShadowLayer from MulleGraphics.

**Shadow Control:**
- `- (void) setShowsShadow:(BOOL) flag` - Enable or disable shadow rendering. Creates CAShadowLayer lazily when enabled.
- `- (BOOL) isShowingShadow` - Returns YES if shadow is currently enabled

**Shadow Layer Access:**
- `- (CAShadowLayer *) shadowLayer` - Returns the CAShadowLayer instance. Asserts if `isShowingShadow` returns NO.

**Layout Integration:**
- `- (void) layoutShadowLayer:(id <UILayer>) layer layoutInfo:(struct UILayoutInfo *) info` - Internal method that handles shadow layer frame calculation with extrusion for shadow insets

**Usage Pattern:** Call `setShowsShadow:YES`, then configure shadow properties via `shadowLayer`.

### 3.6. Backend Category Implementations

#### `UIWindow+GLFW.m` - GLFW Backend Binding
**Purpose:** Implements `osWindowClass` to return `GLFWOSWindow` by default for GLFW-based platforms.

**Methods:**
- `+ (Class) osWindowClass` - Returns `GLFWOSWindow` class or custom override
- `+ (NSUInteger) osGraphicsHints` - Maps CGContext's NanoVG backend selection (CG_GL3, CG_GLES2, etc.) to GLFW context hints

#### `UIWindow+SDL.m` - SDL Backend Binding
**Purpose:** Implements `osWindowClass` to return `SDLOSWindow` by default for SDL-based platforms.

**Methods:**
- `+ (Class) osWindowClass` - Returns `SDLOSWindow` class or custom override
- `+ (NSUInteger) osGraphicsHints` - Maps CGContext's NanoVG backend to SDL context hints

#### `UIWindow+CG.m` - CoreGraphics Context Binding
**Purpose:** Implements `osGraphicsContextClass` to return `CGContext` by default.

**Methods:**
- `+ (Class) osGraphicsContextClass` - Returns `CGContext` class or custom override (can be Nil for headless)

#### `UINullWindow+GLFW.m`, `UINullWindow+SDL.m` - Headless Window GLFW/SDL Binding
**Purpose:** Override `osWindowClass` for `UINullWindow` to return `UINullOSWindow` instead of real window classes.

**Methods:**
- `+ (Class) osWindowClass` - Returns `UINullOSWindow` class or custom override

#### `UINullWindow+CG.m` - Headless Graphics Context Binding
**Purpose:** Override `osGraphicsContextClass` for `UINullWindow`, allowing `Nil` for truly headless operation.

**Methods:**
- `+ (Class) osGraphicsContextClass` - Returns `CGContext` class or custom override (often set to Nil for testing)

### 3.7. `MulleObjCLoader+MulleUIOS.h` - Runtime Dependency Loading

#### `@interface MulleObjCLoader( MulleUIOS)`
**Purpose:** Declares dependencies for the mulle-objc runtime loader, ensuring proper initialization order.

**Methods:**
- `+ (struct _mulle_objc_dependency *) dependencies` - Returns array of mulle-objc dependencies loaded from `objc-loader.inc`

**Note:** This is primarily for internal runtime use; users don't typically interact with this directly.

## 4. Performance Characteristics

### Overhead
- **Near-zero runtime overhead**: Categories add no storage overhead; they only extend method dispatch tables at load time.
- **Headless mode**: UINullWindow/UINullOSWindow bypass all OS window creation and GPU initialization, providing minimal overhead for logic-only tests.

### Memory
- **No additional allocations**: Categories don't allocate new objects; they extend existing instances.
- **Shadow layer**: Created lazily only when `setShowsShadow:YES` is called, avoiding overhead when not needed.

### Threading
- **Single-threaded UI model**: Like most UI frameworks, all UIWindow and UIView operations should occur on the main thread.
- **Graphics context**: CGContext and backend contexts are not thread-safe without external synchronization.

### Graphics Context Creation
- **Lazy initialization**: Graphics contexts are created on first use, not at window creation time.
- **Backend selection**: Must be done before first window creation; changing backends mid-run is not supported.

## 5. AI Usage Recommendations & Patterns

### Best Practices

1. **Backend Selection Early**: Always call `[UIWindow setOSWindowClass:]` and `[UIWindow setOSGraphicsContextClass:]` before creating any windows. Once windows exist, changing backends is undefined behavior.

2. **Use Factory Methods**: Prefer `[UIWindow windowWithFrame:titleUTF8String:styleMask:]` over `[[UIWindow alloc] init...]` for consistency with MulleObjC style.

3. **Headless Testing Setup**:
   ```objc
   [UIWindow setOSWindowClass:[UINullOSWindow class]];
   [UIWindow setOSGraphicsContextClass:Nil];
   // Now create windows for testing
   ```

4. **Shadow Layers**: Always check `isShowingShadow` before accessing `shadowLayer` to avoid assertions.

5. **Style Masks**: Use `UIWindowStyleMaskBySetting()` helper to modify style masks instead of bitwise operations:
   ```objc
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
   ```

6. **GPU Synchronization**: Always call `[context barrier]` before using `imageWithFramebuffer:nameUTF8String:` to ensure GPU drawing is complete.

### Common Pitfalls

1. **Forgetting Headless Setup**: If tests fail with "Cannot create GLFW window" errors, you forgot to set up UINullOSWindow for headless testing.

2. **Backend Mismatch**: Don't mix SDL and GLFW headers/libraries in the same build. Use conditional compilation or separate build configurations.

3. **Late Backend Selection**: Calling `setOSWindowClass:` after windows are created will not affect existing windows and may cause crashes.

4. **Property Observable Side Effects**: Properties marked `observable` trigger KVO notifications. Be aware of reentrancy if observers modify state.

5. **Shadow Layer Lifecycle**: The shadow layer is retained by UIView; calling `setShowsShadow:NO` releases it. Don't keep dangling references.

6. **Context Activation**: Some operations require an active graphics context. Use `[window activateWindowGraphicsContext]` and `[window deactivateGraphicsContext:]` pairs.

### Idiomatic Usage

- **Category Pattern**: When extending functionality for a specific platform, follow the naming pattern `ClassName+BackendName.m` (e.g., `UIWindow+GLFW.m`).
- **Conditional Compilation**: Wrap backend-specific code in `#ifdef HAVE_IMPORT__MULLE_GLFW` to ensure portability.
- **Protocol Conformance**: Use categories to make classes conform to protocols without modifying their headers.

## 6. Integration Examples

### Example 1: Basic Window Creation with GLFW Backend

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;

   // GLFW is default, no explicit backend selection needed
   app       = [UIApplication sharedInstance];
   styleMask = UIWindowStyleMaskDefault;
   window    = [UIWindow windowWithFrame:CGRectMake( 0, 0, 640, 480)
                          titleUTF8String:"My Application"
                                styleMask:styleMask];
   [app addWindow:window];
   [app run];  // Enters event loop

   return( 0);
}
```

### Example 2: Headless Window for Testing

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;

   // Configure headless mode before creating windows
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

   // Test your logic here without OS window/GPU
   [window processOneFrame:0.016];  // Simulate frame

   [app terminate];
   return( 0);
}
```

### Example 3: View with Custom Drawing and Shadow

```objc
#import <MulleUIOS/MulleUIOS.h>

static void   customDraw( CGGraphicsLayer *layer, CGContext *context)
{
   CGRect   bounds;

   bounds = [layer bounds];
   [context setFillColor:CGColorMake( 0.2, 0.5, 0.8, 1.0)];
   [context fillRect:bounds];
}

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   UIView          *view;
   CAShadowLayer   *shadow;

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 640, 480)
                      titleUTF8String:"Shadow Demo"
                            styleMask:UIWindowStyleMaskDefault];

   view = [UIView viewWithFrame:CGRectMake( 100, 100, 200, 200)];
   [view setDrawCallback:customDraw];
   [view setBackgroundColor:CGColorMake( 1.0, 1.0, 1.0, 1.0)];
   [view setCornerRadius:10.0];

   // Enable shadow
   [view setShowsShadow:YES];
   shadow = [view shadowLayer];
   [shadow setShadowOffset:CGSizeMake( 5.0, 5.0)];
   [shadow setShadowBlur:8.0];

   [[window contentView] addSubview:view];
   [app addWindow:window];
   [app run];

   return( 0);
}
```

### Example 4: Offscreen Rendering to Image

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication           *app;
   UIWindow                *window;
   id <UIGraphicsContext>  context;
   id <UILayer>            framebuffer;
   id <UIImage>            image;
   NSUInteger              styleMask;

   app       = [UIApplication instance];
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleOffscreen, YES);

   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 256, 256)
                      titleUTF8String:NULL
                            styleMask:styleMask];
   [app addWindow:window];

   // Render content to offscreen framebuffer
   [window processOneFrame:0.016];

   // Get the framebuffer and create an image from it
   context     = [window renderGraphicsContext];
   framebuffer = [window framebuffer];

   [(CGContext *) context barrier];  // Ensure GPU is done
   image = [(CGContext *) context imageWithFramebuffer:framebuffer
                                        nameUTF8String:"offscreen"];

   // Now 'image' contains the rendered content
   // ... save or process image ...

   [app terminate];
   return( 0);
}
```

### Example 5: UINullWindow with Explicit CGContext

```objc
#import <MulleUIOS/MulleUIOS.h>

int   main( void)
{
   UIApplication           *app;
   id <UIWindow>           window;
   id <UIGraphicsContext>  context;
   UINullOSWindow          *osWindow;

   app = [UIApplication instance];

   // Create null OS window explicitly
   osWindow = [[[UINullOSWindow alloc] initWithFrame:CGRectMake( 0, 0, 64, 64)
                                      titleUTF8String:NULL
                                            styleMask:UIWindowStyleMaskDefault] autorelease];

   // Wrap in UINullWindow
   window = (id <UIWindow>) [[[UINullWindow alloc] initWithOSWindow:osWindow] autorelease];
   [app addWindow:window];

   // UINullWindow can still create a CGContext if needed
   context = [window renderGraphicsContext];
   if( ! context)
   {
      fprintf( stderr, "No graphics context\n");
      return( 1);
   }

   // Process frames for testing
   [window processOneFrame:0.016];

   [app terminate];
   return( 0);
}
```

## 7. Dependencies

MulleUIOS directly depends on:

- **MulleUIWindow** - Core window and view hierarchy, event handling, application lifecycle
- **MulleGraphics** - CALayer/CGGraphicsLayer rendering, CGContext, CGImage, NanoVG bindings
- **MulleGLFW** - GLFW window system bindings (GLFWOSWindow, event translation)
- **mulle-objc-list** - Runtime introspection tool (build-time dependency, not linked)

Optional backend alternatives:
- **MulleSDL** - SDL window system bindings (alternative to MulleGLFW)

All dependencies cascade their own dependencies (MulleObjC, mulle-core, etc.).
