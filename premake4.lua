--
-- Premake 5.x build configuration script
-- Use this script to configure the project with Premake4.
--

--
-- Define the project. Put the release configuration first so it will be the
-- default when folks build using the makefile. That way they don't have to
-- worry about the /scripts argument and all that.
--

	solution "Premake5"
		configurations { "Release", "Debug" }
		location ( _OPTIONS["to"] )

	project "Premake5"
		targetname  "premake5"
		language    "C"
		kind        "ConsoleApp"
		flags       { "No64BitChecks", "ExtraWarnings", "StaticRuntime" }
		includedirs { "src/host/lua-5.1.4/src" }

		files
		{
			"*.txt", "**.lua",
			"src/**.h", "src/**.c",
			"src/host/scripts.c"
		}

		excludes
		{
			"src/host/lua-5.1.4/src/lua.c",
			"src/host/lua-5.1.4/src/luac.c",
			"src/host/lua-5.1.4/src/print.c",
			"src/host/lua-5.1.4/**.lua",
			"src/host/lua-5.1.4/etc/*.c",
			"src/host/lua-5.1.4/src/lauxlib.c"
		}

		configuration "Debug"
			targetdir   "bin/debug"
			defines     "_DEBUG"
			flags       { "Symbols" }

		configuration "Release"
			targetdir   "bin/release"
			defines     "NDEBUG"
			flags       { "OptimizeSize" }

		configuration "vs*"
			defines     { "_CRT_SECURE_NO_WARNINGS" }

		configuration "vs2005"
			defines	{"_CRT_SECURE_NO_DEPRECATE" }

		configuration "windows"
			links { "ole32" }

		configuration "linux or bsd or hurd"
			defines     { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
			links       { "m" }
			linkoptions { "-rdynamic" }

		configuration "linux or hurd"
			links       { "dl" }

		configuration "macosx"
			defines     { "LUA_USE_MACOSX" }
			links       { "CoreServices.framework" }

		configuration { "macosx", "gmake" }
			-- toolset "clang"  (not until a 5.0 binary is available)
			buildoptions { "-mmacosx-version-min=10.4" }
			linkoptions  { "-mmacosx-version-min=10.4" }

		configuration { "solaris" }
			linkoptions { "-Wl,--export-dynamic" }

		configuration "aix"
			defines     { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
			links       { "m" }


--
-- A more thorough cleanup.
--

	if _ACTION == "clean" then
		os.rmdir("bin")
		os.rmdir("build")
	end



--
-- Use the --to=path option to control where the project files get generated. I use
-- this to create project files for each supported toolset, each in their own folder,
-- in preparation for deployment.
--

	newoption {
		trigger = "to",
		value   = "path",
		description = "Set the output location for the generated files"
	}



--
-- Use the embed action to convert all of the Lua scripts into C strings, which
-- can then be built into the executable. Always embed the scripts before creating
-- a release build.
--

	dofile("scripts/embed.lua")

	newaction {
		trigger     = "embed",
		description = "Embed scripts in scripts.c; required before release builds",
		execute     = doembed
	}


--
-- Use the release action to prepare source and binary packages for a new release.
-- This action isn't complete yet; a release still requires some manual work.
--


	dofile("scripts/release.lua")

	newaction {
		trigger     = "release",
		description = "Prepare a new release (incomplete)",
		execute     = dorelease
	}
