minetest = minetest or require("mock_minetest")
local modpath = minetest.get_modpath("minetest_rx")
minetest.Rx = {}
dofile(modpath.."/registration.lua")
dofile(modpath.."/game_events.lua")
dofile(modpath.."/controls.lua")
