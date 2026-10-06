### 0.1.1

Various small improvements

## 0.1.0



feature: add Metal graphics backend support and version API

* new `CG_METAL` backend for macOS using a `GLFW_NO_API` window rendered via CAMetalLayer
* new `glfw-metal` build configuration for the Metal backend
* new `MulleUIOSGetVersion()` API returning the MulleUIOS version
* no-draw windows now always route to a CGNullContext regardless of window style


### 0.0.1

Various small improvements
