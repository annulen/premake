--
-- tests/test_gdc.lua
-- Automated test suite for the GCC toolset interface.
-- Copyright (c) 2009-2011 Jason Perkins and the Premake project
--

	T.gdc = { }
	local suite = T.gdc

	local cfg
	function suite.setup()
		cfg = { }
        cfg.dc         = premake.gdc
		cfg.basedir    = "."
		cfg.location   = "."
		cfg.language   = "D"
		cfg.project    = { name = "MyProject" }
		cfg.flags      = { }
		cfg.objectsdir = "obj"
		cfg.platform   = "Native"
		cfg.links      = { }
		cfg.libdirs    = { }
		cfg.linktarget = { fullpath="libMyProject.a" }
	end


--
-- FLAGS tests
--

	function suite.flags_x32()
		cfg.system = "windows"
		cfg.platform = "x32"
		local r = premake.gdc.getflags(cfg)
		test.isequal("-m32 -frelease", table.concat(r, " "))
	end

	function suite.flags_x32_SharedLib()
		cfg.system = "linux"
		cfg.platform = "x32"
        cfg.kind = "SharedLib"
		local r = premake.gdc.getflags(cfg)
		test.isequal("-m32 -fPIC -shared -frelease", table.concat(r, " "))
	end

	function suite.flags_x64()
		cfg.system = "linux"
		cfg.platform = "x64"
		local r = premake.gdc.getflags(cfg)
		test.isequal("-m64 -frelease", table.concat(r, " "))
	end

	function suite.flags_Optimize()
		cfg.system = "linux"
		cfg.flags = { "Optimize" }
		local r = premake.gdc.getflags(cfg)
		test.isequal("-O2  -frelease", table.concat(r, " "))
	end
--
-- DEFINES test
--

	function suite.defines_AsVersion()
		cfg.defines = { "abc" }
		local r = premake.gdc.getdefines(cfg.defines)
		test.isequal("-fversion=abc", table.concat(r, " "))
	end

--
-- LDFLAGS tests
--

	function suite.ldflags_SharedLib_Linux()
		cfg.kind = "SharedLib"
		cfg.system = "linux"
		local r = premake.gdc.getldflags(cfg)
		test.isequal('', table.concat(r,"|"))
	end

-- 
-- DFLAGS test
--

	function suite.flags_IsStaticLib()
		cfg.kind = "StaticLib"
		cfg.system = "linux"
		local r = premake.gdc.getflags(cfg)
		test.isequal(" -static -frelease", table.concat(r," "))
	end



