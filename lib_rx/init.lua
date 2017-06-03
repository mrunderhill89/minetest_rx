--All this does is load RxLua and make it available to Minetest.
minetest.lib = minetest.lib or {}
minetest.lib.Rx = dofile(minetest.get_modpath("lib_rx").."/rx.lua")

return minetest.lib.Rx
