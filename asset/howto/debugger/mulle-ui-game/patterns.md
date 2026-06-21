<!-- keywords: debugger, game, patterns, diagnostic, framerate, input, rendering -->
# Patterns

## Minimal rendering proof

```objc
static int   frameCount;

static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   frameCount++;
   CGContextFillRectWithColor( context,
                               CGRectMake( 0, 0, 100, 100),
                               CGColorCreateGenericRGB( 1, 0, 0, 1));
   if( frameCount % 60 == 0)
      fprintf( stderr, "frame %d\n", frameCount);
   return( YES);
}
```

If `frame N` prints but nothing appears, the problem is framerate setup.

## Input diagnostic

```objc
static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   CGPoint   mouse;
   int       buttons;

   mouse   = [context mouseLocation];
   buttons = [context buttonStates];
   fprintf( stderr, "mouse: %.0f,%.0f buttons: %d\n",
            mouse.x, mouse.y, buttons);
   return( YES);
}
```

If mouse is always `0,0` while cursor is over the window, the context is
wrong or the window is not receiving events.

## Framerate gate check

```objc
// Add before run loop or after window creation:
fprintf( stderr, "frameRate: %f\n", [window frameRate]);
if( [window frameRate] == INFINITY)
   fprintf( stderr, "WARNING: frameRate is INFINITY, nothing will render!\n");
```

## View hierarchy diagnostic

```objc
// Check if views are wired correctly
UIView   *content = [window contentView];
fprintf( stderr, "contentView: %p frame: %s\n",
         content, CGRectCStringDescription( [content frame]));
fprintf( stderr, "subviews: %ld\n", (long) [[content subviews] count]);
```

## Collision diagnostic

```objc
// Test tracking area intersection at a known rect
UITrackingArea   *areas[16];
NSUInteger        count;

count = [window getTrackingAreasIntersectingRect:CGRectMake( 90, 90, 20, 20)
                                           areas:areas
                                        maxAreas:16];
fprintf( stderr, "intersecting areas at (90,90,20,20): %lu\n",
         (unsigned long) count);
```
