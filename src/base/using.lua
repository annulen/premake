--
--
--

	premake.packages = {}

--
-- @see
--   premake.packages, _OPTIONS["includedirs"], _OPTIONS["libdirs"]

	function using(pkg)
		-- TODO move to _premake_main.lua
		-- >>
		local pattern
		if(not _OPTIONS["os"]) then _OPTIONS["os"] = os.get() end
		-- init
		if    (_OPTIONS["os"] == "windows") then pattern = ";"
		elseif(_OPTIONS["os"] ==   "linux") then pattern = ":"
		end
		-- parse _OPTIONS["includedirs"]
		if(_OPTIONS["includedirs"]) then
			local arr = string.explode(_OPTIONS["includedirs"], pattern)
			for _, t in ipairs(arr) do
				if(os.isdir(t)) then includedirs { t }
				else error("Error: os.isdir("..t..") return false")
				end
			end
		end
		-- parse _OPTIONS["libdirs"]
		if(_OPTIONS["libdirs"]) then
			local arr = string.explode(_OPTIONS["libdirs"], pattern)
			for _, t in ipairs(arr) do
				if(os.isdir(t)) then libdirs { t }
				else error("Error: os.isdir("..t..") return false")
				end
			end
		end
		-- <<
		if(not pkg or not pkg.name) then
			print("Error: use \"using\" without package.name")
			return nil
		end
		--
		if(not premake.packages[pkg.name]) then
			print("Warning: package "..pkg.name.." not supported")
			return nil
		end
		-- default includedirs and libdirs
		if(_OPTIONS["os"] == "linux") then
			includedirs { "/usr/include/", "/usr/local/include/" }
			libdirs { "/usr/lib/" }
		end
		--
		return premake.packages[pkg.name].config(pkg)
	end

--
--
--

	function findin(dirs, name)
		if(not dirs) then return nil end
		for _, t in ipairs(dirs) do
			if(os.isdir(path.join(t, name)) or os.isfile(path.join(t, name))) then return t end
		end
		return nil
	end
