local like_honey = { radius = 1, pickup_delay = 5}

function like_honey:new(radius)
    setmetatable({}, like_honey)
    self.radius = radius
    self.pickup_delay = pickup_delay
    return self
end

function like_honey:check_builtin_objects_inside_radius(player, radius)
    local items = {}
    for obj in core.objects_inside_radius(player:get_pos(), radius) do
        if not obj:is_player() then
            if obj:get_luaentity() and obj:get_luaentity().name == "__builtin:item" then
                table.insert(items, obj)
            end
        end
    end
    return items
end
function like_honey:does_the_item_have_an_owner(obj)
    local stack = obj:get_luaentity().itemstring
    local item = ItemStack(stack)
    local meta = item:get_meta()
    local owner = meta:get_string("magnet_owner")
    return owner ~= "" and owner or "no_owner"
end

function like_honey:has_been_dug(entity)
    local stack = entity:get_luaentity().itemstring
    local item = ItemStack(stack)
    local meta = item:get_meta()
    local digger_status = meta:get_string("digger_aio")
    return string.find(digger_status, "dug") ~= nil
end

-- Function to set the owner of an item
function like_honey:set_owner_to_item(obj, player)
    local stack = obj:get_luaentity().itemstring
    local item = ItemStack(stack)
    local meta = item:get_meta()
    meta:set_string("magnet_owner", player:get_player_name())
    meta:set_int("aio_digger_time", core.get_us_time())
    obj:get_luaentity().itemstring = item:to_string()
end

-- Function to check if the owner is the given player
function like_honey:check_if_owner_is_player(player, owner)
    return player:get_player_name() == owner
end

local honey = like_honey:new(1,5)
core.register_globalstep(function(dtime)
    local current_time = core.get_us_core()
    local players = core.get_connected_players()
    if players then
        for _, player in ipairs(players) do
            local player_name = player:get_player_name()
            local player_pos = player:get_pos()
            local found_objects = honey:check_builtin_objects_inside_radius(player, honey.radius)
            if found_objects then
                for _, obj in ipairs(found_objects) do  
                    if not obj:is_player() then
                        local owner = honey:does_the_item_have_an_owner(obj)
                        if owner == "no_owner" then
                            honey:set_owner_to_item(obj,player)
                        elseif owner == player:get_player_name() then   
                            if like_honey:has_been_dug(obj) then
                                local itemstack = ItemStack(obj:get_luaentity().itemstring)
                                itemstack:get_meta():set_string("digger_aio", "")
                                itemstack:get_meta():set_string("magnet_owner", "")
                                itemstack:get_meta():set_int("aio_digger_time", 0)
                                local leftover = player:get_inventory():add_item("main", itemstack)
                                if not leftover:is_empty() then
                                    core.add_item(player_pos, leftover)
                                end
                                obj:remove()
                            else
                                local itemstack = ItemStack(obj:get_luaentity().itemstring)
                                local time_dropped = itemstack:get_meta():get_int("aio_digger_time")
                                local difference = (current_time - time_dropped) / 1000
                                if difference >= honey.pickup_delay then
                                    core.chat_send_player(player_name, "Time is up")
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)