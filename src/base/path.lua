--
-- path.lua
-- Path manipulation functions.
-- Copyright (c) 2002-2013 Jason Perkins and the Premake project
--


--
-- Appends a file extension to the path. Verifies that the extension
-- isn't already present, and adjusts quotes as necessary.
--

	function path.appendextension(p, ext)
		-- if the extension is nil or empty, do nothing
		if not ext or ext == "" then
			return p
		end

		-- if the path ends with a quote, pull it off
		local endquote
		if p:endswith('"') then
			p = p:sub(1, -2)
			endquote = '"'
		end

		-- add the extension if it isn't there already
		if not p:endswith(ext) then
			p = p .. ext
		end

		-- put the quote back if necessary
		if endquote then
			p = p .. endquote
		end

		return p
	end


--
-- Retrieve the filename portion of a path, without any extension.
--

	function path.getbasename(p)
		local name = path.getname(p)
		local i = name:findlast(".", true)
		if (i) then
			return name:sub(1, i - 1)
		else
			return name
		end
	end


--
-- Retrieve the directory portion of a path, or an empty string if
-- the path does not include a directory.
--

	function path.getdirectory(p)
		local i = p:findlast("/", true)
		if (i) then
			if i > 1 then i = i - 1 end
			return p:sub(1, i)
		else
			return "."
		end
	end


--
-- Retrieve the drive letter, if a Windows path.
--

	function path.getdrive(p)
		local ch1 = p:sub(1,1)
		local ch2 = p:sub(2,2)
		if ch2 == ":" then
			return ch1
		end
	end



--
-- Retrieve the file extension.
--

	function path.getextension(p)
		local i = p:findlast(".", true)
		if (i) then
			return p:sub(i)
		else
			return ""
		end
	end



--
-- Retrieve the filename portion of a path.
--

	function path.getname(p)
		local i = p:findlast("[/\\]")
		if (i) then
			return p:sub(i + 1)
		else
			return p
		end
	end




--
-- Returns true if the filename has a particular extension.
--
-- @param fname
--    The file name to test.
-- @param extensions
--    The extension(s) to test. Maybe be a string or table.
--

	function path.hasextension(fname, extensions)
		local fext = path.getextension(fname):lower()
		if type(extensions) == "table" then
			for _, extension in pairs(extensions) do
				if fext == extension then
					return true
				end
			end
			return false
		else
			return (fext == extensions)
		end
	end


--
-- Returns true if the filename represents a C/C++ source code file. This check
-- is used to prevent passing non-code files to the compiler in makefiles. It is
-- not foolproof, but it has held up well. I'm open to better suggestions.
--

	function path.iscfile(fname)
		return path.hasextension(fname, { ".c", ".s", ".m" })
	end

	function path.iscppfile(fname)
		return path.hasextension(fname, { ".cc", ".cpp", ".cxx", ".c", ".s", ".m", ".mm" })
	end

	function path.iscppheader(fname)
		return path.hasextension(fname, { ".h", ".hh", ".hpp", ".hxx" })
	end

	function path.isdfile(fname)
		return path.hasextension(fname, { ".d", ".di", ".ddoc" })
	end


--
-- Returns true if the filename represents an OS X framework.
--

	function path.isframework(fname)
		return path.hasextension(fname, ".framework")
	end


--
-- Returns true if the filename represents an object file.
--

	function path.isobjectfile(fname)
		return path.hasextension(fname, { ".o", ".obj" })
	end


--
-- Returns true if the filename represents a Windows resource file. This check
-- is used to prevent passing non-resources to the compiler in makefiles.
--

	function path.isresourcefile(fname)
		return path.hasextension(fname, ".rc")
	end


--
-- Takes a path which is relative to one location and makes it relative
-- to another location instead.
--

	function path.rebase(p, oldbase, newbase)
		p = path.getabsolute(path.join(oldbase, p))
		p = path.getrelative(newbase, p)
		return p
	end


--
-- Converts from a simple wildcard syntax, where * is "match any"
-- and ** is "match recursive", to the corresponding Lua pattern.
--
-- @param pattern
--    The wildcard pattern to convert.
-- @returns
--    The corresponding Lua pattern.
--

	function path.wildcards(pattern)
		-- Escape characters that have special meanings in Lua patterns
		pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")

		-- Replace wildcard patterns with special placeholders so I don't
		-- have competing star replacements to worry about
		pattern = pattern:gsub("%*%*", "\001")
		pattern = pattern:gsub("%*", "\002")

		-- Replace the placeholders with their Lua patterns
		pattern = pattern:gsub("\001", ".*")
		pattern = pattern:gsub("\002", "[^/]*")

		return pattern
	end
