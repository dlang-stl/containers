travis - linux [![Build Status](https://travis-ci.org/dlang-cpp-interop/stl-containers.svg?branch=master)](https://travis-ci.org/dlang-cpp-interop/stl-containers)

appveyor - windows [![Build status](https://ci.appveyor.com/api/projects/status/yrp0q22grqefvpcn/branch/master?svg=true)](https://ci.appveyor.com/project/LaeethIsharc/stl-containers/branch/master)

https://github.com/dlang/druntime/pull/2448

https://github.com/dlang/druntime/pull/2456

https://github.com/dlang/druntime/pull/2310


STATUS:

* almost builds on Windows - it just needs to fix the windows sdk reference.  however Manu says tests pass on Windows for vector, string, optional

TODO:

0. fix Windows build and CI
1. implementation for various containers on Linux not yet done/finished - gcc held back by internal struct pointer (awaiting opMove hook I think) and for clang the work just needs to be done.
2. osx, freebsd impl and build not done at all I think
3. implement unordered map
4. add builds for osx/bsd/android
5. std::optional only works for POD

