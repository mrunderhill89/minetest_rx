local _ = _ or require("moses_min")
local Rx = Rx or require("rx")

local warn = print

local load_module = Rx.Subject.create()
local load_dependency = Rx.Subject.create()
local Deps = {
  --A read-only version of load_module for public use.
  on_module_load = load_module:map(_.identity),
  on_dependency_load = load_dependency:map(_.identity),
	modules = {},
	dependencies = {}
}

local function kvp(tab)
	local i = 1
	local array = {}
	for k,v in pairs(tab) do
		array[i] = {
			key = k,
			value = v
		}
		i = i + 1
	end
	return array
end

local function table_to_string(tab)
	return _.reduce(kvp(tab), function(result, kvp)
		local head = result.."\n"..tostring(kvp.key).."=>"
		return head..tostring(kvp.value)
	end, "{").."\n}"
end

-- Internal functions

local function to_property(source, ...)
	local prop = Rx.BehaviorSubject.create(...)
  source:subscribe(
		_.bind(prop.onNext, prop),
		_.bind(prop.onError, prop),
		_.bind(prop.onCompleted, prop)
	)
	return prop
end

local function bind_last(fun, ...)
  local bound_args = {...}
  return function (...)
      return fun(unpack(_.append({...},bound_args)))
    end
end

-- Get Module

function Deps.get_module(name)
	if _.isNil(Deps.modules[name]) then
		--Create a branch off of on_module_load for this module.
		Deps.modules[name] = to_property(
      load_module:filter(function(loaded_module)
        return loaded_module.name == name
      end):map(function(loaded_module)
        return loaded_module.value
      end):distinctUntilChanged())
	end
	return Deps.modules[name]
end

-- Get Dependency

function Deps.get_dependency(deps)
	if (_.isArray(deps) and _.size(deps) > 1) then
		for ex_deps, obs in pairs(Deps.dependencies) do
			if (_.same(ex_deps, deps)) then
				--Reuse the previous observable if there is one
				return obs
			end
		end
		local new_dep = Rx.Observable.combineLatest(
			unpack(
				 _.map(deps, function(key, module_name)
					return Deps.get_module(module_name)
				end)
			)
		)
		new_dep:subscribe(function(...)
			load_dependency:onNext({
				deps = deps,
				results = {...}
			})
		end)
		Deps.dependencies[deps] = new_dep
		return new_dep
	elseif (_.isString(deps)) then
		return Deps.get_module(deps)
	elseif (_.isArray(deps)) then
		if (_.size(deps) == 1) then
			return Deps.get_module(deps[1])
		else
			error("Dependency array is empty.")
		end
	else
		error("Dependency needs to be a string or array of strings.\n"
		.."Got "..typeof(deps).." instead.")
	end
end

--Depend

--- Core dependency registration function. Calls the provided function when
-- all dependencies are met. "Transform" parameter allows for Rx functions
-- to be called on the returned dependency.
-- @arg {string, array<string>} deps: dependencies to check before calling.
-- @arg {function(...)=>nil} definition: definition function to call when all deps are loaded.
-- @arg {function(observable)=>observable} transform: modifies the initial dependency observable.
function Deps.depend_custom(deps, definition, transform)
	if _.isCallable(definition) then
		if (_.isArray(deps) and _.size(deps) == 0) then
		  warn("Deps.depend: Got dependency array but it was empty. Do you really need to use dependencies for this?")
		  definition()
		else
		  transform(Deps.get_dependency(deps)):subscribe(definition)
		end
	else
		error("Deps.depend: Definition function needs to be callable.")
	end
end

--- Standard dependency function. Automatically reloads when dependencies do.
function Deps.depend(deps, definition)
	return Deps.depend_custom(deps, definition, _.identity)
end

--- Definition is ran only once after all deps are loaded. Reloading has no effect.
-- Use this if you have some sensitive data that you don't want clobbered on reload.
function Deps.depend_once(deps, definition)
	return Deps.depend_custom(deps, definition, bind_last(Rx.Observable.take, 1))
end

--- Definition will stop listening to reloads when the given observable sends a value.
function Deps.depend_until(deps, definition, til)
	return Deps.depend_custom(deps, definition, bind_last(Rx.Observable.takeUntil, til))
end

--- Definition will stop listening to reloads when the predicate returns falsy.
function Deps.depend_while(deps, definition, predicate)
	return Deps.depend_custom(deps, definition, bind_last(Rx.Observable.takeWhile, predicate))
end


--Define

--- Super-simple module definition. Use this for modules already loaded using
-- require or dofile that don't need dependencies.
-- @arg {string} module_name: name of the module to define
-- @arg {any} value: value to store in the module
function Deps.define_value(module_name, value)
  local output = Deps.get_module(module_name)
	local module_event = {
		name = module_name,
		value = value
	}
	load_module:onNext(module_event)
  
  --Debug logic. Make sure the module got loaded correctly
  local result = output:getValue()
	assert(result == module_event.value, 
		"DefineValue: Module '"..module_event.name.."' got something other than the value passed into it."
		.."\nGot: "..tostring(result or "Nothing")
		.."\nShould Be: "..tostring(module_event.value or "Nothing")
	)
end

--- Core module definition function. Very similar to define_custom, but passes
-- the results of the definition function in as a new module.
--	Example Usage:
--	define("MyModule", 
--    {"dep1", "dep2"},
--		function(dep1,dep2) 
--			return my_module 
--		end
--  )
-- @arg {string} module_name: name of the module to define
-- @arg {string, array<string>} deps: dependencies to check before calling.
-- @arg {function(...)=>nil} definition: definition function to call when all deps are loaded.
-- @arg {function(observable)=>observable} transform: modifies the initial dependency observable.
function Deps.define_custom(module_name, deps, definition, transform)
	if _.isCallable(definition) then
      Deps.depend_custom(deps, 
        function(...)
          Deps.define_value(module_name, definition(...))
        end
      ,transform)
	else
    warn("Deps.define: Received non-callable data for definition. You might want to use define_value instead.")
		Deps.define_value(module_name, definition)
	end
end

function Deps.define(module_name, deps, definition)
	return Deps.define_custom(module_name, deps, definition, _.identity)
end

function Deps.define_once(module_name, deps, definition)
	return Deps.define_custom(module_name, deps, definition, bind_last(Rx.Observable.take, 1))
end

function Deps.define_until(module_name, deps, definition, til)
	return Deps.define_custom(module_name, deps, definition, bind_last(Rx.Observable.takeUntil, til))
end

function Deps.define_while(module_name, deps, definition, predicate)
	return Deps.define_custom(module_name, deps, definition, bind_last(Rx.Observable.takeWhile, predicate))

end

-- Globalize

function Deps.globalize()
  depend = Deps.depend
  depend_once = Deps.depend_once
  depend_until = Deps.depend_until
  depend_while = Deps.depend_while
  depend_custom = Deps.depend_custom
  
  define = Deps.define
  define_value = Deps.define_value
  define_once = Deps.define_once
  define_until = Deps.define_until
  define_while = Deps.define_while
  define_custom = Deps.define_custom
end

-- Finalize

function Deps.finalize()
	Deps.on_module_load:onCompleted()
end

--Debugging Tools

function print_module(name, value)
	local value_text = (_.isNil(value)) and "Empty" 
		or tostring(value)
	print("module: "..name.." = "..value_text)
end

function Deps.log_modules()
	_.each(Deps.modules, function(name, obs)
		print_module(name, obs:getValue())
	end)
end

function Deps.rx_log_modules()
	--Log the modules that we already have (if any).
	Deps.log_modules()
	Deps.on_module_load:subscribe(function(params)
		print_module(params.name, params.value)
	end)
	Deps.on_dependency_load:subscribe(function(dep)
		print("dependency:"..table_to_string(dep.deps))
	end)
end

--Default Modules
Deps.define_value("Moses", _)
Deps.define_value("Rx", Rx)

--Return module interface
return Deps
