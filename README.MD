travis - linux [![Build Status](https://travis-ci.org/dlang-cpp-interop/stl-containers.svg?branch=master)](https://travis-ci.org/dlang-cpp-interop/stl-containers)

appveyor - windows [![Build status](https://ci.appveyor.com/api/projects/status/yrp0q22grqefvpcn/branch/master?svg=true)](https://ci.appveyor.com/project/LaeethIsharc/stl-containers/branch/master)


Original pull requests
----------------------
https://github.com/dlang/druntime/pull/2448

https://github.com/dlang/druntime/pull/2456

https://github.com/dlang/druntime/pull/2310


STATUS
------

* almost builds on Windows - just need to install Visual D on CI.  however Manu says tests pass on Windows for vector, string, optional


TODO
-----

Build
=====

Finish Windows Build and CI - need to install Visual D from command line (@rmanthorpe)
Write builds for Linux, Android, OSX, FreeBSD

Implementation
==============

1. Key container not implemented at all yet: unordered map
2. std::string and std:optional complete for Linux and Windows
3. std::vector is only complete for Windows and should be done for Posix, OSX, BSD.  gcc held back by internal struct pointer (awaiting implementation of OpMove hook); clang just needs somebody to do the work.
4. std::string and std::optional are implemented on Windows and Linux and should be done for Posix, OSX, (BSD?)
5. std::optional only works for POD due to D unions

Tests
=====
* tests pass only for Windows currently and only on Manu's machine (maybe others, but nobody has checked yet)


Contributing
------------
Pull requests welcomed.


Code of conduct
---------------
Same as the D forum - be civilised.

