#import <MulleUIOS/MulleUIOS.h>

//
// Valgrind notes (Linux/Wayland/NVIDIA):
//
// This test produces valgrind errors that are all inside third-party libraries
// and not caused by our code:
//
// 1. "Syscall param write(buf) points to unaddressable byte(s)" at address 0x3
//    inside libnvidia-egl-wayland.so during _glfwCreateContextEGL and
//    destroyContextEGL. Likely caused by valgrind's inability to model the
//    NVIDIA driver's ioctl (0x644f) — valgrind itself warns "this could cause
//    spurious value errors to appear."
//
// 2. Leaks in libwayland-client.so (wp_viewporter_get_viewport,
//    wp_fractional_scale_manager_v1_get_fractional_scale) — GLFW/Wayland
//    proxy objects not fully cleaned up by glfwDestroyWindow.
//
// 3. Leak in libwayland-client.so (wl_display_create_queue) — allocated during
//    NVIDIA EGL init, never freed by the driver.
//
// 4. Leak in libdbus-1.so (dbus_bus_register) — one-time D-Bus allocation
//    triggered by NVIDIA EGL initialization, never freed.
//
// None of these are actionable in our code. A valgrind suppression file
// could silence them.
//
// -- Kiro AI, 2026-08-06
//


int   main( int argc, char *argv[])
{
   UIApplication           *app;
   UIWindow                *window;
   NSUInteger              styleMask;
   id <UIGraphicsContext>  context;

   app        = [UIApplication instance];

   assert( ! UIApp); // because we don't use sharedInstance
   styleMask  = UIWindowStyleMaskDefault;
   styleMask &= ~UIWindowStyleRetained;
   styleMask |= UIWindowStyleHidden;
   window     = [UIWindow windowWithFrame:CGRectMake( 0, 0, 100, 100)
                          titleUTF8String:NULL
                                styleMask:styleMask];
   assert( ! UIApp); // because we don't use convenience constructor
   [app addWindow:window];

   context = [window activateWindowGraphicsContext];
   [window deactivateGraphicsContext:context];

   [app terminate];

   return( 0);
}


/*
 * extension : mulle-sde/objc-test-library-demo
 * directory : demo/all
 * template  : .../noleak.m
 * Suppress this comment with `export MULLE_SDE_GENERATE_FILE_COMMENTS=NO`
 */
