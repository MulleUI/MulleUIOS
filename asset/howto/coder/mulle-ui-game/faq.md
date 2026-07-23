<!-- keywords: faq, last-resort, common-mistakes, CGColor, setNeedsDisplay, polygon, gradient, pitch -->
# FAQ — Last Resort

Only consult this file when you have already read `index.md`, `quirks.md`,
`patterns.md`, and `drawing-api.md` — and are still stuck.

---

## "How do I draw a polygon / triangle / arbitrary shape?"

Use the path API. This is in `patterns.md`.

```objc
CGContextBeginPath( context);
CGContextMoveTo( context, CGPointMake( x1, y1));
CGContextLineTo( context, CGPointMake( x2, y2));
CGContextLineTo( context, CGPointMake( x3, y3));
CGContextClosePath( context);
CGContextFillWithColor( context, color);
```

## "How do I fill a polygon with a gradient?"

Set the gradient as fill, then fill the path:

```objc
CGContextBeginPath( context);
CGContextMoveTo( context, p1);
CGContextLineTo( context, p2);
CGContextLineTo( context, p3);
CGContextClosePath( context);
CGContextSetFillLinearGradient( context, start, end, startColor, endColor);
CGContextFill( context);
```

## "I changed a property but the layer doesn't redraw"

In a game loop with `UIWindowDisplayNeedsRedraw` set every frame, everything
redraws every frame. You do not need `setNeedsDisplay`. See `quirks.md`.

## "What is `CGColorRef`?"

It does not exist. `CGColor` is a struct (four floats, by value). See
`quirks.md` → "CGColor is a struct, not a pointer".

## "How do I render text from a custom .ttf file?"

Load it with `CGContextCreateFont`, then use it by face name:

```objc
CGContextCreateFont( context, "myfont", "path/to/MyFont.ttf");
CGContextFontFace( context, "myfont");
CGContextFontSize( context, 24);
CGContextText( context, point, "Hello", (size_t) -1);
```

## "MulleAudio: how do I just play a sound without pitch-shifting?"

```objc
[audio playVoice:voice duration:duration];
```

`pitchToFrequency:fromFrequency:ofVoice:` is for resampling a base waveform
to a different pitch. If your buffer already contains the complete sound, just
play it directly.
