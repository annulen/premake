--
--
--

	premake.packages.gtk = {}

--
-- @see
--   using, _OPTIONS["includedirs"], _OPTIONS["libdirs"]

	function premake.packages.gtk.config(pkg)
		-- defines
		if(not pkg.nodefines) then
			defines { "GTK_COMPILATION" }
		end
		-- includedirs
		if(not pkg.noincludedirs) then
			-- gtk/gtk.h
			if(not findin(includedirs(), "gtk/gtk.h")) then
				local s = findin(includedirs(), "gtk-3.0/gtk/gtk.h")
				if(not s) then print("Warning: \"gtk/gtk.h\" not found")
				else includedirs { path.getabsolute(path.join(s, "gtk-3.0/")) }
				end
			end
			-- gdk-pixbuf/gdk-pixbuf.h
			if(not findin(includedirs(), "gdk-pixbuf/gdk-pixbuf.h")) then
				local s = findin(includedirs(), "gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf.h")
				if(not s) then print("Warning: \"gdk-pixbuf/gdk-pixbuf.h\" not found")
				else includedirs { path.getabsolute(path.join(s, "gdk-pixbuf-2.0/")) }
				end
			end
		end
		-- links
		if(not pkg.nolinks) then
			if(_OPTIONS["os"] == "linux") then
				links { "gtk-3", "gdk-3", "gdk_pixbuf-2.0" }
			elseif(_OPTIONS["os"] == "windows" and _OPTIONS["platform"] == "x32") then
				links { "gtk-win32-3.0", "gdk-win32-3.0" }
			elseif(_OPTIONS["os"] == "windows" and _OPTIONS["platform"] == "x64") then
				links { "gtk-win64-3.0", "gdk-win64-3.0" }
			end
		end
		-- depends
		if(not pkg.nodepends) then
			using { name =  "glib" }
			using { name = "pango" }
			using { name = "cairo" }
			using { name =   "atk" }
		end
	end
