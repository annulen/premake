--
--
--

	premake.packages.atk = {}

--
-- @see
--   using, _OPTIONS["includedirs"], _OPTIONS["libdirs"]

	function premake.packages.atk.config(pkg)
		-- includedirs
		if(not pkg.noincludedirs) then
			if(not findin(configuration().includedirs, "atk/atk.h")) then
				local s = findin(configuration().includedirs, "atk-1.0/atk/atk.h")
				if(not s) then print("Warning: \"atk/atk.h\" not found") end
				includedirs { path.join(s, "atk-1.0/") }
			end
		end
		-- links
		if(not pkg.nolinks) then
			links { "atk-1.0" }
		end
	end
