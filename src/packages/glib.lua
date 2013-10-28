--
--
--

	premake.packages.glib = {}

--
-- @see
--   using, _OPTIONS["includedirs"], _OPTIONS["libdirs"]

	function premake.packages.glib.config(pkg)
		-- includedirs
		if(not pkg.noincludedirs) then
			if(not findin(includedirs(), "glib.h")) then
				local s = findin(includedirs(), "glib-2.0/glib.h")
				if(not s) then print("Warning: \"glib.h\" not found") end
				includedirs { path.join(s, "glib-2.0/") }
			end
			-- includedirs glibconfig.h
			if(not findin(includedirs(), "glibconfig.h")) then
				local s = findin(libdirs(), "glib-2.0/include/glibconfig.h")
				if(not s) then print("Warning: \"glibconfig.h\" not found") end
				includedirs { path.join(s, "glib-2.0/include/") }
			end
		end
		-- links
		if(not pkg.nolinks) then
			links { 'glib-2.0', 'gobject-2.0' }
		end
	end
