--
--
--

	premake.packages.opengl = {}

--
-- @see
--   using, _OPTIONS["includedirs"], _OPTIONS["libdirs"]

	function premake.packages.opengl.config(pkg)
		if(language() == "C" or language() == "C++") then
			if(not pkg.noincludedirs or not findin(configuration().includedirs, "GL/gl.h")) then
				print("Warning: \"GL/gl.h\" not found")
				return false
			end
		end
	end