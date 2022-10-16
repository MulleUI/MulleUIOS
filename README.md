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


## mulle-sde

This is a [mulle-sde](//github.com/mulle-sde) project. mulle-sde combines
recursive package management with cross-platform builds via **cmake**:

Action  | Command                               | Description
--------|---------------------------------------|---------------
Build   | `mulle-sde craft [--release|--debug]` | Builds into local `kitchen` folder
Add     | `mulle-sde dependency add --c --github MulleUI MulleUIOS` | Add MulleUIOS to another mulle-sde project as a dependency
Install | `mulle-sde install --prefix /usr/local https://github.com/MulleUI/MulleUIOS.git` | Like `make install`


### Manual Installation


Install the requirements:

Requirements                                        | Description
----------------------------------------------------|-----------------------
[MulleGraphics](//github.com/MulleUI/MulleGraphics) | pulls in nanovg
[MulleGLFW](//github.com/MulleUI/MulleGLFW)         | pulls in glfw
[MulleUIWindow](//github.com/MulleUI/MulleUIWindow) | generic view/window code

Install into `/usr/local`:

``` sh
cmake -B build \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_PREFIX_PATH=/usr/local \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


<!--
extension : mulle-sde/sde
directory : demo/library
template  : .../README.md
Suppress this comment with `export MULLE_SDE_GENERATE_FILE_COMMENTS=NO`
-->
