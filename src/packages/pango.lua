--
--
--

	premake.packages.pango = {}

--
-- @see
--   using, _OPTIONS["includedirs"], _OPTIONS["libdirs"]

	function premake.packages.pango.config(pkg)
		-- includedirs
		if(not pkg.noincludedirs) then
			if(not findin(configuration().includedirs, "pango/pango.h")) then
				local s = findin(configuration().includedirs, "pango-1.0/pango/pango.h")
				if(not s) then print("Warning: \"pango/pango.h\" not found") end
				includedirs { path.join(s, "pango-1.0/") }
			end
		end
		-- links
		if(not pkg.nolinks) then
			links { 'pango-1.0' }
		end
	end
