local accumulator = 0
local interval = 0.1
local check_distance = 5 -- Distance beyond which to reset metadata
local current_time = core.get_us_time()

-- Store last known positions of players
local player_last_pos = {}
core.register_globalstep(function(dtime)
    
    
    accumulator = accumulator + dtime
    if accumulator < interval then return end
    accumulator = 0

    -- Get list of connected players
    local players = core.get_connected_players()
    for _, player in pairs(players) do
        -- Get player position
        local player_name = player:get_player_name()
        local player_pos = player:get_pos()
        local last_pos = player_last_pos[player_name]

        -- Find objects within a 3-block radius of the player
        for obj in core.objects_inside_radius(player_pos, 2) do
            if not obj:is_player() then
                if obj:get_luaentity() and obj:get_luaentity().name == "__builtin:item" then
                    local stack = obj:get_luaentity().itemstring
                    local item = ItemStack(stack)
                    local meta = item:get_meta()
                    local obj_pos = obj:get_pos()
                    
                    if not meta:get_string("owner") or meta:get_string("owner") == "" then
                        -- Set the meta of the item to the player's username if not already set
                        meta:set_string("owner", player:get_player_name())
                        meta:set_int("time_of_drop", core.get_us_time())
                    end
                        if meta:get_string("owner") == player:get_player_name() then
                            -- Ensure the entity is an item entity
                            if obj:get_luaentity() and obj:get_luaentity().name == "__builtin:item" then
                                -- Simulate picking up the item by adding it to the player's inventory
                                local itemstack = ItemStack(obj:get_luaentity().itemstring)
                                local leftover = player:get_inventory():add_item("main", itemstack)
                                if not leftover:is_empty() then
                                    core.add_item(player_pos, leftover)
                                end
                                meta:set_string("owner", "")
                                -- Remove the entity from the world
                                obj:remove()
                                current_time = new_time
                            end
                        end
                end
            end
        end

        -- Check if the player moved away from the last position
        if last_pos then
            local distance = vector.distance(player_pos, last_pos)
            if distance >= check_distance then
                -- Reset metadata of items within the check distance
                for obj in core.objects_inside_radius(last_pos, check_distance) do
                    if not obj:is_player() then
                        if obj:get_luaentity() and obj:get_luaentity().name == "__builtin:item" then
                            local stack = obj:get_luaentity().itemstring
                            local item = ItemStack(stack)
                            local meta = item:get_meta()
                            if meta:get_string("owner") == player_name then
                                meta:set_string("owner", "")
                            end
                        end
                    end
                end
            end
        end

        -- Update last known position of the player
        player_last_pos[player_name] = player_pos
    end
end)
