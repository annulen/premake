--
-- actions/vstudio/monodevelop.lua
-- Add support for the MonoDevelop project formats.
-- Copyright (c) 2009-2013 Manu Evans and the Premake project
--

	premake.vstudio.monodevelop = {}
	local monodevelop = premake.vstudio.monodevelop
	local vs2010 = premake.vstudio.vs2010
	local vstudio = premake.vstudio



--
-- Write out contents of the SolutionProperties section; currently unused.
--

	function monodevelop.solutionProperties(sln)
		_p('\tGlobalSection(MonoDevelopProperties) = preSolution')
		if sln.startupproject then
			for prj in solution.eachproject_ng(sln) do
				if prj.name == sln.startupproject then
-- TODO: fix me!
--					local prjpath = vstudio.projectfile_ng(prj)
--					prjpath = path.translate(path.getrelative(slnpath, prjpath))
--					_p('\t\tStartupItem = %s', prjpath )
				end
			end
		end
		_p('\tEndGlobalSection')
	end



---
-- Identify the type of project being exported and hand it off
-- the right generator.
---

	function monodevelop.generateProject(prj)
		io.eol = "\r\n"
		io.esc = vs2010.esc

		if premake5.project.isdotnet(prj) then
			premake.generate(prj, ".csproj", vstudio.cs2005.generate_ng)
			premake.generate(prj, ".csproj.user", vstudio.cs2005.generate_user_ng)
		else
			premake.generate(prj, ".cproj", vstudio.monodevelop.generate)
		end
	end



--
-- Define the MonoDevelop export action.
--

	newaction {
		-- Metadata for the command line and help system

		trigger         = "monodevelop",
		shortname       = "MonoDevelop",
		description     = "Generate MonoDevelop project files (experimental)",

		-- temporary, until I can phase out the legacy implementations

		isnextgen = true,

		-- The capabilities of this action

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		valid_languages = { "C", "C++", "C#" },
		valid_tools     = {
			cc     = { "gcc"   },
			dotnet = { "msnet" },
		},

		-- Solution and project generation logic

		onsolution = vstudio.vs2005.generateSolution,
		onproject  = vstudio.monodevelop.generateProject,

		oncleansolution = vstudio.cleanSolution,
		oncleanproject  = vstudio.cleanProject,
		oncleantarget   = vstudio.cleanTarget

		-- This stuff is specific to the Visual Studio exporters

		vstudio = {
			csprojSchemaVersion = "2.0",
			productVersion      = "10.0.0",
			solutionVersion     = "11",
			versionName         = "2010",
			targetFramework     = "4.0",
			toolsVersion        = "4.0",
		}
	}
