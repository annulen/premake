--
-- dmd.lua
-- Provides GCC-specific configuration strings.
-- Copyright (c) 2002-2011 Jason Perkins and the Premake project
--


	premake.tools.dmd = { }
	local dmd = premake.tools.dmd
	local project = premake5.project
	local config = premake5.config

	premake.dmd = dmd
--
-- Set default tools
--

	dmd.dc    = premake.DMD
	dmd.ar    = "ar"


--
-- Translation of Premake flags into GCC flags
--

	local flags =
	{
		ExtraWarnings   = "-w",
		Optimize        = "-O",
		Symbols         = "-g",
		SymbolsLikeC    = "-gc",
		Release         = "-release",
		Documentation   = "-D",
		PIC             = "-fPIC",
		Inline          = "-inline",
		GenerateHeader  = "-H",
		GenerateMap     = "-map",
		NoBoundsCheck   = "-noboundscheck",
		NoFloat         = "-nofloat",
		RetainPaths     = "-op",
		Profile         = "-profile",
		Quiet           = "-quiet",
		Verbose         = "-v",
		Test            = "-unittest",
		GenerateJSON    = "-X",
		CodeCoverage    = "-cov",
	}


--
-- DMD flags
--

	dmd.sysflags = 
	{
		universal = {
			flags    = "",
			ldflags  = "", 
		},
		x32 = { 
			flags    = "-m32",
			ldflags  = "-L-L/usr/lib", 
		},
		x64 = { 
			flags    = "-m64",
			ldflags  = "-L-L/usr/lib64",
		}
	}

	function dmd.getsysflags(cfg, field)
		local result = {}

		-- merge in system-level flags
		local system = dmd.sysflags[cfg.system]
		if system then
			result = table.join(result, system[field])
		end

		-- merge in architecture-level flags
		local arch = dmd.sysflags[cfg.architecture]
		if arch then
			result = table.join(result, arch[field])
		end

		return result
	end



--
-- Returns the target name specific to compiler
--

	function dmd.gettarget(name)
		return "-of" .. name
	end


--
-- Returns the object directory name specific to compiler
--

	function dmd.getobjdir(name)
		return "-od" .. name
	end


--
-- Returns a list of compiler flags, based on the supplied configuration.
--

	function dmd.getflags(cfg)
		local flags = dmd.getsysflags(cfg, 'flags')

		--table.insert( f, "-v" )
		if cfg.kind == premake.STATICLIB then
			table.insert( flags, "-lib" )
		elseif cfg.kind == premake.SHAREDLIB then
			table.insert( flags, "-shared" )
			if cfg.system ~= premake.WINDOWS then
				table.insert( flags, "-fPIC" )
			end
		end

		if premake.config.isdebugbuild( cfg ) then
			table.insert( flags, "-debug" )
		else
			table.insert( flags, "-release" )
		end

		return flags
	end


	--
	-- Returns a list of linker flags, based on the supplied configuration.
	--

	function dmd.getldflags(cfg)
		local flags = {}

		local sysflags = dmd.getsysflags(cfg, 'ldflags')
		flags = table.join(flags, sysflags)

		return flags
	end


	--
	-- Return a list of library search paths.
	--

	function dmd.getlibdirflags(cfg)
		local result = {}

		for _, value in ipairs(premake.getlinks(cfg, "all", "directory")) do
			table.insert(result, '-L-L' .. _MAKE.esc(value))
		end

		return result
	end


	--
	-- Returns a list of linker flags for library names.
	--

	function dmd.getlinks(cfg)
		local result = {}

		local links = config.getlinks(cfg, "dependencies", "object")
		for _, link in ipairs(links) do
			-- skip external project references, since I have no way
			-- to know the actual output target path
			if not link.project.externalname then
				local linkinfo = config.getlinkinfo(link)
				if link.kind == premake.STATICLIB then
					-- Don't use "-l" flag when linking static libraries; instead use 
					-- path/libname.a to avoid linking a shared library of the same
					-- name if one is present
					table.insert(result, project.getrelative(cfg.project, linkinfo.abspath))
				else
					table.insert(result, "-L-l" .. linkinfo.basename)
				end
			end
		end

		-- The "-l" flag is fine for system libraries
		links = config.getlinks(cfg, "system", "basename")
		for _, link in ipairs(links) do
			if path.isframework(link) then
				table.insert(result, "-L-framework " .. path.getbasename(link))
			elseif path.isobjectfile(link) then
				table.insert(result, link)
			elseif path.hasextension(link, premake.systems[cfg.system].staticlib.extension) then
				table.insert(result, link)
			else
				table.insert(result, "-L-l" .. link)
			end
		end

		return result

	end


	--
	-- Decorate defines for the DMD command line.
	--

	function dmd.getdefines(defines)
		local result = { }
		for _,def in ipairs(defines) do
			table.insert(result, '-version=' .. def)
		end
		return result
	end


	--
	-- Decorate include file search paths for the GCC command line.
	--

	function dmd.getincludedirs(cfg)
		local result = {}
		for _, dir in ipairs(cfg.includedirs) do
			table.insert(result, "-I" .. project.getrelative(cfg.project, dir))
		end
		return result
	end

