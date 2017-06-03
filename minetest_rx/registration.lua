minetest = minetest or require("mock_minetest")
local Rx = minetest.lib.Rx or require("rx")
local _ = minetest.lib._ or require("moses_min")

local function wrap_existing(name, existing)
  return
    type(existing) == "function" and existing()
    or type(existing) == "string" and minetest[existing]
    or minetest["registered_"..name.."s"]
end

local mt_native = {}

-- Keyless Events
local function keyless_event_setup(name, native, existing)
    local existing = wrap_existing(name, existing)
    local future = Rx.Subject.create()
    local observable = Rx.Observable.create(function(observer)
        for i, value in ipairs(existing) do
            observer:onNext(value)
        end
    end):merge(future)
    local wrapper = function(...)
        local result = {native(...)}
        future:onNext(...)
        return unpack(result)
    end
    return native, wrapper, observable
end

for i, key in pairs({
    "craft",
    "decoration",
    "ore"
  }) do
  mt_native["register_"..key], minetest["register_"..key], minetest["on_register_"..key] = 
    keyless_event_setup(key, minetest["register_"..key])
end

-- Keyed Events
local any = ""
local function key_event_setup(name, native, existing)
    local existing = wrap_existing(name, existing)
    local store = {
        [any] = Rx.Subject.create()
    }
    local observables = function(key)
        if (type(key) ~= "string") then
            return store[any]
        end
        if (store[key] == nil) then
            if string.match(key, "^group:") then
                local g_name = string.gsub(key, "^group:", "")
                -- This is a group.
                store[key] = Rx.Observable.create(function(obs)
                    for k,params in pairs(existing) do
                        local g_val = type(params.groups) == "table" and params.groups[g_name] or 0
                        obs:onNext({
                            key = key,
                            value = g_val,
                            params = params
                        })
                    end
                end):merge(store[any]:map(function(kvp)
                    local params = kvp.value[1]
                    local g_val = type(params.groups) == "table" and params.groups[g_name] or 0
                    return {
                        key = kvp.key,
                        value = g_val,
                        params = params
                    }
                end))
            else
                -- This is just a node name.
                store[key] = Rx.ReplaySubject.create(1)
                if (existing[key]) then
                    store[key]:onNext(existing[key])
                end
            end
        end
        return store[key]
    end
    local wrapper = function(key, ...)
        assert(type(key) == "string", "Key for registration function must be a string. Got "..type(key).." instead.")
        local san_key = string.gsub(key, "^:+", "")
        assert(san_key ~= any, "Attempted to use special 'any' value for registration.")
        local result = {native(":"..san_key, ...)}
        observables(any):onNext({
            key = san_key,
            value = {...}
        })
        observables(key):onNext(...)
        return unpack(result)
    end
    return native, wrapper, observables
end

for i, key in pairs({
    "craftitem",
    "node",
    "tool",
    "privilege"
  }) do
  mt_native["register_"..key], minetest["register_"..key], minetest["on_register_"..key] = 
    key_event_setup(key, minetest["register_"..key])
end
-- Special case for weird plurals.
mt_native.register_entity, minetest.register_entity, minetest.on_register_entity = 
  key_event_setup("entity", minetest.register_entity, "registered_entities")

local function lazy_extend(base, length)
    if (length == 0) then
        return base
    end
    return function(n)
        local step = _.extend(n, base)
        return lazy_extend(step, length-1)
    end
end

-- Extend/Copy functions
for i, key in pairs({
    "craftitem",
    "node",
    "tool",
    "entity"
  }) do
  minetest["extend_"..key] = function(old_name, new_name, params)
    assert(type(old_name) == "string", "Extension target key must be a string. Got "..type(old_name).." instead.")
    assert(old_name ~= any, "Attempted to use special 'any' value for extension.")
    assert(not string.match(old_name, "^group:"), old_name.." is a group and shouldn't be used as an extension target.")
    if type(new_name) ~= "string" and params == nil then
        params = new_name
        new_name = old_name
    end
    local san_name = string.gsub(new_name, "^:+", "")
    local extend = type(params) == "function" and params
        or function(old,new)
            local result = {}
            for k,v in pairs(old) do
                result[k] = v
            end
            for k,v in pairs(new) do
                result[k] = v
            end
            return result
        end
    minetest["on_register_"..key](old_name):subscribe(function(old_params)
        if (old_params) then
            local new_params = extend(old_params, params or {})
            print("Extending "..old_name.." to "..new_name..".")
            -- At least try to prevent infinite loops
            if (old_name == new_name) then
                mt_native["register_"..key](":"..san_name, new_params)
            else
                minetest["register_"..key](":"..san_name, new_params)
            end
        end
    end)
  end
end


