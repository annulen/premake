--
-- actions/vstudio/monodevelop_cproj.lua
-- Generate a MonoDevelop C/C++ cproj project.
-- Copyright (c) 2012-2013 Manu Evans and the Premake project
--

	local monodevelop = premake.vstudio.monodevelop
	local vstudio = premake.vstudio
	local project = premake5.project
	local config = premake5.config
	local tree = premake.tree


--
-- Generate a MonoDevelop C/C++ project, with support for the new platforms API.
--

	function monodevelop.generate(prj)
		io.eol = "\r\n"
		io.indent = "  "

		monodevelop.header("Build")
		
		monodevelop.projectProperties(prj)

		for cfg in project.eachconfig(prj) do
			monodevelop.configurationProperties(cfg)
		end

		monodevelop.files(prj)
--		monodevelop.projectReferences(prj)

		_p('</Project>')
	end



--
-- Output the XML declaration and opening <Project> tag.
--

	function monodevelop.header(target)
		_p('<?xml version="1.0" encoding="utf-8"?>')

		local defaultTargets = ""
		if target then
			defaultTargets = string.format(' DefaultTargets="%s"', target)
		end

		_p('<Project%s ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">', defaultTargets)
	end


--
-- Write out the project properties: what kind of binary it 
-- produces, and some global settings.
--

	function monodevelop.projectProperties(prj)
		_p(1,'<PropertyGroup>')

		_p(2,'<Configuration Condition=" \'$(Configuration)\' == \'\' ">%s</Configuration>', 'Debug')
		_p(2,'<Platform Condition=" \'$(Platform)\' == \'\' ">%s</Platform>', 'AnyCPU')
		_p(2,'<ProductVersion>%s</ProductVersion>', action.vstudio.productVersion)
		_p(2,'<SchemaVersion>%s</SchemaVersion>', action.vstudio.csprojSchemaVersion)
		_p(2,'<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
		_p(2,'<Target>%s</Target>', 'Bin')

		_p(2,'<Language>%s</Language>', iif(prj.language == 'C', 'C', 'CPP'))

		_p(2,'<Compiler>')
		_p(3,'<Compiler ctype="%s" />', iif(prj.language == 'C', 'GccCompiler', 'GppCompiler'))
		_p(2,'</Compiler>')

		-- packages
		
		_p(1,'</PropertyGroup>')
	end


--
-- Write out the configuration property group: what kind of binary it 
-- produces, and some global settings.
--

	function monodevelop.configurationProperties(cfg)
		_p(1,'<PropertyGroup %s>', monodevelop.condition(cfg))

		monodevelop.debuginfo(cfg)
		_x(2,'<OutputPath>%s</OutputPath>', cfg.buildtarget.directory)
		monodevelop.preprocessorDefinitions(cfg.defines)
		_x(2,'<SourceDirectory>%s</SourceDirectory>', '.')
		_x(2,'<OutputName>%s</OutputName>', cfg.buildtarget.name)
		monodevelop.config_type(cfg)
		monodevelop.warnings(cfg)
		monodevelop.optimization(cfg)
		_x(2,'<Externalconsole>%s</Externalconsole>', 'true')
		
		monodevelop.additionalOptions(cfg)
		monodevelop.additionalLinkOptions(cfg)

		monodevelop.additionalIncludeDirectories(cfg)
		monodevelop.additionalLibraryDirectories(cfg)
		monodevelop.additionalDependencies(cfg)
		
		monodevelop.buildEvents(cfg)

		_p(1,'</PropertyGroup>')
	end


--
-- Format and return a Visual Studio Condition attribute.
--

	function monodevelop.condition(cfg)
		return string.format('Condition=" \'$(Configuration)|$(Platform)\' == \'%s\' "', premake.esc(vstudio.configname(cfg)))
	end


--
-- Map Premake's project kinds to Visual Studio configuration types.
--

	function monodevelop.config_type(cfg)
		local map = {
			SharedLib = "SharedLibrary",
			StaticLib = "StaticLibrary",
			ConsoleApp = "Bin",
			WindowedApp = "Bin"
		}
		_p(2,'<CompileTarget>%s</CompileTarget>', map[cfg.kind])
	end


--
-- Translate Premake's debugging settings to the Visual Studio equivalent.
--

	function monodevelop.debuginfo(cfg)
		if cfg.flags.Symbols then
			_p(2,'<DebugSymbols>%s</DebugSymbols>', iif(cfg.flags.Symbols, 'true', 'false'))
		end
	end


--
-- Translate Premake's optimization flags to the Visual Studio equivalents.
--

	function monodevelop.optimization(cfg)
		-- this needs work, it's all or nothing as is!
		local level = 0
		for _, flag in ipairs(cfg.flags) do
			if flag == "Optimize" then
				level = 2
			elseif flag == "OptimizeSize" then
				level = 2	-- TODO: What we really want is Os, but this option just seems to be a numeric value
			elseif flag == "OptimizeSpeed" then
				level = 3
			end
		end
		if level > 0 then
			_p(2,'<OptimizationLevel>%s</OptimizationLevel>', level)
		end
	end


--
-- Write out a <PreprocessorDefinitions> element, used by both the compiler
-- and resource compiler blocks.
--

	function monodevelop.preprocessorDefinitions(defines)
		if #defines > 0 then
			defines = table.concat(defines, ' ')
			_x(2,'<DefineSymbols>%s</DefineSymbols>', defines)
		end
	end


--
-- Convert Premake warning flags to Visual Studio equivalents.
--

	function monodevelop.warnings(cfg)
	
		local warnLevel = nil -- default to normal warning level if there is not any warnings flags specified
		if cfg.flags.NoWarnings then
			warnLevel = 'None'
		elseif cfg.flags.ExtraWarnings then
			warnLevel = 'All'
		end
		if warnLevel then
			_p(2,'<WarningLevel>%s</WarningLevel>', warnLevel)
		end

		-- Ohter warning blocks only when NoWarnings are not specified
		if cfg.flags.NoWarnings then
			return
		end

		if cfg.flags.FatalWarnings then
			_p(2,'<WarningsAsErrors>%s</WarningsAsErrors>', iif(cfg.flags.FatalWarnings, 'true', 'false'))
		end
	end


--
-- Write out additional compiler args.
--

	function monodevelop.additionalOptions(cfg)
		local opts = { }

		if cfg.project.language == 'C++' then
			if cfg.flags.NoExceptions then
				table.insert(opts, "-fno-exceptions")
			end
			if cfg.flags.NoRTTI then
				table.insert(opts, "-fno-rtti")
			end
		end

		-- TODO: Validate these flags are what is intended by these options...
--		if cfg.flags.FloatFast then
--			table.insert(opts, "-mno-ieee-fp")
--		elseif cfg.flags.FloatStrict then
--			table.insert(opts, "-mieee-fp")
--		end

		if cfg.flags.EnableSSE2 then
			table.insert(opts, "-msse2")
		elseif cfg.flags.EnableSSE then
			table.insert(opts, "-msse")
		end

		local options
		if #opts > 0 then
			options = table.concat(opts, " ")
		end
		if #cfg.buildoptions > 0 then
			local buildOpts = table.concat(cfg.buildoptions, " ")
			options = iif(options, options .. " " .. buildOpts, buildOpts)
		end

		if options then
			_x(2,'<ExtraCompilerArguments>%s</ExtraCompilerArguments>', options)
		end
	end


--
-- Write out the <AdditionalOptions> element for the linker blocks.
--

	function monodevelop.additionalLinkOptions(cfg)
		if #cfg.linkoptions > 0 then
			local opts = table.concat(cfg.linkoptions, " ")
			_x(2, '<ExtraLinkerArguments>%s</ExtraLinkerArguments>', opts)
		end
	end


--
-- Write out the <AdditionalIncludeDirectories> element, which is used by 
-- both the compiler and resource compiler blocks.
--

	function monodevelop.additionalIncludeDirectories(cfg)
		if #cfg.includedirs > 0 then
			_x(2,'<Includes>')
			_x(3,'<Includes>')

			for _, i in ipairs(cfg.includedirs) do
				_x(4,'<Include>%s</Include>', path.translate(i))
			end

			_x(3,'</Includes>')
			_x(2,'</Includes>')
		end
	end


--
-- Write out the linker's <AdditionalLibraryDirectories> element.
--

	function monodevelop.additionalLibraryDirectories(cfg)
		if #cfg.libdirs > 0 then
			_x(2,'<LibPaths>')
			_x(3,'<LibPaths>')

			for _, l in ipairs(cfg.libdirs) do
				_x(4,'<LibPath>%s</LibPath>', path.translate(l))
			end

			_x(3,'</LibPaths>')
			_x(2,'</LibPaths>')
		end
	end


--
-- Write out the linker's additionalDependencies element.
--

	function monodevelop.additionalDependencies(cfg)
		local links
		
		-- check to see if this project uses an external toolset. If so, let the
		-- toolset define the format of the links
		local toolset = premake.vstudio.vc200x.toolset(cfg)
		if toolset then
			links = toolset.getlinks(cfg, false)
		else
			-- VS always tries to link against project dependencies, even when those
			-- projects are excluded from the build. To work around, linking dependent
			-- projects is disabled, and sibling projects link explicitly
			links = config.getlinks(cfg, "all", "fullpath")
		end
		
		if #links > 0 then
			_x(2,'<Libs>')
			_x(3,'<Libs>')

			for _, lib in ipairs(links) do
				_x(4,'<Lib>%s</Lib>', path.translate(lib))
			end

			_x(3,'</Libs>')
			_x(2,'</Libs>')
		end
	end


--
-- Write out the pre- and post-build event settings.
--

	function monodevelop.buildEvents(cfg)

		-- TODO: handle cfg.prelinkcommands...

		if #cfg.prebuildcommands > 0 or #cfg.postbuildcommands > 0 then
			_x(2,'<CustomCommands>')
			_x(3,'<CustomCommands>')

			for _, c in ipairs(cfg.prebuildcommands) do
				_x(4,'<Command type="BeforeBuild" command="%s" />', c)
			end

			for _, c in ipairs(cfg.postbuildcommands) do
				_x(4,'<Command type="AfterBuild" command="%s" />', c)
			end
			
			_x(3,'</CustomCommands>')
			_x(2,'</CustomCommands>')
		end
	end


--
-- Write out the list of source code files, and any associated configuration.
--

	function monodevelop.files(prj)
		monodevelop.filegroup(prj, "Include", "None")
		monodevelop.filegroup(prj, "Compile", "Compile")
		monodevelop.filegroup(prj, "None", "None")
		monodevelop.filegroup(prj, "ResourceCompile", "None")
		monodevelop.filegroup(prj, "CustomBuild", "None")
	end

	function monodevelop.filegroup(prj, group, action)
		local files = monodevelop.getfilegroup(prj, group)
		if #files > 0  then
			_p(1,'<ItemGroup>')
			for _, file in ipairs(files) do
				monodevelop.putfile(action, file)
			end
			_p(1,'</ItemGroup>')
		end
	end

	function monodevelop.putfile(action, file)
		local filename = file.relpath

		if not string.startswith(filename, '..') then
			_x(2,'<%s Include=\"%s\" />', action, path.translate(filename))
		else
			_x(2,'<%s Include=\"%s\">', action, path.translate(filename))

			-- Relative paths referring to parent directories need to use the special
			--   'Link' option to present them in the project hierarchy nicely
			while string.startswith(filename, '..') do
				filename = filename:sub(4)
			end
			_x(3,'<Link>%s</Link>', filename)
			
-- TODO: MonoDevelop really doesn't handle custom build tools very well (yet)
--			for cfg in project.eachconfig(prj) do
--				local condition = monodevelop.condition(cfg)					
--				local filecfg = config.getfileconfig(cfg, file.abspath)
--				if filecfg and filecfg.buildrule then
--					local commands = table.concat(filecfg.buildrule.commands,'\r\n')
--					_p(3,'<Generator %s>%s</Generator>', condition, premake.esc(commands))
--				end
--			end

			_x(2,'</%s>', action)
		end
	end
	
	function monodevelop.getfilegroup(prj, group)
		-- check for a cached copy before creating
		local groups = prj.monodevelop_file_groups
		if not groups then
			groups = {
				Compile = {},
				Include = {},
				None = {},
				ResourceCompile = {},
				CustomBuild = {},
			}
			prj.monodevelop_file_groups = groups
			
			local tr = project.getsourcetree(prj)
			tree.traverse(tr, {
				onleaf = function(node)
					local function targetGroup()
						-- if any configuration of this file uses a custom build rule,
						-- then they all must be marked as custom build
						local hasbuildrule = false
						for cfg in project.eachconfig(prj) do				
							local filecfg = config.getfileconfig(cfg, node.abspath)
							if filecfg and filecfg.buildrule then
								hasbuildrule = true
								break
							end
						end
					
						if hasbuildrule then
							return groups.CustomBuild
						elseif path.iscppfile(node.name) then
							return groups.Compile
						elseif path.iscppheader(node.name) then
							return groups.Include
						elseif path.isresourcefile(node.name) then
							return groups.ResourceCompile
						else
							return groups.None
						end
					end

					table.insert(targetGroup(), node)
				end
			})
		end

		return groups[group]
	end


--
-- Generate the list of project dependencies.
--

	function monodevelop.projectReferences(prj)
		local deps = project.getdependencies(prj)
		if #deps > 0 then
			local prjpath = project.getlocation(prj)
			
			_p(1,'<ItemGroup>')
			for _, dep in ipairs(deps) do
				local relpath = path.getrelative(prjpath, vstudio.projectfile(dep))
				_x(2,'<ProjectReference Include=\"%s\">', path.translate(relpath))
				_p(3,'<Project>{%s}</Project>', dep.uuid)
				_p(2,'</ProjectReference>')
			end
			_p(1,'</ItemGroup>')
		end
	end
