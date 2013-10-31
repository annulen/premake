--
-- make_d.lua
-- Generate a D project makefile.
-- Copyright (c) 2002-2009 Andrew Gough and the Premake project
--

    premake.make.d = { }
    local make = premake.make
    local d = premake.make.d
    local project = premake5.project
    local config = premake5.config


    function d.generate(prj)

--        table_print( prj )

        d.header(prj)

        -- main build rule(s)
        _p('.PHONY: clean prebuild prelink')
        _p('')

		for cfg in project.eachconfig(prj) do
			d.config(cfg)
		end
		
		-- list intermediate files
		d.objects(prj)

		_p('all: $(TARGETDIR) $(OBJDIR) prebuild prelink $(TARGET)')
		_p('\t@:')
		_p('')


		_p('$(TARGET): $(FILES)')
		_p('\t@echo Building %s...', prj.name)
		_p('\t$(SILENT) $(BUILDCMD) $(FILES)')
		_p('\t$(POSTBUILDCMDS)')
		_p('')

		-- Create destination directories. Can't use $@ for this because it loses the
		-- escaping, causing issues with spaces and parenthesis
		make.mkdirrule("$(TARGETDIR)")
		make.mkdirrule("$(OBJDIR)")

		-- clean target
		_p('clean:')
		_p('\t@echo Cleaning %s...', prj.name)
		_p('ifeq (posix,$(SHELLTYPE))')
		_p('\t$(SILENT) rm -f  $(TARGET)')
		_p('\t$(SILENT) rm -rf  $(OBJDIR)')
		_p('else')
		_p('\t$(SILENT) if exist $(subst /,\\\\,$(TARGET)) del $(subst /,\\\\,$(TARGET))')
		_p('\t$(SILENT) if exist $(subst /,\\\\,$(OBJDIR)) rmdir /s /q $(subst /,\\\\,$(OBJDIR))')
		_p('endif')
		_p('')

		-- custom build step targets
		_p('prebuild:')
		_p('\t$(PREBUILDCMDS)')
		_p('')

		_p('prelink:')
		_p('\t$(PRELINKCMDS)')
		_p('')
	end



	--
	-- Write the makefile header
	--

	function d.header(prj)
		_p('# %s project makefile autogenerated by Premake', premake.action.current().shortname)

		make.defaultconfig(prj)

		-- set up the environment

		_p('ifndef verbose')
		_p('  SILENT = @')
		_p('endif')
		_p('')

		-- identify the shell type
		_p('SHELLTYPE := msdos')
		_p('ifeq (,$(ComSpec)$(COMSPEC))')
		_p('  SHELLTYPE := posix')
		_p('endif')
		_p('ifeq (/bin,$(findstring /bin,$(SHELL)))')
		_p('  SHELLTYPE := posix')
		_p('endif')
		_p('')

	end


	--
	-- Write a block of configuration settings.
	--

	function d.config(cfg)

		local toolset = premake.tools[cfg.toolset or "dmd"]
		if not toolset then
			error("Invalid toolset '" + cfg.toolset + "'")
		end

		_p('ifeq ($(config),%s)', make.esc(cfg.shortname))

		-- write toolset specific configurations
		local sysflags = toolset.sysflags[cfg.architecture] or toolset.sysflags[cfg.system] or {}
		if sysflags.dc then
			_p('  DC         = %s', sysflags.dc)
		else
			_p('  DC         = %s', toolset.dc)
		end

		--table_print( cfg )
		-- write target information (target dir, name, obj dir)
		d.targetconfig(cfg,toolset)
		d.linkconfig(cfg,toolset)

		-- write the custom build commands		
		_p('  define PREBUILDCMDS')
		if #cfg.prebuildcommands > 0 then
			_p('\t@echo Running pre-build commands')
			_p('\t%s', table.implode(cfg.prebuildcommands, "", "", "\n\t"))
		end
		_p('  endef')

		_p('  define PRELINKCMDS')
		if #cfg.prelinkcommands > 0 then
			_p('\t@echo Running pre-link commands')
			_p('\t%s', table.implode(cfg.prelinkcommands, "", "", "\n\t"))
		end
		_p('  endef')

		_p('  define POSTBUILDCMDS')
		if #cfg.postbuildcommands > 0 then
			_p('\t@echo Running post-build commands')
			_p('\t%s', table.implode(cfg.postbuildcommands, "", "", "\n\t"))
		end
		_p('  endef')
		_p('')

		-- write out config-level makesettings blocks
		make.settings(cfg, toolset)

		_p('endif')
		_p('')

	end

	--
	-- Target (name, dir) configuration.
	--

	function d.targetconfig(cfg,toolset)
		local targetinfo = config.gettargetinfo(cfg)
		_p('  OBJDIR     = %s', make.esc(project.getrelative(cfg.project, cfg.objdir)))
		_p('  TARGETDIR  = %s', make.esc(targetinfo.directory))
		_p('  TARGET     = $(TARGETDIR)/%s', make.esc(targetinfo.name))
		_p('')
		_p('  DEFINES   += %s', table.concat(toolset.getdefines(cfg.defines), " "))
		_p('  INCLUDES  += %s', table.concat(toolset.getincludedirs(cfg), " "))
		_p('  DFLAGS    += $(ARCH) %s', table.concat(table.join(toolset.getflags(cfg), cfg.buildoptions), " "))
		_p('  LDFLAGS   += %s', table.concat(table.join(toolset.getldflags(cfg), cfg.linkoptions), " "))
		_p('')
	end

	--
	-- Link Step
	--

	function d.linkconfig(cfg, toolset)
		local flags = toolset.getlinks(cfg)
		_p('  LIBS      += %s', table.concat(flags, " "))

		local deps = config.getlinks(cfg, "siblings", "fullpath")
		_p('  LDDEPS    += %s', table.concat(make.esc(deps), " "))

		_p('  BUILDCMD   = $(DC) $(DFLAGS) ' .. toolset.gettarget("$(TARGET)") .. ' $(INCLUDES) $(OBJECTS) $(ARCH) $(LIBS) $(LDFLAGS)')
		_p('')
	end

	--
	-- List the objects file for the project, and each configuration.
	--

	function d.objects(prj)
		-- create lists for intermediate files, at the project level and
		-- for each configuration
		local root = { objects={}, resources={} }
		local configs = {}		
		for cfg in project.eachconfig(prj) do
			configs[cfg] = { objects={}, resources={} }
		end

		-- now walk the list of files in the project
		local tr = project.getsourcetree(prj)
		premake.tree.traverse(tr, {
			onleaf = function(node, depth)
				-- figure out what configurations contain this file, and
				-- if it uses custom build rules
				local incfg = {}
				local inall = true
				local custom = false
				for cfg in project.eachconfig(prj) do
					local filecfg = config.getfileconfig(cfg, node.abspath)
					if filecfg then
						incfg[cfg] = filecfg
						custom = (filecfg.buildrule ~= nil)
					else
						inall = false
					end
				end

				if not custom then
					-- identify the file type
					local kind
					if path.isdfile(node.abspath) then
						kind = "objects"
					end

					-- skip files that aren't compiled
					if not custom and not kind then
						return
					end

					-- if this file exists in all configurations, write it to
					-- the project's list of files, else add to specific cfgs
					if inall then
						table.insert(root[kind], project.getrelative(prj, node.abspath))
					else
						for cfg in project.eachconfig(prj) do
							if incfg[cfg] then
								table.insert(configs[cfg][kind], project.getrelative(prj, node.abspath))
							end
						end
					end

				else
					error("No support for custom build rules in D")
				end

			end
		})

		-- now I can write out the lists, project level first...
		function listobjects(var, list)
			_p('%s \\', var)
			for _, objectname in ipairs(list) do
				_p('\t%s \\', make.esc(objectname))
			end
			_p('')
		end

		listobjects('FILES :=', root.objects)

		-- ...then individual configurations, as needed
		for cfg in project.eachconfig(prj) do
			local files = configs[cfg]
			if #files.objects > 0 then
				_p('ifeq ($(config),%s)', make.esc(cfg.shortname))
				if #files.objects > 0 then
					listobjects('  FILES +=', files.objects)
				end
				_p('endif')
				_p('')
			end
		end
	end

	function table_print (tt, indent, done)
		done = done or {}
		indent = indent or 0
		if type(tt) == "table" then
			for key, value in pairs (tt) do
				io.stdout:write(string.rep (" ", indent)) -- indent it
				if type (value) == "table" and not done [value] then
					done [value] = true
					io.stdout:write(string.format("[%s] => table\n", tostring (key)));
					io.stdout:write(string.rep (" ", indent+4)) -- indent it
					io.stdout:write("(\n");
					table_print (value, indent + 7, done)
					io.stdout:write(string.rep (" ", indent+4)) -- indent it
					io.stdout:write(")\n");
				else
					io.stdout:write(string.format("[%s] => %s\n",
					tostring (key), tostring(value)))
				end
			end
		else
			io.stdout:write(tt .. "\n")
		end
	end 



