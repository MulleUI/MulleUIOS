# MulleUIOS

#### 💻📱 MulleUIOS provides platform/OS specifica

This project ties the underlying window system, graphics context and drawing
library together. In theory this could be some kind of ncurses windowing,
with an ASCII renderere, but in practicality it's this:

OS      | Windows | Drawing      | State
--------|---------|--------------|-------
android | ???     | nanovg       | Planned
darwin  | GLFW    | nanovg.metal | Experimental
ios     | ???     | nanovg.metal | Planned
linux   | GLFW    | nanovg       | Works
windows | GLFW    | nanovg.d311  | Planned


The project is relatively bare, the interesting part of the project
is the sourcetree.


## mulle-sde

This is a [mulle-sde](//github.com/mulle-sde) project. mulle-sde combines
recursive package management with cross-platform builds via **cmake**:

Action  | Command                               | Description
--------|---------------------------------------|---------------
Build   | `mulle-sde craft [--release|--debug]` | Builds into local `kitchen` folder
Add     | `mulle-sde dependency add --c --github <|GITHUB_USER|> MulleUIOS` | Add MulleUIOS to another mulle-sde project as a dependency
Install | `mulle-sde install --prefix /usr/local https://github.com/<|GITHUB_USER|>/MulleUIOS.git` | Like `make install`


### Manual Installation


Install the requirements:

Requirements                                      | Description
--------------------------------------------------|-----------------------
[some-requirement](//github.com/some/requirement) | Some requirement

Install into `/usr/local`:

```
mkdir build 2> /dev/null
(
   cd build ;
   cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
         -DCMAKE_PREFIX_PATH=/usr/local \
         -DCMAKE_BUILD_TYPE=Release .. ;
   make install
)
```


<!--
extension : mulle-sde/sde
directory : demo/library
template  : .../README.md
Suppress this comment with `export MULLE_SDE_GENERATE_FILE_COMMENTS=NO`
-->
