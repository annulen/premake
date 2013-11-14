--
-- tests/actions/vstudio/vc200x/test_manifest_block.lua
-- Validate generation of VCManifest elements Visual Studio 200x C/C++ projects.
-- Copyright (c) 2009-2013 Jason Perkins and the Premake project
--

	local suite = test.declare("vs200x_manifest_block")
	local vc200x = premake.vstudio.vc200x


--
-- Setup/teardown
--

	local sln, prj

	function suite.setup()
		_ACTION = "vs2008"
		sln, prj = test.createsolution()
	end

	local function prepare()
		local cfg = test.getconfig(prj, "Debug")
		vc200x.VCManifestTool(cfg)
	end


--
-- The manifest tool should empty if there are no manifest files.
--

	function suite.isEmpty_onNoManifests()
		files { "hello.c" }
		prepare()
		test.capture [[
			<Tool
				Name="VCManifestTool"
			/>
		]]
	end


--
-- If manifest file(s) are present, they should be listed.
--

	function suite.listsFiles_onManifests()
		files { "hello.c", "project1.manifest", "goodbye.c", "project2.manifest" }
		prepare()
		test.capture [[
			<Tool
				Name="VCManifestTool"
				AdditionalManifestFiles="project1.manifest;project2.manifest"
			/>
		]]
	end