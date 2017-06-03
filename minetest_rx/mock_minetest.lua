package.path = package.path 
	.. ";../lib_moses/?.lua"
	.. ";../lib_rx/?.lua"
	.. ";../lib_deps/?.lua"

local mock = {
	get_modpath = function(path)
		return "."
	end,
	Rx = {
		events = {
			globaltime = {
				subscribe = function()
					print("events.globaltime subscribed")
				end
			}
		}
	},
	lib = {
		_ = require("moses_min"),
		Rx = require("rx"),
		Deps = require("deps"),
	}
}
return mock
