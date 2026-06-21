<!-- keywords: debugger, game, quirks, framerate, silent, model state, rendering proof -->
# Quirks

## Model state is not rendering proof

Stdout output showing state changes (positions, counters, flags) only proves
that logic is running. It says nothing about whether pixels are being
presented. Do not declare "rendering confirmed" based on model-layer dumps.

Acceptable rendering proof:
- A frame counter that increments inside `displayFrameIfNeeded:`
- `[window frameRate]` is not `INFINITY`
- A visible change on screen

## `UIWindowFrameRateAsync` is silent — not an error

When `frameRate` is `INFINITY` and the window skips presentation, there is no
error, no log, no assertion. The draw callback runs, game logic executes, and
everything looks correct — except no frame ever reaches the screen.

## Run loop order matters

DrawAndSwap → FireTimers → PollEvents(sleep). The sleep duration is
`min(nextTimerFire, nextWindowDisplay)`. With `frameRate = INFINITY`,
`nextWindowDisplay` is never, so draws happen but nothing is ever presented.

## Input state is per-frame, not per-event

`[context mouseLocation]` gives you the mouse position at the start of this
frame, not a stream of events. If you need event granularity (drag tracking,
double-click detection), use the `UIView` responder chain.

## Retained vs non-retained affects debugging

`UIWindowStyleMaskNonRetained` (volatile) is easier to debug because it
runs single-threaded without a separate render thread. Use it during
development. Switch to retained for production if needed.
