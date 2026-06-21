<!-- keywords: debugger, game, nothing renders, framerate, silent, UIWindowFrameRateAsync, black screen -->
# MulleUI game debugging

Use this when a game builds but does not render, animate, or respond to input.

## Understand first

```bash
mulle-sde howto cat mulle-ui-app-construction
mulle-sde api apropos UIWindowFrameRate
mulle-sde code search displayFrameIfNeeded
mulle-sde code search mouseLocation
```

## Main fault lines

| Symptom | Likely cause | Check |
| --- | --- | --- |
| Builds, runs, black screen | Framerate is `INFINITY` | `[window frameRate]` |
| Logic runs but nothing animates | Framerate gate skipping frames | Set explicit Hz or Synced |
| Mouse input always (0,0) | Polling outside draw callback | Move to inside callback |
| Input works but no visual response | Missing `setNeedsDisplay` or draw not using state | Verify render reads state |
| Collision never triggers | Views not in hierarchy or zero-size | Check view frames and superview |

## Diagnostic flow

### Step 1 — Is the framerate set?

```objc
NSLog(@"frameRate: %f", [window frameRate]);
```

If it returns `INFINITY`, nothing will ever be presented. Fix:

```objc
[window setFrameRateSynced];
```

If using `UIApplicationRunDrawCallbackHz`, check that the last parameter is
not `UIWindowFrameRateAsync` (which is `INFINITY`).

### Step 2 — Is the draw callback being called?

Add a frame counter or `NSLog` inside the callback. If it increments but
nothing appears on screen, the framerate gate is the problem (step 1).

### Step 3 — Is input reaching the game?

Log `[context mouseLocation]` and `[context buttonStates]` inside the draw
callback. If mouse is always (0,0), verify the context is the one passed to
the callback, not a stale reference.

### Step 4 — Are views receiving events?

If using the structured `UIView` path, verify:
- The view is in the window's view hierarchy
- `[view isUserInteractionEnabled]` is YES
- The view's frame is non-zero and visible
- The window has become key window

## Local workflow

- Start with the simplest reproduction: `UIApplicationRunDrawCallbackHz` with
  a hardcoded colored rectangle. If that doesn't render, the problem is
  window/framerate setup.
- Once basic rendering works, add input. If input fails, the problem is
  context access or responder chain wiring.
- Only then add game logic.
