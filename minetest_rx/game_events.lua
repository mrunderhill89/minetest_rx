minetest = minetest or require("mock_minetest")
local Rx = minetest.lib.Rx or require("rx")
local _ = minetest.lib._ or require("moses_min")

local function dispose_on_shutdown(observer)
	minetest.register_on_shutdown(function()
		observer:onCompleted()
	end)
end

local events = {
	globalstep = Rx.Observable.create(function(observer)
		minetest.register_globalstep(function(dtime)
			local params = {dtime = dtime}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_shutdown = Rx.Observable.create(function(observer)
		minetest.register_on_shutdown(function()
			observer:onNext()
		end)
		dispose_on_shutdown(observer)
	end),
	on_dignode = Rx.Observable.create(function(observer)
		minetest.register_on_dignode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
			local params = {
				pos = pos,
				newnode = newnode,
				placer = placer,
				oldnode = oldnode,
				itemstack = itemstack,
				pointed_thing = pointed_thing
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_punchnode = Rx.Observable.create(function(observer)
		minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
			local params = {
				pos = pos,
				node = node,
				puncher = puncher,
				pointed_thing = pointed_thing
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_placenode = Rx.Observable.create(function(observer)
		minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
			local params = {
				pos = pos,
				newnode = newnode,
				placer = placer,
				oldnode = oldnode,
				itemstack = itemstack,
				pointed_thing = pointed_thing
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_punchplayer = Rx.Observable.create(function(observer)
		minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
			local params = {
				player = player,
				hitter = hitter,
				time_from_last_punch = time_from_last_punch,
				tool_capabilities = tool_capabilities,
				dir = dir,
				damage = damage
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_craft = Rx.Observable.create(function(observer)
		minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
			local params = {
				itemstack = itemstack,
				player = player,
				old_craft_grid = old_craft_grid,
				craft_inv = craft_ind
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	craft_predict = Rx.Observable.create(function(observer)
		minetest.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
			local params = {
				itemstack = itemstack,
				player = player,
				old_craft_grid = old_craft_grid,
				craft_inv = craft_ind
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_item_eat = Rx.Observable.create(function(observer)
		minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
			local params = {
				hp_change = hp_change,
				replace_with_item = replace_with_item,
				itemstack = itemstack,
				user = user,
				pointed_thing = pointed_thing
			}
		end)
		dispose_on_shutdown(observer)
	end),
	on_generated = Rx.Observable.create(function(observer)
		minetest.register_on_generated(function(minp, maxp, blockseed)
			local params = {
				minp = minp,
				maxp = maxp,
				blockseed = blockseed
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_newplayer = Rx.Observable.create(function(observer)
		minetest.register_on_newplayer(function(obj_ref)
			local params = {
				obj_ref = obj_ref
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_prejoinplayer = Rx.Observable.create(function(observer)
		minetest.register_on_prejoinplayer(function(obj_ref)
			local params = {
				name = name,
				ip = ip
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_joinplayer = Rx.Observable.create(function(observer)
		minetest.register_on_joinplayer(function(obj_ref)
			local params = {
				obj_ref = obj_ref
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_dieplayer = Rx.Observable.create(function(observer)
		minetest.register_on_dieplayer(function(obj_ref)
			local params = {
				obj_ref = obj_ref
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_respawnplayer = Rx.Observable.create(function(observer)
		minetest.register_on_respawnplayer(function(obj_ref)
			local params = {
				obj_ref = obj_ref
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_leaveplayer = Rx.Observable.create(function(observer)
		minetest.register_on_respawnplayer(function(obj_ref)
			local params = {
				obj_ref = obj_ref
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_cheat = Rx.Observable.create(function(observer)
		minetest.register_on_respawnplayer(function(obj_ref, cheat)
			local params = {
				obj_ref = obj_ref,
				cheat = cheat
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_chat_message = Rx.Observable.create(function(observer)
		minetest.register_on_chat_message(function(name, message)
			local params = {
				name = name,
				message = message
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end),
	on_protection_violation = Rx.Observable.create(function(observer)
		minetest.register_on_protection_violation(function(pos, name)
			local params = {
				pos = pos,
				name = name
			}
			observer:onNext(params)
		end)
		dispose_on_shutdown(observer)
	end)
}
-- This stream is generally the same as globalstep, but returns
-- the accumulated time since the server was started. It's used
-- for anything that requires polling.
events.globaltime = events.globalstep:scan(function(memo, step)
	memo.time = memo.time + step.dtime
	memo.dtime = step.dtime
	return memo
end, {time = 0, dtime = 0}):map(_.clone)

minetest.Rx.events = events
return events
