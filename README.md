# MulleUIOS

#### 💻📱 MulleUIOS provides platform/OS specifica


# MulleUIOS

#### 💻📱 MulleUIOS provides platform/OS specifica


===
MEMO: This is actually MulleUIOSGLFWNanoVG or so, there needs to be another
      project called MulleUISDLNanoVG or MulleUISDLSkia that mixes backend
      and drawing library. (Or use different configs ?)
===

This project ties the underlying window system, graphics context and drawing
library together. In theory this could be on top of some kind of ncurses
windowing, with an ASCII renderer. But in practicality it's probably this:

OS      | Windows | Drawing      | State
--------|---------|--------------|-------
android | ???     | nanovg       | Planned
darwin  | GLFW    | nanovg.metal | Experimental
ios     | ???     | nanovg.metal | Planned
linux   | GLFW    | nanovg       | Works
windows | GLFW    | nanovg.d311  | Planned


The project itself is relatively bare, except for glue code. For instance
CALayer is made a UILayer in MulleUIOS.

Also this project contains quite a few leak and functionality tests.





| Release Version                                       | Release Notes
|-------------------------------------------------------|--------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleUIOS.svg?branch=release) [![Build Status](https://github.com/MulleUI/MulleUIOS/workflows/CI/badge.svg?branch=release)](//github.com/MulleUI/MulleUIOS/actions) | [RELEASENOTES](RELEASENOTES.md) |






### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleUIOS to your project:

``` sh
mulle-sde add github:MulleUI/MulleUIOS
```

To only add the sources of MulleUIOS with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleUIOS
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

### Install with mulle-sde

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleUIOS and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleUIOS/archive/latest.tar.gz
```

### Manual Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleGraphics](https://github.com/MulleUI/MulleGraphics)             | 🌠 MulleGraphics provides CALayer subclasses
| [MulleGLFW](https://github.com/MulleUI/MulleGLFW)             | 🌐 MulleGLFW provides platform windows and events
| [MulleUIFrame](https://github.com/MulleUI/MulleUIFrame)             | 🛸 MulleUIFrame gives MulleUIWindow access to its framebuffer
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleUIOS/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleUIOS/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleUIOS** into `/usr/local` with [cmake](https://cmake.org):

``` sh
cmake -B build \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_PREFIX_PATH=/usr/local \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  



