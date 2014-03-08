---
-- base/field.lua
--
-- Fields hold a particular bit of information about a configuration, such
-- as the language of a project or the list of files it uses. Each field has
-- a particular data "kind", which describes the structure of the information
-- it holds, such a simple string, or a list of paths.
--
-- The field.* functions here manage the definition of these fields, and the
-- accessor functions required to get, set, remove, and merge their values.
--
-- Copyright (c) 2014 Jason Perkins and the Premake project
---

	premake.field = {}
	local field = premake.field


-- Lists to hold all of the registered fields and data kinds

	field._list = {}
	field._kinds = {}

	-- For historical reasons
	premake.fields = field._list

-- A cache for data kind accessor functions

	field._accessors = {}


---
-- Register a new field.
--
-- @param f
--    A table describing the new field, with these keys:
--     name     A unique string name for the field, to be used to identify
--              the field in future operations.
--     kind     The kind of values that can be stored into this field. Kinds
--              can be chained together to create more complex types, such as
--              "list:string".
--
--    In addition, any custom keys set on the field description will be
--    maintained.
--
-- @return
--    A populated field object. Or nil and an error message if the field could
--    not be registered.
---

	function field.new(f)
		-- Translate the old approaches to data kind definitions to the new
		-- one used here. These should probably be deprecated eventually.

		local kind = f.kind

		if f.list then
			kind = "list:" .. kind
		end

		if f.keyed then
			kind = "keyed:" .. kind
		end

		f._kind = kind

		field._list[f.name] = f
		return f
	end



---
-- Register a new kind of data for field storage.
--
-- @param tag
--    A unique name of the kind; used in the kind string in new field
--    definitions (see new(), above).
-- @param functions
--    A table of processor functions for the new kind.
---

	function field.kind(tag, functions)
		field._kinds[tag] = functions
	end



---
-- Build an "accessor" function to process incoming values for a field. This
-- function should be an interview question.
--
-- An accessor function takes the form of:
--
--    function (field, current, value, nextAccessor)
--
-- It receives the target field, the current value of that field, and the new
-- value that has been provided by the project script. It then returns the
-- new value for the target field.
--
-- @param f
--    The field for which an accessor should be returned.
-- @param method
--    The type of accessor function required; currently this should be one of
--    "set", "remove", or "merge" though it is possible for add-on modules to
--    extend the available methods by implementing appropriate processing
--    functions.
-- @return
--    An accessor function for the field's kind and method. May return nil
--    if no processing functions are available for the given method.
---


	function field.accessor(f, method)
		-- Prepare a cache for accessors using this method; each encountered
		-- kind only needs to be fully processed once.

		field._accessors[method] = field._accessors[method] or {}
		local cache = field._accessors[method]

		-- Helper function recurses over each piece of the field's data kind,
		-- building an accessor function for each sequence encountered. Results
		-- cached from earlier calls are reused again.

		local function accessorForKind(kind)
			-- Have I already cached a result from an earlier call?
			if cache[kind] then
				return cache[kind]
			end

			-- Split off the first piece from the rest of the kind. If the
			-- incoming kind is "list:key:string", thisKind will "list" and
			-- nextKind will be "key:string".

			local thisKind = kind:match('(.-):') or kind
			local nextKind = kind:sub(#thisKind + 2)

			-- Get the processor function for this kind. Processors perform
			-- data validation and storage appropriate for the data structure.

			local functions = field._kinds[thisKind]
			if not functions then
				error("Invalid field kind '" .. thisKind .. "'")
			end

			local processor = functions[method]
			if not processor then
				return nil
			end

			-- Now recurse to get the accessor function for the remaining parts
			-- of the field's data kind. If the kind was "list:key:string", then
			-- the processor function handles the "list" part, and this function
			-- takes care of the "key:string" part.

			local nextAccessor = accessorForKind(nextKind)

			-- Now here's the magic: wrap the processor and the next accessor
			-- up together into a Matryoshka doll of function calls, each call
			-- handling just it's level of the kind.

			accessor = function(f, current, value)
				return processor(f, current, value, nextAccessor)
			end

			-- And cache the result so I don't have to go through that again
			cache[kind] = accessor
			return accessor
		end

		-- The _kind is temporary; I'm using it while I transition off the old
		-- codebase. Once everything is migrated it can go away.

		return accessorForKind(f._kind or f.kind)
	end



---
-- Fetch a field description by name.
---

	function field.get(name)
		return field._list[name]
	end



	function field.merge(f, current, value)
		local processor = field.accessor(f, "merge")
		if processor then
			return processor(f, current, value)
		else
			return value
		end
	end


---
-- Is this a field that supports merging values together? Non-merging fields
-- can simply overwrite their values, merging fields can call merge() to
-- combine two values together.
---

	function field.merges(f)
		return (field.accessor(f, "merge") ~= nil)
	end