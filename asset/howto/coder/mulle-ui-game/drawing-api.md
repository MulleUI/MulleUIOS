<!-- keywords: drawing, API, reference, cheatsheet, CGContext, fill, stroke, circle, rect, line, rounded, gradient, text, font, path, transform, image, paint, color, CGColor, CGGradient, CGPaint, complete -->
# Complete Drawing API Reference

One-page reference of all drawing functions available in a game's
`drawInContext:` method. Header: `CGContext+DrawingConveniences.h` for
convenience functions, `CGContext+Drawing.h` for path-level drawing.

## Colors

```objc
// compile-time constant (use in static initializers)
CGColor c = CGColorDataWithRGBA( 1.0, 0.0, 0.0, 1.0);

// runtime creation
CGColor c = CGColorMakeWithRGBA( r, g, b, a);
CGColor w = CGColorMakeWhite();
CGColor b = CGColorMakeBlack();
CGColor t = CGColorMakeTransparent();
```

## Convenience drawing (CGContext+DrawingConveniences.h)

All take a `CGContext *context` as first arg.

### Shapes — fill

```objc
CGContextFillWithColor( ctx, color);                                    // fill entire canvas
CGContextFillRectWithColor( ctx, rect, color);
CGContextFillRoundedRectWithColor( ctx, rect, cornerRadius, color);
CGContextFillCircleWithColor( ctx, circle, color);                      // CACircle
CGContextFillCircleWithGradientColors( ctx, circle, outerColor, innerColor);
CGContextFillRoundedShadow( ctx, rect, cornerRadius, &shadow);
```

### Shapes — stroke

```objc
CGContextStrokeWithColor( ctx, strokeWidth, color);                     // stroke current path
CGContextStrokeRectWithColor( ctx, rect, strokeWidth, color);
CGContextStrokeInsideOfRectWithColor( ctx, rect, strokeWidth, color);
CGContextStrokeRoundedRectWithColor( ctx, rect, cornerRadius, strokeWidth, color);
CGContextStrokeInsideOfRoundedRectWithColor( ctx, rect, cornerRadius, strokeWidth, color);
CGContextStrokeCircleWithColor( ctx, circle, strokeWidth, color);
CGContextStrokeCircleWithGradientColors( ctx, circle, outerColor, innerColor, strokeWidth);
CGContextStrokeLineWithColor( ctx, start, end, strokeWidth, color);
CGContextStrokeLineHWithColor( ctx, point, width, strokeWidth, color);  // horizontal
CGContextStrokeLineVWithColor( ctx, point, height, strokeWidth, color); // vertical
```

### Text

```objc
// printf-style formatted text in a rect (most useful for games)
CGContextFormatInRect( ctx, rect, contentMode, options, "Score: %d", score);

// printf-style at a point
CGContextFormat( ctx, point, "FPS: %d", fps);

// raw text in rect with alignment
CGContextTextInRect( ctx, str, strlen(str), rect, contentMode, options);

// measure text bounds without drawing
struct CGTextBoundsInfo info = CGContextTextBoundsOptions( ctx, str, len, rect, contentMode, options);
```

`CGTextOptions` is a bitmask: `CGTextOptionDefault`, `CGTextOptionAlignVisually`,
`CGTextOptionAlignBaseline`, `CGTextOptionNoClip`, `CGTextOptionFill`.

Set font size and text color BEFORE calling text functions:

```objc
CGContextFontSize( ctx, 20);
CGContextTextColor( ctx, CGColorMakeWhite());
CGContextFormatInRect( ctx, rect, CGContentModeCenter, CGTextOptionDefault, "Score: %d", score);
```

`CGContentMode`: `CGContentModeCenter`, `CGContentModeTop`,
`CGContentModeTopLeft`, `CGContentModeBottom`, etc.

## Path-based drawing (CGContext+Drawing.h)

Build a path, then fill or stroke.

```objc
CGContextBeginPath( ctx);
CGContextMoveTo( ctx, startPoint);
CGContextLineTo( ctx, point);
CGContextBezierTo( ctx, cp1, cp2, endPoint);
CGContextQuadTo( ctx, controlPoint, endPoint);
CGContextArcTo( ctx, tangent1, tangent2, radius);
CGContextArc( ctx, circle, angle, rotation);
CGContextArcFromAngleToAngle( ctx, circle, startAngle, endAngle, direction);
CGContextRect( ctx, rect);
CGContextRoundedRect( ctx, rect, cornerRadius);
CGContextEllipse( ctx, center, rx, ry);
CGContextCircle( ctx, circle);
CGContextClosePath( ctx);

// then:
CGContextFillColor( ctx, color);
CGContextFill( ctx);
// or:
CGContextStrokeColor( ctx, color);
CGContextStrokeWidth( ctx, width);
CGContextStroke( ctx);
```

### Path options

```objc
CGContextLineCap( ctx, cap);       // CGLineCapButt, CGLineCapRound, CGLineCapSquare
CGContextLineJoin( ctx, join);     // CGLineJoinMiter, CGLineJoinRound, CGLineJoinBevel
CGContextMiterLimit( ctx, limit);
CGContextPathWinding( ctx, style); // CGPathFillStyleSolid, CGPathFillStyleHole
```

## Transforms

```objc
CGContextSave( ctx);                    // push state
CGContextRestore( ctx);                 // pop state
CGContextTranslate( ctx, point);
CGContextRotate( ctx, rotation);        // CARotation (0.0–1.0 = full turn)
CGContextScale( ctx, vector);           // CGVector
CGContextSkewX( ctx, angle);
CGContextSkewY( ctx, angle);
CGContextResetTransform( ctx);

// scoped save/restore (auto-restores at end of block)
CGContextDo( ctx)
{
   CGContextTranslate( ctx, offset);
   CGContextRotate( ctx, CARotation90);  // 0.25 = 90 degrees clockwise
   // ... draw rotated ...
}
```

## Gradient fills (paint-before-fill pattern)

Set the gradient paint, then draw a shape. The gradient fills the next
filled/stroked shape.

```objc
// linear gradient
CGContextSetFillLinearGradient( ctx, startPoint, endPoint, startColor, endColor);
CGContextSetStrokeLinearGradient( ctx, startPoint, endPoint, startColor, endColor);

// radial gradient
CGContextSetFillRadialGradient( ctx, outerCircle, outerColor, innerRadius, innerColor);
CGContextSetStrokeRadialGradient( ctx, outerCircle, outerColor, innerRadius, innerColor);

// box gradient (soft shadow/glow)
CGContextSetFillBoxGradient( ctx, rect, cornerRadius, color, feather, featherColor);
CGContextSetStrokeBoxGradient( ctx, rect, cornerRadius, color, feather, featherColor);

// image pattern
CGContextSetFillImagePattern( ctx, textureID, rect, rotation, alpha);
```

## CGGradient objects (as backgroundPaint)

```objc
CGGradient *g = [CGGradient gradientWithStartColor:c1 endColor:c2];

// transforms
[g reversedGradient];
[g rotatedGradient:rotation];
[g brightenedGradient:0.2];
[g dimmedGradient:0.3];
[g transparentGradient:0.5];
[g desaturatedGradient:0.5];

// use as view/layer background
[view setBackgroundPaint:g];
```

## Compositing

```objc
CGContextGlobalCompositeOperation( ctx, CGCompositeOperationSourceOver);
CGContextGlobalAlpha( ctx, 0.5);
```

## Images / textures

```objc
CGTextureID tex = CGContextCreateImage( ctx, "path/to/file.png", 0);
CGTextureID tex = CGContextCreateImageMem( ctx, flags, data, length);
CGTextureID tex = CGContextCreateImageRGBA( ctx, size, flags, pixelData);
CGPixelSize sz  = CGContextImageSize( ctx, tex);
CGContextUpdateImage( ctx, tex, newData);
CGContextDeleteImage( ctx, tex);
```

## Fonts

```objc
CGContextFontFace( ctx, "sans");        // set active font by name
CGContextFontSize( ctx, 24.0);
CGContextTextColor( ctx, color);
CGContextTextAlignment( ctx, UITextAlignmentCenter);
CGContextFontBlur( ctx, 1.0);           // shadow/glow effect

// measurement
CGTextMetrics m = CGContextTextMetrics( ctx);  // ascender, descender, lineHeight
CGRect bounds = CGContextTextVisualBounds( ctx, point, str, len);
```

## Scissoring (clip region)

```objc
CGContextScissor( ctx, rect);           // set clip rect
CGContextIntersectScissor( ctx, rect);  // narrow existing clip
CGContextResetScissor( ctx);            // remove clip
```

## Geometry helpers (mulle-geometry)

```objc
CACircle c = CACircleMakeWithCenterAndRadius( point, radius);
CGFloat overlap = CACircleOverlapWithCircle( a, b);
CGVector normal = CACircleCollisionNormal( a, b);
BOOL hit = CACircleIntersectsCircle( a, b);
CGPoint center = CGRectGetCenterPoint( rect);
```

## Quick pattern: game HUD

```objc
- (BOOL) drawInContext:(CGContext *) context
{
   CGRect   canvas = [self canvas];

   // background
   CGContextFillRectWithColor( context, canvas, CGColorMakeWithRGBA( 0, 0, 0, 0.7));

   // score (top-left)
   CGContextFontSize( context, 20);
   CGContextTextColor( context, CGColorMakeWhite());
   CGContextFormatInRect( context,
                          CGRectMake( 10, 10, 200, 30),
                          CGContentModeTopLeft,
                          CGTextOptionDefault,
                          "Score: %d", _score);

   // health bar
   CGContextFillRoundedRectWithColor( context,
                                      CGRectMake( 10, 50, 200 * _healthPct, 20),
                                      5.0,
                                      CGColorMakeWithRGBA( 0, 1, 0, 0.8));
   return( YES);
}
```
