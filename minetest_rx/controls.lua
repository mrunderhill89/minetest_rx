local minetest = minetest or require("mock_minetest")
local Rx = minetest.lib.Rx or require("rx")
local _ = minetest.lib._ or require("moses_min")

-- Player -> Key -> Function
-- Null string "" is used to indicate "all players."
local all = ""
local function build_key()
	local key = {
		value = Rx.Subject.create()
	}

	key.change = key.value:scan(function(mem, event)
		local value = event.status and 1 or 0
		if mem.event then
			mem.delta = (event.status and 1 or 0) - (mem.event.status and 1 or 0)
		end
		mem.event = event
		return mem
	end, {delta = 0})

	key.press = key.change:filter(function(v_data)
		return v_data.delta == 1
	end):map("event")

	key.release = key.change:filter(function(v_data)
		return v_data.delta == -1
	end):map("event")

	key.hold = key.change:filter(function(v_data)
		return v_data.delta == 0 and (vdata.event and v_data.event.status)
	end):map("event")

	key.idle = key.change:filter(function(v_data)
		return v_data.delta == 0 and not (vdata.event and v_data.event.status)
	end):map("event")

	key.release_time = key.press:flatMap(function(press_event)
		return control_data[press_event.player][press_event.key].release:take(1):map(function(release_event)
			return {
				press = press_event,
				release = release_event,
				hold_time = release_event.t.time - press_event.t.time
			}
		end)
	end)

	return key
end

local player_meta = {
	__index = function(self,key)
		--print('New Key:"'..key..'"')
		self[key] = build_key()
		return self[key]
	end
}

local function build_player()
	local player = setmetatable({}, player_meta)
	player[all].value:subscribe(function(event)
		player[event.key].value:onNext(event)
	end)
	return player
end

local control_data = setmetatable({}, {
	__index = function(self,key)
		--print('New Player:"'..key..'"')
		self[key] = build_player()
		return self[key]
	end
})
control_data[all][all].value:subscribe(function(event)
	control_data[event.player][all].value:onNext(event)
end)

function on_frame(t)
	for i, player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()
		if player_name ~= all then
			local input = player:get_player_control()
			for key, status in pairs(input) do
				control_data[all][all].value:onNext({
					player = player,
					key = key,
					status = status,
					t = t
				})
			end
		end
	end
end
minetest.Rx.events.globaltime:subscribe(on_frame)
return control_data
