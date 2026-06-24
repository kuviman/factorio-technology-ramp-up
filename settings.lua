local constants = require("constants")

local defaultFinal = "rocket-silo"
if mods["space-age"] then
    defaultFinal = "stellar-discovery-solar-system-edge"
end

data:extend{
    {
        type = "double-setting",
        name = constants.settings.initialMultiplier,
        setting_type = "startup",
        minimum_value = 0.0,
        default_value = 1,
        order = "a"
    },
    {
        type = "double-setting",
        name = constants.settings.finalMultiplier,
        setting_type = "startup",
        minimum_value = 0.0,
        default_value = 50,
        order = "b"
    },
    {
        type = "string-setting",
        name = constants.settings.finalTechnology,
        setting_type = "startup",
        default_value = defaultFinal,
        allow_blank = true,
        auto_trim = true,
        order = "c"
    },
    {
        type = "bool-setting",
        name = constants.settings.skipInitialTriggerTechs,
        setting_type = "startup",
        default_value = true,
        order = "d"
    }
}
