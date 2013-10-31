--
-- gdc.lua
-- Provides GDC-specific configuration strings.
-- Copyright (c) 2002-2011 Jason Perkins and the Premake project
--

    
    premake.gdc = { }
    

--
-- Set default tools
--

    premake.gdc.dc    = "gdc"
    

--
-- Translation of Premake flags into GDC flags
--

    local flags =
    {
        ExtraWarnings   = "-w",
        Optimize        = "-O2",
        Symbols         = "-g",
        SymbolsLikeC    = "-fdebug-c",
        Deprecated      = "-fdeprecated",
        Release         = "-frelease",
        Documentation   = "-fdoc",
        PIC             = "-fPIC",
        NoBoundsCheck   = "-fno-bounds-check",
        NoFloat         = "-nofloat",
        Test            = "-funittest",
        GenerateJSON    = "-fXf",
        Verbose         = "-fd-verbose"
    }

    
    
--
-- Map platforms to flags
--

    premake.gdc.platforms = 
    {
        Native = {
            flags    = "",
            ldflags  = "", 
        },
        x32 = { 
            flags    = "-m32",
            ldflags  = "-L-L/usr/lib", 
        },
        x64 = { 
            flags    = "-m64",
            ldflags  = "-L-L/usr/lib64",
        }
    }

    local platforms = premake.gdc.platforms
 
--
-- Returns the target name specific to compiler
--

    function premake.gdc.gettarget(name)
        return "-o " .. name
    end


--
-- Returns the object directory name specific to compiler
--

    function premake.gdc.getobjdir(name)
        return "-fod=" .. name
    end


--
-- Returns a list of compiler flags, based on the supplied configuration.
--

    function premake.gdc.getflags(cfg)
        local f = table.translate(cfg.flags, flags)

        table.insert(f, platforms[cfg.platform].flags)

        --table.insert( f, "-v" )
        if cfg.kind == "StaticLib" then
            table.insert( f, "-static" )
        elseif cfg.kind == "SharedLib" and cfg.system ~= "windows" then
            table.insert( f, "-fPIC -shared" )
        end

        if premake.config.isdebugbuild( cfg ) then
            table.insert( f, "-fdebug" )
        else
            table.insert( f, "-frelease" )
        end
        return f
    end

--
-- Returns a list of linker flags, based on the supplied configuration.
--

    function premake.gdc.getldflags(cfg)
        local result = {}

        table.insert(result, platforms[cfg.platform].ldflags)

        return result
    end


--
-- Return a list of library search paths.
--

    function premake.gdc.getlibdirflags(cfg)
        local result = {}

        for _, value in ipairs(premake.getlinks(cfg, "all", "directory")) do
            table.insert(result, '-L-L' .. _MAKE.esc(value))
        end

        return result
    end


--
-- Returns a list of linker flags for library names.
--

    function premake.gdc.getlinkflags(cfg)
        local result = {}

        for _, value in ipairs(premake.getlinks(cfg, "siblings", "object")) do
            if (value.kind == "StaticLib") then
                local pathstyle = premake.getpathstyle(value)
                local namestyle = premake.getnamestyle(value)
                local linktarget = premake.gettarget(value, "link",  pathstyle, namestyle, cfg.system)
                local rebasedpath = path.rebase(linktarget.fullpath, value.location, cfg.location)
                table.insert(result, rebasedpath)
            elseif (value.kind == "SharedLib") then
                table.insert(result, '-L-l' .. _MAKE.esc(value.linktarget.basename))
            else
                -- TODO When premake supports the creation of frameworks
            end
        end

        for _, value in ipairs(premake.getlinks(cfg, "system", "basename")) do
            if path.getextension(value) == ".framework" then
                table.insert(result, '-L-framework -L' .. _MAKE.esc(path.getbasename(value)))
            else
                table.insert(result, '-L-l' .. _MAKE.esc(value))
            end
        end

        return result
    end


--
-- Decorate defines for the gdc command line.
--

    function premake.gdc.getdefines(defines)
        local result = { }
        for _,def in ipairs(defines) do
            table.insert(result, '-fversion=' .. def)
        end
        return result
    end


    
--
-- Decorate include file search paths for the gdc command line.
--

    function premake.gdc.getincludedirs(includedirs)
        local result = { }
        for _,dir in ipairs(includedirs) do
            table.insert(result, "-I" .. _MAKE.esc(dir))
        end
        return result
    end

