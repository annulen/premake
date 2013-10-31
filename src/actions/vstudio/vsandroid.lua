--
-- vsandroid.lua
-- VS-Android helpers for vs2010.
-- Copyright (c) 2012 Manu Evans and the Premake project
--

	premake.vstudio.vsandroid = { }
	local vsandroid = premake.vstudio.vsandroid
	local vstudio = premake.vstudio
	local project = premake5.project
	local config = premake5.config


--
-- Write the VS-Android related ProjectConfigurationPlatforms section.
--

	function vsandroid.projectConfigurationPlatforms(prj, slncfg, prjcfg, slnplatform, prjplatform, architecture)

		_p(2,'{%s}.%s|%s.Deploy.0 = %s|%s', prj.uuid, slncfg.buildcfg, slnplatform, prjplatform, architecture)

	end

--
-- Write the VS-Android configuration property group.
--

	function vsandroid.configurationProperties(cfg)

			-- TODO-ANDROID: we need a way to select the GCC toolchain version...

			if cfg.architecture == "armv7" or cfg.architecture == "armv6" then
				_p(2,'<PlatformToolset>arm-linux-androideabi-4.6</PlatformToolset>')
				_p(2,'<AndroidArch>armv7-a</AndroidArch>')
			elseif cfg.architecture == "armv5" then
				_p(2,'<PlatformToolset>arm-linux-androideabi-4.6</PlatformToolset>')
				_p(2,'<AndroidArch>armv5te</AndroidArch>')
			elseif cfg.architecture == "x32" then
				_p(2,'<PlatformToolset>x86-4.6</PlatformToolset>')
				_p(2,'<AndroidArch>x86</AndroidArch>')
			elseif cfg.architecture == "mips" then
				_p(2,'<PlatformToolset>mipsel-linux-android-4.6</PlatformToolset>')
				_p(2,'<AndroidArch>mips</AndroidArch>')
			end

--			_p(2,'<AndroidAPILevel>%s</AndroidAPILevel>', -- TODO-ANDROID: we need the android api level -- )
--			_p(2,'<AndroidStlType>stlport_static</AndroidStlType>', -- TODO-ANDROID: do we want an stl type options? -- )

	end


--
-- Write the VS-Android <ClCompile> compiler settings.
--

	function vsandroid.clCompile(cfg)

		vsandroid.warnings(cfg)

		_p(3,'<OptimizationLevel>%s</OptimizationLevel>', vsandroid.optimization(cfg))

		if cfg.flags.NoExceptions then
			_p(3,'<GccExceptionHandling>false</GccExceptionHandling>')
		else
			_p(3,'<GccExceptionHandling>true</GccExceptionHandling>')
		end

		if cfg.flags.Symbols then
			_p(3,'<GenerateDebugInformation>true</GenerateDebugInformation>')
		end

		if cfg.flags.SoftwareFloat then
			_p(3,'<SoftFloat>true</SoftFloat>')
		end

		if cfg.flags.EnableThumb then
			_p(3,'<ThumbMode>true</ThumbMode>')
		end

		if cfg.flags.EnableStrictAliasing then
			_p(3,'<StrictAliasing>true</StrictAliasing>')
		end
		if cfg.flags.DisableStrictAliasing then
			_p(3,'<StrictAliasing>false</StrictAliasing>')
		end

		if cfg.flags.EnablePIC then
			_p(3,'<PositionIndependentCode>true</PositionIndependentCode>')
		end
		if cfg.flags.DisablePIC then
			_p(3,'<PositionIndependentCode>false</PositionIndependentCode>')
		end

		-- TODO: NEON, hardware float settings, endian selection
		-- VS-Android does not support these settings yet... we'll add them manually to <AdvancedOptions> below.

	end


--
-- Add options unsupported by VS-Android UI to <AdvancedOptions>.
--
	function vsandroid.additionalOptions(cfg)

		local function alreadyHas(t, key)
			for _, k in ipairs(t) do
				if string.find(k, key) then
					return true
				end
			end
			return false
		end


		-- Flags that are not supported by the VS-Android UI may be added manually here...

		-- we might want to define the arch to generate better code
		if not alreadyHas(cfg.buildoptions, "-march=") then
			if cfg.architecture == "armv6" then
				table.insert(cfg.buildoptions, "-march=armv6")
			elseif cfg.architecture == "armv7" then
				table.insert(cfg.buildoptions, "-march=armv7")
			end
		end

		-- Android has a comprehensive set of floating point options
		if not cfg.flags.SoftwareFloat and cfg.floatabi ~= "soft" then

			if cfg.architecture == "armv7" then

				-- armv7 always has VFP, may not have NEON

				if not alreadyHas(cfg.buildoptions, "-mfpu=") then
					if cfg.flags.EnableNEON then
						table.insert(cfg.buildoptions, "-mfpu=neon")
					elseif cfg.flags.HardwareFloat or cfg.floatabi == "softfp" or cfg.floatabi == "hard" then
						table.insert(cfg.buildoptions, "-mfpu=vfpv3-d16") -- d16 is the lowest common denominator
					end
				end

				if not alreadyHas(cfg.buildoptions, "-mfloat-abi=") then
					if cfg.floatabi == "hard" then
						table.insert(cfg.buildoptions, "-mfloat-abi=hard")
					else
						-- Android should probably use softfp by default for compatibility
						table.insert(cfg.buildoptions, "-mfloat-abi=softfp")
					end
				end

			else

				-- armv5/6 may not have VFP

				if not alreadyHas(cfg.buildoptions, "-mfpu=") then
					if cfg.flags.HardwareFloat or cfg.floatabi == "softfp" or cfg.floatabi == "hard" then
						table.insert(cfg.buildoptions, "-mfpu=vfp")
					end
				end

				if not alreadyHas(cfg.buildoptions, "-mfloat-abi=") then
					if cfg.floatabi == "softfp" then
						table.insert(cfg.buildoptions, "-mfloat-abi=softfp")
					elseif cfg.floatabi == "hard" then
						table.insert(cfg.buildoptions, "-mfloat-abi=hard")
					end
				end

			end

		elseif cfg.floatabi == "soft" then

			table.insert(cfg.buildoptions, "-mfloat-abi=soft")

		end

		if cfg.flags.LittleEndian then
			table.insert(cfg.buildoptions, "-mlittle-endian")
		elseif cfg.flags.BigEndian then
			table.insert(cfg.buildoptions, "-mbig-endian")
		end

	end


--
-- Write the VS-Android <AntBuild> settings.
--

	function vsandroid.antBuild(cfg)
		if cfg.kind == premake.STATICLIB or cfg.kind == premake.SHAREDLIB then
			return
		end

		_p(2,'<AntBuild>')
		if premake.config.isdebugbuild(cfg) then
			_p(3,'<AntBuildType>Debug</AntBuildType>')
		else
			_p(3,'<AntBuildType>Release</AntBuildType>')
		end
		_p(2,'</AntBuild>')
	end


--
-- Convert Premake warning flags to Visual Studio equivalents.
--

	function vsandroid.warnings(cfg)

		if cfg.flags.NoWarnings then
			_p(3,'<Warnings>DisableAllWarnings</Warnings>')
		elseif cfg.flags.ExtraWarnings then
			_p(3,'<Warnings>AllWarnings</Warnings>')
		end

		-- Ohter warning blocks only when NoWarnings are not specified
		if cfg.flags.NoWarnings then
			return
		end

		if cfg.flags.FatalWarnings then
			_p(3,'<WarningsAsErrors>true</WarningsAsErrors>')
		end

	end


--
-- Translate Premake's optimization flags to the VS-Android equivalents.
--

	function vsandroid.optimization(cfg)

		local result = "O0"

		for _, flag in ipairs(cfg.flags) do
			if flag == "Optimize" then
				result = "O2"
			elseif flag == "OptimizeSize" then
				result = "O2"	-- TODO: Check if vs-android supports Os
			elseif flag == "OptimizeSpeed" then
				result = "O3"
			end
		end

		return result

	end
