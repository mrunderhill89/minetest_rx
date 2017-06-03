--All this does is load Moses and make it available to Minetest.
minetest.lib = minetest.lib or {}
minetest.lib._ = dofile(minetest.get_modpath("lib_moses").."/moses_min.lua")

return minetest.lib._
