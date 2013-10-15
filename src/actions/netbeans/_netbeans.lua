--
-- _netbeans.lua
-- Define the netbeans action(s).
-- Copyright (c) 2013 Santo Pfingsten
--

	premake.netbeans = { }
	local netbeans = premake.netbeans
	local solution = premake.solution
	local project = premake.project
	
--
-- Register the "netbeans" action
--

	newaction {
		trigger         = "netbeans",
		shortname       = "NetBeans",
		description     = "Generate NetBeans project files",
	
		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++" },
		
		valid_tools     = {
			cc     = { "clang", "gcc" },
		},
		
		onproject = function(prj)
			io.esc = netbeans.esc
			premake.generate(prj, prj.name .. "/Makefile", netbeans.makefile.generate)
			premake.generate(prj, prj.name .. "/nbproject/project.xml", netbeans.projectfile.generate)
			premake.generate(prj, prj.name .. "/nbproject/configurations.xml", netbeans.configfile.generate)
		end,
		
		oncleanproject = function(prj)
			premake.clean.directory(prj, prj.name)
		end
	}
	
---
-- Apply XML escaping on a value to be included in an
-- exported project file.
---

	function netbeans.esc(value)
		value = string.gsub(value, '&',  "&amp;")
		value = value:gsub('"',  "&quot;")
		value = value:gsub("'",  "&apos;")
		value = value:gsub('<',  "&lt;")
		value = value:gsub('>',  "&gt;")
		value = value:gsub('\r', "&#x0D;")
		value = value:gsub('\n', "&#x0A;")
		return value
	end
	
	function netbeans.escapepath(prj, file)
		if path.isabsolute(file) then
			file = project.getrelative(prj, file)
		end
		
		if not path.isabsolute(file) then
			file = path.join('../', file)
		end
		return premake.esc(file)
	end  
	
	function netbeans.gettoolset(cfg)
		local toolset = premake.tools[cfg.toolset or "gcc"]
		if not toolset then
			error("Invalid toolset '" + cfg.toolset + "'")
		end
		return toolset
	end