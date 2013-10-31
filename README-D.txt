PREMAKE
A build configuration tool

 Copyright (C) 2002-2011 by Jason Perkins
 Distributed under the terms of the BSD License, see LICENSE.txt

 The Lua language and runtime library is (C) TeCGraf, PUC-Rio.
 See their website at http://www.lua.org/


 See the file BUILD.txt for instructions on building Premake.


 For questions, comments, or more information, visit the project
 website at http://industriousone.com/premake


 Building D Projects
 ===================

 Support is now available to configure and build D language projects.
 These projects are identified by the tool when the language 
 configuration setting is "D".

 The DigitalMars DMD, GDC and LDC compilers are supported through
 GNU makefile's, and Visual Studio projects via the Visual-D plugin.

 Note that D language support is experimental and works for small projects
 but does not currently support documentation generation, for example.

 Example
 -------

 Let's suppose we have a simple project called 'proj' whose layout is as follows

    proj
      |
      +- src/
          |
          +- main.d
          |
          +- proj.d

 We can simply generate an executable using a 'premake4.lua' script as follows:

 solution "proj"
	configurations { "debug", "release" }

	configuration "debug"
		flags { "Symbols" }     -- turns on '-debug'
        buildoptions { "-gc" }  -- pass through to compiler

	configuration "release"
		flags { "Optimize" } -- turns on '-O -release'

	project "proj"
		kind "ConsoleApp"
		language "D"         -- enables D language processing
		files { "src/*.d" }

 then

    $ premake4 gmake
    $ make

 and a 'proj' executable should be your reward :-)


 Build Mappings
 --------------
 Depending on the build kind, certain flags are enabled:

 --------------------------------------------------------------------
 | Premake kind                 | DMD Flag         | GDC Flag       |
 --------------------------------------------------------------------
 | StaticLib                    | -lib             | -static        |
 | SharedLib                    | n/a              | -shared        |
 | ConsoleApp                   |                  |                |
 | WindowedApp                  |                  |                |
 --------------------------------------------------------------------

 All Premake 'defines' (see http://industriousone.com/defines) turn into 
 D version identifiers. So:

    defines { "abc", "def" }    becomes

    DMD: -version=abc -version=def
    GDC: -fversion=abc -fversion=def

 There is no easy mechanism to support "-debug=..." constructs, so this must
 currently be done with 'buildoptions' directly.

 Premake supports a set of flags that map to (it appears) Visual Studio
 flags on the whole.

 --------------------------------------------------------------------
 | Premake flag                 | DMD Flag         | GDC Flag       |
 --------------------------------------------------------------------
 | DebugEnvsDontMerge           |                  |                |
 | DebugEnvsInherit             |                  |                |
 | EnableSSE                    |                  |                |
 | EnableSSE2                   |                  |                |
 | ExtraWarnings                | -w               | -w             |
 | FatalWarnings                |                  |                |
 | FloatFast                    |                  |                |
 | FloatStrict                  |                  |                |
 | Managed                      |                  |                |
 | MFC                          |                  |                |
 | NativeWChar                  |                  |                |
 | No64BitChecks                |                  |                |
 | NoEditAndContinue            |                  |                |
 | NoExceptions                 |                  |                |
 | NoFramePointer               |                  |                |
 | NoImportLib                  |                  |                |
 | NoIncrementalLink            |                  |                |
 | NoManifest                   |                  |                |
 | NoMinimalRebuild             |                  |                |
 | NoNativeWChar                |                  |                |
 | NoPCH                        |                  |                |
 | NoRTTI                       |                  |                |
 | Optimize                     | -O               | -O2            |
 | OptimizeSize                 |                  |                |
 | OptimizeSpeed                |                  |                |
 | SEH                          |                  |                |
 | StaticRuntime                |                  |                |
 | Symbols                      | -g -debug        | -g -fdebug     |
 | Unicode                      |                  |                |
 | Unsafe                       |                  |                |
 | WinMain                      |                  |                |
 --------------------------------------------------------------------

 Additional build flags may be passed through via the use of
    buildoptions    http://industriousone.com/buildoptions
    linkoptions     http://industriousone.com/linkoptions


