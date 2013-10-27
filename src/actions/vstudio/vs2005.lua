--
-- actions/vstudio/vs2005.lua
-- Add support for the  Visual Studio 2005 project formats.
-- Copyright (c) 2008-2013 Jason Perkins and the Premake project
--

	premake.vstudio.vs2005 = {}
	local vs2005 = premake.vstudio.vs2005
	local vstudio = premake.vstudio


---
-- Register a command-line action for Visual Studio 2006.
---

	function vs2005.generateSolution(sln)
		io.eol = "\r\n"
		io.esc = vs2005.esc

		premake.generate(sln, ".sln", vstudio.sln2005.generate)
	end


	function vs2005.generateProject(prj)
		io.eol = "\r\n"
		io.esc = vs2005.esc

		if premake.project.isdotnet(prj) then
			premake.generate(prj, ".csproj", vstudio.cs2005.generate)
			premake.generate(prj, ".csproj.user", vstudio.cs2005.generate_user)
		elseif premake.project.iscpp(prj) then
			premake.generate(prj, ".vcproj", vstudio.vc200x.generate)
			premake.generate(prj, ".vcproj.user", vstudio.vc200x.generate_user)
		end
	end



---
-- Apply XML escaping on a value to be included in an
-- exported project file.
---

	function vs2005.esc(value)
		value = string.gsub(value, '&',  "&amp;")
		value = value:gsub('"',  "&quot;")
		value = value:gsub("'",  "&apos;")
		value = value:gsub('<',  "&lt;")
		value = value:gsub('>',  "&gt;")
		value = value:gsub('\r', "&#x0D;")
		value = value:gsub('\n', "&#x0A;")
		return value
	end



---
-- Define the Visual Studio 2005 export action.
---

	newaction {
		-- Metadata for the command line and help system

		trigger     = "vs2005",
		shortname   = "Visual Studio 2005",
		description = "Generate Visual Studio 2005 project files",

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
			productVersion      = "8.0.50727",
			solutionVersion     = "9",
		}
	}
