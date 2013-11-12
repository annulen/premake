--
--
--

	premake.packages.cairo = {}

--
-- @see
--   _OPTIONS["includedirs"], _OPTIONS["libdirs"]

	function premake.packages.cairo.config(pkg)
		-- includedirs
		if(not pkg.noincludedirs) then
			if(not findin(includedirs(), "cairo.h")) then
				local s = findin(includedirs(), "cairo/cairo.h")
				if(not s) then print("Warning: \"cairo.h\" not found") end
				includedirs { path.join(s, "cairo/") }
			end
		end
		-- links
		if(not pkg.nolinks) then
			links { 'cairo' }
		end
	end
