local start_time = core.get_us_time()

dofile(core.get_modpath("aio_digndrop") .. "/digndrop.lua")
dofile(core.get_modpath("aio_digndrop") .. "/newhoney.lua")

core.register_on_mods_loaded(function()
    local end_time = core.get_us_time()
    local load_time = (end_time - start_time) / 1000 -- Convert microseconds to milliseconds
    core.log("action", "Mod: ".."[Dig\'nDrop]" .." is loaded after " .. load_time .. " ms")
end)

