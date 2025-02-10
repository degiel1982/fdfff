aio_digndrop = {
    disable = false
}
local aiocombined_itemdrop = { drop_list = {}} 
function aiocombined_itemdrop:new(drop_list)
    setmetatable({}, aiocombined_itemdrop)
    self.drop_list = drop_list
    return self
end
function aiocombined_itemdrop:get_nodes_of_mod(mod_name)
    local nodes = {}
    for node_name, _ in pairs(core.registered_nodes) do
        if node_name:find("^" .. mod_name .. ":") then
            table.insert(nodes, node_name)
        end
    end
    return nodes
end
function aiocombined_itemdrop:has_pattern(item, patterns)
    if item then
        for _, pat in ipairs(patterns) do
            if string.match(item, pat) then
                return pat
            end
        end
    end
    return nil
end
function aiocombined_itemdrop:construct_drop_list(node)
    local pattern_drop_created = false
    local pattern = {"_waving", "_open","_closed", "_flat", "_a", "_b", "_c", "_d"}
    local pattern_found = self:has_pattern(node.name, pattern)
    if pattern_found then
        local nodename_with_pattern = node.name
        local nodename_without_pattern = string.gsub(node.name, pattern_found, "")
        self.drop_list[node.name] = {
                 max_items = 1,
                 items = {
                     { items = {nodename_without_pattern}, },
                 },
        }
        pattern_drop_created = true
    end
    if type(node.drop) == "string" and node.name ~= node.drop then
        self.drop_list[node.name] = node.drop
    elseif type(node.drop) == "table" then
        table.sort(node.drop.items, function(a, b)
            return (a.rarity or 0) > (b.rarity or 0)  -- Handling cases where 'rarity' might be nil
        end)
        self.drop_list[node.name] = node.drop
    end

end 
function aiocombined_itemdrop:check_tools_if_can_drop(digger,item_stack)
    if item_stack.tools then
        local wielded_item = digger:get_wielded_item():get_name()
        for _, tool in ipairs(item_stack.tools) do
            if wielded_item == tool then
                return false
            else
                return true
            end
        end
    else
        return true
    end
end
function aiocombined_itemdrop:check_toolgroup_if_can_drop(digger,item_stack)
    if item_stack.tool_groups then
        local can_drop = false
        local wielded_item = digger:get_wielded_item():get_name()
        for _, group in ipairs(item_stack.tool_groups) do
            if type(group) == "string" then
                if core.get_item_group(wielded_item, group) > 0 then
                    return true
                end
            elseif type(group) == "table" then
                local matches_all = true
                for _, grp in ipairs(group) do
                    if core.get_item_group(wielded_item, grp) == 0 then
                        return false
                    end
                end
                if matches_all then
                    return true
                end
            end
        end
    else
        return true
    end
end
function aiocombined_itemdrop:new_after_dig_node(pos, oldnode, oldmetadata, digger) 
    aio_digndrop.enable = true
    local max_items = 0
    local item_list = {}
    local dropped_items = 0
    local can_drop = false
    if not self.drop_list[oldnode.name] then
        self:drop_item(oldnode.name, pos, nil, oldnode,digger)
    elseif type(self.drop_list[oldnode.name]) == "string" then
            self:drop_item(self.drop_list[oldnode.name], pos, nil, oldnode,digger)
    elseif type(self.drop_list[oldnode.name]) == "table" then
        if not self.drop_list[oldnode.name].max_items or not self.drop_list[oldnode.name].items then
            core.log("action", "[ERROR] The drop table of node ".. oldnode.name .. " is corrupted")
        else
            max_items = math.random(1,self.drop_list[oldnode.name].max_items)
            item_list = self.drop_list[oldnode.name].items
            for i = 1, max_items do
                for _, item_stacks in ipairs(item_list) do
                    if not self:check_toolgroup_if_can_drop(digger, item_stacks) or not self:check_tools_if_can_drop(digger, item_stacks) then
                        can_drop = false
                        dropped_items = max_items
                        break
                    else
                         can_drop = true
                    end
                    if can_drop then
                        for _, item_name in ipairs(item_stacks.items) do
                            if dropped_items < max_items and math.random(1, (item_stacks.rarity or 1)) == 1 then
                                self:drop_item(item_name, pos, item_stacks, oldnode,digger)
                                dropped_items = dropped_items + 1
                            end
                        end
                    else
                        dropped_items = max_items
                    end
                end
                if dropped_items >= max_items then
                    break
                end
            end
        end
    end
end
function aiocombined_itemdrop:override_items(node)
    node = core.registered_nodes[node]
    if node then
        self:construct_drop_list(node)
        local original_after_dig = node.after_dig_node
        local new_def = {
            drop = "",
            after_dig_node = function(pos, oldnode, oldmetadata, digger)
                self:new_after_dig_node(pos, oldnode, oldmetadata, digger)
                if original_after_dig then
                    original_after_dig(pos, oldnode, oldmetadata, digger)
                end
            end,
        }
        core.override_item(node.name, new_def)
    end
end
function aiocombined_itemdrop:set_nodes(optional_mods)
    if optional_mods then
        for i = 1, #optional_mods do
            local nodes = self:get_nodes_of_mod(optional_mods[i])
            if nodes then
                for _, node in ipairs(nodes) do
                    self:override_items(node)
                end
            else
                core.log("action","[ERROR] Mod " .. optional_mods[i] .. " nodes are not loading")
            end

        end
    else
        core.log("action","[ERROR] No mods found or error loading the mods")
    end
end
function aiocombined_itemdrop:drop_item(node_name, pos, item_stacks, oldnode, digger)
    local drop_pos = vector.add(pos, {x=0, y=0.5, z=0})
    local item = core.add_item(drop_pos, ItemStack(node_name))
    if item then
        if item_stacks ~= nil then
            if item_stacks.inherit_color and oldnode.param2 then
                item:get_luaentity().palette_index = oldnode.param2
            end
        end
        local velocity = {
            x = math.random(-1, 1),
            y = math.random(0.5, 1),
            z = math.random(-1, 1),
        }
        item:set_velocity(velocity)
              -- Set metadata
              local stack = ItemStack(node_name)
              local meta = stack:get_meta()
              meta:set_string("magnet_owner", digger:get_player_name())
              meta:set_string("digger_aio", "dug")  -- Replace "owner_name" with the desired owner
              item:get_luaentity().itemstring = stack:to_string()
    end
    
end
--Create an Object
local itemdrop = aiocombined_itemdrop:new({},{},{})
--Gets the list of mods that has been added in the mod.conf optional_depends field
local installed_mods = core.get_modnames()
-- Overrides all the nodes definitions of the mods that are installed
itemdrop:set_nodes(installed_mods)