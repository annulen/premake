--
--
--

premake.monodevelop = {}
local monodevelop = premake.monodevelop

function monodevelop.solution(sln)
	-- local active = ''
	io.eol = '\r\n'

	-- header
	_p('Microsoft Visual Studio Solution File, Format Version 11.00')
	_p('# Visual Studio 2010')
	for i, prj in ipairs(sln.projects) do
		local lang_uuid
		local land_extension
		if(prj.language == 'C' or prj.language == 'C++') then
			lang_uuid	   = '2857B73E-F847-4B02-9238-064979017E93'
			land_extension = '.cproj'
		end

		local dir = path.translate(path.getrelative(sln.location,
			prj.location), "\\")
		dir = path.join(dir, prj.name)..land_extension
		_p('Project("{%s}") = "%s", "%s", "{%s}"', lang_uuid, prj.name, dir, prj.uuid)
		_p('EndProject')
	end

	-- global
	_p('Global')
	_p('\tGlobalSection(SolutionConfigurationPlatforms) = preSolution')
	_p('\t\tDebug|Any CPU = Debug|Any CPU')
	_p('\t\tRelease|Any CPU = Release|Any CPU')
	_p('\tEndGlobalSection')
	_p('\tGlobalSection(ProjectConfigurationPlatforms) = postSolution')
	for i, prj in ipairs(sln.projects) do
		_p('\t\t{%s}.Debug|Any CPU.ActiveCfg = Debug|Any CPU', prj.uuid)
		_p('\t\t{%s}.Debug|Any CPU.Build.0 = Debug|Any CPU', prj.uuid)
		_p('\t\t{%s}.Release|Any CPU.ActiveCfg = Release|Any CPU', prj.uuid)
		_p('\t\t{%s}.Release|Any CPU.Build.0 = Release|Any CPU', prj.uuid)
	end
	_p('\tEndGlobalSection')
	_p('\tGlobalSection(MonoDevelopProperties) = preSolution')
	-- TODO active project
	-- _p('\t\tStartupItem = ee\ee.cproj')
	_p('\tEndGlobalSection')
	_p('EndGlobal')
end

function monodevelop.project(prj)
	_p('<?xml version="1.0" encoding="utf-8"?>')
	_p('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" DefaultTargets="Build" ToolsVersion="4.0">')
	_p('\t<PropertyGroup>')
	_p('\t\t<Configuration Condition=" \'$(Configuration)\' == \'\' ">Debug</Configuration>')
	_p('\t\t<Platform Condition=" \'$(Platform)\' == \'\' ">AnyCPU</Platform>')
	_p('\t\t<ProductVersion>10.0.0</ProductVersion>')
	_p('\t\t<SchemaVersion>2.0</SchemaVersion>')
	_p('\t\t<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
	
	-- language
	if(prj.language == 'C') then
		_p('\t\t<Compiler>')
		_p('\t\t\t<Compiler ctype="GccCompiler"/>')
		_p('\t\t</Compiler>')
		_p('\t\t<Language>C</Language>')
	elseif(prj.language == 'C++') then
		_p('\t\t<Compiler>')
		_p('\t\t\t<Compiler ctype="GppCompiler"/>')
		_p('\t\t</Compiler>')
		_p('\t\t<Language>CPP</Language>')
	--else
	--	os.exit()
	end
	_p('\t\t<Target>Bin</Target>')
	_p('\t\t<BaseDirectory>%s</BaseDirectory>',
			path.getrelative(prj.location, prj.basedir))
	_p('\t</PropertyGroup>')

	--
	--
	--

	for cfg in premake.eachconfig(prj) do
		_p('\t<PropertyGroup Condition=" \'$(Configuration)|$(Platform)\' == \'%s|AnyCPU\' ">', cfg.name)
		_p('\t\t<DebugSymbols>true</DebugSymbols>')
		_p('\t\t<OutputPath>%s</OutputPath>',
			path.join(prj.targetdir, prj.name))
		_p('\t\t<Externalconsole>true</Externalconsole>')
		_p('\t\t<OutputName>%s</OutputName>', prj.name)
		
		-- kind
		local kind
		if     (prj.kind == 'ConsoleApp') then kind = 'Bin'
		elseif(prj.kind == 'WindowedApp') then kind = 'Bin'
		elseif(prj.kind == 'SharedLib'  ) then kind = 'SharedLibrary'
		elseif(prj.kind == 'StaticLib'  ) then kind = 'StaticLibrary'
		-- else
		--	print('')
		--	os.exit()
		end
		_p('\t\t<CompileTarget>%s</CompileTarget>', kind)
		
		-- defines
		_p('\t\t<DefineSymbols>%s</DefineSymbols>', table.concat(cfg.defines, ' '))
		_p('\t\t<SourceDirectory>%s</SourceDirectory>',
			path.getrelative(prj.location, prj.basedir))
		
		-- includedirs
		if(cfg.includedirs) then
			_p('\t\t<Includes>')
			_p('\t\t\t<Includes>')
			for _, t in ipairs(cfg.includedirs) do
				if(path.isabsolute(t)) then
					_p('\t\t\t\t<Include>%s</Include>', t)
				else
					t = path.join('${ProjectDir}', path.rebase(t,
						prj.location, prj.basedir))
					_p('\t\t\t\t<Include>%s</Include>', t)
				end
			end
			_p('\t\t\t</Includes>')
			_p('\t\t</Includes>')
		end
		
		-- libdirs
		if(cfg.libdirs and table.getn(cfg.libdirs) ~= 0) then
			_p('\t\t<LibPaths>')
			_p('\t\t\t<LibPaths>')
			for _, t in ipairs(cfg.libdirs) do
				_p('\t\t\t\t<LibPath>%s</LibPath>', t)
			end
			_p('\t\t\t</LibPaths>')
			_p('\t\t</LibPaths>')
		end
		
		-- links
		if(cfg.links and table.getn(cfg.links) ~= 0) then
			_p('\t\t<Libs>')
			_p('\t\t\t<Libs>')
			for _, t in ipairs(cfg.links) do
				_p('\t\t\t\t<Lib>%s</Lib>', t)
			end
			_p('\t\t\t</Libs>')
			_p('\t\t</Libs>')
		end
		
		-- buildoptions
		if(cfg.buildoptions and table.getn(cfg.buildoptions) ~= 0) then
			_p('\t\t<ExtraCompilerArguments>%s</ExtraCompilerArguments>',
				table.concat(cfg.buildoptions, " "))
		end
		
		-- prebuildcommands
		if(cfg.prebuildcommands and table.getn(cfg.prebuildcommands) ~= 0) then
			_p('\t\t<CustomCommands>')
			_p('\t\t\t<CustomCommands>')
			for _, t in ipairs(cfg.prebuildcommands) do
				_p('\t\t\t\t<Command type="BeforeBuild" command="%s" workingdir="%s"/>', t, prj.basedir)
			end
			_p('\t\t\t</CustomCommands>')
			_p('\t\t</CustomCommands>')
		end
		_p('\t</PropertyGroup>')
	end

	-- files
	local cwd = os.getcwd()
	os.chdir(prj.basedir)
	local tr = premake.project.buildsourcetree(prj)
	local d	 = 0
	
	function back(d, depth)
		while(d > depth) do
			os.chdir('../')
			d = d - 1
		end
		return d
	end
	
	premake.tree.sort(tr)
	_p('\t<ItemGroup>')
	premake.tree.traverse(tr, {
		onbranch = function(node, depth)
			d = back(d, depth)
			os.chdir(path.getname(node.name))
			d = d + 1
		end,

		onleaf = function(node, depth)
			d = back(d, depth)
			local f = path.translate(path.join(path.getrelative(
				prj.location, os.getcwd()), path.getname(node.name)), '\\')
			if(path.iscfile(f) or path.iscppfile(f)) then
				_p('\t\t<Compile Include="%s"/>', f)
			else
				_p('\t\t<None    Include="%s"/>', f)
			end
		end
	})
	_p('\t</ItemGroup>')
	os.chdir(cwd)

	_p('</Project>')
end

--
--
--

newaction {
	trigger			= 'monodevelop-4.0',
	description		= 'MonoDevelop project',
	valid_kinds		= { "ConsoleApp", "WindowedApp", "SharedLib", "StaticLib" },
	valid_languages = { "C", "C++" },
	valid_tools		= {
		cc = { "gcc" }
	},

	onsolution =
		function(sln)
			premake.generate(sln, '%%.sln', monodevelop.solution)
			-- local premake.monodevelop.cpp = { }
		end,

	onproject =
		function(prj)
			premake.generate(prj, '%%.cproj', monodevelop.project)
		end
}
