--
-- actions/vstudio/vs2008.lua
-- Add support for the Visual Studio 2008 project formats.
-- Copyright (c) 2008-2013 Jason Perkins and the Premake project
--

	premake.vstudio.vs2008 = {}
	local vs2008 = premake.vstudio.vs2008
	local vstudio = premake.vstudio


---
-- Define the Visual Studio 2008 export action.
---

	newaction {
		-- Metadata for the command line and help system

		trigger     = "vs2008",
		shortname   = "Visual Studio 2008",
		description = "Generate Visual Studio 2008 project files",

		-- Visual Studio always uses Windows path and naming conventions

		os = "windows",

		-- The capabilities of this action

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib", "Makefile", "None" },
		valid_languages = { "C", "C++", "C#" },
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		-- Solution and project generation logic

		onsolution = vstudio.vs2005.generateSolution,
		onproject  = vstudio.vs2005.generateProject,

		oncleansolution = vstudio.cleanSolution,
		oncleanproject  = vstudio.cleanProject,
		oncleantarget   = vstudio.cleanTarget,

		-- This stuff is specific to the Visual Studio exporters

		vstudio = {
			csprojSchemaVersion = "2.0",
			productVersion      = "9.0.30729",
			solutionVersion     = "10",
			versionName         = "2008",
			toolsVersion        = "3.5",
		}
	}
